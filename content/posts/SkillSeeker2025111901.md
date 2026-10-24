---
title: Skill Seeker中文使用手册
date: 2025-11-19 17:00:00+08:00
draft: false
categories:
- 人工智能
tags:
- Skill Seeker
- Claudecode
- Claude Skill
- 爬虫
- MCP服务器
permalink: agent-memory/个人随笔站点/site/content/posts/skill-seeker2025111901
---

# Skill Seeker中文使用手册

## 概述：Skill Seeker 是什么？

Skill Seeker 是一个开源工具，由 Yusuf Karaaslan 开发（GitHub 仓库：https://github.com/yusufkaraaslan/Skill_Seekers），旨在从文档网站（如编程框架、API 或游戏引擎的官方文档）中自动抓取、组织和打包内容，创建“skills”（技能包）。这些技能包可以上传到 Anthropic 的 Claude AI（特别是 Claude Code），让 Claude 成为特定领域的“专家”，例如 React、Godot 或 Steam API 的文档专家。

**核心目的**：简化将大量文档注入 AI 的过程，让用户可以通过自然语言查询获取准确、结构化的信息，而无需手动搜索或复制文档。基于提供的参考文件（如 QUICKSTART.md 和 MCP_SETUP.md），它专注于自动化文档处理，支持从小型网站到大型文档（如 10K+ 页）的抓取，并通过增强功能（如本地或 API 增强）提升技能包的质量。

从我的理解来看，Skill Seeker 解决了 AI 知识局限性的痛点：在通用 AI 如 Claude 中注入专业知识通常很繁琐（手动上传文件或编写提示），而 Skill Seeker 像一个“文档到 AI 技能”的桥梁，让非技术用户也能轻松创建自定义 AI 助手。它强调效率、隔离依赖和可扩展性，适合开发者、教育者和研究者使用。

## 架构组成与设计框架

**整体架构**

Skill Seeker 采用模块化设计，分为 CLI（命令行接口）、MCP 服务器和辅助脚本。核心是 Python 脚本，使用 requests 和 beautifulsoup4 抓取网页。

- **CLI 核心（cli/ 目录）**
  - doc_scraper.py：抓取文档，生成 raw 数据和技能目录。
  - pdf_extractor_poc.py：PDF 处理，支持 OCR、表格、图像提取。
  - enhance_skill_local.py：本地增强 SKILL.md。
  - package_skill.py：打包 ZIP。
  - split_config.py：分割大型配置。
  - estimate_pages.py：估算页面数。
- **MCP 服务器（skill_seeker_mcp/ 目录）**
  - server.py：MCP 协议服务器，与 Claude Code 通信，支持 9 个工具（如 generate_config、scrape_docs）。
  - 通过自然语言桥接 CLI 功能。
- **配置与输出**
  - configs/：JSON 预设（如 base_url、max_pages）。
  - output/：技能目录（SKILL.md + references/）和 ZIP 文件。
- **依赖**：requests、beautifulsoup4、pytesseract（OCR）、PyMuPDF（PDF）等。虚拟环境（venv）隔离。

**设计框架**

- **模块化**：每个脚本独立，便于扩展（如添加 PDF 高级功能）。
- **分层**：输入（URL/PDF）→ 处理（抓取/提取）→ 增强（AI 优化）→ 输出（ZIP）→ 集成（Claude）。
- **优化焦点**：并行处理、缓存、检查点，针对大型任务（参考 LARGE_DOCUMENTATION.md 的分割策略）。
- 产品功能点
  - **核心**：文档到技能转换。
  - **扩展**：多源统一（文档 + GitHub）、路由技能（智能分发查询）。
  - **用户导向**：互动模式、预设、测试支持。

我的理解：架构像一个 ETL（Extract-Transform-Load）管道，Extract 从源抓取，Transform 组织/增强，Load 到 Claude。设计注重鲁

棒性（如错误处理、恢复），适合开源贡献。

## 解决了什么核心痛点？

**Skill Seeker是一个能将任何在线文档、本地PDF或代码库，自动转化为大型语言模型（如Claude）专属“知识技能包”的强大工具。**

你可以把它想象成一个“AI知识营养师”，它把网上杂乱的、海量的技术文档“消化吸收”，制作成Claude能直接使用的、结构化的、高度优化的“知识胶囊”（即.zip格式的Skill包）。

1. **突破模型知识局限性**：像Claude这样的AI，其内部知识有截止日期，且不包含特定领域的私有或冷门知识。Skill Seeker让你可以为Claude“植入”任何你需要的最新、最专业的知识库。
2. **克服上下文窗口限制**：你无法一次性将整个框架的文档（成千上万页）粘贴到对话框中。Skill Seeker将文档处理成优化的结构，让Claude可以在需要时精准地“查阅”相关部分，而不是一次性“阅读”全部内容。
3. **告别手动喂养资料的低效**：在遇到复杂问题时，我们常常需要手动查找文档、复制关键部分再粘贴给AI。Skill Seeker将这个过程完全自动化，你只需要提问，集成了对应Skill的Claude会自动查找并给出答案。
4. **实现知识的结构化与可用性**：直接复制的网页内容包含大量无关信息（广告、导航栏等）。Skill Seeker能智能抓取核心内容，将其转换为干净、结构化的Markdown文件，极大提升了知识质量。

### 核心特点一览

- **多源数据支持**：不仅支持抓取网站文档，还能处理本地PDF文件（包括扫描件OCR识别、表格提取等高级功能），甚至能统一处理文档和GitHub代码库（unified模式）。
- **高度自动化**：从抓取、清洗、转换、增强到打包，整个流程可通过几行命令完成。
- **智能文档处理**：
  - **大型文档拆分**：对于数万页的文档（如Godot、AWS文档），能自动或按策略（分类、路由模式）拆分成多个更小、更专注的Skill，便于管理和提升性能。
  - **AI增强**：能利用本地AI模型（如Claude Code Max）自动生成高质量的SKILL.md主文件，该文件是引导Claude如何使用这个知识库的“说明书”。
- **与Claude Code无缝集成**：通过MCP（Message Control Protocol）服务，你可以在Claude Code桌面应用中用自然语言直接指挥Skill Seeker完成所有操作，例如：“帮我创建一个React文档的Skill”。
- **配置灵活**：提供交互式配置、预设配置（如React, Vue, Django等）和命令行快速配置等多种方式，丰俭由人。

## 工作流程与原理

### 工作流程

**抓取 -> (增强) -> 打包 -> 上传**

1. **抓取 (Scrape)**：
   - 你提供一个配置文件（或通过命令行参数）。
   - Skill Seeker的爬虫根据base_url开始访问网页。
   - 它会解析HTML，剥离导航、页脚等无关元素，提取核心内容。
   - 将提取到的内容转换成干净的Markdown格式。
   - 根据文档结构，将内容存放到output/你的技能名/references/目录下。
   - 同时，生成一个基础的SKILL.md文件。
2. **增强 (Enhance) - 可选但强烈推荐**：
   - 这一步会调用AI模型。
   - 模型会“阅读”references/下的所有文档。
   - 基于对全部内容的理解，重写SKILL.md文件，生成一份高质量的、包含核心概念、代码示例和使用指南的摘要。这极大提升了Claude使用该Skill的效率和准确性。
3. **打包 (Package)**：
   - 这个过程非常简单，就是将output/你的技能名/文件夹（包含SKILL.md和references/）压缩成一个.zip文件。
   - 这个.zip文件就是最终可以上传给Claude的“知识技能包”。
4. **上传 (Upload)**：
   - 你可以手动将.zip文件上传到Claude官网。
   - 也可以通过配置API密钥，使用--upload参数实现自动上传。

### 与 Claude Code 的协同原理 (MCP)

这是Skill Seeker最酷的功能之一。其原理如下：

1. **配置**：你需要在Claude Code的配置文件(~/.config/claude-code/mcp.json)中，声明Skill Seeker的MCP服务器。这相当于告诉Claude Code：“当你需要‘skill-seeker’这个工具时，去运行这个路径下的Python服务器程序”。
2. **启动**：当你启动Claude Code时，它会根据配置文件在后台静默启动Skill Seeker的MCP服务器。
3. **交互**：
   - 你在Claude Code里输入自然语言指令，如：“用react的配置抓取文档”。
   - Claude Code的AI大脑理解你的意图，并识别出这需要调用mcp__skill-seeker__scrape_docs工具。
   - Claude Code通过MCP协议向本地的Skill Seeker MCP服务器发送一个包含工具名和参数的请求。
   - MCP服务器接收到请求，解析它，然后 **在你的本地终端中执行对应的CLI命令**，例如skill-seekers scrape --config configs/react.json。
   - CLI工具执行的结果（如“抓取成功，文件在output/react/”）被返回给MCP服务器，再由服务器传回给Claude Code。
   - 最终，Claude Code将结果以自然语言的形式呈现给你。

**简单来说，Claude Code是你的“智能遥控器”，MCP服务器是“信号接收器”，而Skill Seeker的CLI工具是真正干活的“机器人”。**

> **关键优势**：无需编写代码，只需在Claude Code中输入自然语言命令（如"生成React文档的技能"），Skill Seeker会自动完成整个流程。

## 命令行使用

| 命令              | 参数                | 用途                 | 示例                                                         |
| ----------------- | ------------------- | -------------------- | ------------------------------------------------------------ |
| `scrape`          | `--config`          | 使用配置文件爬取文档 | `skill-seekers scrape --config configs/react.json`           |
|                   | `--interactive`     | 交互式创建配置       | `skill-seekers scrape --interactive`                         |
|                   | `--max-pages`       | 限制爬取页面数量     | `skill-seekers scrape --config configs/react.json --max-pages 50` |
|                   | `--skip-scrape`     | 使用已存在的数据     | `skill-seekers scrape --config configs/react.json --skip-scrape` |
| `enhance`         | `--local`           | 本地增强SKILL.md     | `skill-seekers enhance output/react/ --local`                |
| `package`         |                     | 打包技能             | `skill-seekers package output/react/`                        |
| `split_config`    | `--strategy router` | 拆分大型文档         | `skill-seekers split_config configs/godot.json --strategy router` |
| `generate_router` |                     | 生成路由技能         | `skill-seekers generate_router configs/godot-*.json`         |
| `pdf_scraper`     | `--pdf`             | 从PDF爬取文档        | `skill-seekers pdf_scraper --pdf docs/manual.pdf --name myskill` |
|                   | `--ocr`             | 启用OCR（扫描PDF）   | `skill-seekers pdf_scraper --pdf scanned.pdf --ocr`          |
|                   | `--extract-tables`  | 提取表格             | `skill-seekers pdf_scraper --pdf data.pdf --extract-tables`  |

