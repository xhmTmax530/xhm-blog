---
title: 基于WireGuard的国内到国外VPS组网架构
date: 2025-11-13 18:05:00+08:00
draft: false
categories: ["技术"]
tags:
- WireGuard
- VPN
- VPS
- 组网
---

## 概述与技术栈建议
- **需求实现**：
  - **DNS分流 (黑名单模式)**：被墙域名通过`8.8.8.8`走WireGuard隧道解析；国内及所有未匹配的域名，默认通过`114.114.114.114`直连解析。
  - **流量分流 (黑名单模式)**：目标IP在大陆IP列表中的流量直连；目标IP在被墙IP列表中的流量走隧道；所有未匹配的流量默认直连。
  - **安全增强**：集成Kill Switch，当隧道意外断开时，自动阻止所有应走隧道的流量，防止真实IP泄露。
  - **自动化与持久化**：所有路由和防火墙规则与WireGuard接口生命周期绑定，实现开机自启、自动配置与清理，无需手动干预。
- **技术栈**：
  - WireGuard：VPN隧道（UDP，端口51820）。
  - Dnsmasq：本地DNS服务器，分流解析。
  - ipset + iptables + ip rule/route：政策路由分流。
  - gfwlist2dnsmasq.sh：生成被墙域名黑名单。
  - cron + bash：自动化更新。

- **注意事项**：
  - 先在测试环境试运行，避免影响生产。
  - VPS防火墙需允许WireGuard端口：`ufw allow 51820/udp`。
  - VPS启用IP转发：`echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf; sysctl -p`。

## 步骤1: 安装必要工具
- **VPS (服务器端)**：
```bash
  # 2. 更新Dnsmasq域名列表
  wget -O /etc/dnsmasq.d/accelerated-domains.china.conf https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf
  wget -O /etc/dnsmasq.d/bogus-nxdomain.china.conf https://github.com/felixonmars/dnsmasq-china-list/raw/master/bogus-nxdomain.china.conf
  # 清空gfwlist ipset，让脚本重新填充
  ipset flush gfwlist
  /usr/local/bin/gfwlist2dnsmasq.sh -s 8.8.8.8 -i gfwlist -o /etc/dnsmasq.d/gfwlist.conf
  
  # 3. 更新ipset IP列表
  # 使用临时文件避免网络问题导致列表被清空
  TMP_FILE=$(mktemp)
  wget -O "$TMP_FILE" https://github.com/gaoyifan/china-operator-ip/raw/ip-lists/china.txt
  ipset flush china_ip
  while read line; do ipset add china_ip $line; done < "$TMP_FILE"
  rm "$TMP_FILE"
  ipset add china_ip 114.114.114.114
  
  # 4. 重启Dnsmasq服务以应用新域名列表
  systemctl restart dnsmasq
  echo "Lists updated successfully."
  ```
- **VPS (/etc/wireguard/wg0.conf)** - (此部分无变化):
  ```ini
  [Interface]
  Address = 10.0.0.1/24
  PrivateKey = <VPS私钥>
  ListenPort = 51820
  PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
  SaveConfig = true
  
  [Peer]
  PublicKey = <客户端公钥>
  AllowedIPs = 10.0.0.2/32
  ```
  - 启动：`wg-quick up wg0; systemctl enable wg-quick@wg0`

