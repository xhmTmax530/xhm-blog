---
title: "Gemini Cli 新手教程"
date: 2025-11-28T12:35:00+08:00
draft: false
categories: ["技术"]
tags: ["Gemini Cli", "agent", "大模型", "命令行编程工具", "新手小白"]
---
# Gemini Cli 新手教程

## windows安装gemini cli

### 安装到D盘的方式：

默认情况下，Node.js 的安装机制（npm）会将全局包（Global Packages）和缓存都放在 C 盘的用户目录下（AppData），随着时间推移，这会占用大量空间。

作为专家，我为你提供一套**最稳妥、最标准**的解决方案：**修改 npm 的全局安装路径配置**。这样你不需要重新安装 Windows，也不用把 Node.js 主程序卸载（虽然也可以），就能把占用空间最大的“包”和“缓存”全部迁移到 D 盘。

请跟着我的步骤一步步操作：

#### 第一步：在 D 盘建立专属目录

我们需要在 D 盘手动创建两个文件夹，一个用来放程序（如 Gemini CLI），一个用来放缓存。

1. 打开 D 盘。
2. 创建一个名为 NodeJS 的文件夹（名字随意，建议英文，不要有空格）。
3. 进入 D:\NodeJS，再新建两个文件夹：
   - node_global （用来存放安装的程序，如 gemini）
   - node_cache （用来存放下载过程中的缓存，省 C 盘空间）

#### 第二步：告诉 npm 修改路径

打开你的终端（PowerShell 或 CMD），分别输入以下两条命令（一行输入完按回车）：

1. **修改全局安装路径到 D 盘：**

   ```bash
   npm config set prefix "D:\NodeJS\node_global"
   ```

2. 修改缓存路径到 D 盘：

```bash
npm config set cache "D:\NodeJS\node_cache"
```

*验证一下：* 输入 npm config list，检查输出信息中是否包含了你刚才设置的 D 盘路径。

#### 第三步：配置环境变量（最关键的一步）

这步如果不做，你虽然安装到了 D 盘，但你在终端输入 gemini 时，Windows 会告诉你“找不到命令”，因为它不知道去 D 盘找。

1. **打开设置**：按 Win 键，搜索“**编辑系统环境变量**”，并打开它。
2. **进入环境配置**：点击右下角的 **“环境变量”** 按钮。
3. **找到 Path 变量**：
   - 在上面的 **“用户变量”** 框里（注意是上面那个框，不是下面的系统变量），找到名为 Path 的一行，选中它，点击 **“编辑”**。
4. **新建路径**：
   - 点击右侧的 **“新建”**。
   - 输入：D:\NodeJS\node_global
   - *(这是我们刚才建立的那个文件夹)*
5. **保存**：连续点击“确定”关闭所有窗口。

**注意**：如果你之前在 C 盘安装过 Node.js，Path 里可能有一个指向 C:\Users\你的用户名\AppData\Roaming\npm 的路径，你可以把它删除，或者保留也可以（D 盘的新路径优先级最好排在上面）。

#### 第四步：安装 Gemini CLI

现在，万事俱备，我们可以安装了。请**重启一下你的终端**（关闭 PowerShell 再重新打开），让刚才的环境变量生效。

输入安装命令：

```bash
npm install -g @google/gemini-cli
```

**原理分析**：

- 此时，npm 会把 Gemini CLI 的核心文件下载并解压到 D:\NodeJS\node_global\node_modules 下。
- 它会把 gemini 这个启动指令放到 D:\NodeJS\node_global 下。
- 因为我们在第三步把这个 D 盘路径告诉了 Windows，所以系统能找到它。

#### 第五步：验证安装

安装完成后，输入：

```bash
where gemini
```

如果系统返回类似 D:\NodeJS\node_global\gemini 的路径，恭喜你！**你已经成功实现了“程序装在 C 盘（Node.js），但数据和工具装在 D 盘”的完美分离。**

现在你可以输入 gemini 开始使用了，完全不用担心它占用 C 盘空间。

#### 第六步：登入Gemini Cli

进入到你的项目中，键入:gemini ，你可以通过登入google 和 直接使用API 两种方式，我直接用了后者，记得在AI studio 获得免费层级的API即可

## Gemini cli 命令

### Gemini CLI最核心的“命令菜单”

| 命令                                                         | 大白话解释（像朋友聊天）                                     | 背后原理                                                     | 实际新手最常用场景（带例子）                                 |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `/about`                                                     | 告诉我你现在到底是哪个版本？老子要确认一下是不是最新         | 读取本地的package.json版本号并显示                           | 你怀疑功能不对，先敲这个确认版本对不对                       |
| `/auth`                                                      | 换一种登录Gemini的方式（比如换API Key、换Google账号）        | Gemini CLI支持多种认证方式（API Key、OAuth、Service Account等） | 你公司换了Google账号，或者想用更高级的Gemini 1.5 Pro模型时用 |
| `/bug`                                                       | “我发现个bug！帮我一键打包发给作者！”                        | 把你的配置、版本、错误日志打包，直接打开GitHub提issue页面    | 用着用着突然报错，你懒得自己截图，直接 `/bug` 一键上报       |
| `/chat list` `/chat save <tag>` `/chat resume <tag>` `/chat delete <tag>` | 聊天记录的“存档/读档/删档”系统，像游戏存档一样               | 会把当前完整的对话上下文（包括代码、图片）存在本地JSON文件   | 你写了一半大项目，晚上要睡觉：`/chat save 项目v1` → 第二天 `/chat resume 项目v1` 继续干 |
| `/chat share <file>`                                         | 把当前聊天记录导出成好看的markdown或json给别人看             | 把对话转成标准格式保存                                       | 你写完一个牛逼脚本，想发给同事：`/chat share 今天写的爬虫.md` |
| `/clear`                                                     | 一键清屏 + 清掉当前对话历史，干干净净重新开始                | 把终端画面清空，同时把当前会话上下文彻底丢弃                 | 刚才聊得太乱了，想重新来过                                   |
| `/compress`                                                  | “这段对话太长了，帮我浓缩成一段总结，省点token！”            | 让Gemini自己总结前面所有对话，替换掉原始长上下文             | 对话超过10万字快超上下文限制了，敲一下瞬间变几百字           |
| `/copy`                                                      | 自动把AI最后输出的那段代码/文字复制到剪贴板                  | 直接调用系统剪贴板工具（pbcopy/clip）                        | AI刚给你写完一段Python，直接 `/copy` → Ctrl+V就能粘到编辑器里 |
| `/docs`                                                      | 直接打开官方完整文档（就是你给我的那个网站）                 | 在浏览器打开 https://geminicli.com/docs/                     | 你想看最详细的说明，直接敲这个比搜半天快                     |
| `/directory add` `/directory show`                           | 把你当前项目的文件夹告诉AI，让它“看得到”你的代码             | 把指定文件夹路径加入“workspace”，以后AI能直接读取里面的文件  | 你要让AI帮你改一个大项目，先：`/directory add ./my-awesome-project` |
| `/editor`                                                    | 告诉你AI你平时用哪个编辑器（vscode、cursor、vim…），以后它会生成对应的打开命令 | 只是记录偏好，生成代码时会附带 `code 文件名` 这种命令        | 设置成VS Code后，AI会说“运行 code index.js 打开文件”         |
| `/extensions` 系列                                           | 安装各种插件（比如联网搜索、画图、跑shell、读PDF等等）       | 相当于给Gemini CLI装DLC，超级强大                            | `/extensions explore` 打开插件市场逛一圈                     |
| `/init`                                                      | 让AI扫描你当前文件夹，自动生成一个 GEMINI.md 项目说明文件    | AI会读取你的package.json、README、代码结构，写一份“项目说明书” | 新接手一个陌生项目，敲一下 `/init`，AI立刻告诉你这项目是干嘛的 |
| `/mcp` 系列                                                  | 超级高级功能：对接外部工具服务器（比如你自己搭的搜索、数据库工具） | Model Context Protocol，相当于给Gemini外接“机械臂”           | 一般人暂时不用，属于黑客级玩法                               |
| `/memory show/add`                                           | 让AI“长久记住”某些信息，哪怕你开了新对话它也记得             | 把内容写进 GEMINI.md 文件，下次自动加载                      | 你想让AI永远记住“你是做后端的，喜欢用FastAPI” → `/memory add 我是后端工程师，主要用FastAPI和Python"` |
| `/model`                                                     | 弹出一个选择框让你换模型（gemini-1.5-pro、1.5-flash、2.0等） | 切换底层大模型，速度/能力/价格都不同                         | 想省钱切flash，想牛逼切pro，就敲这个                         |
| `/stats`                                                     | 看看这次对话到底花了多少钱、用了多少token                    | 读取Google API返回的usage数据                                | 月底要对账：`/stats model` 看用了多少输入输出token           |
| `/theme`                                                     | 换终端配色（黑色、白色、dracula等）                          | 纯外观设置                                                   | 你眼睛疼了，换个护眼主题                                     |
| `/tools`                                                     | 看看现在开启了哪些“超能力”（比如执行代码、联网、读文件等）   | Gemini本身支持function calling，这些就是本地工具             | 敲 `/tools desc` 看每个工具是干嘛的                          |
| `/settings`                                                  | 打开配置文件，一键改所有设置                                 | 直接编辑 ~/.gemini/config.json                               | 想改温度、改语言、改默认模型，敲这个最快                     |
| `/vim`                                                       | 打开/关闭Vim按键模式（喜欢hjkl移动的老鸟用）                 | 切换输入法的按键绑定                                         | Vim党狂喜                                                    |
| `/setup-github`                                              | 帮你在GitHub Actions里配置自动用Gemini审查PR                 | 生成workflow yaml文件                                        | 想让每次push代码都自动让AI code review                       |
| `/terminal-setup`                                            | 在VS Code、Cursor等终端里开启多行输入的快捷键（Shift+Enter换行） | 修改终端的keybindings.json                                   | 以前按回车就直接发送了，改完就能好好写多行代码了             |
| `!` 开头的命令                                               | 直接跑系统的shell命令                                        | 相当于临时退出到bash，又不用真的退出                         | `!ls` `!git status` `!python test.py` 直接在聊天里跑         |