Skill Seeker 的命令行工具 (CLI) 是整个系统的引擎。它提供了一套从**数据源定义**、**内容提取**、**AI增强**到**最终打包**的完整、自动化的指令集。本手册将带你掌握这些命令，让你能将任何文档转化为AI的专属知识。

### **1. 核心工作流命令**

这是创建任何Skill都必须经历的**三个核心步骤**。

#### **1.1 skill-seekers scrape - 抓取与创建**

这是最核心、最常用的命令，负责从一个在线文档网站创建Skill的基础结构。

- **用途解释**:
  此命令会启动一个内容感知的爬虫，它会从一个起始URL开始，发现并抓取相关页面，提取核心内容，将其转换为Markdown，并构建出Skill的初始目录结构 (output/skill-name/)。
- **使用模式**:
  scrape命令有三种主要的使用模式，以适应不同需求：
  1. **配置文件模式 (推荐)**: 最强大、最可复现的方式。
  2. **交互模式 (新手友好)**: 通过问答引导你创建配置。
  3. **快速命令模式 (适合单次任务)**: 直接在命令行中提供基本信息。
- **关键参数与实例**:

| 参数              | 别名 | 作用与解释                                                   | 实例                                                         |
| ----------------- | ---- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| --config [path]   | -c   | **(核心)** 使用指定的.json配置文件。这是进行严肃项目时的最佳实践，因为它精确、可控且可复用。 | skill-seekers scrape --config configs/react.json             |
| --interactive     | -i   | 启动一个问答向导来创建一次性的配置。非常适合初学者或快速创建新配置文件的原型。 | skill-seekers scrape --interactive                           |
| --name [name]     | -n   | **(快速)** 直接为Skill命名。通常与--url联用，适合抓取简单的、一次性的目标。 | skill-seekers scrape --name svelte --url https://svelte.dev  |
| --url [url]       | -u   | **(快速)** 指定爬虫的起始URL。                               | ... --url https://docs.myframework.com/                      |
| --max-pages [num] | -p   | **(测试必备)** 设置抓取页数的上限。在正式进行大规模抓取前，用此参数进行小批量测试，是验证配置是否正确的关键步骤。 | ... --config configs/react.json --max-pages 20               |
| --enhance-local   |      | **(强烈推荐)** 在抓取完成后，自动调用AI对SKILL.md进行增强。这能将一个普通Skill的可用性提升10倍。 | skill-seekers scrape --config configs/react.json --enhance-local |
| --skip-scrape     |      | 跳过抓取步骤，直接使用缓存的原始数据重新构建Skill。当你调整了内容处理逻辑但不想重新下载所有网页时，这个参数能为你节省大量时间。 | skill-seekers scrape --config configs/react.json --skip-scrape |

------

#### 1.2 skill-seekers enhance - AI 增强

- **用途解释**:
  此命令是让Skill“活起来”的关键。它会调用AI模型，读取Skill references/目录下的所有文档，然后生成一份高质量的、包含核心摘要、功能索引和使用示例的SKILL.md主文件。**一个没有被增强的Skill，只是一个文件列表；一个增强过的Skill，才是一个真正的知识库。**

- **如何使用**:
  虽然可以独立运行，但它最常见的用法是通过scrape命令的--enhance-local参数来自动调用。

- **关键参数与实例**:

  | 参数             | 作用与解释                                                   | 实例                                |
  | ---------------- | ------------------------------------------------------------ | ----------------------------------- |
  | [directory_path] | **(必需)** 指定要进行增强的Skill源文件夹路径（例如output/react/）。 | skill-seekers enhance output/react/ |

  ------

#### 1.3 skill-seekers package - 打包交付

- **用途解释**:
  这是工作流的最后一步。此命令会将Skill的源文件夹（包含SKILL.md和references/）压缩成一个符合Claude要求的、可直接上传的.zip文件。
- **关键参数与实例**:

| 参数             | 作用与解释                                                   | 实例                                         |
| ---------------- | ------------------------------------------------------------ | -------------------------------------------- |
| [directory_path] | **(必需)** 指定要打包的Skill源文件夹路径。                   | skill-seekers package output/react/          |
| --upload         | 在打包完成后，如果配置了ANTHROPIC_API_KEY环境变量，此参数会自动将生成的.zip文件上传到Claude。 | skill-seekers package output/react/ --upload |

### 2处理本地与海量文档

**2.1 skill-seekers pdf_scraper - PDF 专业处理**

- **用途解释**:
  专门用于处理**本地PDF文件**的强大模块。它不是“抓取”，而是“解析和提取”，能处理包括扫描件、加密文件和复杂表格在内的各种PDF。

- **综合实例**:

```bash
# 处理一份大型、加密的、包含表格的扫描版PDF手册，并使用8个核心加速
skill-seekers pdf_scraper --pdf secure_scanned_manual.pdf --name secure-manual --password "secret" --ocr --extract-tables --parallel --workers 8
```

在命令成功执行完毕后，你将会在output/目录下得到一个名为 secure-manual/ 的文件夹。这个文件夹就是你的Skill源文件，其内部结构如下

```
output/
└── secure-manual/
    ├── SKILL.md        # 一个基础的、描述性的主文件
    └── references/     # 存放所有从PDF提取出的内容的文件夹
        ├── page_001.md
        ├── page_002.md
        ├── ...
        └── page_XXX.md   # XXX是PDF的总页数
```

**这个文件夹里的内容具备以下特点：**

1. **文本化 (Textualized)**: 即使原始PDF是扫描的图片，references/里的.md文件也包含了从图片中识别出的**纯文本内容**。
2. **结构化 (Structured)**: PDF中的表格被转换成了**Markdown表格**，而不是混乱的文本，保留了其行列结构。
3. **解密 (Decrypted)**: 原始内容是受密码保护的，但现在生成的文件是**可以直接阅读**的。
4. **原子化 (Atomized)**: 整个大型PDF被拆分成了**以页为单位**的独立Markdown文件，便于AI进行精确的检索。

简而言之，你将得到一个**完全解构、数字化、AI友好的知识库源文件**，可以立即进行**下一步的enhance（增强）和package（打包）**操作。

**参数逐一深度解析 (Parameter-by-Parameter Breakdown)**

让我们像解剖精密仪器一样，逐一分析这条命令中的每一个参数，理解它的作用和重要性。

**skill-seekers pdf_scraper**

- **作用**: **启动PDF专业处理模块**。
- **解释**: 这是命令的“动词”，它告诉Skill Seeker，接下来的任务不是去网上爬取数据（scrape），而是要处理一个本地的PDF文件。这个指令会调用一套完全不同的、专门为解析PDF而设计的代码库和逻辑。

**--pdf secure_scanned_manual.pdf**

- **作用**: **指定输入源文件**。
- **解释**: 这是命令的“宾语”，明确了要处理的目标是当前目录下的secure_scanned_manual.pdf文件。这个路径也可以是绝对路径，例如/home/user/docs/manual.pdf。

**--name secure-manual**

- **作用**: **为输出的Skill命名**。
- **解释**: 这是你未来Skill的身份标识。所有处理结果都将被存放在output/secure-manual/目录下，最终打包成的文件将是secure-manual.zip。

**--password "secret"**

- **作用**: **提供解密密码**。
- **解释**: 这个参数解决了处理受保护文档的问题。程序在尝试打开PDF时，会自动使用"secret"这个密码进行身份验证。如果没有这个参数，处理一个加密的PDF将会直接失败。

**--ocr**

- **作用**: **启用光学字符识别 (Optical Character Recognition)**。
- **解释**: 这是处理**扫描版PDF**的“魔法棒”。对于那些内容是图片而不是可选中文本的PDF页面，Skill Seeker会：
  1. 将该页面渲染成一张高分辨率的临时图片。
  2. 调用系统底层的Tesseract OCR引擎来“读取”这张图片中的文字。
  3. 将识别出的文本作为该页面的内容。
     **重要性**: 没有--ocr，处理扫描版PDF将只会得到一堆空白的.md文件。

**--extract-tables**

- **作用**: **启用表格智能提取**。
- **解释**: 这是保留**结构化数据**的关键。当程序解析页面时，它不仅仅是提取文本流，还会主动寻找由线条和单元格组成的表格区域。一旦发现，它会：
  1. 分析表格的行列结构。
  2. 提取每个单元格的内容。
  3. 在最终的Markdown文件中，将这些内容重新组织成一个格式正确的Markdown表格。
     **重要性**: 假设一个表格描述了不同安全等级的防火墙规则，如果不用此参数，这些规则会变成一长串难以理解的文字；用了此参数，它们会以清晰的表格形式呈现，AI可以轻松地进行查询和对比。

**--parallel**

- **作用**: **启用并行处理模式**。
- **解释**: 这是提升性能的“加速器”。默认情况下，程序会一页一页地串行处理PDF。启用此参数后，程序会创建一个包含多个工作线程的“线程池”。
  **重要性**: 对于一个几百页的大型PDF，特别是当每一页都需要进行耗时的OCR操作时，并行处理可以将总时间从数十分钟缩短到几分钟。

**--workers 8**

- **作用**: **指定并行处理的工作线程数**。
- **解释**: 这个参数是对--parallel的具体化。它告诉程序：“请创建8个工作线程来同时处理这份PDF”。程序会将PDF的页面分成多批，交给这8个线程去同时执行解析、OCR和表格提取等任务。
  **重要性**: 通常，这个数字可以设置为你电脑CPU的核心数，以达到最佳性能。它允许你根据自己的硬件配置来最大化处理效率。