- **客户端 (/etc/wireguard/wg0.conf)** - **【核心修改】**
  **将原配置替换为以下完整内容。** 它集成了策略路由、防火墙规则和Kill Switch，实现了完全自动化。

  ```ini
  [Interface]
  Address = 10.0.0.2/24
  PrivateKey = <客户端私钥>
  DNS = 127.0.0.1
  MTU = 1420
  # 关键：告诉wg-quick不要自动修改主路由表，让我们的策略路由完全接管
  Table = off
  
  # === 启动时自动执行 ===
  # 1. 创建策略路由: 所有被标记(fwmark 0x1)的流量，查询路由表100
  PostUp = ip rule add fwmark 0x1 table 100
  # 2. 在路由表100中，设置默认网关为VPS的隧道IP (10.0.0.1)，通过wg0接口(%i)出去
  PostUp = ip route add default via 10.0.0.1 dev %i table 100
  # 3. 创建一个新的iptables链，用于集中管理标记规则
  PostUp = iptables -t mangle -N WIREGUARD_MARK
  # 4. 将进入和本机产生的数据包都送到这个新链进行处理
  PostUp = iptables -t mangle -A PREROUTING -j WIREGUARD_MARK
  PostUp = iptables -t mangle -A OUTPUT -j WIREGUARD_MARK
  # 5. 在链中定义规则: 如果目标IP是国内IP(在china_ip集合中)，则直接返回，不再继续匹配
  PostUp = iptables -t mangle -A WIREGUARD_MARK -m set --match-set china_ip dst -j RETURN
  # 6. 如果目标IP是被墙IP(在gfwlist集合中)，则打上标记0x1
  PostUp = iptables -t mangle -A WIREGUARD_MARK -m set --match-set gfwlist dst -j MARK --set-mark 0x1
  # 7. 如果是本机发往国外DNS(8.8.8.8)的查询请求，也打上标记0x1，确保DNS查询本身也走隧道
  PostUp = iptables -t mangle -A WIREGUARD_MARK -p udp -d 8.8.8.8 --dport 53 -j MARK --set-mark 0x1
  # 8. 添加Kill Switch: 在OUTPUT链顶部插入规则，如果数据包有标记0x1但出口不是wg0(%i)，则直接丢弃
  PostUp = iptables -I OUTPUT 1 -m mark --mark 0x1 ! -o %i -j DROP
  
  # === 关闭时自动清理 (顺序与PostUp相反) ===
  PreDown = iptables -D OUTPUT -m mark --mark 0x1 ! -o %i -j DROP
  PreDown = iptables -t mangle -D PREROUTING -j WIREGUARD_MARK
  PreDown = iptables -t mangle -D OUTPUT -j WIREGUARD_MARK
  PreDown = iptables -t mangle -F WIREGUARD_MARK
  PreDown = iptables -t mangle -X WIREGUARD_MARK
  PreDown = ip route del default via 10.0.0.1 dev %i table 100
  PreDown = ip rule del fwmark 0x1 table 100
  
  [Peer]
  PublicKey = <VPS公钥>
  AllowedIPs = 0.0.0.0/0, ::/0 # 允许所有IP通过隧道，但具体走向由策略路由决定
  Endpoint = <VPS公IP>:51820
  PersistentKeepalive = 25
  ```
  - 启动：`wg-quick up wg0; systemctl enable wg-quick@wg0`

## 步骤3: 配置Dnsmasq（DNS分流）- 【逻辑修正】
- **主配置 (/etc/dnsmasq.conf)** - (无变化):
  ```
  no-resolv
  strict-order
  listen-address=127.0.0.1
  port=53
  conf-dir=/etc/dnsmasq.d/,*.conf
  ```
- **设置默认国内DNS (`/etc/dnsmasq.d/upstream.conf`)** - **【关键修改】**
  ```bash
  # 创建此文件，将114设为所有未匹配查询的默认DNS服务器
  echo "server=114.114.114.114" | sudo tee /etc/dnsmasq.d/upstream.conf
  ```
- **国内域名白名单** - **【修正指导】**
  ```bash
  # 只需下载，无需任何手动编辑
  wget https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf -O /etc/dnsmasq.d/accelerated-domains.china.conf
  wget https://github.com/felixonmars/dnsmasq-china-list/raw/master/bogus-nxdomain.china.conf -O /etc/dnsmasq.d/bogus-nxdomain.china.conf
  ```
- **被墙黑名单 (`gfwlist.conf`)** - (无变化):
  ```bash
  # 此脚本会为gfwlist中的域名强制指定8.8.8.8作为DNS服务器
  /usr/local/bin/gfwlist2dnsmasq.sh -s 8.8.8.8 -i gfwlist -o /etc/dnsmasq.d/gfwlist.conf
  ```
- **系统DNS与重启**:
  ```bash
  echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
  sudo systemctl restart dnsmasq
  ```