### **新手最常用Top 8组合技（直接复制粘贴用）**

```bash
/model                → 换模型
/directory add .      → 把当前项目文件夹加进来
/init                 → 让AI先读懂整个项目
/chat save v1         → 存个档
/copy                 → 一键复制AI刚写的代码
/compress             → 对话太长时浓缩
/chat resume v1       → 第二天继续昨天的活
/chat share 今天成果.md → 发给领导/朋友看
```

------

## Gemini 命令高级用法

### 自定义命名

自定义命令（Custom Slash Commands）是 Gemini CLI 的核心扩展机制，让你创建可重用、参数化的提示快捷方式。无需编程，只用 TOML 文件定义，支持全局/项目级、参数注入和工具调用。从 v0.4.0 开始支持。

#### 1. **前提**

- 更新 CLI：npm update -g @google/gemini-cli。
- 目录结构：
  - 全局：~/.gemini/commands/（所有项目可用）。
  - 项目：<project>/.gemini/commands/（仅当前项目）。

#### 2、审阅 GitHub PR

**基本格式**：每个命令是一个 .toml 文件，文件名即命令名（区分大小写，如 review.toml → /review）。

- 示例：

  ~/.gemini/commands/review.toml

  （审阅 GitHub PR）：

  ```
  description = "审阅 GitHub PR 并建议改进"
  prompt = """
  分析 PR #{{arguments}}：
  1. 检查代码质量。
  2. 建议重构。
  3. 用 @github 获取 PR 细节。
  输出：Markdown 报告。
  """
  ```

  - description：可选，一行描述（显示在 /help 中）。

  - prompt

    ：核心提示，支持：

    - 参数：{{arguments}}（命令后输入，如 /review 123）。
    - 文件注入：@./file.txt（包含文件内容）。
    - Shell 扩展：!git log（注入命令输出）。

  **步骤**：

  1. 创建目录：mkdir -p ~/.gemini/commands/review（子目录可选，用于分组）。
  2. 编辑 TOML 文件（如上）。
  3. 重启 CLI：gemini。
  4. 使用：/review 123（它会自动发送参数化提示给 Gemini）。

#### 3、重构代码

假设你是个Python小白，常写函数但总忘纯函数原则（无副作用、只靠输入输出）。我们一步步建个 /refactor：AI自动分析你提供的代码，重构它。步骤1：创建文件夹（CLI的“命令仓库”）

- 全局版

  （所有项目用）：在终端敲

  ```
  mkdir -p ~/.gemini/commands/refactor
  ```

- 项目版

  （只当前文件夹用）：

  ```
  mkdir -p .gemini/commands/refactor
  ```

  （先cd到你的项目目录）

  原理：这就像建个“工具箱”，CLI扫描时会找到它。

  #### 步骤2：写TOML文件（你的“魔法咒语”）

  用任何编辑器（nano、vim、VS Code）打开 ~/.gemini/commands/refactor/pure.toml（或项目版的路径），粘这个内容：

  ```
  name = "/refactor"
  description = "重构提供的代码成纯函数（无副作用，只靠输入输出）"
  
  prompt = """
  请分析我提供的代码，并重构它成一个纯函数。纯函数原则：不修改外部状态，只用输入参数计算输出。
  
  提供的代码：
  {{code}}
  
  重构要求：
  - 提取副作用（如print、文件操作）到函数外。
  - 返回值明确。
  - 保持原功能不变。
  
  输出：先解释变化，然后给出完整重构代码。
  """
  ```

  - 保存！（TOML格式超简单：key = value，prompt支持多行。{{code}} 是占位符，CLI会自动替换你传的参数。）

  原理：TOML像JSON的亲戚，易读。prompt里的 {{code}} 是Mustache模板语法，CLI在执行时替换（e.g., 你敲 /refactor "def add(x): print(x); return x+1"，它塞进prompt）。

  #### 步骤3：重启CLI测试（或直接敲）

  - 退出当前CLI（/quit），重新跑 gemini（或 npx gemini-cli）。
  - 测试：敲 /refactor 然后粘你的代码（或一行：/refactor def impure_add(x): print('Logging:', x); global total; total += x; return x + 1）。

  - CLI输出示例（AI响应）：

    ```
    解释：原函数有副作用（print和修改global total）。重构后：提取print到外部，global移到输入参数，返回纯计算结果。
    
    重构代码：
    def pure_add(x, total):  # total现在是输入参数
        return x + 1  # 纯计算
    
    # 外部使用：
    total = 0
    print('Logging:', 5)
    total = pure_add(5, total)
    ```

  哇！一键重构，省时省力。想加文件嵌入？改prompt成 "提供的代码：@{main.py}"，CLI会自动读文件内容塞进去。

  #### 步骤4：管理你的命令（进阶玩法）

  - 列出所有：CLI帮助菜单会自动显示（敲 /help）。
  - 删掉：rm 文件夹里的pure.toml，重启CLI。
  - 传参数：如上例，/refactor "你的代码"。
  - 分享：打包成Extension（文档有教程），上传GitHub让别人用

### agent编排

#### 1、玩法一：用“自定义命令”一键召唤不同角色（最推荐！90% 的需求都靠这个解决）

你只需要建几个小文本文件，就等于给自己加了几个专属小助手。

1. 打开文件资源管理器，在这个路径新建文件夹（没有就自己建）：

   ```
   C:\Users\你的用户名\.gemini\commands
   ```

2. 在里面新建这几个文件（直接用记事本，保存为 .toml 格式）：

文件1：coder.toml（专职写代码的 Agent）

```
description = "写代码专用"
prompt = "你现在是专业程序员，只负责写代码和修 bug，不废话，直接给出完整代码。用户说：{{arguments}}"
```

文件2：review.toml（专职代码审查的 Agent）

```
description = "代码审查专用"
prompt = "你现在是严厉的前端/后端老专家，只负责挑毛病和提优化建议。用户代码如下，请逐行审查：{{arguments}}"
```

