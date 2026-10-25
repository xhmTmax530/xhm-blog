---
title: "AutoGen小白篇(Windows)"
date: 2025-11-22T12:35:00+08:00
draft: false
categories: ["技术"]
tags: ["AutoGen", "agent", "大模型", "工作流", "worker"]
---

# AutoGen小白篇(Windows)

## 1. 什么是 AutoGen？它解决了什么痛点？

AutoGen 是一个开源框架，用于构建多代理（multi-agent）AI 应用程序，这些代理可以自主行动或与人类协作。根据提供的文档和 GitHub 仓库（https://github.com/microsoft/autogen），AutoGen 旨在简化 AI 代理系统的开发，支持从简单聊天代理到复杂分布式系统的构建。它由 Microsoft xAI 团队开发，支持 Python 和 .NET 等语言，强调事件驱动的编程模型、异步消息传递和可扩展性

从我的理解来看，AutoGen 不仅仅是一个库，而是一个生态系统，包括核心框架、扩展工具和开发者工具（如 AutoGen Studio）。它允许开发者创建 AI 代理，这些代理可以处理任务如代码生成、网页浏览、数学计算等，通过事件和消息进行协作。相比传统单代理系统，AutoGen 专注于多代理协作，类似于一个“AI 团队”来解决问题。

### 核心定义

它不仅仅是一个调用 LLM（大语言模型）的工具，而是一个**协作平台**。它允许你创建多个“角色”（Agents），这些角色可以相互对话、分工合作、调用工具，甚至可以让人类参与其中。

### 解决的痛点

1. **单打独斗的局限性**：单个 ChatGPT 只能回答问题，难以完成复杂任务（如“写代码并运行测试，如果报错则修复”）。AutoGen 让一个负责写，一个负责审，形成闭环。
2. **上下文管理难**：在长任务中，手动管理对话历史很痛苦。AutoGen 自动处理多轮对话的上下文。
3. **工具集成繁琐**：让 AI 浏览网页、执行 Python 代码通常需要大量胶水代码。AutoGen 提供了标准化的工具接口（如 MCP Server）。
4. **扩展性差**：旧的 Agent 框架难以跨语言或跨网络分布。v0.4 引入了“事件驱动”架构，支持分布式部署。

## 2. 核心特点与架构组成 (核心分析)

AutoGen v0.4 的设计理念是 **“异步、事件驱动、分布式”**。

### 2.1 架构分层

#### **AutoGen 的架构是分层的**、可扩展的，基于发布-订阅模型。核心组件包括：

- **代理（Agents）**：基本单元，处理事件、调用模型、访问内存或工具。每个代理有事件处理器（Event Handlers），响应特定事件类型。
- **事件（Events）**：使用 CloudEvents 格式，包括 ID、源和类型。系统内置事件如系统事件（启动/停止代理）。
- **主题（Topics）**：代理订阅主题以接收消息。主题 ID 包括类型和源，支持匹配和映射到代理。
- **服务（Services）**：包括 Worker（托管代理）、Gateway（RPC 和事件桥接）、Registry（代理注册）、AgentState（持久状态）和 Routing（事件路由）。
- **后端选项**：内存、Python 服务、Microsoft Orleans（分布式演员系统）。

整体架构：代理通过 Worker 连接服务，事件在服务间流动。分布式时，使用 gRPC 通信。

#### **对AutoGen的大白话解释**

**AutoGen 就像一个“AI 客服呼叫中心”：**

- 代理 = 每一个坐席客服
- 事件 = 客户打进来的电话（带着“谁打的、什么事”）
- 主题 = 呼叫中心的分机号（比如“技术支持 8001”“退货 8002”）
- 服务 = 后勤部门（总机、调度室、档案室、数据库） 整个系统靠“电话铃响了谁接”而不是“你去叫张三来接电话”来运转，这就是发布-订阅的本质。

下面用一个真实的呼叫中心来彻底讲明白 AutoGen 的每一层。

##### 1. 代理（Agents）—— 真正干活的客服小哥哥小姐姐

- **大白话**：每个代理就是一个会用大模型思考的“智能员工”。你给他发消息，他就能看、思考、回话、打电话（调用工具）、写笔记（改内存）。
- **原理**：他们不主动找活干，只听电话铃（事件）。铃声一响，匹配到自己的分机号，就开始处理。
- 真实例子
  - 写手代理：专门写文章
  - 代码代理：专门写代码
  - 浏览网页代理：专门上网查东西
  - 审查代理：专门挑毛病

##### 2. 事件（Events）—— 客户打进来的每一通电话

- **大白话**：一张标准工单，上面写清楚： “谁打的（source）” + “什么事（type）” + “具体内容（data）” + “工单编号（id）” 这就是 CloudEvents 格式，全国客服中心都认这个标准。
- **真实例子**： 你问：“帮我写一个神经网络” → 系统立刻生成一张工单： type = “用户提问” source = “你” data = “帮我写一个神经网络” id = “uuid-12345”

##### 3. 主题（Topics）—— 呼叫中心的分机号和转接规则

- **大白话**：就像你拨打客服电话： 技术问题按1 → 转到技术组 退货按2 → 转到售后组 代理提前登记“我能接1号分机”，电话一来自动转过去。
- 两个关键概念
  - type（主题类型）：比如 “编程问题”
  - source（来源）：可以是具体用户、具体对话ID 组合起来就是完整分机号：编程问题 + 来自用户张三 → 只转给张三专属的编程代理

##### 4.服务（Services）—— 呼叫中心的后勤部门（你平时看不到但离了不行

| 服务名字   | 呼叫中心比喻 | 实际干啥                             |
| ---------- | ------------ | ------------------------------------ |
| Worker     | 客服工位     | 真正跑代理代码的电脑进程             |
| Gateway    | 总机姐姐     | 收发所有电话，决定打给哪个工位       |
| Registry   | 花名册       | 记录“哪个代理能接什么分机”           |
| Routing    | 智能转接系统 | 根据分机号把电话精准送到对应代理     |
| AgentState | 员工档案柜   | 保存每个代理的记忆（上文、历史对话） |

##### 5.后端选项—— 呼叫中心可以开一家小店，也可以开全国连锁

| 后端类型          | 比喻                         | 适合场景               |
| ----------------- | ---------------------------- | ---------------------- |
| 内存（In-Memory） | 你家客厅开个2人小呼叫中心    | 玩玩、调试、写脚本     |
| Python 服务       | 市中心一间办公室             | 小团队用               |
| Microsoft Orleans | 全国连锁呼叫中心 + 云调度    | 上千人同时用、生产环境 |
| gRPC              | 不同城市办公室之间的电话专线 | 分布式部署             |

##### 完整工作流程（用你之前的多代理例子来说）

你问：“帮我用Python从零写一个神经网络”

1. 系统生成一张工单（事件）
2. 工单扔到“编程问题”这个总机号（主题）
3. 两个分析代理早就登记了“我能接编程问题” → 同时接到电话（并行！）
4. 分析代理1（追求高效）开始写答案
5. 分析代理2（追求简单）也开始写答案
6. 两个答案写完后，再生成新工单扔给“优化总结”分机
7. 优化代理接到后，把两份答案对比、补漏、排版成Markdown → 给你

整个过程没有“你去叫谁”，全靠“铃响了谁接”，这就是发布-订阅（**观察者模式**）的灵魂。

### 2.2 关键概念

- **Agent (智能体)**：具有特定角色（如“程序员”、“产品经理”）。
  - *ID*: 由 namespace (命名空间) 和 name 组成。
- **Topic (话题)**：Agent 订阅话题来接收消息（类似消息队列）。
- **Lifecycle (生命周期)**：Agent 并不是一直活着的。当有消息发给它时，系统会激活它；闲置时可能会休眠。

### 2.3 使用原理

AutoGen 的核心原理是**发布-订阅（Pub-Sub）**模型结合事件驱动架构：

- 代理订阅感兴趣的事件主题。
- 当事件发布时，匹配订阅的代理处理它，可能触发新事件或调用工具（如 LLM、网页浏览）。
- 对于 RPC 等模式，在事件上层构建请求/响应。
- 代理生命周期：按需激活，无需显式创建/销毁。
- 数据流：事件携带上下文，代理可修改状态、调用外部 API 或发出新事件。

原理优势：解耦代理，易于扩展和调试。结合 LLM（如 OpenAI），代理可生成智能响应。

#### AutoGen代理如何判断“我对这个事件感兴趣”？

**关键点：流程说明**

- 代理自己提前“登记”感兴趣的分机号（订阅主题）。
- 每来一个事件（电话），系统就看事件的分机号（TopicId）和自己登记的分机号对不对得上。
- 对得上 → 感兴趣 → 接电话！对不上 → 完全忽略。
- 匹配方式超级灵活：可以精确匹配，也可以“*通配符”批量匹配。

下面用最接地气的例子给你讲明白。

------