**总结**

这条命令的执行过程，堪称一次对复杂PDF文档的“工业级”处理流程：

1. 首先，用**密码**打开了上了锁的大门。
2. 然后，派出了**8个工人** (--workers 8) 准备**同时开工** (--parallel)。
3. 工人们拿到每一页后，发现有些页面是手写的草稿（扫描件），于是他们拿起了**文字识别器** (--ocr) 将其内容数字化。
4. 在处理过程中，他们遇到了很多登记表（表格），于是他们使用了**专业的表格处理工具** (--extract-tables)，将表格内容原样复制下来，而不是抄成一堆流水账。
5. 最终，所有工人将处理好的、干净整洁的单页报告，交给了你，并按页码整理好，放在了名为**secure-manual**的文件夹中。

------

### 3.处理大型文档

对于大型文档（10K+页面），Skill Seeker提供智能拆分和路由功能：

```bash
# 估算页面数量
skill-seekers estimate_pages configs/godot.json

# 预期输出：
⚠️ 40,000 pages detected - splitting recommended

# 自动拆分（使用路由）
skill-seekers split_config configs/godot.json --strategy router --target-pages 5000

# 并行爬取子技能
# 遍历 configs/ 目录下所有以 godot- 开头、.json 结尾的配置文件（比如 godot-3d.json、godot-ui.json 等）
#对每个配置文件，启动一个 skill-seekers 抓取任务，并用 & 让它在后台运行（即多个任务同时进行，不等前一个完成）
for config in configs/godot-*.json; do 
  skill-seekers scrape --config $config & 
done
wait

# 生成路由技能
skill-seekers generate_router configs/godot-*.json

# 打包所有技能
skill-seekers package_multi output/godot*/
```

### 4.大型文档如何开篇

当面对数万页的文档（如Godot, AWS）时，需要使用一套专门的命令来进行规划和拆分当面对数万页的文档（如Godot, AWS）时，需要使用一套专门的命令来进行规划和拆分。

- **skill-seekers estimate_pages**:
  - **用途**: 在正式抓取前，对目标网站进行快速扫描，估算出总页数。这是一个**决策工具**，帮助你判断是否需要启用大型文档拆分策略。
  - **实例**: skill-seekers estimate_pages --config configs/godot.json
- **skill-seekers split_config**:
  - **用途**: 根据你选择的策略，自动将一个总的配置文件拆分成多个子配置文件。
  - **关键参数**: --strategy [router|category|size]，用于指定拆分方式。router是最佳实践。
  - **实例**: skill-seekers split_config configs/godot.json --strategy router --target-pages 5000
- **skill-seekers generate_router**:
  - **用途**: 在使用router策略拆分并抓取了所有子技能后，此命令会创建一个智能的“主路由Skill”，负责将用户的问题引导到正确的子技能。
  - **实例**: skill-seekers generate_router configs/godot-*.json

## 创建你的第一个 Skill (Ubuntu)

本教程将带你使用预设的react.json配置，创建一个小型的React文档Skill

### 第1步：环境准备 (Ubuntu)

```bash
# 1. 更新包列表
sudo apt update

# 2. 安装Git和Python 3.10+ (Ubuntu 22.04及以上版本通常自带)
sudo apt install git python3-pip python3-venv -y

# 3. 验证安装
git --version
python3 --version
```

​        ✅ **成功标志**: 你应该能看到git和python的版本号（如 Python 3.10.x）

### 第2步：获取并安装 Skill Seeker

```bash
# 1. 选择一个工作目录，并克隆项目
cd ~ # 回到你的主目录
git clone https://github.com/yusufkaraaslan/Skill_Seekers.git

# 2. 进入项目目录
cd Skill_Seekers

# 3. 创建并激活Python虚拟环境 (这是最佳实践，避免污染系统环境)
python3 -m venv venv
source venv/bin/activate

# 激活后，你的终端提示符前会出现 (venv) 字样

# 4. 安装必要的依赖
pip install requests beautifulsoup4
```

​        ✅ **成功标志**: 所有包都成功安装，没有报错。并且你的终端提示符前有 (venv)

### 第3步：创建你的第一个 Skill (以React为例)

我们将抓取React文档的前20页作为示例

```bash
# 运行抓取命令
# --config 使用预设的react配置文件
# --enhance-local 表示在抓取完成后，立即使用本地AI进行增强
# --max-pages 限制只抓取20页，便于快速测试
skill-seekers scrape --config configs/react.json --enhance-local --max-pages 20
```

**这个过程会持续几分钟**，你会看到终端输出如下信息：

- 开始抓取页面，并显示进度（Page 1/20, Page 2/20...）
- 抓取完成后，提示开始进行本地增强（Enhancing SKILL.md locally...）
- 增强完成后，显示最终Skill的输出路径。

​       ✅ **成功标志**: 终端最后输出 ✅ Skill created at: output/react/。现在你可以用ls -R output/react命令查看生成的文件结构

### 第4步：打包 Skill

现在，我们将生成的output/react/文件夹打包成一个.zip文件。

~~~bash
# 运行打包命令，参数是上一步生成的文件夹路径
skill-seekers package output/react/
```> ✅ **成功标志**: 终端输出 `✅ Skill packaged successfully! 📦 Created: output/react.zip`。

### 第5步：上传并使用 Skill

1.  在你的文件管理器中，导航到`~/Skill_Seekers/output/`目录，你会找到`react.zip`。
2.  打开浏览器，访问 [Claude.ai](https://claude.ai)。
3.  登录后，找到“Skills”或“Add Skill”相关的按钮。
4.  点击上传，并选择你刚刚创建的`react.zip`文件。
5.  上传成功后，你就可以开始提问了！例如：
    > "在React中，如何使用useState这个Hook？请给我一个例子。"

Claude现在会利用你刚刚喂给它的“知识”，给出一个基于官方文档的、精准的回答。恭喜你，成功地扩展了Claude的能力！
~~~

### 与Claude Code的集成使用

#### **1. 设置MCP（一次配置）**

```bash
# 创建MCP配置目录
mkdir -p ~/.config/claude-code

# 创建MCP配置文件
nano ~/.config/claude-code/mcp.json
```

添加以下内容（替换路径为你的实际路径）：

```json
{
  "mcpServers": {
    "skill-seeker": {
      "command": "python3",
      "args": ["/home/yourname/Projects/Skill_Seekers/skill_seeker_mcp/server.py"],
      "cwd": "/home/yourname/Projects/Skill_Seekers"
    }
  }
}
```

#### **2. 重启Claude Code**

完全退出并重新启动Claude Code（不要只是关闭窗口）。

#### **3. 在Claude Code中使用自然语言命令**

```text
# 列出所有可用配置
List all available configs

# 生成React技能配置
Generate config for React at https://react.dev/

# 估算页面数量
Estimate pages for configs/react.json

# 爬取文档
Scrape docs using configs/react.json

# 打包技能
Package skill at output/react/
```

> **实际效果**：Claude Code会自动执行整个流程，无需手动输入命令。



## 常见工作流示例

### 工作流 A：为新网站创建一个Skill (标准流程)

```bash
# 1. (可选) 用交互模式创建一个可复用的配置文件
skill-seekers scrape --interactive

# 2. 用少量页面进行测试，确保配置无误
skill-seekers scrape --config configs/new-site.json --max-pages 20

# 3. 进行完整抓取并进行AI增强
skill-seekers scrape --config configs/new-site.json --enhance-local

# 4. 打包最终的Skill
skill-seekers package output/new-site/
```

### 工作流 B：处理本地PDF技术手册

```bash
# 1. 一条命令完成PDF的解析、提取和Skill的创建
skill-seekers pdf_scraper --pdf ~/Documents/my_manual.pdf --name my-manual-skill --extract-tables

# 2. (可选) 对生成的SKILL.md进行AI增强，以获得更好的摘要
skill-seekers enhance output/my-manual-skill/

# 3. 打包
skill-seekers package output/my-manual-skill/
```

### 工作流 C：处理一个超大型网站 (如10000+页)

```bash
#方案二
# 1. 评估网站规模
skill-seekers estimate_pages --config configs/large-site.json

# 2. 决定采用路由策略，自动拆分配置文件
skill-seekers split_config configs/large-site.json --strategy router

# 3. (并行执行) 在多个终端中，分别抓取所有子技能
# Terminal 1: skill-seekers scrape --config configs/large-site-part1.json &
# Terminal 2: skill-seekers scrape --config configs/large-site-part2.json &
# ...

# 4. 所有子技能抓取完成后，生成主路由Skill
skill-seekers generate_router configs/large-site-part*.json

# 5. 一次性打包所有生成的Skill文件夹
# (这里需要手动写个小脚本或逐个打包)
skill-seekers package output/large-site-part1/
skill-seekers package output/large-site-part2/
...
skill-seekers package output/large-site-router/
```

**针对工作流C的最佳实践**：

#### **方案一**：【最佳实践】使用 Shell 循环和后台任务 (&)

```bash
# 遍历所有以 'godot-' 开头的配置文件
for config_file in configs/godot-*.json; do
  echo "Starting scrape job for: $config_file"
  skill-seekers scrape --config "$config_file" &
done

# 等待所有后台任务完成
wait