文件3：plan.toml（专职做计划的 Agent）

```
description = "项目规划专用"
prompt = "你现在是项目经理，只负责拆任务、排时间、定技术选型，不写代码。用户需求是：{{arguments}}"
```

建好这 3 个文件后，重启一下 gemini（退出再进一次）。

以后你就这样用（超简单）：

- 想写代码 → 输入：/coder 帮我写一个天气查询页面
- 想让人审查代码 → 先复制你的代码，然后输入：/review 回车 再粘贴代码
- 想做项目规划 → 输入：/plan 我要做一个个人博客

就这么简单！相当于你有 3 个专属 Agent，随时切换。

#### 2、玩法二：让一个 Agent 当“领导”，指挥其他 Agent（稍微高级一点）

你只需要再建一个文件，叫 team.toml（多 Agent 编排专用）：

```toml
description = "多 Agent 团队协作"
prompt = """
你现在是团队 Leader，下面有 3 个队员：
1. 规划师（用 /plan）
2. 程序员（用 /coder）
3. 审查师（用 /review）

任务来了以后，你必须按顺序指挥他们干活：
第一步：先喊规划师做计划
第二步：让程序员按计划写代码
第三步：让审查师检查代码
最后你汇总出最终结果

用户任务是：{{arguments}}
现在开始干活！
"""
```

以后你只用一句话就能启动整个团队：

```
/team 帮我做一个带登录功能的记事本网页
```

它就会自动：

1. 先规划
2. 再写代码
3. 再审查
4. 最后给你完整版本

##### 总结：你现在只需要做 3 件事

1. 建一个文件夹：C:\Users\你的用户名\.gemini\commands
2. 把上面 4 个文件（coder、review、plan、team）复制进去
3. 重启 gemini

从此以后你就有 4 个 Agent 听你指挥了：

- /plan → 规划师
- /coder → 程序员
- /review → 代码审查师
- /team → 自动指挥全部三人干活

完全免费，完全本地，几分钟搞定，比任何复杂框架都好用。

你现在就去建这几个文件吧，建好了告诉我，我直接带你用 /team 做一个完整小项目玩玩看～超级爽！

#### 3、/chat new 不污染主线(不知是否扯蛋)

/chat new 创建临时分支会话测试危险想法不污染主线”——这简直是开发者思维的精髓，就像Git分支一样，先在“实验分支出”折腾，万一炸了也不影响main。Gemini CLI绝对有类似玩法，虽然没有精确的“/chat new”命令（官方文档里没这个），但它的**/chat save/resume/delete组合拳完美模拟分支系统**，超级适合隔离“高风险实验”（比如让AI直接改代码、跑shell、测试YOLO模式下的疯狂想法）。这不光是存档，还能跨会话“读档”，零污染主线。

**大白话解释：Gemini CLI的“分支会话”像Git，但更AI味儿**

- **核心玩法**：主会话（main branch）在跑着，你突然有危险想法（e.g., “让AI直接 !rm -rf 测试我的备份脚本”）？别慌，先 /chat save risky-test（存个分支），然后 /clear 清掉主线，继续实验。实验OK了，就 /chat resume main 回主线；NG了，/delete risky-test 扔垃圾桶。整个过程不污染主上下文（token、历史全隔离）。
- **为啥牛？** 比VS Code的“new chat”强多了——它不光新开窗口，还能**带上项目上下文**（GEMINI.md、workspace文件），实验时AI还能“看到”你的代码，但主线不受影响。适合测试“危险”：YOLO模式下的文件改动、MCP工具调用、长prompt实验啥的。
- **小坑**：分支是**项目级**的（只在当前目录有效），跨项目要cd过去resume。文档说：chats saved into project-specific directory。

比喻：主线是你的“生产环境”仓库，/chat save 是 git checkout -b experiment，实验完 git checkout main 切换回来。区别：Gemini的“分支”还能自动总结（/compress）省token。

------

------

**你的专属案例演示：测试“危险想法”——让AI在临时分支里“模拟黑客攻击脚本”**

假设你主线在开发一个Web app，突然脑洞：想让AI生成一个“测试SQL注入的payload脚本”，但怕污染主上下文（token爆+历史乱）。我们用分支隔离：主线保持干净，实验分支随便炸。

**步骤1：主线存档（创建“安全点”）**

- 在Gemini CLI里（gemini >），敲：

  ```
  /chat save main-safe
  ```

  - 输出：Conversation saved as 'main-safe'.

- 原理：这打了个标签，存当前历史到 .gemini/chats/main-safe.json。

**步骤2：清主线，进实验分支（隔离开始）**

- 敲 /clear 清屏+清当前历史（主线现在空了，但存档还在）。

- 敲 /chat resume main-safe 确认主线OK（可选，测试resume）。

- 现在开始危险实验：敲你的prompt

  ```
  帮我生成一个Python脚本，模拟SQL注入攻击测试我的app（别真跑！），包括payload生成和执行逻辑。项目文件：@app.py @database.py
  ```

  - AI输出：一段脚本（e.g., 用sqlmap库模拟注入）。

- 立刻存实验分支：

  ```
  /chat save sql-injection-test
  ```

  - 现在，主线没变，实验历史在分支里。

**步骤3：继续“危险”测试（不污染主线）**

- 在这个分支里，继续问：

  ```
  现在用YOLO模式运行这个脚本在沙箱里，看看输出。（警告：危险！）
  ```

  - 如果你开了YOLO（/settings），AI可能会 !python script.py 真跑（沙箱安全，但分支隔离防万一）。
  - 实验中途 /compress 浓缩历史（省token）。

**步骤4：回主线or清理（零痕迹）**

- 实验完，敲：

  ```
  /chat resume main-safe
  ```

  - 瞬间回主线：上下文变回存档点，实验历史没了。

- 列分支看：/chat list（显示 main-safe, sql-injection-test）。

- 删实验：/chat delete sql-injection-test（文件没了，主线永洁）。

**预期输出示例（CLI模拟）**

```
> /chat save main-safe
Saved checkpoint: main-safe

> /clear
Screen and history cleared.

> 你好，继续主线开发...
[AI: 基于main-safe，继续聊...]

> /chat save sql-injection-test  (在实验后)
Saved: sql-injection-test

> /chat resume main-safe
Resumed from main-safe. Experiment isolated!

> /chat list
- main-safe (2025-11-29 10:00)
- sql-injection-test (2025-11-29 10:05)

> /chat delete sql-injection-test
Deleted.
```

哇！整个过程5分钟，危险想法测试完，主线如新。想更分支化？用不同tag多层：/chat save feature-v1 → /chat save bugfix-off-v1。

**新手Tips（防坑+进阶）**

- **列所有分支**：/chat list 随时看“git log”。
- **跨天用**：resume能从昨天的分支接上，完美不丢进度。
- **结合大佬建议**（上轮聊的）：先 /plan 规划危险实验，再分支测试。关YOLO防真炸（/settings allowYolo: false）。
- **如果想更Git-like**：用Extensions建自定义 /branch 命令，自动save+push到GitHub（/extensions explore）。

------

## 安装MCP服务器

MCP 服务器有官方的（如 GitHub MCP）和社区的（如 Docker MCP Toolkit）。我以最常见的 GitHub MCP 为例（让 AI 能直接操作你的 GitHub 仓库）。其他服务器类似

**方式一：用 CLI 命令一键添加（推荐，新手友好）**

- 启动 Gemini CLI：gemini

- 在交互模式里输入：

  /mcp add github

  - 它会自动下载、安装并配置 GitHub MCP 服务器（需要你的 GitHub Token，CLI 会引导你生成）。
  - 确认后，重启 CLI。

- 验证：输入 /mcp list，应该看到 "github" 在列表里。试试问 AI：“用 GitHub MCP 创建一个新 Issue。”

**方式二：手动配置（更灵活，如果命令不支持你的服务器）**

1. 找到设置文件：~/.gemini/settings.json（Windows: C:\Users\你的用户名\.gemini\settings.json）。用记事本或 VS Code 打开（没有就新建）。