**用“客服呼叫中心”再讲一遍（你已经熟悉这个比喻了）**

1. 代理提前去总机登记：
   - 代码代理说：“我能接所有 type=编程问题 的电话！”
   - 数学代理说：“我只接 type=数学计算:* 的电话（*表示不管是谁打的都接）”
   - 用户专属代理说：“我只接 type=用户提问 AND source=用户张三 的电话”
2. 用户打进来一个电话（事件） 事件内容： type = “编程问题” source = “用户张三”
3. 系统（Routing服务）立刻拿这张工单去比对所有代理的登记表：
   - 代码代理登记的是 “编程问题” → 完全匹配 → 响铃！
   - 数学代理登记的是 “数学计算” → 不匹配 → 不响铃
   - 用户专属代理登记的是 “编程问题 + 用户张三” → 也匹配 → 也响铃！
4. 结果：代码代理和用户专属代理同时接到这个任务（可以并行干活）

这就是整个匹配过程！

| 函数    | 大白话名字       | 作用                                         | 举例                                                         |
| ------- | ---------------- | -------------------------------------------- | ------------------------------------------------------------ |
| Matcher | “我感不感兴趣”   | 输入一个事件TopicId → 返回 True / False      | Matcher = lambda topic: topic.type.startswith("编程")        |
| Mapper  | “转给我哪个工位” | 如果感兴趣了，把这个事件转给具体哪个代理实例 | Mapper = lambda topic: AgentId(type="代码代理", key=topic.source) |

代码长这样（真实Python写法）：

```python
# 代码代理订阅所有编程问题（用通配符 * 表示“我全都要”）
subscription = Subscription(
    matcher=lambda topic: topic.type == "编程问题",           # 精确匹配type
    # matcher=lambda topic: "编程" in topic.type             # 模糊包含也行
    # matcher=lambda topic: topic.type.startswith("com.ai.") # 前缀匹配也行
    mapper=lambda topic: AgentId(type="代码代理", key="default")  # 都转给同一个默认实例
)

# 数学代理用通配符订阅所有数学相关
subscription2 = Subscription(
    matcher=lambda topic: topic.type.startswith("数学计算:"),  # :后面是source，随便
    mapper=lambda topic: AgentId(type="数学代理", key=topic.source.split(":")[1])  # 按来源动态创建不同实例
)
```

**支持的匹配方式汇总（超级灵活！）**

| 匹配方式   | 代码例子                                            | 大白话解释                   |
| ---------- | --------------------------------------------------- | ---------------------------- |
| 完全相等   | topic.type == "编程问题"                            | 分机号一模一样才接           |
| 前缀匹配   | topic.type.startswith("com.microsoft.")             | 所有微软内部事件都接         |
| 包含关键词 | "数学" in topic.type                                | 只要提到数学我就接           |
| 通配符 *   | topic.type == "用户提问:*"                          | 所有用户提问我都接，不管是谁 |
| 正则表达式 | re.match(r"编程\d+", topic.type)                    | 编程1、编程2、编程123 都接   |
| 组合条件   | topic.type == "编程问题" and topic.source == "张三" | 只有张三的编程问题我才接     |

**实际运行时发生了什么（一步一步）**

1. 代理启动时，把自己的 Matcher 和FD Mapper 函数注册到 Registry（花名册）
2. 有人发布一个事件 → Routing 服务拿到事件
3. Routing 遍历所有订阅：
   - 挨个调用每个代理的 matcher(event)
   - 返回 True 的代理全被叫醒
   - 再用 mapper(event) 决定具体转给哪个实例（可能动态创建新实例！）
4. 事件被送到对应代理的“事件处理器”里执行

#### AutoGen订阅机制真实运行示例

```java
import asyncio  # 引入异步库，让程序可以“同时等多个电话”而不卡住
```

观察者模式思维：整个系统是异步事件驱动的，代理像“客服在座位上等铃响”，不用自己不停问“有没有活”。

```java
from autogen_core.base import MessageContext  # 消息上下文，事件到来时会带上
from autogen_core.components import DefaultTopicPubSub, RoutedAgent, message_handler
from autogen_core.application import SingleThreadedAgentRuntime  # 单线程运行时（本地调试用）
```

**观察者模式思维**：

- RoutedAgent = 可订阅的观察者（Observer）
- DefaultTopicPubSub = 主题总线（Subject）
- message_handler = 观察者收到通知后执行的方法

```java
# 1. 定义一个“代码代理”——观察者本人
class CodeWriterAgent(RoutedAgent):  # 继承RoutedAgent，表示它能被路由（能订阅）
    def __init__(self, description: str):
        super().__init__(description)  # 初始化父类，告诉系统“我是一个可订阅的代理”

    # 装饰器：当收到匹配的事件时，自动调用这个方法（这就是观察者被通知！）
    @message_handler
    async def handle_user_message(self, message: dict, ctx: MessageContext):
        print(f"【代码代理收到任务】用户说：{message['content']}")
        reply = f"我来写代码啦！这里是解决方案：\n```python\n# 示例代码\ndef hello():\n    print('Hello from AutoGen!')\n```"
        # 把结果发回给原来的主题（相当于回电话）
        await self.publish_message({"content": reply}, topic_id=ctx.topic_id)
```

**观察者模式核心在这里**：

- @message_handler = “我注册了一个观察方法”
- 当系统发现事件匹配时，自动调用这个方法 → **被观察者（Subject）主动通知观察者（Observer）**
- 代理完全不知道谁发的消息，只管处理 → 完美解耦

```java
async def main():
    # 2. 创建运行时 = 创建“事件总线”（被观察者/Subject）
    runtime = SingleThreadedAgentRuntime()
```

观察者模式思维：runtime 就是整个系统的“大脑”，负责维护“谁订阅了什么”。

```java
# 3. 注册代理 + 订阅主题 —— 这就是观察者向被观察者注册！
    await CodeWriterAgent.register(
        runtime,                                   # 把代理注册到总线
        type="code_writer",                        # 代理类型名称
        factory=lambda: CodeWriterAgent("我是一个专业的代码生成代理"),  # 如何创建实例
        subscriptions=lambda topic: topic.type == "programming_task"  # ← 关键！订阅规则
    )
```

**逐行拆解 subscriptions=lambda topic: topic.type == "programming_task"**

- 这是一个**Matcher 函数**（判断“我感不感兴趣”）
- 每当有新事件到来，系统会遍历所有已注册的代理，调用这个 lambda
- 如果返回 True → “铃响了！这个代理要被唤醒”
- **这就是观察者模式中最经典的“注册兴趣”步骤**！

```java
# 4. 启动默认的发布-订阅总线
    DefaultTopicPubSub.register(runtime)
```

观察者模式思维：激活总线，现在所有订阅都生效了。

```java
runtime.start()  # 启动运行时，开始监听事件
    print("系统已启动，代码代理正在等待编程任务...")
```

观察者模式思维：代理现在坐在工位上，耳朵竖着等铃响

```java
# 5. 模拟用户发布一个事件 —— 相当于“有人打进电话”
    await runtime.publish_message(
        {"content": "帮我写一个Python快速排序"},
        topic_id={"type": "programming_task", "source": "user123"}  # 事件的分机号
    )
```

**观察者模式关键时刻**：

1. 事件发布 → 总线收到
2. 总线遍历所有订阅 → 调用 lambda → 返回 True
3. 自动把事件路由给 CodeWriterAgent
4. @message_handler 方法被调用 → 打印“收到任务” → 回复代码

```java
await asyncio.sleep(2)  # 等待2秒看结果
    await runtime.stop()     # 停止系统
