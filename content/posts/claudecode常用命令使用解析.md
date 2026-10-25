---

title: claudecode常用命令使用解析
date: 2025-11-17 17:20:00+08:00
draft: false
categories: ["技术"]
tags:
- AI
- Claude
- 安全工具
- 命令行
permalink: agent-memory/个人随笔站点/site/content/posts/claudecode-常用命令使用解析
---

# Claude Code 常用命令使用解析

大家好，作为一个刚接触 Claude Code 的新手，我根据官方文档和一些热门的介绍视频，整理这份学习笔记和实践总结。主要是为了记录自己的学习过程，同时也希望能起到一个抛砖引玉的作用，为同样在入门路上的朋友们提供一些参考和便利。

这篇总结更多是我个人的理解和实践，内容可能比较基础，难免有疏漏或错误之处，对于经验丰富的高手们，可以直接略过这篇文章。

## 🚀 第一部分：基础入门 - 安装与启动

### 1. 环境准备

- **安装 Node.js：** Claude Code 是一个基于 Node.js 的命令行工具。请先访问 [Node.js 官网](https://www.google.com/url?sa=E&q=https%3A%2F%2Fnodejs.org%2F)，下载并安装推荐的 LTS (长期支持) 版本。

### 2. 安装 Claude Code

- 打开你的终端（Windows 用户使用 PowerShell，Mac/Linux 用户使用 Terminal），输入以下命令并回车：

  codeBash

  ```
  npm install -g @anthropic-ai/claude-code
  ```

  > **【原理讲解】** npm 是 Node.js 的包管理器。-g 参数代表“全局安装”，这意味着你可以在电脑的任何文件夹中使用 claude 命令。

### 3. 启动与初始化

1. **创建项目文件夹：** 在你希望的位置创建一个新文件夹（例如 my-first-app），然后通过终端进入该文件夹。
2. **启动 Claude Code：** 在项目文件夹的终端中，输入 claude 并回车。
3. **初始化项目：** 启动后，立刻输入 /init 命令。

> **【至关重要】** /init 命令是与 Claude Code 高效协作的基石。它会扫描当前项目并创建一个 CLAUDE.md 文件。这个文件相当于 AI 的“项目记忆”，后续所有操作，AI 都会参考它来理解你的项目结构，确保它的行为与你的项目高度相关。

------



## 🧠 第二部分：核心交互 - 与 AI 高效对话

掌握以下命令，你就能像指挥一位得力助手一样，精准地管理 AI 的“记忆”和“专注力”。

| 命令                                              | 功能               | 详细解读                                                     |
| ------------------------------------------------- | ------------------ | ------------------------------------------------------------ |
| /init                                             | **初始化项目**     | **最重要的命令**。为项目创建 CLAUDE.md 上下文文件，让 AI 拥有对项目的宏观认知。 |
| /compact                                          | **压缩上下文**     | 智能地“忘记”不重要的历史对话，保留核心摘要，**提高 AI 专注力并节省 Token 消耗**。可以附加指令，如 /compact 主要保留前端对话。 |
| /clear                                            | **清理上下文**     | 当开始一个全新任务时，用它来清空对话历史，避免 AI 受到之前内容的干扰。 |
| think<br>think hard<br>think harder<br>ultrathink | **提升思考强度**   | 在提问前加上这些官方内置的指令，可以逐步增加 AI 用于思考和规划的计算资源。对于复杂任务，ultrathink 能带来更全面的解决方案。 |
| ! (例如 ! npm install)                            | **临时命令行模式** | 无需切换窗口，直接在 Claude Code 中执行系统命令。**执行的命令和结果会自动加入上下文**，AI 会知道你刚刚做了什么。 |
| # (例如 # 使用 Next.js 14)                        | **添加记忆**       | 将重要信息添加为“长期记忆”。可以选择仅对当前项目生效 (Project memory) 或全局生效 (User memory)。 |

------



## ⚙️ 第三部分：生态集成 - 让 Claude Code 融入你的工作流

Claude Code 的强大之处在于它能与你现有的开发工具无缝集成。

### 1. IDE 集成 (/ide)

- **准备：** 在你的 IDE (如 VS Code) 中安装官方插件 Claude Code for VSCode。
- **连接：** 在 Claude Code 中运行 /ide 命令并连接到你的 IDE。
- **核心功能：**
  - **代码感知：** 你在 IDE 中选中的代码，Claude Code 能实时感知并进行问答。
  - **代码修改同步：** AI 对代码的修改会直接在 IDE 中以“差异对比 (Diff)”视图呈现，让你清晰地看到变更，并一键接受。

### 2. MCP (Model Context Protocol) 集成

- **概念：** MCP 是一种让 AI 与**外部工具**（如数据库、API、文件系统）交互的协议。
- **作用：** 极大地扩展了 AI 的能力边界。例如，通过 context7 这个 MCP Server，AI 可以查询到最新的第三方库文档，弥补自身知识库的滞后性。
- **使用：** 通过 claude mcp add 命令进行添加。

### 3. GitHub 集成

- **准备：** 安装 [GitHub CLI](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcli.github.com%2F)。
- **作用：** 授权后的 Claude Code 可以直接操作你的 GitHub 仓库。
- **强大之处：** 可以实现惊人的自动化工作流。例如，你可以直接告诉它：“**查看 GitHub 仓库里的 Issue #1，根据描述修复这个 bug，创建一个名为 bugfix/login-error 的新分支，然后将修改推送到这个分支。**” Claude Code 会一步步自动完成所有操作。

------



## 🤖 第四部分：自动化与智能化 - Hooks 与 SubAgents

这是 Claude Code 最能体现其“智能”的两个高级功能。它们能将重复性的工作流程自动化，甚至让 AI 自我修正，极大地提升开发效率。

### 1. SubAgent (子代理)

- **概念：** 类似于编程中的“多线程”或现实生活中的“专家团队”。主 Agent (你的主对话) 可以将一个复杂的任务**拆解**成多个独立的子任务，并分配给不同的、专门的 **SubAgent** 去**并行执行**。
- **优势：**
  - **专注：** 每个 SubAgent 只关心自己的小任务，拥有独立的、精简的上下文，不易出错。
  - **高效：** 并行处理可以显著加快复杂任务的完成速度。

#### 1.1 创建并使用你的第一个 SubAgent (新手教程)

   创建一个专门负责“播报天气”的 SubAgent。

**第一步：进入 Agent 管理界面**

- **操作：** 在 Claude Code 中输入 /agents 并回车。

**第二步：开始创建新 Agent**

- **操作：** 你会看到一个菜单，选择 > Create new agent 并回车。

**第三步：定义 Agent 的角色 (核心)**

- **操作：** 这是最关键的一步。你需要用自然语言清晰地描述这个 Agent 的职责。输入以下描述：

  > 你是一个天气预报大师，使用联网工具查询天气。

**第四步：为 Agent 分配工具**

- **操作：** 接下来会让你选择这个 Agent 可以使用哪些工具。对于一个天气预报员，它需要联网。为了简单起见，新手可以直接选择 [x] All tools (所有工具)。
- **进阶提示：** 在实际应用中，为了安全和专注，你应该只为 Agent 分配它完成任务所必需的最小工具集。比如，天气 Agent 只需要 WebSearch 工具就足够了。

**第五步：选择模型和颜色**

- **操作：** 选择一个模型（通常默认的 Sonnet 即可），然后为你的 Agent 选一个颜色（例如 Blue），这样在对话中可以轻松区分它。

**第六步：确认并保存**

- **操作：** 回车确认，你的第一个 SubAgent weather-forecast-master 就创建完成了！

#### 1.2 如何调用 SubAgent

有两种方式可以调用你创建的 SubAgent：

1. **隐式调用 (自动委派)：**
   这是最智能的方式。你只需要在主对话中提出一个包含多个任务的复杂请求，主 Agent 会自动分析并将合适的子任务委派给对应的 SubAgent。

   > **示例：** “帮我审查 feature/new-ui 分支的代码，并查一下北京今天的天气怎么样？”
   >
   > Claude Code 会自动将“审查代码”的任务交给代码审查 Agent，将“查天气”的任务交给天气预报 Agent。

2. **显式调用 (手动指定)：**
   如果你想强制使用某个 Agent，可以在对话中使用 @ 符号来直接呼叫它。

   > **示例：** @weather-forecast-master 北京今天天气如何？
   >
   > 这会确保只有 weather-forecast-master 这个 Agent 来处理你的请求。

### 2. Hooks (钩子)：终极自动化工具

这是我们重点讲解的部分，也是实现高度自动化工作流的关键。

#### 2.1 钩子是什么？

- **定义：** 钩子是一种**事件驱动**的自动化机制。它允许你在 Claude Code 工作流程的**特定事件发生时**，自动**触发并执行预先定义好的操作**。
- **运行原理：**
  1. **监听 (Listening)：** Claude Code 在运行时会不断广播各种事件信号（如 PreToolUse）。
  2. **匹配 (Matching)：** 你定义的 Hook 监听到信号后，会检查**事件类型**和**触发条件 (Matcher)** 是否都匹配。
  3. **触发与执行 (Triggering & Execution)：** 匹配成功后，Hook 被触发，系统暂停当前流程，去执行你定义的操作。
  4. **反馈 (Feedback)：** 脚本的执行结果（通过**退出码**）可以反过来影响 Claude Code 的后续行为（是继续还是中止）。

#### 2.2 钩子的运行

为了更好地理解 Hook，我们可以把它想象成一个机场的“智能安检系统”，它的工作流程由以下四个核心概念构成：

1.**Hook Events (钩子事件) —— “安检的时机”**

- **定义：** Hook 被触发的**时间点**。

- **核心类型：**

  - PreToolUse：在工具**使用之前**触发。（相当于登机前的安检）。
  - PostToolUse：在工具**使用之后**触发。（相当于落地后的海关检查）。
  - Notification, UserPromptSubmit 等。

  **常用列表**：

  | 触发事件         | 触发时机                             |
  | ---------------- | ------------------------------------ |
  | PreToolUse       | 在工具**使用之前**触发。（事前钩子） |
  | PostToolUse      | 在工具**使用之后**触发。（事后钩子） |
  | Notification     | 系统发出通知时触发。                 |
  | UserPromptSubmit | 用户提交新消息时触发。               |

- **一句话总结：** 它是**触发器**，决定了你的逻辑在哪个阶段介入。

2.**触发条件 (Matchers) —— “安检系统针对哪种旅客？”**

- **定义：** Matcher 是一个**过滤器**，它精确地告诉 Hook 应该关注**哪一种或哪一类工具**的行为。

- **作用：** 确保 Hook 只在您关心的特定操作上触发，而不是对所有操作都做出反应。

- **触发条件 (Matchers) - “针对哪个工具？”**

  | Matcher              | 对应的工具/操作       |
  | -------------------- | --------------------- |
  | Edit MultiEdit Write | 文件创建、编辑、写入  |
  | Bash                 | 执行命令行命令        |
  | Task Subagent        | 创建子任务或子代理    |
  | WebFetch WebSearch   | 访问网页或网络搜索    |
  | UseMcpTool           | **使用外部 MCP 工具** |

- **组合使用：** 您可以用 |（代表“或”）来组合多个 Matcher，例如 "matcher": "Edit|Write" 表示当“编辑”或“写入”文件时都触发。

- **一句话总结：** 它是**过滤器**，是 Hook 触发的精确条件。

3.**Hook Input (钩子输入) —— “安检员拿到的旅客信息”**

- **定义：** 当事件触发时，Claude Code **通过标准输入 (Stdin) “喂”给你的脚本的数据**，通常是 JSON 格式。
- **核心作用：** 让你的脚本知道“要发生什么”或“发生了什么”。例如，对于 PreToolUse 事件，Input 会包含工具名和参数，如 {"tool": "Edit", "path": "main.py"}。
- **一句话总结：** 它是**脚本接收到的上下文数据包**。

4.**Hook Output (钩子输出) —— “安检员的最终决定”**

- **定义：** 你的脚本运行结束后，**反馈给 Claude Code 的信息**。
- **核心组成：**
  - **退出码 (Exit Code)：** 0 代表“成功/放行”，非 0 代表“失败/中止”。
  - **打印信息 (Stdout/Stderr)：** 你在脚本中 print() 的内容，会作为反馈信息显示给用户。
- **一句话总结：** 它是**脚本的判决书和给用户的留言**。

5.**Working with MCP Tools (处理特殊旅客) —— “针对外部工具的规则”**

- **定义：** 这是一个特定的应用场景，指 Hook 如何针对 **MCP 工具**（外部扩展工具，如数据库连接器）进行拦截。
- **核心区别：** 拦截外部工具需要使用专门的 matcher: "UseMcpTool"。
- **一句话总结：** 它是**针对外部扩展工具的特定拦截规则**。

#### 2.3 command 与 script 的核心区别 

- **command**：简单、直接，**不能接收**来自 Claude Code 的事件数据。适用于“即发即忘”的通知类任务。
- **script**：功能强大，**能通过标准输入 stdin 接收**事件数据（Hook Input），并通过**退出码**（Hook Output）反馈处理结果。适用于需要验证、判断、与工作流交互的复杂任务。👉 参考官方文档 [https://code.claude.com/docs/en/hooks#subagentstop](https://code.claude.com/docs/en/hooks#subagentstop)

#### 2.4 简单上手例子：代码修改后语法检查

**需求：** 每当 Claude Code 修改了代码，都自动运行 prettier 检查格式。

**配置 (.claude/settings.json)：**

codeJSON

```
{
  "hooks": {
    "PostToolUse": [ // 事后钩子
      {
        "matcher": "Edit|MultiEdit|Write", // 匹配文件修改操作
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --check ." // 执行格式化检查命令
          }
        ]
      }
    ]
  }
}
```

**解读：** 这个配置定义了一个事后钩子，在任何文件编辑操作**之后**，执行一个简单的命令行命令来检查代码格式。

#### 2.5 复杂例子：事前和事后审计钩子

**需求：** 在 Claude Code 每次**准备**执行任何命令行 (Bash) 操作**之前**，将该命令及其描述记录到日志文件中。

**第一步：配置事前钩子 (PreToolUse) 记录“意图”**
在 .claude/settings.json 中添加：

codeJSON

```
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"INTENT: \\(.tool_input.command)\"' >> ~/.claude/bash-audit-log.txt"
          }
        ]
      }
    ]
  }
}
```

> **解读：** 这个钩子的作用是**创建一个命令执行日志**。在 Claude Code 每次**准备**执行任何命令行 (Bash) 操作**之前**，它会先将这个即将执行的命令和它的描述，自动记录到一个名为 bash-command-log.txt 的日志文件中。

------

✍️逐行解释

让我们来拆解这段 JSON 配置：

```
{
  "hooks": {
```

- "hooks": { ... }：这是定义所有钩子的**顶层容器**。所有的 Hook 规则都必须写在这个大括号里面。

```
"PreToolUse": [
```

- "PreToolUse": [ ... ]：这里定义了一个**钩子事件**。PreToolUse 意味着这个钩子将在 Claude Code **“准备使用工具之前”** (Pre-Tool-Use) 被触发。这是一个**事前钩子**，它有机会在操作真正发生前介入。

```
{
        "matcher": "Bash",
```

- "matcher": "Bash"：这是**触发条件**。它告诉 Claude Code：“我只关心 Bash 类型的工具”。也就是说，只有当 AI 准备执行一个**命令行命令**时，这个钩子才会被激活。如果 AI 准备做的是修改文件 (Edit) 或网络搜索 (WebSearch)，这个钩子将保持沉默。

```
"hooks": [
```

- "hooks": [ ... ]：这是当上述条件满足时，需要执行的**具体操作列表**。

```
{
            "type": "command",
```

- "type": "command"：定义了要执行的操作类型是**命令行命令**。

```
"command": "jq -r '\"\\(.tool_input.command) - \\(.tool_input.description // \"No description\")\"' >> ~/.claude/bash-command-log.txt"
          }
```

- "command": "..."：这是整个例子的核心，是实际被执行的命令。我们把它拆成三个部分来理解：

  1. **jq -r '...'** (数据处理部分)
  2. **>>** (数据流向部分)
  3. **~/.claude/bash-command-log.txt** (数据目的地部分)

  下面我们来详细讲解这三个部分。

------



📄 核心命令 jq 的深度解析

jq 是一个非常强大的**命令行 JSON 处理器**。你可以把它想象成一个专门用来解析和格式化 JSON 数据的“瑞士军刀”。

当这个 Hook 被触发时，Claude Code 会自动将 PreToolUse 事件的**输入数据（Hook Input）**——一个描述了即将执行的 Bash 命令的 JSON 对象——通过管道传递给 jq 命令。

这个 JSON 输入数据大概长这个样子：

codeJSON

```
{
  "tool_input": {
    "command": "ls -l",
    "description": "List files in the directory"
  }
}
```

现在我们来看 jq 命令本身：

jq -r '\"\\(.tool_input.command) - \\(.tool_input.description // \"No description\")\"'

- **jq**: 调用 jq 这个程序。
- **-r**: 代表 "raw output"（原始输出）。它的作用是，在输出结果时去掉字符串两边的双引号。如果没有它，输出到文件里的内容会是 "ls -l - List files..."，带有多余的引号。
- **'...'**: 单引号里是 jq 的处理脚本。
  - \"...\"：脚本最外层的 \" 表示我们希望最终输出的是一个**字符串**。
  - \\(.tool_input.command)：这是 jq 的**字符串插值**语法。
    - .tool_input.command 表示“从输入的 JSON 数据中，找到 tool_input 对象，再找到它里面的 command 字段”。在这里，它会提取出 "ls -l"。
  - -：这是一个**普通的分隔符**，会原样输出。
  - \\(.tool_input.description // "No description")：
    - 它首先尝试提取 .tool_input.description 字段。
    - // 是 jq 中的**默认值操作符**。如果 description 字段存在且不为 null，就使用它的值。如果它不存在或者为 null，就使用 // 后面的默认值 "No description"。这使得脚本非常健壮，即使 AI 有时没有提供描述，日志也不会出错。

所以，这一整段 jq 命令的作用就是：读取输入的 JSON，提取出 command 和 description，然后把它们格式化成一个像 ls -l - List files in the directory 这样的、人类可读的字符串。

数据流向与目的地

- **>>**: 这是标准的 Shell **追加重定向**操作符。它会将 jq 命令处理后输出的字符串，**追加**到指定文件的末尾。使用 >> 而不是 > 可以确保日志文件是不断累加的，而不是每次都被覆盖。
- **~/.claude/bash-command-log.txt**: 这是日志文件的**存储路径**。~ 代表用户的**主目录**（Home Directory）。这意味着无论你在哪个项目里运行 Claude Code，所有的 Bash 命令执行记录都会被统一记录到用户主目录下的同一个全局日志文件中。

📌总结一下完整流程

1. Claude Code 准备执行一个 Bash 命令，比如 ls -l。
2. PreToolUse 事件被触发，matcher 成功匹配到 Bash。
3. Claude Code 将包含 { "command": "ls -l", "description": "..." } 的 JSON 数据作为**输入**，传递给 Hook 中定义的 command。
4. 系统终端执行 jq 命令，jq 从输入中读取 JSON，将其格式化为字符串 ls -l - List files in the directory。
5. \>> 操作符捕获这个字符串，并将其作为新的一行写入到 ~/.claude/bash-command-log.txt 文件中。
6. 这个 Hook 执行完毕后，Claude Code **才会继续执行**原来的 ls -l 命令。

这个例子巧妙地利用了 PreToolUse 事件、command 类型、jq 工具和 Shell 重定向，实现了一个非侵入式、全局生效的 AI 行为审计功能。侵入式、全局生效的 AI 行为审计功能。

------

**第二步：配置事后钩子 (PostToolUse) 记录“结果”**

因为 PreToolUse 钩子是在命令**即将被执行之前**触发的，所以它能捕获到的信息只有：

- **将要执行的命令本身**（例如 rm -rf temp/）。
- AI 对这个命令的**描述**。

在那个时间点，命令还没有被交给操作系统去执行，因此**任何由该命令产生的结果都是未知的**。具体来说

- **看不到标准输出 (stdout)：** 比如 ls -l 命令会列出哪些文件，在 PreToolUse 阶段是不知道的。
- **看不到标准错误 (stderr)：** 如果命令执行失败，失败的原因在 PreToolUse 阶段也是不知道的。
- **看不到文件系统变化：** rm 命令到底成功删除了哪些文件，mkdir 命令是否成功创建了文件夹，这些在 PreToolUse 阶段都无法获知。

🔍所以PreToolUse只能审计 AI 打算做什么，而不能审计它实际做成了什么**。它是一个行为意图的记录器。

**❓如何记录“结果”？**

为了解决这个问题，Claude Code 提供了 PreToolUse 的“另一半”—— 💎**PostToolUse 钩子**。

PostToolUse 钩子是在命令**执行完成之后**触发的。它接收到的 Hook Input (输入数据) 就包含了命令执行的结果。

PostToolUse 的输入数据（JSON 格式）大致如下：PostToolUse 的输入数据（JSON 格式）大致如下：

```
{
  "tool_output": {
    "stdout": "这是命令的标准输出内容...",
    "stderr": "这是命令的错误输出内容..."
  }
}
```

**示例：创建一个记录“结果”的日志钩子**

我们可以再创建一个钩子，专门用来记录命令执行后的结果。

1. **修改 settings.json 文件：**
   我们可以添加一个新的 PostToolUse 钩子。

   codeJSON

   ```
   {
     "hooks": {
       // ... 这是我们之前创建的 PreToolUse 钩子 ...
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "command": "jq -r '\"INTENT: \\(.tool_input.command)\"' >> ~/.claude/bash-audit-log.txt"
             }
           ]
         }
       ],
       // +++ 这是我们新添加的 PostToolUse 钩子 +++
       "PostToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "command": "jq -r '\"RESULT: STDOUT=\\(.tool_output.stdout // \\\"\\\") | STDERR=\\(.tool_output.stderr // \\\"\\\")\"' >> ~/.claude/bash-audit-log.txt"
             }
           ]
         }
       ]
     }
   }
   ```

2. **代码解释：**

   - "PostToolUse": 在工具使用**之后**触发。
   - jq -r '...：同样使用 jq 来处理。
     - \"RESULT: ...\"：输出一个以 "RESULT:" 开头的字符串。
     - STDOUT=\\(.tool_output.stdout // \\\"\\\")：提取标准输出。如果 stdout 为空 (null)，则 // 默认值操作符会将其替换为一个空字符串 ""，避免日志中出现 "null" 字样。
     - STDERR=\\(.tool_output.stderr // \\\"\\\")：同理，提取标准错误。
   - \>> ~/.claude/bash-audit-log.txt：将结果**追加**到同一个日志文件中。

最终效果：完整的审计闭环，当您同时配置了 PreToolUse 和 PostToolUse 这两个钩子后，您的 bash-audit-log.txt 日志文件就会变成这样，形成一个完美的审计闭环：

> **解读：** 这会在 Bash 命令**执行后**，从 **Hook Input** (tool_output) 中提取标准输出 (stdout) 和标准错误 (stderr)，格式化后同样追加到日志文件中。

**最终的审计闭环日志 (bash-audit-log.txt) 效果：**

```
# 1. 事前钩子记录意图
INTENT: rm non_existent_file.txt
# 2. 事后钩子记录结果
RESULT: STDOUT= | STDERR=rm: cannot remove 'non_existent_file.txt': No such file or directory
```

通过 PreToolUse 和 PostToolUse 的组合，我们完美地实现了对 AI 行为的**意图记录**和**结果审计**，形成了一个强大而完整的监控闭环。

------



## 🖥️ 第五部分：可视化操作 - Claudia 桌面应用

对于不习惯纯命令行的用户，社区提供了 Claudia 这个开源的桌面应用。它为 Claude Code 的核心功能提供了图形化界面：

- **项目和对话管理：** 直观地查看和切换不同的项目和历史会话。
- **可视化配置：** 通过点击界面来创建和管理 Agents, MCP, 自定义命令, Hooks 等。
- **历史检查点 (Checkpoints)：** 强大的“时间旅行”功能，可以一键将**文件系统状态**和**对话历史**同时回退到之前的某个时间点，是撤销误操作的神器。

------