2. 添加 MCP 配置（以 GitHub MCP 为例）：

   ```json
   {
     "mcpServers": {
       "github": {
         "url": "http://localhost:8080",  // 或官方 MCP URL，如 Docker 容器地址
         "token": "你的 GitHub Personal Access Token"  // 从 GitHub 设置生成
       }
     }
   }
   ```

   - 对于 Docker MCP（浏览器自动化）：先用 Docker 拉镜像 docker pull google/mcp-toolkit，然后 URL 改成容器地址。
   - 保存文件，重启 CLI。

3. 验证：gemini 后输入 /mcp，看服务器列表。

#### 常见 MCP 服务器安装示例

- **GitHub MCP**（管理仓库、PR）：用 /mcp add github，或 Docker: docker run -p 8080:8080 google/github-mcp。
- **Docker MCP Toolkit**（浏览器测试）：安装 Docker Desktop，然后 docker pull google/mcp-toolkit，运行容器，再加到 settings.json。
- **Atlassian Rovo MCP**（Jira/Confluence 集成）：/mcp add atlassian-rovo-mcp（自动配置）。
- **自定义 MCP**（用 FastMCP 建自己的）：先 pip install fastmcp>=2.12.3，写个 server.py，然后 fastmcp install gemini-cli。

#### 怎么用 MCP（快速上手）

- 启动：gemini
- 列出：/mcp list（看所有服务器和工具）。
- 测试：问 AI “用 GitHub MCP 列出我的仓库”，它会自动调用。
- 移除：/mcp remove github 或删 settings.json 里的条目。

**注意事项**：

- 需要 Token/API Key：安全起见，别硬编码，用环境变量（如 export GITHUB_TOKEN=xxx）。
- 资源消耗：MCP 服务器跑在本地进程，监控 CPU（用 /status 看）。
- 问题排查：如果连不上，检查防火墙/端口（默认 8080），或 /bug 报告。文档：https://google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html。

## 进阶玩法

Philipp Schmid 提供的最佳实践建议经过AI整合。

### 建议1(Grok总结)：

—— 融合其他 AI 解读 + 我的原有分析 + 新 GEMINI.md 规则（2025 年 11 月 29 日版）

嘿！感谢你分享这个从其他 AI 提取的解读（GEMINI.md 规则 + /plan 命令模板）。我仔细分析了它：这个模板超级硬核，完美捕捉了 Philipp 的“Plan First + 测试先行 + 类型安全”精髓（从他 X 推文和官方文档看，他强调的正是这种结构化工作流）。它和我之前的解读高度互补——我原有版更偏小白实操（大白话 + 案例），新版加了“不可编辑规则”和详细计划模板，能让 AI 像“严格的工程导师”一样工作。

下面，我先**总结其他 AI 的解读**（提炼精华），然后**整合成全新版本**：保留我的生动案例 + 新规则的深度 + 官方文档的原理。结果是份“零门槛 + 生产级”的指南，直接复制到你的项目里用！

#### 第一步：其他 AI 解读的快速总结（提炼 3 大亮点）

从你分享的内容看，其他 AI 把 Philipp 的建议提炼成一个“永不修改的 GEMINI.md + /plan 命令”体系，核心是：

1. **最高规则（GEMINI.md）**：定义 AI “人格”（10 年全栈工程师，类型安全 + 测试先行），强制“先计划、再编码、先测试”。用 black/ruff/mypy 等工具确保代码质量（Python 偏好，但可扩展到 JS/TS）。原理：System Prompt 锁定行为，避免 AI 乱来。
2. **/plan 命令模板**：不是内置，而是自定义 .toml（prompt 强调“不要写代码，只规划”），输出结构化计划（文件列表、风险、测试策略）。这直接对应 Philipp 的“先创建详细实施计划”，让复杂任务从“乱写”变“可控”。
3. **整体哲学**：测试驱动（TDD）+ 风险评估，适合生产环境。比单纯的“规划”多了一层“工程严谨性”（e.g., 引用 @文件名 查看上下文）。

**我的评价**：这个解读比单纯的“Philipp 原话翻译”更落地，补齐了我原有版的“工具链”部分（e.g., mypy 类型检查）。缺点：太 Python 导向（我们可以 JS 化）；优点：模板可复用，防 AI 越界。

#### 第二步：整合后全新解读（原有 + 新版融合）

我把 Philipp 的 6 条原话、我的小白案例、其他 AI 的规则/模板无缝融合。新增：**JS/TS 适配版 GEMINI.md**（因为你用 React/Next.js 多），和**升级 /plan.toml**（结合新 prompt）。原理用“大白话 + 底层逻辑”解释，确保你形象理解（e.g., “像给实习生发 KPI”）。

#### 原话 vs 整合解读 vs 落地实操（升级表，一行一条）

| Philipp 原话                                                 | 整合解读（大白话 + 原理 + 其他 AI 融合）                     | 落地实操方案（复制粘贴 + 真实案例）                          |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1. 对于复杂的任务，我从不首先要求提供代码。我的初始提示是创建一个计划（功能、缺陷）创建一个详细的实施计划 | **大白话**：别让 AI 一上来就敲代码（它容易写成“艺术品”），先逼它出“施工图”。 **原理**：Chain of Thought（逐步思考），减少幻觉；融合其他 AI：输出 PLAN.md 结构化，包含风险/测试。 **形象比喻**：像建筑师先画蓝图，再动砖。 | 用升级 /plan 命令： `/plan 任务：加支付功能到记账本 App` **案例输出**：AI 吐 PLAN.md（文件列表：`src/payment.js` 新增；风险：API 密钥泄露；测试：模拟 Stripe 回调）。确认后执行。 |
| 2. 创建多个分层 GEMINI.md 文件，定义角色、有用的代码片段以及一个严格的规则 | **大白话**：给 AI 发“员工手册”，不同文件夹不同“岗位”。 **原理**：分层 System Prompt（项目 > 子目录），继承 + 覆盖；融合其他 AI：加“永不修改”规则 + 工具链（black → ESLint）。 **形象比喻**：像公司有总部 KPI + 分公司 SOP。 | 建分层 GEMINI.md（见下方模板）。 **案例**：根目录规则“用 TS”；`frontend/GEMINI.md` 覆盖“用 Tailwind”。AI 自动切换：写 React 时优先 hooks。 |
| 3. 协作 → YOLO。我不使用“YOLO 模式”，而是拦截并重新提示      | **大白话**：YOLO 太野蛮，先“试探”AI 意图，再放行。 **原理**：ReAct 循环（Reason + Act），拦截工具调用；融合其他 AI：只在“测试通过”后 YOLO。 **形象比喻**：像开车前检查刹车，不是一脚油门。 | 安全 YOLO 流程： 1. `! npm test` 2. 测试绿 → `gemini --yolo -p "执行 PLAN.md 第2步，只改代码"` **案例**：重构登录页 → 先审 diff → YOLO 应用。 |
| 4. 使用 MCP 服务器来访问错误、问题、浏览器、GitHub（以及内部工具）或在沙箱中运行代码 | **大白话**：给 AI 装“外挂”，让它自己查 GitHub Issue 或上网。 **原理**：MCP 协议（外部 API 桥接）；融合其他 AI：沙箱测试（e.g., MCP browser 预览 PDF）。 **形象比喻**：AI 从“关在屋里”变“出门办事”。 | 安装 + 用： `/mcp add github && /mcp add browser` **案例**：`/team 加 PDF 导出` → AI 用 browser MCP 预览效果 → GitHub MCP 自动开 Issue 记录 bug。 |
| 5. 利用 100 万的上下文。指示它将大量文件读入上下文或使用“@”原语 | **大白话**：别藏着文件，全塞给 AI（它吃得下）。 **原理**：Gemini 2.5 Pro 的 1M token 窗口 + RAG（@ 检索）；融合其他 AI：计划中引用 @文件。 **形象比喻**：像给厨师全厨房食材，不是只给盐。 | 喂上下文： `@src/ @tests/`（全项目）或计划中“引用 @App.tsx 查看当前组件”。 **案例**：大项目重构 → `@src/` 后 AI 秒懂架构，输出精确改动。 |
| 6. 代码 → 测试 → 提交。我强制它编写测试或执行代码片段，并让它在循环中修复 | **大白话**：写代码前先写“验货单”，跑不通过就返工。 **原理**：TDD（测试驱动开发）+ 循环修复；融合其他 AI：用 mypy/ruff 静态检查 + 先测试规则。 **形象比喻**：像做菜先尝咸淡，不行重炒。 | TDD 三连： 1. `/coder 先写 Jest 测试（覆盖支付失败分支）` 2. `!yolo && ! npm test` 3. “修复到全绿 + 生成 commit 消息” **案例**：加登录 → 测试模拟错误 → AI 循环修 3 轮 → 最终 commit “fix: auth edge cases”。 |