```

完整运行逻辑图（观察者模式视角）

| 角色                | 代码对应部分                                     | 观察者模式术语   |
| ------------------- | ------------------------------------------------ | ---------------- |
| 被观察者（Subject） | runtime + DefaultTopicPubSub                     | 事件总线         |
| 观察者（Observer）  | CodeWriterAgent                                  | 代码代理         |
| 注册观察            | CodeWriterAgent.register(..., subscriptions=...) | attach(observer) |
| 发布事件            | runtime.publish_message(...)                     | notify()         |
| 收到通知            | @message_handler 方法被调用                      | update()         |

**总结一句话**

“代理订阅 = 观察者提前告诉系统‘这种电话我接’，事件发布 = 被观察者喊一声‘来电话啦！’，系统自动遍历所有观察者，问一遍‘你接吗？’，回答‘接’的就自动被叫醒干活 —— 整个过程代理之间互不认识，完全靠系统自动通知，这才是真正的观察者模式！”

### 技术原理解释（Matcher 函数和 Mapper 函数）

AutoGen文档里写了两个核心函数，就是“判断感兴趣”和“转给谁”的关键：

### 2.4 实际使用场景

- **自动化任务**：如代码审查（一个代理生成代码，另一个审查）。
- **研究与数据分析**：多代理协作查询数学、化学问题，或浏览网页获取实时信息。
- **聊天机器人**：构建多代理聊天系统，一个代理处理用户输入，另一个调用工具。
- **分布式 AI 系统**：在云环境中部署代理团队处理大规模数据。
- **游戏/模拟**：代理模拟角色互动。
- **企业应用**：如客服系统，多代理分工处理查询。

案例：在 README 中，展示网页浏览代理查询 GitHub 贡献者，或多代理处理数学/化学查询。

### 2.5 功能模块说明

| 模块名称              | 作用                                          | 适用场景                                       |
| --------------------- | --------------------------------------------- | ---------------------------------------------- |
| **autogen-core**      | 提供消息总线、事件处理、RPC。                 | 高级开发，需要构建分布式、跨语言 Agent 系统。  |
| **autogen-agentchat** | 提供 AssistantAgent, UserProxy 等高级封装。   | **新手推荐**。构建聊天机器人、任务编排。       |
| **autogen-ext**       | 提供模型客户端（OpenAI/Azure）和工具（MCP）。 | 连接大模型 API，连接外部工具（浏览器、终端）。 |
| **AutoGen Studio**    | 无代码/低代码的可视化界面。                   | 演示、原型设计，不想写代码时使用。             |

你可以把 **AutoGen** 想象成你在组装一台 **“超级电脑”** 或者经营一家 **“AI 公司”**。为了让这个系统灵活好用，微软把代码拆成了四个不同的零件包。

我用**大白话 + “开公司”的例子**给你逐一解释：

------


没问题！作为一个刚接触的新手，看到这些带横杠的英文包名确实容易晕。

你可以把 **AutoGen** 想象成你在组装一台 **“超级电脑”** 或者经营一家 **“AI 公司”**。为了让这个系统灵活好用，微软把代码拆成了四个不同的零件包。

我用**大白话 + “开公司”的例子**给你逐一解释：

------

#### 1. autogen-core —— 公司的地基和电话线

- **别名**：核心底层
- **大白话原理**：
  这是最底层的东西，你平时写代码可能很少直接用到它，但没它不行。它负责**脏活累活**，比如：
  - 保证 Agent A 发的消息，Agent B 能收到。
  - 如果 Agent 很多，它负责安排谁在哪个进程里运行。
  - 它定义了大家沟通的“语言标准”（事件）。
- **比喻**：
  这就是公司的**办公大楼、电话线路和会议室**。它不干具体的业务，但提供了员工（Agent）工作的物理场所和沟通渠道。没有它，员工没法上班，也没法打电话。

#### 2. autogen-agentchat —— 公司的员工和管理制度 【新手最常用】

- **别名**：聊天代理层（应用层）
- **大白话原理**：
  这是你**90%的时间都在打交道**的部分。这里面封装好了各种现成的“员工模板”。
  - 你想造一个会写代码的 AI？用这里的 AssistantAgent。
  - 你想造一个代表用户的 AI？用这里的 UserProxy。
  - 你想让两个 AI 聊天？用这里的代码把它们连起来。
- **比喻**：
  这就是公司的**招聘启事和员工手册**。
  你通过它来定义：“你是程序员，叫小王”、“你是产品经理，叫小李”。你在这里指挥他们干活。
  **新手写代码，主要就是 import 这个包里的东西。**

#### 3. autogen-ext —— 员工的外部工具包

- **别名**：扩展包/插件包
- **大白话原理**：
  AutoGen 本身是个空架子，它得连上大模型（比如 GPT-4）或者外部工具才能干活。
  - 你想用 OpenAI 的模型？你需要 autogen-ext[openai]。
  - 你想用 Azure 的模型？你需要 autogen-ext[azure]。
  - 你想让 AI 能控制浏览器？你需要这里的 MCP 工具扩展。
    之所以把这些拆出来，是因为不想让你安装主程序时，被迫下载一堆你用不到的驱动。
- **比喻**：
  这就是员工的**电脑、软件和外设**。
  你招了人（AgentChat），安排了工位（Core），但还没给他们配电脑。如果你想让他们用微软的 Word 干活，你就装个“微软扩展包”；如果你想让他们用谷歌的 Docs，你就装个“谷歌扩展包”。**按需购买，随插随用。**

#### 4. AutoGen Studio —— 傻瓜式老板控制台

- **别名**：可视化界面
- **大白话原理**：
  这是一个网页界面（UI）。给那些**不想写代码**，或者想快速给老板演示的人用的。
  - 你不需要在黑乎乎的命令行里敲代码。
  - 你在网页上点点鼠标，“拖拽”出一个 Agent，设置它的名字，就能在这个网页里跟它聊天。
- **比喻**：
  这就是**极品飞车游戏的驾驶界面**。
  前面的三个（Core/AgentChat/Ext）相当于你在车库里手搓零件造赛车。而 AutoGen Studio 相当于直接给你一个做好的界面，你只需要握着方向盘（鼠标）开就行了，不用管引擎是怎么接线的。

------

#### 总结：他们之间的关系

如果我们要完成一个任务：**“让 AI 帮我写个贪吃蛇游戏”**。

1. **autogen-core** 在后台默默搭建了消息通道，确保信号畅通。
2. 你写代码调用 **autogen-agentchat**，创建了一个“程序员 Agent”和一个“测试员 Agent”。
3. 因为你要用 GPT-4 的智力，所以你安装了 **autogen-ext** 来连接 OpenAI 的 API。
4. 如果你懒得写代码，你想直接用鼠标点一点就生成游戏，你就打开 **AutoGen Studio**。

#### 给新手的建议

- **如果不写代码，只想玩玩**：直接去研究 **AutoGen Studio**。
- **如果是开发人员，想写 Python 代码**：
  - 安装时：pip install autogen-agentchat autogen-ext[openai]
  - 写代码时：主要关注 **autogen-agentchat** 里的写法。
  - 不用太纠结 **autogen-core**，除非你要搞超级复杂的分布式系统。

------

## 安装(windows)

作为 Windows 用户，建议使用 PowerShell 或 VS Code 的终端。

### 第一步：环境准备

确保你安装了 **Python 3.10 或更高版本**。
在 CMD 或 PowerShell 中输入 python --version 检查。

### 第二步：创建虚拟环境 (强烈推荐)

不要把包安装到全局环境，容易冲突。

```powershell
# 1. mkdir (Make Directory) 创建新目录，cd (Change Directory) 切换当前工作目录
mkdir MyAutoGenProject
cd MyAutoGenProject

# 2. 创建虚拟环境 (venv)，让Python 在这个文件夹里建一个“独立小房间”。以后安装的软件只放在这个小房间里，不会弄脏你电脑的其他地方
python -m venv .venv

# 3. 激活虚拟环境 (Windows PowerShell)
# 如果提示权限错误，先运行：Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\.venv\Scripts\Activate

#如果系统提示“禁止运行脚本”或红色报错，请执行下面这行命令解锁权限，然后再执行上面的激活命令：
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 激活成功后，命令行前面会出现 (.venv) 字样
```

### 第三步：安装 AutoGen v0.4 核心包

根据参考文件 README (1).md，v0.4 采用了分包策略，不再是以前的一个 pyautogen 包了

**执行安装命令**：

```powershell
pip install -U "autogen-agentchat" "autogen-ext[openai]"
```

请仔细看这个命令，我来逐词解释：：

- **"autogen-agentchat"**
  - **【技术原理】**：安装 AutoGen 的高层应用 API（对应文档中的 AgentChat 层）。
  - **【大白话】**：这是**主程序**。也就是你要用来创建“助理Agent”、“用户Agent”的核心代码包。注意，v0.4 必须装这个，而不是旧版的 pyautogen。
- **"autogen-ext[openai]"**
  - **【技术原理】**：安装 AutoGen 的扩展包，并指定 openai 作为附加依赖（Extra Dependencies）。
  - **【大白话】**：这是**配件包**。AutoGen 本身是个空壳，它需要连大模型。这个包里包含了连接 OpenAI（或者兼容 OpenAI 接口的模型，如通义千问、DeepSeek）所需的驱动程序。

### 第四步：配置 API Key 并验证

**设置临时环境变量**

为了验证安装成功，我们需要设置 API Key。在 PowerShell 中输入

```powershell
$env:OPENAI_API_KEY="sk-你的密钥放这里"
```

- **【技术原理】**：在当前 PowerShell 会话中设置名为 OPENAI_API_KEY 的环境变量。
- **【大白话】**：告诉电脑：“待会儿如果有程序要查户口（找密钥），就把这串密码给它。”（注意：关掉窗口后这个设置会失效，下次要重新输）。

**创建测试脚本验证**

```python
import asyncio
# 尝试导入 v0.4 的新包，如果不报错说明安装成功
from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def main():
    print("✅ AutoGen v0.4 环境安装成功！")
    # 简单的创建一个客户端实例测试
    client = OpenAIChatCompletionClient(model="gpt-4o")
    print(f"✅ 客户端创建成功: {client}")

if __name__ == "__main__":
    asyncio.run(main())