- **新原理**:
  Dnsmasq现在以“黑名单”模式工作。`gfwlist.conf`中的域名被**特殊规则**强制导向`8.8.8.8`。而所有其他域名（包括国内和未知域名），由于没有匹配到特殊规则，都会回退使用我们在`upstream.conf`中设置的**默认DNS** `114.114.114.114`进行解析。

## 步骤4: 配置ipset（IP分流）
此步骤的命令本身是正确的，它们用于在系统启动时或手动执行时创建 `ipset` 集合。
- 创建：
  ```
  sudo ipset create china_ip hash:net
  sudo ipset create gfwlist hash:ip
  ```
- 加载china_ip：
  ```bash
  # 建议将此长命令放入自动化更新脚本中
  wget -O - https://github.com/gaoyifan/china-operator-ip/raw/ip-lists/china.txt | sudo xargs -I {} ipset add china_ip {}
  sudo ipset add china_ip 114.114.114.114
  ```
> **注意**：`gfwlist` ipset 会由 `gfwlist2dnsmasq.sh` 脚本在运行时自动填充。

## 步骤5 & 6: 配置iptables与政策路由 - 【已整合】
**这两个步骤已被完全整合入步骤2的客户端WireGuard配置文件中** (`PostUp`和`PreDown`部分)，实现了自动化管理，无需再手动执行或使用 `netfilter-persistent` 保存。

## 步骤7: 自动化更新
此脚本依然非常有用，用于定期更新域名和IP列表。
- 脚本 (/usr/local/bin/update_lists.sh)：
  ```bash
  #!/bin/bash
  set -e # 遇到错误立即退出
  
  # 1. 更新Dnsmasq域名列表
  wget -O /etc/dnsmasq.d/accelerated-domains.china.conf https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf
  wget -O /etc/dnsmasq.d/bogus-nxdomain.china.conf https://github.com/felixonmars/dnsmasq-china-list/raw/master/bogus-nxdomain.china.conf
  # 清空gfwlist ipset，让脚本重新填充
  ipset flush gfwlist
  /usr/local/bin/gfwlist2dnsmasq.sh -s 8.8.8.8 -i gfwlist -o /etc/dnsmasq.d/gfwlist.conf
  
  # 2. 更新ipset IP列表
  # 使用临时文件避免网络问题导致列表被清空
  TMP_FILE=$(mktemp)
  wget -O "$TMP_FILE" https://github.com/gaoyifan/china-operator-ip/raw/ip-lists/china.txt
  ipset flush china_ip
  while read line; do ipset add china_ip $line; done < "$TMP_FILE"
  rm "$TMP_FILE"
  ipset add china_ip 114.114.114.114
  
  # 3. 重启Dnsmasq服务以应用新域名列表
  systemctl restart dnsmasq
  echo "Lists updated successfully."
  ```
- 权限与定时任务：
  ```bash
  sudo chmod +x /usr/local/bin/update_lists.sh
  # 编辑定时任务: sudo crontab -e
  # 添加以下行，表示每天凌晨3点运行
  0 3 * * * /usr/local/bin/update_lists.sh
  ```

## 步骤8: 测试与优化 - 【更新验证逻辑】
- **DNS测试**:
  - `dig baidu.com @127.0.0.1`  # 应从`114.114.114.114`解析（直连）。
  - `dig google.com @127.0.0.1`  # 应从`8.8.8.8`解析（走隧道）。
  - `dig some-random-site.com @127.0.0.1` # 应从`114.114.114.114`解析（直连）。
- **流量测试**:
  - `curl ip.cn`  # 应显示**本地**公网IP（直连）。
  - `curl ifconfig.me` # 应显示**VPS**的公网IP（走隧道）。
  - `curl cip.cc` # 访问一个未知网站，应显示**本地**公网IP（直连）。
- **Kill Switch测试**:
  - 在客户端运行 `sudo wg-quick down wg0`。
  - 此时，您应该**无法**访问 `google.com` (因为应走隧道的流量被阻断)，但**依然可以**访问 `baidu.com` (因为直连流量不受影响)。
  - 运行 `sudo wg-quick up wg0` 即可恢复。