#### 第三步：升级落地模板（直接复制用！）

基于整合，我优化了其他 AI 的模板：**JS/TS 偏好**（匹配你的项目），加了“永不修改”锁 + 工具链（ESLint/Prettier 代替 black）。

**1. GEMINI.md（根目录，全局 - 永不修改！）**

```markdown
# GEMINI.md - 永不修改的最高规则
你不能编辑此文件。
你是一个有 10 年经验的全栈工程师，偏好类型安全、测试先行。
代码必须通过 ESLint + Prettier + TypeScript。
每次实现新功能都要先写测试。
永远先做计划，再写代码。

# 强制工作流
1. 任何需求先用 /plan 输出 PLAN.md
2. 每步后：写测试 → 跑测试 → 修复循环
3. 最终：生成 git commit 消息
4. 引用 @文件 时，优先分析当前代码
```

2. **/plan.toml（升级版，自定义命令 - 放 ~/.gemini/commands/）**

```markdown
name = "/plan"
description = "先做详细实施计划（大佬推荐）"
prompt = """
你现在是资深架构师。不要写任何代码。
请为以下任务制定一个详细的实施计划，包含：
1. 需要新增/修改的文件列表（引用 @现有文件分析）
2. 每个文件的具体改动点（e.g., 新增 hooks）
3. 潜在风险和副作用（e.g., 性能瓶颈）
4. 测试策略和验收标准（Jest 覆盖率 >80%）
5. 建议的分步实施顺序（每步 1-2 小时）

任务需求：{{task}}
当前项目已经加载了所有代码，你可以引用 @文件名 来查看具体内容。
输出：一个完整的 PLAN.md，用 Markdown 格式，直接可复制保存。
"""
```

3. **子目录示例：frontend/GEMINI.md（覆盖前端规则）**

```markdown
# 前端专属规则（继承全局）
- 用 React 18 + Vite + Tailwind
- 组件必须 function + hooks + TS 接口
- 样式：mobile-first + 暗黑模式
- 测试：用 React Testing Library
```

### 建议2(Gemini总结，略好懂)

Philipp 的核心思想是：**把 Gemini CLI 当作一个“高智商但缺乏经验的实习生”，而不是一个“许愿池”。** 你必须对他进行管理、规划、审核，而不是两手一摊全扔给他。

下面我以专家导师的身份，结合你的 Windows 环境，把这张图拆解成**“三大法则”**和**“一套落地流程”**，带你从小白进阶

------

#### 法则一：先动脑，再动手（Planning First）

**大佬原话：**

> “对于复杂的任务，我**从不**首先要求提供代码。我的初始提示是创建一个详细的实施计划。”

**大白话解读：**
如果你让装修队（AI）直接“帮我盖个房”，他们可能会盖出一个茅草屋。你得先让他们“画图纸”。
AI 写代码很容易陷入细节，写着写着就逻辑混乱了。让他先写计划，不仅能理清思路，如果计划有错，你改计划（改几行文字）比改代码（改几百行代码）容易得多。

**原理：**
**思维链（Chain of Thought）**。强迫模型先生成高层逻辑，利用生成的逻辑作为上下文，去指导后续的具体代码生成，能大幅降低 Bug 率。

**✅ 你的落地动作：**
以后接到任务（比如“做一个贪吃蛇”），千万别直接敲“写代码”。

1. **输入命令**：gemini 进入对话。
2. **第一句说**：@src/（如果有旧代码）“我想做一个贪吃蛇游戏，请不要写代码，先帮我生成一个详细的开发计划，保存为 PLAN.md”。
3. **检查**：打开生成的 PLAN.md 看看，逻辑对不对？不对就让他改计划。

------

#### 法则二：立规矩，给语境（Context & Rules）

**大佬原话：**

> “创建多个分层 GEMINI.md 文件... 定义角色、有用的代码片段以及一个严格的规则：‘你不能编辑此文件’。”
> “利用 100 万的上下文... 使用 @ 原语。”

**大白话解读：**
这就是给实习生发“员工手册”。
如果不给规则，AI 可能会用你不喜欢的写法（比如你喜欢 async/await，他非要用 Promise）。通过 GEMINI.md，你告诉他：“这就是本公司的规定，必须遵守。”
同时，利用 @ 把相关文件喂给他，相当于让他“带着参考书考试”，而不是“闭卷考试”。

**原理：**
**System Prompt（系统提示词）注入**。.gemini/GEMINI.md 文件会在每次对话开始前自动注入到模型的“潜意识”里，起到约束和引导作用。

**✅ 你的落地动作：**
在你的 D 盘项目根目录下（比如 D:\NodeJS\Projects\MyGame），新建一个文件夹 .gemini，里面建一个文件 GEMINI.md。

**内容模板（你可以直接复制进去）：**

```markdown
# 角色设定
你是一个资深的全栈工程师，精通 Node.js 和 Python。

# 编码规范
1. 始终使用中文回复。
2. 代码必须有详细注释。
3. 除非我明确要求，否则不要删除原有代码，而是注释掉。
4. 严禁修改本文件 (GEMINI.md)。

# 工作流
在写代码前，先思考潜在的 Bug。
```

有了这个文件，你每次启动 Gemini，他都会乖乖听话，不用你重复啰嗦。

------

#### 法则三：不信任，重测试（Verify & Test）

**大佬原话：**

> “协作 >> YOLO... 我不使用 YOLO 模式。”
> “代码 -> 测试 -> 提交。我强制它编写测试或执行代码片段，并让它在循环中修复。”

**大白话解读：**

- **拒绝 YOLO**：YOLO 模式是“全自动驾驶”，Philipp 觉得这不安全。他喜欢看着 AI 一步步走，发现苗头不对（比如要删重要文件），马上拦截并纠正。
- **强制测试**：既然 AI 是实习生，他写的代码我不信。我要求他写完代码，必须**自己写一个测试程序**跑一下。跑不通？你自己修，修好了再交给我。

**原理：**
**TDD（测试驱动开发）** + **Human-in-the-loop（人在回路）**。通过运行测试（Execution Feedback），AI 能获得真实的反馈信号，从而自我修正，这比单纯的“生成代码”质量高得多。

**✅ 你的落地动作：**
不要让他一次性写完所有功能。

1. **指令**：“帮我写贪吃蛇的移动逻辑，并且**写一个测试脚本来验证它**。”
2. **执行**：让他运行测试脚本（利用 run_shell_command）。
3. **修复**：如果报错，直接把报错丢给他：“测试挂了，修好它。”直到测试全绿。

------

**🚀 总结：给小白的最佳实践流程（SOP）**

结合大佬的图和你现在的环境，我为你定制了一套标准工作流：

**场景：你在 D 盘想开发一个“网页版计算器”。**

**第一步：准备环境（就做一次）**
在项目根目录创建 .gemini/GEMINI.md，写入你的“家规”（用中文回答、代码风格等）。

**第二步：规划（Architect Mode）**

- **你**：gemini
- **你**：“我想做个网页计算器，包含加减乘除。**请先帮我写一个 PLAN.md，列出开发步骤。**”
- *(AI 生成计划文件)*
- **你**：（看一眼 PLAN.md）“第三步逻辑有点问题，先别急着做 UI，先把核心算法写好。修改一下计划。”

**第三步：编码与测试（Developer Mode）**