```

### 第五步：运行测试

```python
python test_install.py
```

- **【反馈】**：如果屏幕打印出 ✅ AutoGen v0.4 环境安装成功！，恭喜你，你的 Windows 环境已经完美就绪！

------

### 总结：老手和新手的区别

- **旧版 (v0.2)**：以前大家习惯 pip install pyautogen。
- **新版 (v0.4)**：现在是 **模块化安装**。
  - 如果你只做普通对话，装 autogen-agentchat。
  - 如果你要连 OpenAI，加装 autogen-ext[openai]。
  - 如果你要用 Azure，加装 autogen-ext[azure]。



## 实战：新人如何开始使用 (代码案例)

我们从最基础的开始，逐步深入。请在项目目录下创建 .py 文件运行。

### 场景一：Hello World (单兵作战)

**目标**：创建一个助手，让它说“Hello World”。
**核心类**：AssistantAgent (助理代理), OpenAIChatCompletionClient (模型客户端)。

创建文件 hello.py:

```python
import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def main() -> None:
    # 1. 定义模型客户端 (这里用 gpt-4o 或 gpt-3.5-turbo)
    model_client = OpenAIChatCompletionClient(model="gpt-4o")
    
    # 2. 创建一个助手 Agent
    agent = AssistantAgent("my_assistant", model_client=model_client)
    
    # 3. 运行任务并打印结果
    print(await agent.run(task="请用中文向我问好，并写一句关于AI的诗。"))
    
    # 4. 关闭客户端
    await model_client.close()

if __name__ == "__main__":
    asyncio.run(main())
```

### 场景二：多智能体协作 (团队作战)

**标**：一个数学专家和一个化学专家，由一个主助手协调回答问题。
**原理**：使用 AgentTool 将一个 Agent 包装成另一个 Agent 的“工具”。这是 v0.4 推荐的简单编排方式。

创建文件 team.py:

```python
# --- 导入部分 ---
# asyncio 是 Python 用来处理并发任务的标准库。
# 简单理解：它可以让程序在等待（比如等待AI回复）的时候不卡死，去处理别的事情。
import asyncio 

# 从 autogen_agentchat 库中导入 AssistantAgent。
# 这是一个通用的 AI 助手类，可以把它看作一个具体的“人”或“角色”。
from autogen_agentchat.agents import AssistantAgent 

# 导入 AgentTool。
# 它的作用是把一个 Agent 包装成一个“工具”，这样其他的 Agent 就可以像调用函数一样调用它。
from autogen_agentchat.tools import AgentTool 

# 导入 Console。这是一个辅助工具，用来在黑框框（终端）里漂亮地打印出 AI 的对话过程。
from autogen_agentchat.ui import Console 

# 导入 OpenAI 的客户端。这是程序的大脑，负责连接 GPT-4 等模型。
from autogen_ext.models.openai import OpenAIChatCompletionClient 

# --- 主函数定义 ---
# async def 定义了一个异步函数。
# 在 Python 中，如果函数内部涉及网络请求（比如问 GPT），通常都要用 async 定义。
async def main() -> None:
    # 1. 初始化模型客户端
    # 这里我们配置了使用 "gpt-4o" 模型。
    # 注意：实际运行通过 api_key 连接，通常从环境变量中自动读取 OPENAI_API_KEY。
    model_client = OpenAIChatCompletionClient(model="gpt-4o")

    # --- 2. 创建专员 (子 Agent) ---
    
    # 创建第一个 Agent：数学专家
    # name: 给这个 Agent 起个名字，方便日志区分。
    # system_message: "人设"指令，告诉 AI 它该扮演什么角色，只做什么事。
    math_agent = AssistantAgent(
        name="math_expert",
        model_client=model_client,
        system_message="你是一个数学专家，只回答数学计算问题。",
    )
    
    # 【关键步骤】将 Agent 包装成工具
    # 正常的 Agent 是用来对话的，但在这里，我们要把它变成主管手中的一个“计算器”。
    # return_value_as_last_message=True: 意思是这个工具运行完，直接把最后一句回复作为结果返回给调用者。
    math_tool = AgentTool(math_agent, return_value_as_last_message=True)

    # 创建第二个 Agent：化学专家
    # 逻辑同上，只是人设不同。
    chem_agent = AssistantAgent(
        name="chemistry_expert",
        model_client=model_client,
        system_message="你是一个化学专家，只回答分子式和化学反应问题。",
    )
    # 同样将其包装成工具
    chem_tool = AgentTool(chem_agent, return_value_as_last_message=True)

    # --- 3. 创建主控 Agent (Manager) ---
    
    # 这个 Agent 是用户直接对话的对象，类似于“包工头”或“前台”。
    manager = AssistantAgent(
        name="manager",
        # 它的指令非常重要：告诉它在什么情况下使用什么工具。
        system_message="你是一个总管。遇到数学问题调用 math_expert，遇到化学问题调用 chemistry_expert。",
        model_client=model_client,
        # tools: 这里把上面做好的两个“工具人”塞给它。
        # 当 GPT 判定用户问题需要数学知识时，它就会自动调用 math_tool。
        tools=[math_tool, chem_tool], 
    )

    # --- 4. 运行任务 ---
    
    # task: 这是用户发出的真实指令。包含了一个化学问题和一个数学问题。
    # manager.run_stream(...): 让 manager 开始思考并处理任务，以“流式”方式返回（像打字机一样一个字一个字蹦）。
    # Console(...): 这是一个 UI 包装器，它会自动接收流式数据并漂亮地打印在屏幕上。
    # await: 这是一个等待指令，意思是“程序在这里暂停，直到对话完全结束再往下走”。
    await Console(manager.run_stream(task="请告诉我水的分子量是多少？然后算一下 2的10次方是多少？"))

# --- 程序入口 ---
# 这是 Python 的标准写法。
# 如果直接运行这个文件（而不是被别的代码 import），就执行下面的代码。
if __name__ == "__main__":
    # asyncio.run() 是启动异步程序的“钥匙”。
    # 它负责创建一个事件循环，并运行 main() 函数。
    asyncio.run(main())
```

------

### 常用命令与参数速查

### 核心类参数说明

#### AssistantAgent (最常用的类)

```python
agent = AssistantAgent(
    name="agent_name",              # [必填] Agent 的名字，用于标识
    model_client=client,            # [必填] 模型客户端实例
    system_message="You are...",    # [可选] 系统提示词（人设）
    tools=[tool1, tool2],           # [可选] 该 Agent 可用的工具列表
    description="描述...",          # [可选] 描述该 Agent 能干什么（给其他 Agent 看的）
    max_tool_iterations=10,         # [可选] 防止工具死循环调用的最大次数
    model_client_stream=True        # [可选] 是否开启流式输出
)
```

#### OpenAIChatCompletionClient

```python
client = OpenAIChatCompletionClient(
    model="gpt-4o",                 # 模型名称
    api_key="...",                  # 如果不设环境变量，可在此传入
    temperature=0.7,                # 创意程度 (0-1)
)
```

### 运行与调试命令

- **运行代码**： python your_script.py
- **启动 AutoGen Studio (UI)**：

```powershell
autogenstudio ui --port 8080 --appdir ./my-app
```

然后在浏览器访问 http://localhost:8080。

------

### RoundRobinTeam

你是一个由三个智能体组成的协作系统，专门用于回答 AI 编程相关的问题：

1. **分析者 A** 和 **分析者 B**：各自独立理解用户提出的问题，并分别提供一个清晰、可行、技术准确的回答。
2. **评审优化者 C**：对比 A 与 B 的回答，选出质量更高的一方作为主答案；同时参考次优回答中的有效信息，对主答案进行查漏补缺、逻辑完善和语言优化；最终输出一个经过融合与提升的最终回答，并简要说明优化理由。

请严格按照上述角色分工协作，确保最终回答准确、完整、实用，且优于任一初始回答。

【2025年11月版】完全小白也能一键部署到互联网的三专家协作系统（支持阿里通义千问 + DeepSeek）

**目标：**

- 4～5个人同时访问（并发极低）
- 完全免费/超低成本部署（推荐 Railway / Fly.io / Render）
- 使用国产模型：写代码用 DeepSeek-Coder，专家思考用通义千问（Qwen-Max / Qwen-Plus）
- 代码带超级详细中文逐行注释 + 大白话解释

**Autogen源码**：

```Python
# ================================== app.py 开始 ==================================

import os                          # 用于读取系统环境变量（就是你设置的API密钥）
import asyncio                     # AutoGen 0.4+ 全部都是异步的，必须导入
from fastapi import FastAPI, Request   # FastAPI = 把AI变成网页的超级简单框架
from fastapi.responses import HTMLResponse   # 返回HTML网页用的
from fastapi.templating import Jinja2Templates # 用来渲染网页模板
from pydantic import BaseModel     # 用来定义用户发来的数据格式（就是问题）