echo "All scrape jobs have completed successfully!"
```

#### **方案二**：【手动控制】使用多个终端窗口

对于只有2-4个子技能的小型项目，或者不熟悉脚本的用户，这是一个非常直观的方法。

#### **方案三**：高级控制】使用 xargs 控制并发数

当你担心同时启动太多任务会耗尽你电脑的CPU/内存，或者给目标服务器带来太大压力时，xargs可以让你更精细地控制并行度

```bash
# 查找所有目标配置文件，然后通过管道交给xargs处理，最多同时运行4个任务
ls configs/godot-*.json | xargs -I {} -P 4 skill-seekers scrape --config {}
```

**📄 参数解释**

- ls configs/godot-*.json: 列出所有目标配置文件。
- |: 管道符，将左边命令的输出（文件名列表）作为右边xargs命令的输入。
- xargs: 一个强大的命令，可以从标准输入读取内容，并将其作为参数来执行其他命令。
- -I {}: 定义一个占位符{}。对于列表中的每一个文件名，xargs都会用该文件名替换掉{}。
- -P 4: **(核心)** 设置最大并发进程数 (Max-Procs)。这里设置为4，意味着xargs会同时运行最多4个scrape任务。当其中一个任务完成后，它会自动启动下一个，始终保持4个任务在运行，直到全部完成。

**如何选择？**

- **对于绝大多数用户**: **方案一（for循环 + & + wait）是最佳选择**。它简单、强大，且能最大化利用你的系统资源。
- **对于初学者或少量任务**: 方案二（多个终端）是一个不错的起点，可以帮助你理解并行的概念。
- **对于需要精细控制并发的高级用户**: 方案三（xargs）提供了无与伦比的灵活性，特别是在需要进行“限流”抓取时。

#### **预设配置之一**：交互模式(--interactive) 

您有以下三种简单的方法来创建这个文件，其中第一种最适合新手。

**方法一：【推荐】使用交互模式 (--interactive) 自动生成**

这是最简单、最不会出错的方法。Skill Seeker会像一个向导一样，通过问答来帮助您生成这个文件。

**步骤：**

1. **确定你的目标**：假设您想为 **Godot 游戏引擎的官方文档** 创建一个配置文件，并将其命名为 godot.json。

2. **运行交互命令**：

   ```bash
   skill-seekers scrape --interactive
   ```

   **根据提示回答问题**：

   ```
   Enter a name for your skill...: 输入 godot
   Enter a short description...: 输入 Skill for the Godot Engine official documentation.
   Enter the base URL...: 输入 https://docs.godotengine.org/en/stable/ (这是最关键的一步)
   Enter CSS selectors for content to include...: 输入 div[itemprop='articleBody'] (这是您需要通过浏览器开发者工具在目标网站上找到的核心内容选择器)
   Enter the maximum number of pages...: 输入 10000 (为一个大型网站设置一个足够高的初始值)
   ... 回答其他问题 ...
   ```

   **保存配置**：最后，程序会问 Save this configuration? (y/n):，**输入 y**

**最终成果**：
程序会提示：

> ✅ Configuration saved to: configs/godot.json

现在，您的 configs/ 目录下就有了 godot.json 这个文件。**这个文件就是您自己的“large-site.json”**。

有了它之后，您就可以运行估算命令了：

```bash
skill-seekers estimate_pages --config configs/godot.json
```

------

#### 预设配置之二：复制并修改现有预设

Skill Seeker 自带了一些预设的配置文件（如 react.json, vue.json），您可以把它们当作模板。

**步骤：**

1. **复制模板**：

```bash
cp configs/react.json configs/my-large-site.json
```

**用文本编辑器打开并修改**：

```bash
{
  "name": "my-large-site",  // <-- 改成你的技能名
  "description": "A skill for my target large documentation site.", // <-- 改成你的描述
  "base_url": "https://docs.your-large-site.com/", // <-- 改成你的目标URL
  "selectors": {
    "content": ["#main-content", ".doc-body"], // <-- 改成你目标网站的核心内容选择器
    "exclude": [".ad-container"]
  },
  "max_pages": 20000, // <-- 设置一个足够大的上限
  "rate_limit": 0.5
}
```

**保存文件**。现在您就可以使用这个新文件了

------

#### 总结与工作流程

所以，正确的完整工作流程应该是这样的：

1. **第一步：定义任务（创建配置文件）**
   - 确定您想抓取的大型网站（例如，Mozilla开发者网络MDN）。
   - 使用**交互模式**或**复制修改**的方法，创建一个代表该任务的配置文件，例如 configs/mdn.json。在这一步，您必须提供至少**技能名称**和**起始URL**。
2. **第二步：规划（估算页面）**
   - 现在您有了 mdn.json 这个“蓝图”，您可以让 Skill Seeker 去进行规划了。
   - 运行命令：skill-seekers estimate_pages --config configs/mdn.json。
3. **第三步：决策与执行（拆分与抓取）**
   - 根据上一步的估算结果（例如，返回“预估有35000页”），您决定需要进行拆分。
   - 运行拆分命令：skill-seekers split_config configs/mdn.json --strategy router
   - 最后，并行抓取所有新生成的 mdn-part*.json 文件。

## 案例实战：从零为 Tailwind CSS 构建一个 Claude Skill

**我们的目标**：创建一个高质量、AI增强的Tailwind CSS文档知识库，并将其打包成Claude可以使用的.zip文件。

**操作环境**：一台已经按照《Bulletproof Quick Start Guide》完成环境设置的Ubuntu电脑。

**前提条件**

在开始之前，请确保你已经：

1. 进入了Skill_Seekers项目目录。
2. 激活了Python虚拟环境（你的终端提示符前应该有(venv)字样）。

```bash
# 如果你还没准备好，请执行以下命令
cd ~/Skill_Seekers
source venv/bin/activate
```

------

**第1步：【蓝图设计】使用交互模式创建配置文件**

我们首先要创建一个tailwind.json的配置文件，它会告诉Skill Seeker抓取什么、怎么抓取。使用交互模式是最适合新手的，因为它会引导我们完成整个过程。

➡️ **执行命令**

```
skill-seekers scrape --interactive
```

📄 **逐行解释**

- skill-seekers scrape: 这是调用Skill Seeker核心功能“抓取”的命令。
- --interactive: 这是一个标志参数，告诉程序不要立即开始抓取，而是启动一个问答式的配置向导。

⚙️ **交互过程与解释**

程序会依次询问你以下问题。下面是我们的回答和每个问题背后的含义：

```
Enter a name for your skill (e.g., react, vue, my-skill):
我们输入: tailwind
解释: 这是你技能的唯一标识名。它将决定生成的文件夹名（output/tailwind/）和最终的压缩包名（tailwind.zip）。
Enter a short description for your skill:
我们输入: A skill for the Tailwind CSS framework, based on its official documentation.
解释: 这段描述会用在SKILL.md文件中，帮助Claude理解这个技能包的核心用途。
Enter the base URL to start scraping from (e.g., https://react.dev/):
我们输入: https://tailwindcss.com/docs/installation
解释: 这是爬虫的起始点。Skill Seeker会从这个页面开始，并跟随页面上的链接去发现和抓取其他相关页面。
Enter CSS selectors for content to include (comma-separated):
我们输入: main
解释: 这是最关键的抓取规则之一。我们告诉Skill Seeker，在每个页面中，只提取HTML中<main>标签内的内容。这可以非常有效地过滤掉导航栏、侧边栏、页脚等所有无关噪音，只保留核心文档内容。
Enter CSS selectors for content to exclude (optional, comma-separated):
我们输入: (直接按回车，跳过)
解释: 如果主要内容区域(main)中还有一些我们不想要的子版块（比如“贡献者列表”、“广告”），可以在这里指定它们的CSS选择器来排除掉。对于Tailwind文档，main已经足够干净，所以无需排除。
Enter the maximum number of pages to scrape (e.g., 100):
我们输入: 500
解释: 这是抓取页数的上限，防止无限抓取。我们先设定一个较高的值，后续测试时可以临时覆盖它。
Enter the rate limit (seconds between requests, e.g., 0.5):
我们输入: 0.5
解释: 这是两次网络请求之间的间隔时间。设置一个合理的延迟（如0.5秒）是一种礼貌的抓取行为，可以避免给对方服务器带来过大压力。
Save this configuration? (y/n):
我们输入: y
解释: 确认保存以上所有配置。
```

**✅ 最终产出**

终端会显示：

> ✅ Configuration saved to: configs/tailwind.json

现在，你的configs/目录下多了一个tailwind.json文件。你可以用cat configs/tailwind.json命令查看它的内容，它就是我们未来所有操作的“蓝图”。

------

**第2步：【小规模测试】抓取少量页面进行验证**

在进行全面抓取前，先抓取少量页面（比如20页）是一个至关重要的好习惯。这可以帮助我们：

- 快速验证配置是否正确。
- 检查抓取到的内容质量如何。
- 避免因配置错误而浪费大量时间。

➡️ **执行命令**

```bash
skill-seekers scrape --config configs/tailwind.json --max-pages 20
```

📄 **逐行解释**

- skill-seekers scrape: 再次调用抓取命令。
- --config configs/tailwind.json: 这次我们不再用交互模式，而是直接告诉程序使用我们刚刚创建的配置文件。
- --max-pages 20: **这是一个临时覆盖参数**。尽管我们的配置文件里写的是500页，但这次运行时，它会优先使用命令行的20作为上限。

⚙️ **执行过程**

你会看到终端开始滚动输出，显示它正在抓取的每一个页面的标题和进度：

```
scraping: 20 pages from https://tailwindcss.com/docs/installation

Page 1/20: Installation - Tailwind CSS
Page 2/20: Editor Setup - Tailwind CSS
...
Page 20/20: Reusing Styles - Tailwind CSS

✅ Skill created at: output/tailwind/
```

✅ **最终产出**

- 一个名为output/tailwind/的文件夹。
- 里面包含一个基础的SKILL.md文件和references/子文件夹。
- references/里有20个从网页转换来的.md文件。

**此时，你可以打开output/tailwind/references/下的任意一个文件，检查内容是否干净、格式是否正确。** 如果一切正常，我们就可以进行下一步了。

------

第3步：【全面构建与AI增强】抓取完整文档并优化

现在我们的配置已经验证无误，是时候进行全面抓取了。同时，我们将启用Skill Seeker的王牌功能：--enhance-local，它会在抓取完成后，利用AI自动为我们生成一份高质量的SKILL.md摘要。

➡️ **执行命令**

```bash
skill-seekers scrape --config configs/tailwind.json --enhance-local
```

📄 **逐行解释**

- skill-seekers scrape --config configs/tailwind.json: 和上一步一样，使用我们的配置文件进行抓取。注意，这次我们**没有**使用--max-pages，所以它会使用配置文件中设定的500页上限。
- --enhance-local: 这是一个强大的标志。它告诉程序，在所有页面抓取完毕后，**不要立即结束**。而是启动一个AI增强流程，该流程会：
  1. “阅读”output/tailwind/references/下的所有Markdown文件。
  2. 理解整个Tailwind文档的核心概念、结构和代码示例。
  3. **重写** output/tailwind/SKILL.md文件，生成一份包含关键概念、快速上手指南和内容索引的高质量摘要。

⚙️ **执行过程**

这个过程会比上一步长很多。

1. **抓取阶段**：你会看到页面抓取进度从1一直到上限（或所有可发现的页面）。
2. **数据复用提示**：由于我们第二次运行，程序会发现已经有20个页面的数据存在了。

```
✓ Found existing data: 20 pages
Use existing data? (y/n): y
```

- 我们输入 y。这样它会跳过已经抓取过的20页，从第21页开始，非常高效。

1. **增强阶段**：抓取完成后，终端会提示正在进行本地增强。

   > Enhancing SKILL.md locally. This may take a minute...

2. **完成**：最后，你会看到成功信息。

   > ✅ SKILL.md enhanced successfully!
   > ✅ Skill created at: output/tailwind/

✅ **最终产出**

output/tailwind/文件夹现在是完整且优化过的状态。如果你现在打开SKILL.md，会发现它不再是之前那个简单的文件列表，而是一份结构清晰、内容丰富的指南，这正是Claude高效利用这个知识库的关键

------

**第4步：【打包交付】创建最终的Skill压缩包**

万事俱备，只差最后一步：将我们精心制作的output/tailwind/文件夹打包成一个Claude认识的.zip文件。

➡️ **执行命令**

```
skill-seekers package output/tailwind/
```

📄 **逐行解释**

- skill-seekers package: 调用打包功能的命令。
- output/tailwind/: **(必需参数)** 告诉打包器要处理哪个文件夹。

⚙️ **执行过程**

这个命令会瞬间完成，并输出打包结果的摘要信息：

```
📦 Packaging skill: tailwind
   Source: output/tailwind
   Output: output/tailwind.zip
   + SKILL.md
   + references/installation.md
   + ... (and all other reference files)

✅ Skill packaged successfully!
📦 Created: output/tailwind.zip
📏 Size: 128.7 KB
```

> Ready to upload to Claude AI!

✅ **最终产出**

在你的output/目录下，现在有了一个全新的文件：tailwind.zip。**这就是我们所有努力的最终成果。**

------

**第5步：【部署使用】上传到Claude**

1. 打开你的文件浏览器，进入~/Skill_Seekers/output/目录。
2. 找到tailwind.zip文件。
3. 登录[Claude.ai](https://www.google.com/url?sa=E&q=https%3A%2F%2Fclaude.ai%2F)。
4. 找到并点击“Add Skill”或类似功能的按钮。
5. 在弹出的窗口中，选择并上传tailwind.zip。

上传成功后，你就可以立即开始测试了！试着问它：

> “How do I set up Tailwind CSS in a Vite project?”
> "在Tailwind CSS中，如何使用JIT模式？"
> “请给我一个使用@apply指令的例子。”

Claude将会利用你刚刚亲手打造的这个专属知识库，给出精准、可靠的回答。恭喜你，你已经走完了从零到一的完整流程！

## 实战案例：为本地的Cisco Nexus 9000安全手册创建AI知识库

**场景设定 (Scenario)**

- **你是谁？** 一名网络工程师。
- **你有什么？** 你从思科官网下载了一份非常重要的PDF技术手册，名为 Cisco_Nexus_9000_Security_Handbook.pdf。这份手册长达300多页，包含了大量的配置命令、访问控制列表（ACL）规则表示例，以及一些用于解释CoPP策略的表格。
- **你的痛点是什么？** 每次需要查找特定的安全配置时，你都要在长篇的PDF中进行繁琐的搜索和翻页，效率低下。
- **你的目标是什么？** 使用Skill Seeker将这份本地PDF手册，制作成一个可以上传到Claude的专属Skill，让你能通过自然语言快速查询所有安全配置细节。

**准备工作 (Prerequisites)**

1. **Skill Seeker环境就绪**：你已经按照之前的指南，安装好了Skill Seeker并激活了虚拟环境。
2. **准备本地文件**：为了让这个案例可以实际操作，我们先模拟这个文件的存在。请在你的终端中执行以下命令：

```bash
# 在你的用户主目录下创建一个存放内部文档的文件夹
mkdir -p ~/Documents/Internal_Docs

# 在该文件夹下创建一个空的PDF文件作为占位符
touch ~/Documents/Internal_Docs/Cisco_Nexus_9000_Security_Handbook.pdf
```

**解释**：这个touch命令创建了一个0KB的空文件。在实际使用中，你会用你真实的PDF文件替换它。这样做是为了确保后续命令中的文件路径是有效的。

------

**第1步：【执行核心命令】解析PDF并提取知识**

这是整个流程中最关键的一步。我们将使用pdf_scraper这个专门为处理PDF设计的命令，并启用高级功能来确保最高质量的内容提取。

➡️ **执行命令**

```bash
skill-seekers pdf_scraper --pdf ~/Documents/Internal_Docs/Cisco_Nexus_9000_Security_Handbook.pdf --name cisco-nexus-security --extract-tables --parallel
```

📄 **逐行解释**

- skill-seekers pdf_scraper
  - **这是什么**: 调用Skill Seeker的**PDF专业处理模块**。注意，它不是网页抓取的scrape命令，而是专门用于解析本地PDF文件的pdf_scraper。
  - **为什么用它**: 这是处理PDF文件的正确入口，它会启用所有针对PDF的优化和高级功能。
- --pdf ~/Documents/Internal_Docs/Cisco_Nexus_9000_Security_Handbook.pdf
  - **这是什么**: 指定要处理的本地PDF文件的**完整路径**。~是Linux系统中代表用户主目录的快捷方式。
  - **为什么用它**: 这是告诉工具输入源在哪里。对于本地文件，我们提供的不再是URL，而是文件系统中的一个具体位置。
- --name cisco-nexus-security
  - **这是什么**: 为我们即将创建的Skill命名。
  - **为什么用它**: 这个名称将用于创建输出文件夹 (output/cisco-nexus-security/) 和最终的压缩包，是Skill的唯一标识。
- --extract-tables
  - **这是什么**: 启用**表格提取**功能。
  - **为什么用它**: 我们的手册中包含大量结构化的表格数据（例如，CoPP策略的默认值）。启用此功能，Skill Seeker会自动识别这些表格，并将它们转换成Claude能够轻松理解和引用的Markdown表格格式，而不是一堆混乱的文本。**这是确保数据质量的关键**。
- --parallel
  - **这是什么**: 启用**并行处理**功能。
  - **为什么用它**: 我们的手册有300多页，逐页处理会比较慢。此参数会利用你电脑的多个CPU核心同时处理多个页面，可以将总耗时缩短60%-70%，极大提升了处理大型文档的效率。

------

**第2步：【理解执行过程】观察Skill Seeker的工作**

在你按下回车后，终端会开始输出处理日志，让你能清楚地看到Skill Seeker正在做什么

```
📄 Extracting from: /home/youruser/Documents/Internal_Docs/Cisco_Nexus_9000_Security_Handbook.pdf
   Pages: 300
   Table extraction: ✅ enabled
   Parallel processing: ✅ enabled (8 workers)

🚀 Extracting 300 pages in parallel (8 workers)...
[==================================================] 100%

   Found table 0 on page 45: 10x4
   Found table 1 on page 78: 15x6
   ...
   (可能会显示更多表格发现日志)

✅ Extraction complete:
   Total characters: 850,000
   Tables found: 25

✅ Skill created at: output/cisco-nexus-security/```

> **解释**: 日志清晰地展示了它识别了300页的PDF，并成功启用了表格提取和并行处理。在处理过程中，它还报告了在哪些页面发现了表格及其尺寸。最后，它告诉你Skill的源文件已经生成完毕。

---

### 第3步：【检查产出物】验证提取内容的质量

处理完成后，我们需要检查一下生成的文件，确保内容是我们想要的。

#### ➡️ **执行命令**

```bash
# 查看生成的文件夹结构
ls -R output/cisco-nexus-security/
```

📄 **你将看到的输出**

```
output/cisco-nexus-security/:
SKILL.md  references/

output/cisco-nexus-security/references:
page_001.md  page_002.md ... page_300.md
```

> **解释**: Skill Seeker为PDF的每一页都创建了一个对应的Markdown文件，并整齐地存放在references目录下。

现在，我们来查看一下第78页的内容，那里应该有一个被提取出来的表格。

➡️ **执行命令**

```bash
# 查看包含表格的那个页面的内容
cat output/cisco-nexus-security/references/page_078.md
```

📄 **你将看到的输出 (示例)**

```markdown
## Class of Service Policies (CoPP)

The default CoPP policies are designed to protect the control plane without disrupting normal network traffic. Below is a summary of the default rate limiters.

### Table 1 (Page 78)
| Traffic Class     | Default Rate (pps) | Burst (packets) |
|-------------------|--------------------|-----------------|
| BGP               | 2000               | 4000            |
| OSPF              | 2500               | 5000            |
| ACL Logging       | 500                | 1000            |
| ARP               | 1000               | 2000            |

It is critical to review these defaults and adjust them based on your network's specific needs...
```

**解释**: 这完美地展示了--extract-tables的价值。PDF中的表格被原封不动地转换成了格式优美的Markdown表格，所有文本内容也围绕着它。这些高质量、结构化的数据对于AI给出精准回答至关重要

------

**第4步：【打包与部署】创建最终的Skill文件**

最后一步，我们将包含所有.md文件的文件夹，打包成一个单一的.zip文件。

➡️ **执行命令**
`skill-seekers package output/cisco-nexus-security/`

```bash

#### 📄 **你将看到的输出**
📦 Packaging skill: cisco-nexus-security
Source: output/cisco-nexus-security
Output: output/cisco-nexus-security.zip

- SKILL.md
- references/page_001.md
  ...

✅ Skill packaged successfully!
📦 Created: output/cisco-nexus-security.zip
📏 Size: 834.2 KB
```

```
#### ✅ **最终成果**
在`output/`目录下，你现在拥有了 `cisco-nexus-security.zip` 文件。

你可以将这个文件上传到Claude。上传后，你就可以开始提问了：

*   **“在Nexus 9000上，CoPP策略的默认BGP速率限制是多少？”**
    > Claude会直接引用第78页的表格，告诉你“默认速率是2000 pps”。
*   **“请给我一个配置ARP inspection的步骤。”**
    > Claude会从相关页面总结出完整的配置命令和说明。
*   **“这份手册里提到了哪些关于ACL日志记录的最佳实践？”**
    > Claude会检索所有300页的内容，为你提炼出最相关的建议。

这个案例完整地展示了如何利用Skill Seeker，将一份复杂的本地PDF技术文档，转化为一个强大、高效、可交互的AI知识库。
```

## 实战案例演示：抓取不同类型的技术文档

#### 案例一：抓取一个简单的网页内容（例如，一篇博客文章）

假设我们要抓取一篇关于Docker的入门文章。这种一次性的抓取，最适合用快速命令。

- **目标URL**: https://www.docker.com/blog/the-what-why-and-how-of-a-docker-first-workflow/
- **➡️ 执行命令**:

```bash
skill-seekers scrape --name docker-blog --url https://www.docker.com/blog/the-what-why-and-how-of-a-docker-first-workflow/ --max-pages 1
```

- **📄 逐行解释**:
  - skill-seekers scrape: 调用抓取工具。
  - --name docker-blog: 我们为这次一次性的抓取任务命名，输出会在output/docker-blog/。
  - --url ...: 指定要抓取的唯一URL。
  - --max-pages 1: 因为我们只想抓取这一个页面，所以将上限设为1。
- **🤔 为什么要用这条命令？**
  - 这条命令最快捷，无需创建配置文件，适合抓取单个或少量无关联的页面。它会使用默认的CSS选择器（通常是<body>或<article>)来尝试提取内容。

#### 案例二：抓取Cisco技术文档（假设我们要抓取BGP配置指南）

这是一个典型的知识库抓取，最好使用配置文件来精确控制。

- **目标**: 抓取思科关于BGP配置的整个文档系列。
- **第一步**: 创建配置文件 configs/cisco-bgp.json。我们可以先用--interactive模式生成，然后手动微调。

```json
{
  "name": "cisco-bgp",
  "description": "Skill for Cisco BGP configuration guides from the official documentation.",
  "base_url": "https://www.cisco.com/c/en/us/support/docs/ip/border-gateway-protocol-bgp/13753-25.html",
  "selectors": {
    "content": ["#article-content", ".article-body"]
  },
  "max_pages": 100,
  "rate_limit": 1
}
```

- **➡️ 执行命令**:

```bash
skill-seekers scrape --config configs/cisco-bgp.json --max-pages 20 --enhance-local
```

- **📄 逐行解释**:
  - --config configs/cisco-bgp.json: 使用我们为Cisco BGP文档量身定制的配置文件。
  - "content": ["#article-content", ".article-body"]: 这是核心，我们通过查看Cisco网页源代码，发现其主要内容区域的ID是article-content。
  - --max-pages 20: 在正式抓取100页前，先用20页进行测试。
  - --enhance-local: 因为这是专业知识，我们希望AI能生成一个高质量的摘要。
- **🤔 为什么要用这条命令？**
  - 对于结构复杂、页面众多的官方文档，使用**配置文件**是唯一可靠的方式。它能保证我们精准、干净地提取每一页的核心知识，而不是抓取到一堆导航链接和脚注。

#### 案例三：抓取CrewAI部署文档

这是一个较新的AI框架，文档很可能经常更新，适合创建一个Skill来跟进。

- **目标URL**: https://docs.crewai.com/how-to/deploying-crew/

- **➡️ 执行命令**:

  ```bash
  skill-seekers scrape --name crewai-deploy --url https://docs.crewai.com/how-to/deploying-crew/ --max-pages 30 --enhance-local
  ```

  - **📄 逐行解释**:
    - --name crewai-deploy: 为技能命名。
    - --url ...: 提供起始URL。
    - --max-pages 30: 假设我们预估部署相关的文档大约有30页。
    - --enhance-local: 让AI为我们总结部署的关键步骤和注意事项。
  - **🤔 为什么要用这条命令？**
    - 这展示了如何快速为一个新技术/库创建知识库。当你开始学习CrewAI时，花10分钟运行这个命令，你就有了一个可以随时提问的AI专家助手，学习效率会大大提高。

## Skill Seeker 深度解析与扩展指南 (v2.0)

在初次总结的基础上，我重新审视了所有文档，发现Skill Seeker的强大之处远不止于基础的“抓取-打包”流程。它实际上是一个覆盖了从**简单应用**到**企业级知识库管理**的全方位、多层次的AI知识工程解决方案。

以下是我补充和深化的核心内容：

**1. 核心工作流的四个层次：从新手到专家的完整路径**

我之前的总结主要聚焦于第一个工作流。但实际上，Skill Seeker为不同需求的用户设计了四种层次递进的工作流。

**层次一：基础单技能工作流 (适用于中小型网站)**

这正是我们在初次总结中详细介绍的流程，其核心是 scrape -> enhance -> package。这是每个用户的起点，也是掌握Skill Seeker的基础。

- **依据**: QUICKSTART.md, BULLETPROOF_QUICKSTART.md

**层次二：专业级PDF处理工作流 (解锁离线与扫描文档)**

Skill Seeker不仅仅是一个网页抓取工具，它对PDF的处理能力是其一大亮点，使其能够处理离线和私有文档。

- **OCR支持**：能处理**扫描版PDF**。当你遇到一个只有图片没有文本的PDF时，--ocr参数会调用Tesseract OCR引擎来识别图像中的文字，将其转化为可用的知识。这对于处理旧的技术手册、扫描的合同或书籍至关重要。
- **表格提取**：--extract-tables参数可以智能识别PDF中的表格，并将其转换为Markdown格式的表格。这意味着结构化数据不会丢失，Claude可以直接引用和分析这些表格内容。
- **密码保护支持**：通过--password参数，可以处理加密的PDF文件，确保私有和安全文档也能被纳入知识库。
- **性能优化**：针对大型PDF，--parallel 和 --workers 参数可以启用并行处理，将提取速度提升**最高达3.3倍**，同时内置的缓存机制能让重复提取或调试变得更快。

**小结**：这部分功能极大地扩展了Skill Seeker的应用场景，从在线文档延伸到了企业内部的各类PDF资料，解决了“非网页”知识源的整合痛点。

**依据**: PDF_ADVANCED_FEATURES.md

**层次三：企业级超大文档处理工作流 (应对数万页的海量知识)**

这是Skill Seeker最强大的功能之一，专门解决像AWS、Microsoft或大型游戏引擎（如Godot）文档那样动辄数万页的“巨兽级”知识库。直接将几万页内容打包成一个Skill，效率低且效果差。Skill Seeker为此提供了精密的**拆分策略**。

- **核心理念**：化整为零，分而治之。
- **关键命令**:
  - skill-seekers estimate_pages：在开始前**预估**一个网站的总页数，帮助你判断是否需要拆分。
  - skill-seekers split_config：**自动**将一个总配置文件，根据你选择的策略，拆分成多个子配置文件。
  - skill-seekers generate_router：当使用“路由”策略时，此命令会创建一个**智能路由Skill**。
- **拆分策略**:
  1. **分类拆分 (Category Split)**：将文档按主题（如API、指南、教程）拆分成多个独立的Skill。用户需要明确知道该使用哪个Skill。
  2. **路由+分类拆分 (Router + Categories)**：**（官方推荐的最佳实践）** 这是最智能的方案。它会创建一个“主路由Skill”和多个“子主题Skill”。当你向Claude提问时：
     - 你只需要上传**所有**生成的zip包。
     - 主路由Skill会首先被激活，它会分析你的问题。
     - 然后，它会像一个聪明的调度员，**自动将你的问题导向最相关的子Skill**（例如，关于3D渲染的问题会被导向godot-3d.zip这个Skill）。
     - 这为用户提供了无缝的体验，背后却是高度协同的多个知识库在工作。
- **并行抓取**：拆分后，你可以同时在多个终端中运行抓取命令，将原来可能需要20小时的串行任务，**缩短到4小时的并行任务**。

**小结**：超大文档处理能力是Skill Seeker从“小工具”迈向“工程化平台”的关键。路由模式的设计，完美地平衡了知识的广度、深度和AI的响应效率。

**依据**: LARGE_DOCUMENTATION.md

**层次四：终极效率工作流 - Claude Code MCP 集成**

这是将Skill Seeker的使用体验提升到极致的方案。它将一个命令行工具，完全融入到了一个**对话式AI环境**中。

- **工作原理回顾**：通过~/.config/claude-code/mcp.json配置文件，Claude Code桌面应用能以后台服务的形式启动并“指挥”你的本地Skill Seeker CLI。
- **体验变革**：你不再需要记忆和输入命令、参数、路径。整个知识库的创建过程，变成了一场与AI的自然语言对话。
  - **你**："为Svelte创建一个技能，文档地址是...，最多20页。"
  - **Claude Code (背后调用Skill Seeker)**："好的，配置文件configs/svelte.json已创建。"
  - **你**："现在开始抓取吧。"
  - **Claude Code**: "好的，正在抓取... 抓取完成，技能已生成在output/svelte/。"
  - **你**："打包这个技能并上传。"
  - **Claude Code**: "打包完成，output/svelte.zip已创建并上传成功！"
- **验证的重要性**：TEST_MCP_IN_CLAUDE_CODE.md文件特别强调了，测试这一功能时，必须在Claude Code应用内进行，因为这验证的是**完整的MCP协议通信**，而不仅仅是Python函数本身能否运行。

**小结**：MCP集成是Skill Seeker设计哲学中“追求极致用户体验”的体现。它将复杂的技术流程，封装在简单的自然语言交互背后，让非技术用户也能轻松构建AI知识库。

**依据**: MCP_SETUP.md, TEST_MCP_IN_CLAUDE_CODE.md

**2. 深度剖析：关键概念与设计哲学**

通读所有文档后，可以看出几个贯穿始终的设计理念。

- **SKILL.md的核心地位**：这个文件是整个Skill的“灵魂”和“大脑”。它不是简单的文件列表，而是Claude理解和使用整个知识库的**入口和说明书**。enhance步骤之所以重要，就是因为它能生成一个高质量的SKILL.md，告诉Claude：“这个知识库是关于什么的，它的核心概念是什么，当用户问到A时，你应该去查阅references/B.md”。
- **渐进式复杂度 (Progressive Complexity)**：Skill Seeker对所有水平的用户都非常友好。
  - **新手**：可以使用--interactive或--name/--url快速上手。
  - **中级用户**：可以复制和修改configs/下的预设文件，进行自定义。
  - **专家用户**：可以运用大型文档拆分策略，配置MCP服务，处理复杂的PDF，将其打造成一个强大的自动化知识工程流水线。
- **效率与性能至上**：工具的多个设计都体现了对效率的追求。
  - --skip-scrape：在调整了内容处理逻辑后，可以秒级重新生成Skill，无需重新爬取。
  - **并行处理**：无论是大型文档的并行抓取，还是大型PDF的并行页面处理，都旨在最大化利用硬件资源，缩短等待时间。
  - **缓存机制**：在PDF处理中，缓存昂贵的操作结果，加速调试和重复运行。
- **明确的交付物 (.zip) 与清晰的上传路径**：UPLOAD_GUIDE.md清晰地说明了最终交付物是什么（一个结构化的.zip文件），以及如何交付（手动上传、CLI自动上传、MCP内上传）。这形成了一个完整、闭环的工作流。

**3. 再次总结**

初看Skill Seeker，它像一把锋利的“瑞士军刀”，能快速抓取网页生成技能。但深入所有文档后，我发现它更像一个**可扩展的“乐高”系统**。

- 基础模块（scrape, package）让你能快速拼出第一个作品。
- 进阶模块（PDF处理、AI增强）为你的作品增加了更多可能性和细节。
- 高级模块（大型文档拆分、路由策略）让你能构建宏伟、复杂的“城堡”。
- 而MCP集成，则像是为这套系统配备了一个“声控AI遥控器”，让整个拼装过程变得轻松写意。

# 我的疑问

## 1. 抓取机制深度解析：它不仅仅是爬虫

**它本质上是一个“面向AI知识构建的、内容感知的、结构化信息提取器”，而不是一个通用的网络爬虫。** 它设计的唯一目的，就是为AI模型制作高质量的“饲料”。

其工作原理可以分解为以下几个步骤：

- 第1步：确定起点 (Starting Point)
  - **原理**：抓取必须有一个开始的URL。这就是你在配置中指定的`base_url`。
  - **实现**：程序将这个URL放入一个待抓取队列中。
- 第2步：链接发现 (Link Discovery)
  - **原理**：程序访问队列中的URL后，会解析该页面的HTML内容，寻找所有的`<a>`标签（即超链接）。它会智能地判断这些链接是否属于同一个网站/文档体系，避免跳到外部网站。
  - **实现**：所有符合条件的、未被抓取过的新链接，都会被加入到待抓取队列中，直到达到`max_pages`的上限。
- 第3步：核心内容提取 (Content Extraction)
  - **原理**：**这是Skill Seeker与普通爬虫最核心的区别。** 普通爬虫会抓取整个页面的HTML，包含大量无用信息（广告、导航栏、侧边栏、版权声明等）。Skill Seeker通过**CSS选择器**，像做“外科手术”一样精准地切出你想要的核心内容。
  - **实现**：你在配置文件中提供的`"selectors": { "content": ["main", "#main-content"] }`等规则，就是“手术”的指令。它告诉程序：“在这个页面里，我只对`<main>`标签或者ID为`main-content`的`<div>`标签里的内容感兴趣，其他的全部丢弃。”
- 第4步：内容清洗与转换 (Cleaning & Conversion)
  - **原理**：拿到核心内容的HTML块之后，程序会进行二次处理。它会将HTML标签（如`<h1>`, `<code>`, `<li>`）转换成对应的Markdown语法（`#`, ``````, `*`）。
  - **实现**：使用像BeautifulSoup这样的库来解析HTML树，并将其“翻译”成干净、结构化的Markdown文本。这个过程也包括清除一些不必要的脚本和样式标签。
- 第5步：结构化组织 (Structural Organization)
  - **原理**：抓取到的内容不能是一堆混乱的文件。Skill Seeker会根据页面的URL或标题，为每个页面生成一个有意义的文件名，并全部存放在`references/`目录下。
  - **实现**：例如，`https://site.com/docs/installation`页面会被保存为`references/installation.md`。这种结构化的存储方式，便于后续AI的检索。

## 2. 应用场景与抓取目标：Skill Seeker 最擅长什么？

**Skill Seeker 主要擅长抓取“知识库”类型的目标。** 它的设计初衷就是为了将那些结构良好、以传授知识为目的的文本内容，转化为AI可以理解和使用的格式。

**最适合抓取的目标具备以下特征：**

- **结构化的技术文档**：例如编程语言、框架、库的官方文档（如React, Vue, Django）。
- **API 参考手册**：详细介绍每个函数、类、参数的文档。
- **教程和指南**：分步骤的操作指南、入门教程。
- **产品说明书和知识库**：例如企业内部的产品文档、FAQ页面。
- **PDF格式的技术白皮书、手册**：如`PDF_ADVANCED_FEATURES.md`中详述。

**对于你提的 “一个cisco的文档适合抓取吗？”**

**非常适合，这正是其核心应用场景。** Cisco的文档是典型的知识库，它结构清晰，分为不同的产品系列、技术专题（如路由、交换、安全），内容包含配置指南、命令参考、故障排除等。

通过为Cisco文档创建一个Skill，你可以将Claude变成一个思科网络专家。你可以直接问它：

> “在Cisco IOS-XE上，配置一个BGP邻居的完整步骤是什么？”

Claude会利用你提供的Skill，直接从官方文档中检索并总结出最准确的配置命令和解释，而不是依赖其可能过时或不完整的通用知识。

**是的，它抓取的就是目标的“知识库”本身，并将其“格式化”成AI专用的知识库。**

## 3. 执行环境解惑：命令在哪里运行？

这是一个非常关键的区别，你的理解很敏锐。

- 主要方式：在它自己的工具目录下用命令抓取。
  - 你首先需要在你的电脑终端中，`cd`到`Skill_Seekers`这个项目目录。
  - 然后你运行`skill-seekers scrape ...`命令。
  - 抓取到的所有文件，都会被存放在`Skill_Seekers`目录下的`output/`子目录中。
  - 这整个过程，可以完全**独立于**Claude Code运行。
- 高级方式（与Claude Code结合）：在Claude Code中“遥控”执行。
  - 当你按照`MCP_SETUP.md`配置好之后，Claude Code在你启动时，会在后台静默地启动一个Skill Seeker的本地服务。
  - 你在Claude Code的聊天框里输入：“帮我抓取React的文档”。
  - Claude Code的AI大脑会把这个自然语言指令，翻译成一个给Skill Seeker服务的请求，比如`{ "tool": "scrape_docs", "config": "configs/react.json" }`。
  - 这个本地服务接收到请求后，**它会在后台替你在终端里执行`skill-seekers scrape --config configs/react.json`这个命令**。
  - 抓取到的文件，**依然是存放在你本地的`Skill_Seekers/output/`目录下**。
  - 执行完毕后，服务将结果（如“抓取成功”）返回给Claude Code，Claude Code再用自然语言告诉你。

------

好的，我们来一次更深入的、逐条的剖析。我将严格依据你提供的文件内容，结合对软件工程实践的理解，对你提出的六个核心问题进行详细解答，并提供具体的案例演示。

------

## 4. 抓取机制深度解析：它不仅仅是爬虫

**它本质上是一个“面向AI知识构建的、内容感知的、结构化信息提取器”，而不是一个通用的网络爬虫。** 它设计的唯一目的，就是为AI模型制作高质量的“饲料”。

其工作原理可以分解为以下几个步骤：

- 第1步：确定起点 (Starting Point)
  - **原理**：抓取必须有一个开始的URL。这就是你在配置中指定的`base_url`。
  - **实现**：程序将这个URL放入一个待抓取队列中。
- 第2步：链接发现 (Link Discovery)
  - **原理**：程序访问队列中的URL后，会解析该页面的HTML内容，寻找所有的`<a>`标签（即超链接）。它会智能地判断这些链接是否属于同一个网站/文档体系，避免跳到外部网站。
  - **实现**：所有符合条件的、未被抓取过的新链接，都会被加入到待抓取队列中，直到达到`max_pages`的上限。
- 第3步：核心内容提取 (Content Extraction)
  - **原理**：**这是Skill Seeker与普通爬虫最核心的区别。** 普通爬虫会抓取整个页面的HTML，包含大量无用信息（广告、导航栏、侧边栏、版权声明等）。Skill Seeker通过**CSS选择器**，像做“外科手术”一样精准地切出你想要的核心内容。
  - **实现**：你在配置文件中提供的`"selectors": { "content": ["main", "#main-content"] }`等规则，就是“手术”的指令。它告诉程序：“在这个页面里，我只对`<main>`标签或者ID为`main-content`的`<div>`标签里的内容感兴趣，其他的全部丢弃。”
- 第4步：内容清洗与转换 (Cleaning & Conversion)
  - **原理**：拿到核心内容的HTML块之后，程序会进行二次处理。它会将HTML标签（如`<h1>`, `<code>`, `<li>`）转换成对应的Markdown语法（`#`, ``````, `*`）。
  - **实现**：使用像BeautifulSoup这样的库来解析HTML树，并将其“翻译”成干净、结构化的Markdown文本。这个过程也包括清除一些不必要的脚本和样式标签。
- 第5步：结构化组织 (Structural Organization)
  - **原理**：抓取到的内容不能是一堆混乱的文件。Skill Seeker会根据页面的URL或标题，为每个页面生成一个有意义的文件名，并全部存放在`references/`目录下。
  - **实现**：例如，`https://site.com/docs/installation`页面会被保存为`references/installation.md`。这种结构化的存储方式，便于后续AI的检索。

**结论：原则上什么都可以抓取吗？**

**不可以。** 它有明确的适用边界：

- **不适合抓取高度动态的JavaScript渲染网站**：如果一个网站的内容完全是靠前端JavaScript动态加载的（比如某些SPA应用），Skill Seeker可能只能抓取到一个空的HTML框架。
- **无法绕过登录墙和验证码**：它没有内置处理用户登录和验证码的功能。
- **不适合抓取非结构化内容**：如论坛、社交媒体等，因为很难定义一个统一的“核心内容”选择器。

------

## 5. 应用场景与抓取目标：Skill Seeker 最擅长什么？

**Skill Seeker 主要擅长抓取“知识库”类型的目标。** 它的设计初衷就是为了将那些结构良好、以传授知识为目的的文本内容，转化为AI可以理解和使用的格式。

**最适合抓取的目标具备以下特征：**

- **结构化的技术文档**：例如编程语言、框架、库的官方文档（如React, Vue, Django）。
- **API 参考手册**：详细介绍每个函数、类、参数的文档。
- **教程和指南**：分步骤的操作指南、入门教程。
- **产品说明书和知识库**：例如企业内部的产品文档、FAQ页面。
- **PDF格式的技术白皮书、手册**：如`PDF_ADVANCED_FEATURES.md`中详述。

**对于你提的 “一个cisco的文档适合抓取吗？”**

**非常适合，这正是其核心应用场景。** Cisco的文档是典型的知识库，它结构清晰，分为不同的产品系列、技术专题（如路由、交换、安全），内容包含配置指南、命令参考、故障排除等。

通过为Cisco文档创建一个Skill，你可以将Claude变成一个思科网络专家。你可以直接问它：

> “在Cisco IOS-XE上，配置一个BGP邻居的完整步骤是什么？”

Claude会利用你提供的Skill，直接从官方文档中检索并总结出最准确的配置命令和解释，而不是依赖其可能过时或不完整的通用知识。

**是的，它抓取的就是目标的“知识库”本身，并将其“格式化”成AI专用的知识库。**

------

## 6. 执行环境解惑：命令在哪里运行？

这是一个非常关键的区别，你的理解很敏锐。

- 主要方式：在它自己的工具目录下用命令抓取。
  - 你首先需要在你的电脑终端中，`cd`到`Skill_Seekers`这个项目目录。
  - 然后你运行`skill-seekers scrape ...`命令。
  - 抓取到的所有文件，都会被存放在`Skill_Seekers`目录下的`output/`子目录中。
  - 这整个过程，可以完全**独立于**Claude Code运行。
- 高级方式（与Claude Code结合）：在Claude Code中“遥控”执行。
  - 当你按照`MCP_SETUP.md`配置好之后，Claude Code在你启动时，会在后台静默地启动一个Skill Seeker的本地服务。
  - 你在Claude Code的聊天框里输入：“帮我抓取React的文档”。
  - Claude Code的AI大脑会把这个自然语言指令，翻译成一个给Skill Seeker服务的请求，比如`{ "tool": "scrape_docs", "config": "configs/react.json" }`。
  - 这个本地服务接收到请求后，**它会在后台替你在终端里执行`skill-seekers scrape --config configs/react.json`这个命令**。
  - 抓取到的文件，**依然是存放在你本地的`Skill_Seekers/output/`目录下**。
  - 执行完毕后，服务将结果（如“抓取成功”）返回给Claude Code，Claude Code再用自然语言告诉你。

**总结：** 无论哪种方式，**真正的抓取动作都是由你本地的Skill Seeker脚本在你电脑上执行的，文件也存放在本地**。Claude Code只是提供了一个更便捷、更智能的“遥控器”界面，让你不用手动去敲命令而已。

------

## 7. Claude Code 与 Skill 的协同工作：程序员如何受益？

Claude Code（或任何支持Skill的Claude版本）使用Skill的过程，可以分为两步：

1. 加载与理解 (Loading & Understanding)

   - 当你上传`.zip`包后，Claude会解压它。

   - 它首先会阅读

     SKILL.md

     这个核心文件。这个文件就像一本书的“序言和目录”，告诉Claude：

     - “我是一个关于Tailwind CSS的知识库。”
     - “我的核心概念包括JIT模式、响应式设计、功能类等。”
     - “如果你想了解安装，可以去看`references/installation.md`；想了解颜色，可以看`references/colors.md`。”

   - 通过阅读`SKILL.md`，Claude就知道了在遇到关于Tailwind CSS的问题时，应该激活并使用这个Skill。

2. 检索与增强生成 (Retrieval-Augmented Generation, RAG)

   - 当你问一个具体问题，比如：“在Tailwind里怎么自定义字体？”
   - Claude会激活`tailwind` Skill。
   - 它会利用从`SKILL.md`获得的理解，对`references/`目录下的所有文件进行**语义搜索**，找到与“自定义字体”最相关的几个段落。
   - 然后，它会将这些从**官方文档中检索到的、100%准确的段落**，作为上下文，结合它自己的语言模型能力，生成一个既准确又通顺的回答。

**这个工具里面放着什么？**

- `SKILL.md`: 知识库的“大脑”和“地图”。
- `references/`: 包含所有核心知识的、分门别类的“图书馆”。

**它能让程序员怎么使用它？**
 程序员**不再需要直接使用这个工具**。在使用阶段，程序员的唯一交互对象就是Claude。他们可以：

- **替代搜索引擎**：直接向Claude提问，获得来自官方文档的、没有广告和干扰的精准答案。
- **获取代码示例**：”给我一个用Tailwind CSS创建一个卡片布局的完整HTML代码。“
- **理解复杂概念**：”解释一下Tailwind CSS的JIT引擎是如何工作的？“
- **调试和排错**：”我的这段Tailwind代码没有生效，可能是什么原因？“

本质上，程序员将繁琐的“**查阅文档**”工作，外包给了已经“**吃透**”了这套文档的AI。

------

## 8.程序员的福音：Skill Seeker 如何让你省心？

**核心道理：它将程序员从“信息检索者”的角色，解放出来，让他们能纯粹地作为“问题解决者”。它通过将权威信息源（官方文档）与AI的交互能力相结合，创造了一个无干扰、高效率的“专家问答系统”。**

**举个形象的例子，让你看到区别：**

**【没有 Skill Seeker 之前】**

一个程序员小王正在用**Kubernetes**部署一个新应用，遇到了一个棘手的Ingress配置问题。他的YAML文件总是报错。

他的工作流是这样的：

1. 第一步：迷失在信息的海洋里
   - 他在Google搜索 `"kubernetes ingress path based routing not working"`。
   - 打开了15个浏览器标签页：
     - 3个是Stack Overflow上的提问，答案互相矛盾，且针对的是3年前的旧版本。
     - 2个是Medium上的教程，但省略了一些关键的细节。
     - 1个是Kubernetes官方文档，非常权威，但内容庞大，他需要费力地在几百页中找到与他问题相关的部分。
     - 其他是一些看起来像广告或内容农场的网站。
2. 第二步：艰难地拼凑信息
   - 他花了20分钟阅读，试图从这些碎片化的信息中找出解决方案。
   - 他复制了一段来自Stack Overflow的YAML代码，粘贴到自己的文件里，但还是报错，因为版本不匹配。
3. 第三步：求助通用AI
   - 他把自己的YAML文件和错误信息粘贴给通用的Claude。
   - Claude给了一个看似合理的回答，但因为它依赖的是截止到某个时间点的通用知识，它并不知道小王使用的Ingress-Nginx Controller最新版本的某个注解（annotation）已经变了。
4. 结果
   - 小王花了1个小时，身心俱疲，问题还没解决。

**【有了 Skill Seeker 之后】**

小王在上周花30分钟，为他当前使用的**Kubernetes v1.28**版本的官方文档创建了一个Skill。

现在，他的工作流是这样的：

1. **第一步：直接提出精准问题**

   - 他打开与加载了`kubernetes-v1.28` Skill的Claude的对话。

   - 他直接把自己的YAML文件和错误粘贴进去，然后问：

     > “这是我的Ingress配置，我想实现基于路径的路由，但它一直返回404。我用的是Ingress-Nginx Controller v1.9.4 和 K8s v1.28，帮我看看哪里错了。”

2. **第二步：获得来自“官方文档专家”的回答**

   - Claude立刻激活了`kubernetes-v1.28` Skill。

   - 它**检索了小王提供的官方文档**，找到了v1.28版本关于Ingress路径和Ingress-Nginx Controller v1.9.4注解的权威说明。

   - Claude回答道：

     > “你的配置主要问题在于注解的使用。在Ingress-Nginx Controller v1.9.0之后的版本中，`kubernetes.io/ingress.class`注解已被废弃。你应该使用`ingressClassName`字段。另外，你的`pathType`设置为`ImplementationSpecific`是正确的，但你的`rewrite-target`注解有误。根据v1.28的文档，正确的写法是... 这是修改后的YAML文件...”

3. **结果**

   - 小王只花了5分钟，就得到了一个基于官方文档的、针对他所用版本的、100%准确的解决方案。他把时间花在了解决问题本身，而不是信息的搜寻和甄别上。

**省心之处总结：**

- **信源的权威性**：答案直接来源于你信任的官方文档，杜绝了过时和错误信息。
- **效率的指数级提升**：从大海捞针式搜索，变为与专家的直接对话。
- **上下文的保持**：你可以在一个对话中持续提问，AI能理解上下文，而无需每次都重新搜索。
- **变被动为主动**：你不再被动地消费信息，而是主动地让AI为你“消化”整个知识库，并按需提供服务