- **你**：“好，现在执行计划的第一步：编写核心算法 math.js。**同时写一个 test_math.js 来测试这些算法是否正确。**”
- *(AI 生成代码和测试代码)*
- **你**：“运行测试。”
- *(AI 调用终端运行 node test_math.js)*
- *(假设报错了)*
- **你**：“报错了，分析原因并修复。”
- *(AI 自动修复，直到测试通过)*

**第四步：人工审查（Reviewer Mode）**

- **你**：“测试通过了。现在我想看下 math.js 的代码。”
- *(AI 展示代码)*
- **你**：（发现没问题）“很好，把这个文件保存（write_file），我们进行下一步。”

------

## 小白开局流程

### 第一步：全局一键安装 + 终极配置

打开终端，复制粘贴下面全部命令，一行一行回车：

```bash
# 1. 安装 gemini-cli（最新版）
pip install -U gemini-cli

# 2. 创建全局配置目录
mkdir -p ~/.gemini/commands/plan
mkdir -p ~/.gemini/commands/coder
mkdir -p ~/.gemini/commands/team

# 3. 关掉最危险的 YOLO（永绝后患）
cat > ~/.gemini/config.json << 'EOF'
{
  "allowYolo": false,
  "defaultModel": "gemini-1.5-pro",
  "temperature": 0.6,
  "autoMemory": true
}
EOF

# 4. 全局最高铁律 GEMINI.md（所有项目自动继承，AI 永远不敢改）
cat > ~/.gemini/GEMINI.md << 'EOF'
# 永久最高规则（你永远不能修改这个文件！）

你现在是我的私人全栈导师 + 代码强迫症患者，必须遵守以下铁律：
1. 前端永远用 React 18 + TypeScript + Tailwind CSS + Vite
2. 必须支持暗黑模式（用 tailwind dark: 语法）
3. 必须先写测试（vitest + testing-library），再写实现代码
4. 所有代码必须同时通过：black + ruff + mypy（后端）或 biome/prettier + eslint（前端）
5. 每次完成后必须生成规范的 git commit 消息
6. 永远先规划（/plan），再写代码（/coder）
7. 永远不废话，除非我让你解释
EOF
```

### 第二步：创建三大神级自定义命令（复制粘贴即可

```bash
# 1. /plan —— 先规划再动手（项目经理）
cat > ~/.gemini/commands/plan/plan.toml << 'EOF'
name = "/plan"
description = "先输出完整 PLAN.md 再动手"

prompt = """
你现在是资深技术 Leader。
请为以下需求输出一个完整的 PLAN.md 文件，包含：
- 项目名称
- 技术栈
- 完整文件夹结构
- 分几步实现
- 每个文件的职责
- 需要哪些依赖
- 潜在风险和测试点
- 验收标准

需求：{{arguments}}
"""
EOF

# 2. /coder —— 只写代码，不废话（程序员）
cat > ~/.gemini/commands/coder/coder.toml << 'EOF'
name = "/coder"
description = "只负责写代码和注释，不讲其他无关的话"

prompt = """
你现在只负责写代码和逐行注释，从编程小白的角度，为每段代码加上两行描述，代码本身的意思以及加上大白话的解释，让小白看的懂代码本身的含义，又配上了形象的解释，还有禁止说其他无关的话。
需求：{{arguments}}

记住全局铁律：React + TypeScript + Tailwind + 暗黑模式 + 先写测试
"""
EOF

# 3. /team —— 最强一键全自动团队（Leader）
cat > ~/.gemini/commands/team/team.toml << 'EOF'
name = "/team"
description = "全自动开发团队：先规划 → 再写代码 → 最后交付"

prompt = """
你现在是全栈团队 Leader，手下有：
• 规划师 → 自动调用 /plan
• 程序员 → 自动调用 /coder

流程必须严格如下：
1. 先让规划师输出完整的 PLAN.md
2. 我确认计划后，你再让程序员逐个实现
3. 最后你汇总所有文件，输出完整项目
4. 最后生成 git commit 消息

现在需求是：{{arguments}}

开始吧！
"""
EOF
```

### 第三步：以后开新项目永远只用这 4 行（10 秒启动）

```bash
mkdir todo-app && cd todo-app
gemini
# 进去后直接敲：
/team 帮我做一个支持增删改查、搜索、支持暗黑模式的 Todo 清单网页，用 React + Vite + Tailwind + TypeScript
```

然后你什么都不用干，喝口水，等 2~5 分钟，它会自动：

1. 输出 PLAN.md（文件夹结构）
2. 一文件一文件写完（带测试、带暗黑模式）
3. 最后说「项目已完成」，给你所有文件 + commit 消息

你只需要：

```bash
# 把 AI 给的所有文件保存到当前文件夹
# 然后运行：
npm create vite@latest . -- --template react-ts
npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
# 把 AI 给的 tailwind.config.js、index.css 覆盖进去
npm install
npm run dev
```

一个完美带暗黑模式的 Todo 应用就出来了！

**最终你拥有的超级能力（新人 1 天达到老鸟 1 年水平）**

```bash
gemini  /team 我要一个 xxx
```

然后喝茶等交付。

把这整个回答保存成「Gemini CLI 终极开局.md」，以后所有电脑、所有项目都复制这套就行。

现在就试试吧！ 在终端敲：

```bash
mkdir my-first-god-project && cd my-first-god-project
gemini
```

然后直接输入：

```
/team 帮我做一个极简个人主页，包含英雄区、项目展示、联系我，支持暗黑模式，用 React + Vite + Tailwind + TypeScript
```

## 我的疑问

### **问题1：为什么大佬都用 React 18 + TypeScript + Tailwind CSS + Vite？这四件套到底有啥魔力？**

想象你要盖一栋超级漂亮的房子：

| 工具             | 传统做法（旧技术）                                   | 新四件套做法                                                 | 小白能感受到的好处                                           |
| ---------------- | ---------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **React 18**     | 用原生 JavaScript 一行行操作 DOM（像用手一个个搬砖） | 像搭乐高一样，写“组件”拼页面，改一个地方全自动更新           | 页面不会整个刷新，体验像 App 一样丝滑；代码像积木，改起来不怕崩 |
| **TypeScript**   | 全程 JavaScript（变量想装啥装啥）                    | 给每个变量贴“身份证”（比如 name 是 string，age 是 number）   | 你敲错变量类型，编辑器立刻红叉提醒（比如不小心把 age 当字符串用）→ 少 80% 低级 bug |
| **Tailwind CSS** | 自己写一堆 .header { color: red; } 这种 CSS 文件     | 直接在 HTML 里写 class="text-red-500 bg-black p-4 rounded-lg" | 改颜色、间距、圆角只要改一个单词；永远不用想类名（不会出现 header-blue、header-blue-v2 这种垃圾） |
| **Vite**         | 用老的 webpack 打包，启动项目要等 30 秒              | Vite 冷启动 0.5 秒，热更新瞬间生效                           | 你改一行代码，浏览器 0.1 秒就刷新出来，爽到飞起（老技术要等 5~10 秒） |

句话总结： 这四件套组合起来 = **写得快、错得少、改得爽、启动快、长得漂亮**，大佬用它就像开法拉利，你用旧技术就像骑自行车。

### **问题2：铁律「React + TS + Tailwind + 暗黑模式 + 先写测试」是大佬日常标配吗？为什么？**

是的！2025 年的前端圈，这套铁律已经跟“喝水”一样自然。原因如下：

| 铁律项目                                     | 为什么大佬都强制用                            | 小白真实感受                                                 |
| -------------------------------------------- | --------------------------------------------- | ------------------------------------------------------------ |
| **React**                                    | 全世界 90% 的前端岗位都要求                   | 学了它就能找到工作                                           |
| **TypeScript**                               | 代码超过 500 行后，不用 TS 一定会崩           | 我自己项目写到 1000 行，没 TS 已经改到崩溃，用了 TS 立刻安稳 |
| **Tailwind**                                 | 设计和开发速度提升 3~5 倍                     | 以前改个按钮颜色要找 CSS 文件，现在改一个单词就行            |
| **暗黑模式**                                 | 2025 年所有产品都必须支持（用户晚上刷会瞎眼） | 你自己用的时候一键切换黑夜模式，瞬间感觉高端                 |
| **先写测试**（TDD：Test-Driven Development） | 防止“改 A 崩 B”                               | 你先写“这个按钮点了要加一条 todo”，AI 实现完跑测试不过它自己就修，直到通过 → 永远不交有 bug 的代码 |