# ------------------- AutoGen 最新核心库（2025年11月版） -------------------
from autogen_agentchat.agents import AssistantAgent         # 智能体类
from autogen_agentchat.teams import RoundRobinTeam          # 团队类（轮流发言）
from autogen_agentchat.conditions import MaxMessageTermination  # 结束条件（最多说几句话）

# ------------------- 国产模型支持（阿里通义千问 + DeepSeek） -------------------
from autogen_ext.models.dashscope import DashScopeChatCompletionClient  # 通义千问
from autogen_ext.models.deepseek import DeepSeekChatCompletionClient    # DeepSeek

# ------------------- 创建网页应用 -------------------
app = FastAPI(title="我的AI三专家编程助手")          # 整个网站的“大脑”
templates = Jinja2Templates(directory="templates")   # 网页模板放在 templates 文件夹里

# ------------------- 定义用户发来的数据格式 -------------------
class QuestionRequest(BaseModel):    # 用户发来的JSON长这样：{"question": "你的问题"}
    question: str                    # 只有一个字段，就是问题本身

# ------------------- 全局变量：只创建一次团队，省钱又快 -------------------
_expert_team = None                  # 一开始是空的，第一次有人问问题时才创建

# ------------------- 核心函数：创建三专家团队 -------------------
async def create_expert_team():
    # 大白话：这里给每个专家装上不同的大脑
    print("正在创建三专家团队（只创建一次）...")

    # 从环境变量读取密钥（部署平台会自动帮你填）
    dashscope_key = os.getenv("DASHSCOPE_API_KEY")   # 阿里通义千问的key
    deepseek_key = os.getenv("DEEPSEEK_API_KEY")     # DeepSeek的key

    if not dashscope_key:
        raise ValueError("错误：没有设置 DASHSCOPE_API_KEY")
    if not deepseek_key:
        raise ValueError("错误：没有设置 DEEPSEEK_API_KEY")

    # 专家1：代码专家 → 用DeepSeek（全球最强代码模型）
    coder = AssistantAgent(
        name="代码大师（DeepSeek）",
        model_client=DeepSeekChatCompletionClient(
            model="deepseek-coder",      # 也可以改成 deepseek-coder-33b（更强）
            api_key=deepseek_key
        ),
        system_message="你只负责写出完美可运行的代码 + 超级详细的中文注释。用简体中文回答。"
    )

    # 专家2：原理专家 → 用通义千问（理解力最强）
    analyst = AssistantAgent(
        name="原理大神（通义千问）",
        model_client=DashScopeChatCompletionClient(
            model="qwen-plus",           # qwen-max 更强，但稍贵一点
            api_key=dashscope_key
        ),
        system_message="你负责用最容易懂的大白话讲解技术原理、设计思路、为什么这样写更好。"
    )

    # 专家3：最终评审优化专家 → 也用通义千问
    reviewer = AssistantAgent(
        name="总编辑（通义千问）",
        model_client=DashScopeChatCompletionClient(
            model="qwen-plus",
            api_key=dashscope_key
        ),
        system_message="""
        你是最终把关人，必须做到以下5点：
        1. 对比前面两个专家的回答
        2. 选出更好的作为主答案，并说明至少3个理由
        3. 把另一个专家的亮点全部融合进来
        4. 补充两人漏掉的关键点（尤其是新手最容易踩的坑）
        5. 输出最终完美答案：完整代码 + 逐行注释 + 大白话解释 + 运行逻辑分析
        用简体中文，语气超级友好！
        """
    )

    # 把三个人拉进一个“轮流发言”的团队（A→B→C→A→B→C...）
    team = RoundRobinTeam(
        name="AI编程三剑客",
        agents=[coder, analyst, reviewer],   # 发言顺序：代码→原理→评审
        max_rounds=9,                        # 最多9条消息（3轮完整讨论）
        termination_condition=MaxMessageTermination(9)  # 防止无限聊天
    )

        return team
    # 【大白话解释】：把刚才创建好的“三专家团队”这个对象“交出去”给调用者
    # 【原理】：create_expert_team() 函数的最后一步就是 return team，
    #         这样外面调用 await create_expert_team() 就能拿到完整的团队对象
    #         以后所有提问都会用这个团队来讨论

# ------------------- 获取团队（带缓存） -------------------
async def get_team():
    # 定义一个异步函数，专门负责“拿到团队”
    # 为什么叫“带缓存”？因为我们只想创建一次团队，后面重复用，省钱又快！

    global _expert_team
    # global 关键字：告诉 Python “我要使用文件最上面定义的那个全局变量 _expert_team”
    # _expert_team 最开始是 None（空）

    if _expert_team is None:               
        # 第一次有人来问问题时，这里是 None，所以会走进这个 if
        # 【大白话】：第一次访问网站的人触发了团队的“出生仪式”
        
        _expert_team = await create_expert_team()
        # await：因为 create_expert_team() 是异步函数，必须等它创建完团队才能继续
        # 创建完后就把团队保存到全局变量 _expert_team 里，下次就不会再创建了
        # 【原理】：这就是“懒加载 + 单例模式”，只创建一次，后面直接复用

    return _expert_team
    # 无论第一次还是第100次，都把同一个团队对象返回给调用者
    # 这样所有用户共享同一个三专家团队，成本最低、速度最快！

# ------------------- 网页首页 -------------------
@app.get("/", response_class=HTMLResponse)
# @app.get("/") 是 FastAPI 的装饰器，意思是：
# 当有人在浏览器输入你的网站域名（比如 https://xxx.up.railway.app/）时，就执行下面的函数
# response_class=HTMLResponse：告诉 FastAPI 要返回一个完整的网页，而不是纯文字或JSON

async def home(request: Request):
    # 这个函数负责显示网站的首页
    # request: Request 是 FastAPI 自动传进来的，代表这次访问的所有信息（我们这里暂时用不到）

    # 把 templates/index.html 这个网页显示出来
    return templates.get_template("index.html").render({"request": request})
    # 【大白话解释】：
    # 1. templates.get_template("index.html") → 去 templates 文件夹里找到 index.html 这个网页文件
    # 2. .render({"request": request}) → 把一些数据塞进网页（这里只塞了一个 request，Jinja2模板需要）
    # 3. 最后返回这个渲染好的完整网页给浏览器，用户就看到漂亮的输入框了！

# ------------------- 核心API：接收问题，返回答案 -------------------
@app.post("/ask")
# @app.post("/ask") 表示：当前端用 POST 方法发请求到 /ask 这个地址时，执行下面的函数
# 前端的 JavaScript 代码里 fetch('/ask', ...) 就是调用这里！

async def ask_question(req: QuestionRequest):
    # req 就是用户发来的数据，格式是 {"question": "用户的问题"}
    # QuestionRequest 是我们前面用 pydantic 定义的模型，会自动检查数据格式

    question = req.question.strip()
    # .strip() 把用户输入前后的空格、换行都去掉，防止空问题

    if not question:
        # 如果用户只点了按钮但啥也没写，就返回一个友好的错误
        return {"error": "问题不能为空哦~"}

    try:  
        # 开始真正干活！下面所有代码都包在 try 里，出错就不会崩溃

        team = await get_team()            
        # 先拿到我们已经准备好的三专家团队（如果还没创建，就会自动创建）

        print(f"收到问题：{question}")
        # 在服务器后台打印一下，便于你看日志，知道有人来问问题了

        # 真正开始三专家讨论！这是整个程序的核心！
        result = await team.run(task=question)
        # team.run() 是 AutoGen 0.4+ 的官方方法
        # 它会让三个专家轮流发言9轮，最终得出一个完美答案
        # await 必须加，因为这是异步操作，要等他们讨论完

        # 返回最终完美答案给前端网页
        return {
            "question": question,              # 把问题原样返回，方便前端显示
            "answer": result.final_output,     # 这就是三专家最终商量出来的超级详细答案！
            "status": "success"                # 告诉前端“成功了”
        }

    except Exception as e:
        # 如果中间任何地方出错了（比如网络问题、API余额不足），都会走到这里
        print(f"出错了：{e}")                   # 在后台打印真实错误，方便你调试
        return {"error": f"系统出错：{str(e)}"} # 给用户一个友好的提示，同时把真实错误也显示（上线后可以隐藏）