暗黑模式到底是啥？ 就是白天白底黑字，晚上黑底白字，保护眼睛 + 装逼。Tailwind 实现只要加一个 dark: 前缀：

```
<div className="bg-white dark:bg-black text-black dark:text-white">
  我会自动变色！
</div>
```

### **问题3：要不要写一个“归档模式”？每天自动记今天干了啥？**

你完全不需要自己再写一个！Gemini CLI 已经给你内置了三把降维打击神器，组合起来比任何“归档模式”都强 100 倍：

| 你想要的功能                 | Gemini CLI 现成功能           | 如何 1 秒实现                        |
| ---------------------------- | ----------------------------- | ------------------------------------ |
| 记住今天干了啥               | /chat save today-2025-11-29   | 敲一行就永久存档                     |
| 明天一进来自动提醒我昨天进度 | /chat resume today-2025-11-29 | 敲一行就无缝接上                     |
| 对话太长占 token             | /compress                     | 自动把 10 万字浓缩成 500 字总结      |
| 想看历史所有项目             | /chat list                    | 列出所有存档，像 git branch 一样清晰 |
| 想彻底清理垃圾对话           | /chat delete xxx              | 一键删除，永不留痕                   |

真实案例（我自己每天的收工仪式，三秒完成）：

```bash
# 快下班了
/chat save 2025-11-29-todo-app-v1
/compress          ← 浓缩今天所有对话，省 token
/quit

# 第二天上班第一件事
gemini
/chat resume 2025-11-29-todo-app-v1
→ 瞬间回到昨天最后一句话，连思路都不用找！
```

比任何“自动归档 md”都强，因为：

- 它带着完整的上下文（AI 记得昨天所有代码、讨论、bug）
- 体积小（compress 后就几百字）
- 随时删、随时恢复、随时分享

结论： **你完全不需要再搞任何归档系统**，/chat save + /compress + /chat resume 就是终极记忆神器，99.99% 的大佬都只用这套。

### **问题4：biome / prettier + eslint 要不要装？Gemini 怎么调用它们？**

**答案：必须装！Gemini 自己不会“跑”这些工具，它只能“提醒你跑”或者“假装自己跑过了”。**

真实情况是：

- Gemini CLI 本身**不包含** black/ruff/mypy/prettier/eslint/biome 这些工具
- 但它会在输出代码时说“我已经通过了 biome 检查”，其实只是**AI 模仿**的（它知道规则，但不会真跑）
- 所以你必须在本地装好这些工具，AI 写完代码后你自己跑一遍才算数

小白最爽的一键安装方案（只敲这三行，全部搞定）：

```bash
# 前端项目里直接敲（只需要一次）
npm install -D biome@latest        # 2025 年最强新王者，替代 prettier + eslint
# 或者老派经典组合（也行）
# npm install -D prettier eslint eslint-plugin-react eslint-plugin-react-hooks

# 初始化 biome（推荐！比 prettier+eslint 快 50 倍）
npx biome init

# 以后每次 AI 写完代码，你只敲这一行就全部检查+自动修复：
npx biome check . --apply
```

结论：AI 只是“写得好看”，真正检查还得靠你本地工具跑一遍。biome 是 2025 年最新最强王者，强烈推荐！

### 问题5：Vite 是脚手架吗？能不能不用？大模型写完直接跑行不行？

Vite 不是传统意义上的脚手架，它是“下一代打包工具”，2025 年已经彻底干翻 webpack！

| 项目     | 传统 create-react-app | Vite       |
| -------- | --------------------- | ---------- |
| 启动速度 | 20~60 秒              | 0.5 秒     |
| 热更新   | 改一行等 3~10 秒      | 瞬间刷新   |
| 配置     | 一堆复杂 webpack 配置 | 几乎零配置 |
| 体积     | 打包后 200~500KB      | 更小更快   |

**大模型写完代码能不能不装 Vite 直接跑？** 完全不行！AI 给你一堆 .tsx 文件，你不装 Vite 就没办法：

- 把 TypeScript 编译成浏览器能懂的 JavaScript
- 把 Tailwind 编译成真实 CSS
- 启动开发服务器

**小白必知盲点**：

- Vite 是“开发服务器 + 打包工具”，缺一不可
- 哪怕 AI 写得再好，没 Vite 就是一堆死文件
- 2025 年所有新项目（React/Vue/Svelte）默认都用 Vite

结论：**Vite 必须装，而且是大佬们爽到飞起的真正原因**！

### 问题6：不用 TypeScript 可以吗？反正 AI 写得对！

可以，但后果自负！ 你这个理解 90% 对，但漏了最关键的 10%：

| 场景                  | 纯 JavaScript                      | 加 TypeScript                         |
| --------------------- | ---------------------------------- | ------------------------------------- |
| AI 写 100 行小项目    | 基本没问题                         | 没必要                                |
| AI 写 1000 行中型项目 | 经常改着改着就崩了（变量类型乱套） | 改到 5000 行都不崩                    |
| 你接手 AI 写的代码改  | 看不懂变量是啥类型                 | 鼠标一悬停就知道是 string 还是 number |
| 团队协作/开源         | 别人骂你“没类型谁敢接”             | 别人夸你“专业”                        |

**真实案例**： 我用纯 JS 让 AI 写了个 800 行项目，第二天改一个函数，AI 把 user.id 当成字符串拼接了，页面直接炸了，找了半小时才发现。 换成 TS 后，AI 一写错，编辑器立刻红叉，我还没运行就知道错了。

**结论（给你的最终建议）**：

- 学习阶段前 5 个项目：**可以先不用 TS**，先跑起来再说
- 第 6 个项目开始：**强制用 TS**，你会感谢自己
- AI 写 TS 代码其实比 JS 更稳定（它知道类型规则）

现在你彻底搞清楚了：

1. 工具必须本地装，AI 只是“假装检查”
2. GEMINI.md 可以先用通用版，不锁技术栈
3. Vite 必须用，没它代码就是死文件
4. TypeScript 不是必须，但用了爽到飞起

### 问题7：AI为什么会给你一堆tsx，我又没指定ai写这个，难道任何前端没有打包工具就全都跑不掉吗？为什么浏览器不认识，tomcat不也是开发服务器吗？他和tomcat一样吗？那么springboot有内置vite吗？

**1. 为什么 AI 会给你一堆 .tsx 文件？**

因为你（或者你的 GEMINI.md）里写了“React + TypeScript + Tailwind”，AI 就老老实实照办了：

- .tsx = TypeScript + JSX（React 的模板语法）
- 现代浏览器只认识三种东西：
  1. 纯 HTML
  2. 纯 JavaScript（ES5/ES6）
  3. 纯 CSS

**浏览器完全不认识下面这些“未来语言”：**

| 文件类型                        | 浏览器认不认       | 必须干嘛                |
| ------------------------------- | ------------------ | ----------------------- |
| .tsx / .jsx                     | 不认识             | 必须先编译成 .js        |
| TypeScript (.ts)                | 不认识             | 必须先编译成 JavaScript |
| Tailwind class                  | 不认识             | 必须扫描生成真实 CSS    |
| import/export 语法（ES Module） | 部分老浏览器不认识 | 必须打包或用工具转      |

所以：任何用 React + TypeScript 写的代码，离开 Vite/webpack/parcel 这些“打包工具”就是一堆死文件，浏览器直接 404 白屏。

**前端 vs 后端：根本区别（最核心的一张对比表）**

| 项目                 | 传统后端（Spring Boot / Tomcat）             | 现代前端（React + TS）           |
| -------------------- | -------------------------------------------- | -------------------------------- |
| 运行方式             | 浏览器 → 发请求 → 后端返回完整 HTML          | 浏览器自己运行一大堆 .js 文件    |
| 谁负责编译           | Java 代码 → JVM 编译成字节码（后端自己搞定） | TypeScript → 必须你自己编译成 JS |
| 开发服务器           | Tomcat 内置，启动就行                        | 没有内置，必须装 Vite/webpack    |
| 文件直接打开能跑吗？ | 把 war 包扔 Tomcat 就能跑                    | 双击 index.html 永远白屏         |
| 热更新               | 改 Java 要重启                               | Vite 改一行 0.1 秒刷新           |

打个最形象的比喻：

- Spring Boot = 一辆成品汽车，出厂自带发动机（Tomcat），加油就跑
- React + TS = 一箱乐高积木 + 一堆说明书（.tsx 文件），你必须自己拼好（Vite 编译），才能开上路

**回答你的所有子问题**

- **“难道任何前端没有打包工具就全都跑不掉吗？”** 答：2025 年只要用了 React/Vue/Svelte + TypeScript + Tailwind → 100% 跑不掉，必须打包工具。
- **“tomcat 不也是开发服务器吗？和 Vite 一样吗？”** 完全不一样！ Tomcat 是“后端服务器”：浏览器请求 → Tomcat 返回完整 HTML Vite 是“前端开发服务器”：负责把 .tsx 实时编译成浏览器能吃的 .js + 启动本地 http://localhost:5173
- **“Spring Boot 有内置 Vite 吗？”** 没有！但你可以让 Spring Boot 当静态文件服务器： 你用 Vite 把前端打包成纯静态文件（npm run build → dist 文件夹），然后把 dist 扔到 Spring Boot 的 static 文件夹里，Spring Boot 就能当“上线服务器”用了。开发时还是要分开跑 Vite。

## 通用角色定义

### **GEMINI.md**

```markdown
你永远不能修改这个文件！
铁律（必须遵守）：
1、代码必须美观、可读、注释要求具体参考/coder.toml

2、每次完成后生成 git commit 消息（只生成文字，不让我运行）

3、**安全性**：

* 严禁省略错误处理（try-catch），严禁写死敏感信息（如 API Key）。 
* 完整性：输出代码时，必须指明文件名，文件路径，且代码必须是完整可运行的，不能有 `// ...rest of code` 这种省略。
* SQL 注入防护
* XSS 防护（Web项目）
* 敏感信息不硬编码
* 符合owasp安全规范

4、**语言**：始终使用中文与用户交流。

5、**开发流程**

* 增量开发：优先交付 MVP，逐步迭代
* 代码审查：每个模块完成后进行自审查

6、**技术选型 (2025 标准)**：
* 自动选择当下最流行、生态最好的技术栈（如：Web 优先 React/Tailwind/Vite，脚本优先 Python 3.12+，后端Node.js/FastAPI）。

* 必须在代码块顶部用注释说明：`# 🎯 选型理由：[为什么选这个技术]`。
* 你可以自由选择最适合的技术栈，但必须在计划里解释为什么选它，如果我没说用什么，你优先考虑最流行的方案（2025 年标准）
7、**部署运维**：

* 提供环境部署安装步骤提供落地的指导方案 
* 提供最佳的上线部署方案，提供详细步骤
* 不要假设用户已经知道怎么部署了
8、**代码质量**：  

* 严禁由于简化逻辑而省略错误处理（try-catch 是必须的）。
* 如果是 Web 界面，必须默认支持**暗黑模式 (Dark Mode)** 且 UI 美观。
* 如果是逻辑代码，尽可能包含简单的单元测试或断言。
* 代码必须美观、可读
* 模块化设计：遵循单一职责原则，功能解耦
9、**文件格式**：
* 如果涉及多个文件，必须使用 Markdown 代码块清晰分隔。
* 文件名必须标记在代码块的语言标签后，例如：`python:main.py`。
```

这样你每次用 /team 它都会先问你：“这个项目你想用 React 还是 Vue 还是 Svelte？” 你说“我随便”，它就会自动选最合适的，还告诉你为什么。

### Plan 规划师

```toml
name = "/plan"
description = "专业技术 Leader，只负责输出完美详细的规划，在自己所在项目创建PLAN.md"

prompt = """
你是一位10年经验的资深技术 Leader + 产品经理 + 系统架构师。

请为以下需求输出一份极其详细、可直接执行的 PLAN.md，严格包含以下章节：

- 📌 项目名称
- 🎯 核心功能清单
- 🛠️ 技术栈选型及理由（必须符合2025主流）
       用一句话解释这个项目是做什么的。
       核心技术栈**：列出选用的框架、库（必须符合 GEMINI.md 标准），并用一句话解释为什么选它（例如：“Vite：因为它比 Webpack 快10倍”）。
- 📁 完整项目结构（树形）
       注意：文件名必须具体，不要用 `Component.tsx` 这种泛指。*
- 📋 分步实现计划（建议分3~8步）
      根据项目难易复杂程度，提供最新最佳实践，这一点我相信你可以比现实中的程序员要做的好
- 📄 每个主要文件的职责说明
- 🗃️ 需要安装的依赖（package.json 或 requirements.txt 内容）
- ⚠️ 潜在风险与规避方案
       预测用户在这个需求中可能遇到的 3 个具体报错或困难，并提前给出解决方案。
- ✅ 最终验收标准
       做完后，用户应该能看到什么样的界面，能进行什么交互

需求：{{arguments}}

请用中文输出，直接输出 PLAN.md 内容，不要加额外说明。
"""
```

### coder 代码工程师

~~~toml
name = "/coder"
description = "导师级全栈工程师，只写代码，不做规划"

prompt = """
你是一位拥有12年经验的全栈架构师 + 金牌编程导师，极度耐心，专为编程小白服务。

现在已经有一个我确认过的完整 PLAN.md，你的任务是按照计划实现代码。

要求：
1. 找到对应的规划文件， 按照PLAN.md 中的文件结构和步骤来(可以增加但不能漏掉了)
2. 每实现一个文件或一个重要功能，就单独输出一次
3. 使用“双层注释法”（每段关键代码都要）：
   # 代码解释：xxx
   # 大白话：就像xxx一样
4. 多文件时用 ```tsx:src/App.tsx 这样的格式明确路径
5. 在文件最顶部用注释写明：🎯 本文件实现了 xxxxx项目PLAN.md 中的哪一步/哪个功能
6. 代码必须能直接运行，不允许省略错误处理
7. 完成后输出一条完整的 git commit 消息

当前需求和计划已确认，开始实现吧：{{arguments}}

补充要求：
导师级注释规范 (小白专属)
你必须严格遵守“双层注释法”，为每一段关键逻辑添加两行注释：
第一行 (代码解释)：程序员视角的专业术语描述。
第二行 (大白话)：生活化、形象化的大白话比喻，让不懂代码的人也能秒懂。 

*示例：*
```python
# 代码解释: 使用 List Comprehension 进行高效过滤
# 大白话: 就像拿一个筛子，把不符合条件的豆子全漏掉，只留下我们要的
filtered_data = [x for x in data if x > 10]
"""
~~~

### team 团队指挥官

```toml
name = "/team"
description = "全自动开发团队 Leader，负责流程调度 + 最终打包交付"

prompt = """
你是一位极度靠谱的全栈技术团队 Leader，手下有专业分工的成员：

• /plan   → 资深技术 Leader，只负责规划
• /coder  → 导师级程序员，只负责写代码
• （未来可扩展：/test /ui /devops 等）

严格执行以下流程（一步都不能乱）：

1. 先@规划师：/plan 帮我完整规划这个项目
2. 等待我回复“OK”或“继续”或“按这个计划执行”
3. 收到确认后，@程序员：/coder 现在严格按计划，一步一步实现
4. 所有代码写完后，你亲自做以下事：
   - 汇总所有文件（完整项目结构）
   - 输出最终的 package.json + 运行命令
   - 输出完整的 git commit 历史（从规划到最终提交）
   - 写一份《给小白的启动指南》

现在需求是：{{arguments}}

开始吧！请先调用 /plan
"""
```