```

**2、网页文件（超级简单）**

新建文件夹 templates，里面新建 index.html，复制下面全部内容：

```
<!-- templates/index.html -->
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8"> <!-- 告诉浏览器用UTF-8编码，防止中文乱码 -->
    <title>AI三专家编程助手</title> <!-- 浏览器标签页显示的标题 -->
    <style>
        /* ==================== 美化样式（可以完全不用管） ==================== */
        body { 
            font-family: "Microsoft YaHei", Arial; 
            background: linear-gradient(to bottom, #667eea, #764ba2); /* 渐变背景 */
            min-height: 100vh; 
            margin:0; 
            display:flex; 
            align-items:center; 
            justify-content:center;
        }
        .box { 
            width: 90%; 
            max-width: 900px; 
            background: white; 
            border-radius: 20px; 
            padding: 40px; 
            box-shadow: 0 20px 40px rgba(0,0,0,0.2); 
        }
        textarea { 
            width: 100%; 
            height: 120px; 
            padding: 15px; 
            font-size: 18px; 
            border: 2px solid #ddd; 
            border-radius: 12px; 
        }
        button { 
            margin-top: 20px; 
            padding: 15px 40px; 
            font-size: 20px; 
            background: #667eea; 
            color: white; 
            border: none; 
            border-radius: 12px; 
            cursor: pointer; 
        }
        button:hover { background: #5a6fd8; }
        #result { 
            margin-top: 30px; 
            padding: 25px; 
            border: 1px solid #eee; 
            border-radius: 12px; 
            background: #f8f9fa; 
            line-height: 1.8; 
            font-size: 17px; 
        }
    </style>
</head>
<body>
<div class="box">
    <h1 style="text-align:center; color:#667eea;">🚀 AI三专家编程助手</h1>
    <p style="text-align:center; color:#555;">
        问任何编程问题，三位大佬会给你最完美的答案！（代码+详细解释）
    </p>
    
    <!-- 用户输入问题的文本框 -->
    <textarea id="question" placeholder="例如：用Python写一个自动发微信消息的脚本"></textarea>
    
    <div style="text-align:center;">
        <button onclick="ask()">立即提问</button> <!-- 点击按钮就触发 ask() 函数 -->
    </div>
    
    <!-- 答案会显示在这里 -->
    <div id="result">答案会在这里显示～</div>
</div>

<!-- ==================== 下面是核心 JavaScript 代码，每一行都有详细注释 ==================== -->
<script>
async function ask() {
    // 【大白话】：这个函数就是“点击按钮后”要干的事
    
    // 1. 先拿到用户在文本框里输入的内容
    const q = document.getElementById('question').value.trim();
    // document.getElementById('question') → 找到 id 为 question 的 textarea
    // .value → 取出用户输入的文字
    // .trim() → 把开头结尾的空格、回车都去掉，防止空提交

    // 2. 如果用户啥也没写，就弹窗提醒
    if (!q) {
        return alert("请先输入问题哦~");
        // return 表示函数到这里就结束，不再往下执行
    }
    
    // 3. 把“答案区”先改成“思考中”，让用户知道正在处理
    document.getElementById('result').innerHTML = 
        "🤖 三位专家正在激烈讨论中，请耐心等待30-60秒...";
    // innerHTML = 直接替换 div 里面的所有内容

    // 4. 真正向后端发送问题（核心！）
    // fetch 是浏览器内置的“发网络请求”神器
    const res = await fetch('/ask', {
        // '/ask' 就是我们 FastAPI 里定义的 @app.post("/ask") 接口
        method: 'POST',                                      // 用 POST 方式发送（比 GET 安全）
        headers: {'Content-Type': 'application/json'},       // 告诉服务器“我发的是 JSON 数据”
        body: JSON.stringify({question: q})                  // 把问题包装成 {"question": "用户的问题"}
        // JSON.stringify 把对象转成字符串，这是标准格式
    });
    // await：必须等服务器回应后才能继续（异步，等同于 Python 的 await）

    // 5. 把服务器返回的 JSON 数据取出来
    const data = await res.json();
    // res.json() 会把返回的 JSON 字符串解析成 JavaScript 对象

    // 6. 判断服务器是成功还是出错了
    if (data.error) {
        // 如果后端返回了 error 字段，说明出问题了
        document.getElementById('result').innerHTML = 
            "<span style='color:red;'>出错了：" + data.error + "</span>";
    } else {
        // 成功！把问题和最终答案漂亮地显示出来
        document.getElementById('result').innerHTML = 
            "<h3>📌 你的问题：</h3>" + data.question + 
            "<h3 style='color:#667eea;'>✅ 最终答案：</h3>" + 
            data.answer.replace(/\n/g, "<br>");  
        // data.answer.replace(/\n/g, "<br>") 的作用：
        // 把答案里的换行符 \n 全部换成 HTML 的 <br>，这样网页才能正确换行显示
    }
}
</script>
</body>
</html>
```

**3.详细的 GitHub + Railway 一键部署教程（手把手截图级）**

**步骤1：创建 GitHub 仓库（1分钟）**

1. 打开 https://github.com/new
2. Repository name 填：ai-expert-assistant（随便填）
3. 点 Create repository

**步骤2：把代码上传到 GitHub（3分钟）**

1. 把上面两个文件保存到电脑一个文件夹里：

```
ai-expert-assistant/
├── app.py
└── templates/
    └── index.html
```

  2.打开终端（Mac）或命令提示符（Windows），进入这个文件夹，运行：

```bash
git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/你的用户名/ai-expert-assistant.git
git push -u origin main
```

（第一次会让你登录GitHub）

**步骤3：申请两个免费API密钥（5分钟）**

1. 阿里通义千问：https://help.aliyun.com/zh/dashscope/developer-reference/tongyi-qwen-quick-start → 控制台 → API-KEY → 复制
2. DeepSeek：https://platform.deepseek.com/api-keys → 注册 → 直接复制 key

**步骤4：Railway 一键部署（最简单！3分钟）**

1. 打开 https://railway.app → 用 GitHub 登录
2. 点右上角 “New Project”
3. 选 “Deploy from GitHub”
4. 选你刚创建的仓库 ai-expert-assistant
5. Railway 自动检测到是 Python 项目，会让你确认 → 直接点 Deploy
6. 部署完成后，点你的项目 → Variables 标签 → 加三行

```
DASHSCOPE_API_KEY    填你的通义千问key
DEEPSEEK_API_KEY     填你的DeepSeek key
PORT                 8000
```

​    7.保存 → 等待30秒重新部署 → 点右上角的网址（类似 https://ai-expert-assistant.up.railway.app）

大功告成！把这个网址发给你的4-5个朋友，他们就能无限使用了！

本地先测试一下（可选）：

```bash
pip install fastapi uvicorn "autogen-agentchat" "autogen-ext[dashscope,deepseek]"
uvicorn app:app --reload
```

现在你拥有了一个比 ChatGPT 还强的、完全属于自己的国产AI编程助手网站！🎉

## AutoGen组件代码解释指南

- **GraphFlow**：这是一个用于结构化多代理工作流的工具，似乎可以可靠地控制代理执行顺序，但需注意实验性，可能有API变更。
- **Magentic-One**：一个通用多代理系统，证据显示它擅长复杂任务协作，但随机性可能导致不一致结果。
- **Swarm**：OpenAI的轻量框架，用于代理协调，看起来易用但实验性质强，适合原型测试。
- **McpWorkbench**：AutoGen的工具集成平台，帮助代理访问外部服务，安全风险需警惕。

这些组件的代码示例基于最新文档，通常涉及Python异步编程和代理实例化。逐行解释包括语法（技术细节）和大白话（简单原理）。每个组件的代码放在单独“文件”中展示。

AutoGen框架是一个开源的多代理AI开发工具，由微软xAI团队维护，用于构建协作AI系统。下面这份调研笔记详细解释了您查询的代码示例与逐行解析，重点针对GraphFlow、Magentic-One、Swarm和McpWorkbench。笔记基于2025年最新文档和教程，整合了语法角度（技术细节，如变量赋值、函数调用）和大白话原理（简单比喻，如“像团队分工”）两种方式解释。每个组件的代码放在一个虚拟“文件”中（以代码块模拟），方便复制展示。笔记还包括组件定义、解决问题、运行原理、痛点、益处和案例。

### 1. GraphFlow (图流/事件驱动工作流)

> **注意**：在 AutoGen v0.4 中，没有一个类直接叫 GraphFlow，这个词通常指代**基于图（Graph）的事件驱动工作流**。这是 v0.4 的核心架构理念。

- **GraphFlow** 是 AutoGen 0.4+（尤其是 AgentChat API）中一个**实验性**的 multi-agent workflow 工具（目前还在快速迭代，API 可能会变）。它把多个 agent 当成图（graph）的节点，用有向边（edges）来精确控制它们之间的执行顺序和消息流动。

  **解决了什么问题？** 以前 AutoGen 的 GroupChat（比如 RoundRobin、Selector）是“自由聊天”模式，agent 轮流发言，流程不固定，容易出现：

  - 对话乱序、重复
  - 无法保证某些步骤一定先执行（比如必须先研究 → 再写代码 → 再审查）
  - 难以做条件分支、循环、并行（fan-out/fan-in）

  GraphFlow 把 workflow 变成**可编程的图**，开发者可以明确说“这个 agent 完成后，下一步走哪个（或哪几个）”，让多 agent 协作变得**确定性、可视化、可调试**。

  **运行原理**

  - 用 DiGraphBuilder 构建一个有向图（Directed Graph）
  - 每个节点 = 一个 agent
  - 每条边 = “从 A 到 B 的消息流动”，可以加条件（condition=lambda msg: ...）
  - 执行时从入口节点（entry point / source nodes）开始，按图拓扑顺序自动推进，支持循环、条件分支、并发（多个 outgoing edges 时可以同时执行）

  **痛点解决 & 带来的启示**

  - 痛点：聊天式多 agent 太“随机”，企业级任务需要严格流程控制
  - 启示：把多 agent 当成“工作流引擎”而不是“群聊”，更适合生产环境（如审批流、研究→写作→审查）

  **怎么用？一个简单案例（fan-out → fan-in）** 任务：让一个 agent 生成一段文字，然后同时翻译成中文和日文，最后汇总。

```python
# 先导入异步运行必须的 asyncio
import asyncio

# 从 AutoGen 导入我们需要的几个核心类
from autogen_agentchat.agents import AssistantAgent          # 基础的助手 Agent
from autogen_agentchat.teams import DiGraphBuilder, GraphFlow  # 图构建器和图流程
from autogen_agentchat.ui import Console                     # 用来在终端实时打印对话
from autogen_ext.models.openai import OpenAIChatCompletionClient  # OpenAI 模型客户端

# 定义一个 async 主函数（AutoGen 0.4 全部用异步）
async def main() -> None:
    
    # 第1步：创建一个连接 OpenAI 的客户端（这里用 gpt-4o）
    # 你需要提前在环境变量里设置 export OPENAI_API_KEY=sk-...
    client = OpenAIChatCompletionClient(model="gpt-4o")
    # 等价于以前的 OpenAIWrapper，只不过现在叫这个名字

    # 第2步：创建 4 个不同的助手 Agent（每个都用同一个模型）
    generator = AssistantAgent(
        name="generator",                  # Agent 的名字，后面图里会用到
        model_client=client,               # 用上面创建的 OpenAI 客户端
        system_message="你是一个内容生成专家，请根据用户任务生成一段英文段落。"  # 系统提示词，决定 Agent 的角色
    )

    translator_zh = AssistantAgent(
        name="translator_zh",
        model_client=client,
        system_message="你只负责把英文翻译成简体中文，不要加额外解释。"
    )

    translator_ja = AssistantAgent(
        name="translator_ja",
        model_client=client,
        system_message="你只负责把英文翻译成日文，不要加额外解释。"
    )

    summarizer = AssistantAgent(
        name="summarizer",
        model_client=client,
        system_message="把所有翻译结果汇总，用中文输出最终版本。"
    )

    # 第3步：开始构建一张“流程图”
    builder = DiGraphBuilder()             # 创建一个空的图构建器

    # 把上面 4 个 Agent 都加入图里（变成图的节点）
    builder.add_node(generator)
    builder.add_node(translator_zh)
    builder.add_node(translator_ja)
    builder.add_node(summarizer)

    # 第4步：画箭头——决定执行顺序（边）
    builder.add_edge(generator, translator_zh)   # generator 完成后 → 发消息给中文翻译
    builder.add_edge(generator, translator_ja)   # generator 完成后 → 同时发消息给日文翻译（并行！）
    builder.add_edge(translator_zh, summarizer)  # 中文翻译完成后 → 发给汇总 Agent
    builder.add_edge(translator_ja, summarizer)  # 日文翻译完成后 → 发给汇总 Agent

    # 第5步：把图和所有 Agent 打包成一个可以运行的“团队”
    flow = GraphFlow(
        participants=builder.get_participants(),   # 所有参与的 Agent
        graph=builder.build()                      # 刚才画好的图
    )

    # 第6步：真正开始运行！任务从入度为 0 的节点（这里是 generator）开始
    await Console(flow.run_stream(
        task="写一段介绍北京故宫的英文段落（大约100字）"
    ))

# 启动程序
asyncio.run(main())
```

------

### 2. Magentic-One (磁性一号 / 全能团队)

- **是什么**：
  它不是一个功能，而是微软官方基于 AutoGen 打造的一个**通用的、高性能的多智能体系统（System）**。
  **大白话**：它是一个**现成的“复仇者联盟”**。你不需要自己去写“程序员Agent”、“搜索Agent”，微软已经帮你写好了一组最强的 Agent 搭配，里面有一个类似“神盾局局长”的 Orchestrator 在指挥。
- **解决了什么问题**：
  - **通用性**：以前你写 Agent 只能干一件事。Magentic-One 号称可以解决各种复杂任务（上网查资料 + 写代码 + 操作文件）。
  - **自我修正**：如果代码跑不通，它内部会自动循环修复，直到成功。
- **痛点与原理& 启示**：
  - *痛点*：新手自己组装的 Agent 团队往往很笨，容易陷入死循环。
  - *原理*：采用 Orchestrator（指挥官）+ Specialists（专家组：WebSurfer, Coder, Executor）的架构。
  - 启示：把不同技能拆成独立 agent + 一个聪明指挥官，是解决“通用复杂任务”的有效模式
  - 4 个专业 agent：
    - WebSurfer：多模态网页浏览（看图、点击、填写表单）
    - FileSurfer：本地文件系统读写
    - Coder：写代码
    - Executor（Computer Terminal）：执行代码、安装库
- **源码示例与逐行解析**：
  *(注意：Magentic-One 通常作为独立包 autogen-magentic-one 存在，以下演示其核心使用逻辑)*

```
import asyncio
from autogen_ext.models.openai import OpenAIChatCompletionClient
# 假设安装了 magentic-one 扩展包
from autogen_magentic_one.agents import MagenticOneOrchestrator, MagenticOneCoder

async def main():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    # [1. 这里的核心是 Orchestrator (总指挥)]
    # Magentic-One 的厉害之处在于这个预设好的指挥官，它内置了非常复杂的策略
    # 它知道什么时候该叫程序员，什么时候该叫浏览器
    team_leader = MagenticOneOrchestrator(
        name="MagenticManager",
        model_client=client
    )
    
    # [2. 这是一个全能的运行入口]
    # 你不需要手动把 Agent 连起来，Magentic-One 封装好了
    # 这行代码背后，可能有4-5个 Agent 在疯狂交互：上网查股价 -> 写绘图代码 -> 运行 -> 存图
    await team_leader.run_task(
        "请上网查询微软过去一年的股价，并用 Python 画一张折线图保存为 stock.png"
    )

if __name__ == "__main__":
    asyncio.run(main())
```

**Magentic-One（开箱即用最强多智能体团队）—— 最详细注释版**

```python
import asyncio
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.teams.magentic_one import MagenticOne  # 直接导入现成的团队
from autogen_agentchat.ui import Console

async def main():
    client = OpenAIChatCompletionClient(model="gpt-4o")  # 可以换其他模型
    m1 = MagenticOne(client=client)                     # 一行创建一个完整 5-agent 团队
    await Console(m1.run_stream(task="帮我查找最近 3 篇关于量子计算的 arXiv 论文，并用中文总结每篇的核心贡献"))

asyncio.run(main())
```

**逐行解释**：

- MagenticOne(client=client)：内部自动创建 Orchestrator + 4 个专业 agent，已经配好工具（Playwright 浏览、Docker 代码执行等）
- m1.run_stream(task=...)：直接扔一个复杂任务，它会自动规划、浏览网页、下载 PDF、总结……

这就是“开箱即用”的通用 agent 系统，几乎不需要你写任何 agent 定义。

------

### 3. Swarm (蜂群模式 / 动态交接)

- **是什么**：
  这是 OpenAI 提出的一种轻量级多 Agent 模式，AutoGen v0.4 完美支持。它的核心概念是 **Handoffs（交接）**。
  **大白话**：就像打电话给客服。

  - 你：“我要退款。”
  - 客服A：“这事我管不了，但我知道‘退款专员B’能管，**转接（Handoff）**给B。”
  - Agent 自己决定下一棒交给谁，而不是由一个总管来分配。

  **运行原理**

  - 每个 agent 有 handoffs=["agent_name", ...] 列表，告诉它可以把任务交给谁
  - agent 用特殊工具 handoff_to_xxx 把控制权完全交给下一个 agent（上下文共享）
  - 整个团队像“接力赛”而不是“群聊

- **解决了什么问题**：

  - **去中心化**：不需要一个超级聪明的“大总管”来分配任务，Agent 自己就能根据对话上下文把锅甩给对的人。
  - **灵活性**：流程非常自然，像人类聊天一样流转。

- **痛点与原理& 启示**：

  - *痛点*：传统的 GroupChat 有时候很乱，所有人都在一个群里抢着说话。
  - *原理*：每个 Agent 的工具箱里都有一个“转接工具”，返回 Handoff 对象。
  - 启示：把多 agent 当成“服务路由”，非常适合对话式应用（客服、订票）

- **源码示例与逐行解析**：

```python
import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.messages import Handoff
from autogen_agentchat.teams import Swarm
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def main():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    # [1. 定义“接待员” Agent]
    # 注意 handoffs 参数：允许它把任务转交给 flight_agent
    receptionist = AssistantAgent(
        "receptionist",
        model_client=client,
        system_message="你是前台。如果用户问航班，转交给 flight_agent。",
        handoffs=["flight_agent"]  # 核心：给它一个通讯录，告诉它能转给谁
    )

    # [2. 定义“航班专员” Agent]
    # 它的 handoffs 指向 receptionist，意味着处理完可以转回去，或者结束
    flight_agent = AssistantAgent(
        "flight_agent",
        model_client=client,
        system_message="你是航班专员，负责查询机票。",
        handoffs=["receptionist"]
    )

    # [3. 组建 Swarm (蜂群) 团队]
    # Swarm 模式不需要路由器，Agent 自己决定下一个是谁
    team = Swarm([receptionist, flight_agent], model_client=client)

    # [4. 运行]
    # 用户问：查机票 -> 前台(接单) -> 前台(无能力) -> 触发Handoff -> 航班专员(接单) -> 回答
    await team.run(task="我想查一张去北京的机票")

if __name__ == "__main__":
    asyncio.run(main())
```

------

这四个概念是 AutoGen v0.4 生态中非常核心、但也容易混淆的术语。它们分别代表了：**工作流架构、超级智能体团队、交互模式、工具标准**。

为了让你直观理解，我将采用**“概念解析 + 源码与逐行注释合并”**的方式来展示。

------

**Swarm（接力式多智能体，类似客服路由）—— 最详细注释版**

```python
import asyncio
from autogen_agentchat.agents import AssistantAgent        # 基础 Agent
from autogen_agentchat.teams import Swarm                  # Swarm 团队类
from autogen_agentchat.ui import Console
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def main():
    client = OpenAIChatCompletionClient(model="gpt-4o")

    # 第1个 Agent：只负责查航班，查完必须把对话交给下一个
    search_agent = AssistantAgent(
        name="flight_search",
        model_client=client,
        system_message="你只负责查询航班信息，绝对不要自己订票。查完后必须使用 handoff 把对话交给 booking_agent。",
        # 关键：handoffs 列表里写明它可以把任务交给谁
        handoffs=["booking_agent", "user"]   # 可以交给订票员或直接交给用户
    )

    # 第2个 Agent：只负责订票和改签
    booking_agent = AssistantAgent(
        name="booking",
        model_client=client,
        system_message="你只负责订票、改签、退票等操作。完成后必须 handoff 给 user。",
        handoffs=["user"]   # 只能交给用户，不能再交给别人
    )

    # 创建 Swarm 团队，第一个 Agent 会自动成为入口
    team = Swarm(participants=[search_agent, booking_agent])

    # 开始对话——用户说想查航班
    await Console(team.run_stream(
        task="帮我查一下明天从北京到上海的航班，有什么便宜的？"
    ))
    # 你会看到：
    # 1. search_agent 先回答航班信息
    # 2. 自动 handoff（交接）给 booking_agent
    # 3. booking_agent 问你要不要订票
    # 4. 最后交还给用户

asyncio.run(main())
```

运行后你会看到：search_agent 查完航班 → 自动 handoff 到 booking_agent → booking_agent 问你要不要订 → 最后 handoff 回 user。

------

### 4. McpWorkbench (MCP 工作台 / 通用工具接口)

- **是什么**：
  McpWorkbench 是 AutoGen 提供的 Model Context Protocol (MCP) 客户端工具。MCP 是 Anthropic 发起的一个开放协议，让 LLM 能安全地调用外部工具服务器（比如 Playwright 浏览网页、文件系统、Git 等）。
  **大白话**：以前你想让 AI 连 GitHub、连 Google Drive、连本地文件，你得给每个平台写一套 Python 代码。现在有了 MCP，就像 **USB 接口**。GitHub 提供了一个“USB设备”（MCP Server），AutoGen 提供了一个“USB插座”（McpWorkbench），插上就能用，不用写驱动代码。

- **解决了什么问题**：

  - **工具荒**：开发者不用自己苦哈哈地写工具函数了，直接用社区现成的 MCP Server。
  - **安全性**：MCP Server 运行在独立进程里，不会搞坏你的主程序。

  **运行原理**

  - 启动一个 MCP server（比如 @playwright/mcp 浏览网页）
  - 用 McpWorkbench 连接这个 server
  - 把 workbench 传给 AssistantAgent，agent 就能像调用普通工具一样调用 MCP 工具

- **痛点与原理& 启示**：

  - *痛点*：连接外部世界（World Grounding）太难了，每个 API 文档都不一样。
  - *原理*：通过标准化的协议（JSON-RPC over Stdio/SSE）与外部工具进程通信。
  - 启示：把工具外部化成服务，是未来 agent 生态的方向（类似 Claude Desktop

- **源码示例与逐行解析**：

```python
import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.ui import Console
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.tools.mcp import McpWorkbench, StdioServerParams

async def main():
    client = OpenAIChatCompletionClient(model="gpt-4o")
    
    # [1. 配置 MCP 服务器参数]
    # 这是一个独立的进程。假设我们安装了一个叫 'fetch-mcp' 的工具，能抓取网页
    # 相当于我们买了一个“USB设备”
    server_params = StdioServerParams(
        command="uvx", # 使用 uvx 运行命令 (Python包管理工具)
        args=["mcp-server-fetch"] # 具体的 MCP Server 包名
    )

    # [2. 启动工作台 (McpWorkbench)]
    # async with 相当于把插头插上，通电
    async with McpWorkbench(server_params) as workbench:
        
        # [3. 创建 Agent 并把 workbench 给他]
        # 我们不需要定义 tool 列表，workbench 会自动读取 MCP Server 里有什么工具
        # 并自动喂给 Agent
        agent = AssistantAgent(
            "web_surfer",
            model_client=client,
            tools=[workbench], # 直接把整个工具台给它
            system_message="你可以使用工具来抓取网页内容。"
        )

        # [4. 运行]
        # Agent 会自动发现 workbench 里有个 'fetch' 工具，并调用它
        await Console(agent.run_stream(task="抓取 https://example.com 的内容并总结"))

if __name__ == "__main__":
    asyncio.run(main())
```

**McpWorkbench（网页浏览神器，基于 MCP 协议）**

```python
import asyncio

# 核心组件导入
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.ui import Console
from autogen_ext.models.openai import OpenAIChatCompletionClient

# MCP 相关（Model Context Protocol）
from autogen_ext.tools.mcp import McpWorkbench, StdioServerParams   # MCP 客户端和工作台

async def main() -> None:
    # 第1步：定义怎么启动 Playwright MCP 服务器（只需要全局安装一次）
    # 你需要在终端先执行一次：npm install -g @playwright/mcp@latest
    server_params = StdioServerParams(
        command="npx",                                          # 用 npx 启动
        args=["@playwright/mcp@latest", "--headless"],          # 参数：最新版 + 无头模式
    )

    # 第2步：用 async with 自动启动和关闭 MCP 服务器（用完自动杀进程）
    async with McpWorkbench(server_params) as mcp:   # mcp 就是一堆网页工具的集合
        # 创建 OpenAI 客户端
        client = OpenAIChatCompletionClient(model="gpt-4o")

        # 创建一个会浏览网页的 Agent
        agent = AssistantAgent(
            name="web_surfer",
            model_client=client,
            workbench=mcp,                  # 重点！把 MCP 工具注入给 Agent
            max_tool_iterations=20,         # 最多允许调用 20 次工具（防止死循环）
        )

        # 第3步：让它去干活——打开 GitHub 页面并读取 star 数
        await Console(agent.run_stream(
            task="打开 https://github.com/microsoft/autogen ，告诉我这个仓库当前有多少个 star？"
        ))
        # Agent 会：
        # 1. 调用 MCP 的 open_url 工具打开页面
        # 2. 调用 screenshot 或 get_element 工具找 star 按钮
        # 3. 提取数字并返回给你

# 启动程序
asyncio.run(main())
```

------

### 总结：它们给开发者带来了什么？

| 功能             | 关键词       | 给开发者带来了什么？                                       | 适合场景                                 |
| ---------------- | ------------ | ---------------------------------------------------------- | ---------------------------------------- |
| **GraphFlow**    | **流程图**   | 像画流程图一样写代码，逻辑极其清晰，不再是一团乱麻。       | 复杂的业务审批流、条件分支任务。         |
| **Magentic-One** | **全能团队** | 开箱即用的“超级员工”，不用自己设计团队结构，直接解决难题。 | 复杂通用任务（如“做个市场调研PPT”）。    |
| **Swarm**        | **自动转接** | 去中心化，让对话更自然，Agent 之间配合更像人类同事。       | 客户服务系统、多角色扮演游戏。           |
| **McpWorkbench** | **USB接口**  | 拥有海量现成工具库（Github/Slack/Drive等），即插即用。     | 需要操作外部软件、读取本地文件的 Agent。 |