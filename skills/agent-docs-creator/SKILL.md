---
name: agent-docs-creator
description: 为项目创建、更新和同步实现文档（implementation docs），帮助 Claude Code 等 coding agent 快速理解项目结构与实现细节。文档存储在项目 `agent_docs/` 目录，并在 AGENTS.md 中添加 `@agent_docs/index.md` 索引引用。当用户说"创建实现文档"、"更新 agent docs"、"生成项目文档"、"同步实现文档"、"impl docs"、"agent-docs-creator"、"为这个项目生成 agent 文档"时触发。仅限用户主动调用，不自动触发。
---

## 目标

为 coding agent（Claude Code、Codex、Gemini-CLI 等）生成高质量的实现文档，而非面向人类阅读的说明文档。文档的核心价值是让 agent 能**快速定位代码、理解结构、避免踩坑**，而非解释业务背景。

## 操作模式

- **首次**：`agent_docs/` 不存在 → 从零生成完整文档体系
- **更新**：`agent_docs/` 已存在 → 读取所有现有文档和对应源码，逐模块对比，只改有出入的部分

## 执行流程

### 第一步：探索项目结构

快速扫描以理解项目全貌：

- 根目录文件列表
- 入口文件（`main.*`, `index.*`, `app.*`, `server.*`）
- 核心配置文件（`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod` 等）
- 现有文档（`README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/`）
- 主要源码目录（`src/`, `lib/`, `packages/` 等）

**更新模式**：额外读取 `agent_docs/` 下所有现有文档，再读取各模块对应的源文件，**逐文件对比**找出实际差异：新增/删除的函数、变更的类型、新出现的注意事项等。只重写有实质变化的模块文档；没有差异的跳过，不要"刷新"没变的内容。

### 第二步：确定模块划分

根据项目结构自主决定拆分方式。判断原则：**每个模块文档应能独立回答"在这里改代码，agent 需要知道什么？"**

常见维度（选最贴合项目的）：
- 按功能模块（auth, api, db, cache）
- 按架构层次（core, adapter, service, handler）
- 按包/子项目（monorepo）
- 按文件类型职责（types, utils, config）

模块粒度适中：太细碎（每个文件一个 doc）噪音多，太粗粒（全项目一个文件）价值低。

### 第三步：生成文档

#### `agent_docs/index.md`（必须生成）

```markdown
# <项目名> — Agent Docs

> 更新：YYYY-MM-DD

## 概览

<技术栈 + 项目做什么，一到两句话>

## 入口

- `<文件路径>` — <作用>

## 模块

- [@agent_docs/<module-a>.md](<module-a>.md) — <一句话描述>
- [@agent_docs/<module-b>.md](<module-b>.md) — <一句话描述>

## 全局约定

<列出项目级的重要约定：错误处理模式、命名特殊规则、关键环境变量、重要的初始化顺序等>
```

#### `agent_docs/<module>.md`（每个模块）

```markdown
# <模块名>

**位置**：`src/<module>/`
**职责**：<一句话>

## 关键文件

| 文件 | 作用 |
|------|------|
| `src/module/foo.ts` | ... |

## 核心类型

<列出关键类型/接口，标注文件位置。只写非自明的，附带语义说明>

## 主要函数

<只列值得关注的函数，带签名和一句话说明。能从名字直接读懂的跳过>

## 注意事项

<非显而易见的行为、已知陷阱、临时方案、依赖顺序、与其他模块的隐式耦合>
```

注意事项为空时，直接省略该小节，不要留空壳。

### 第四步：同步 AGENTS.md

在项目根目录的 `AGENTS.md`（或 `CLAUDE.md`，取项目实际使用的那个）中添加 `agent_docs` 引用。

1. 搜索文件中是否已有 `@agent_docs` 或 `agent_docs/index.md` 的提及
2. 若无，在文件**开头**（第一行非注释内容之前）添加：

```
@agent_docs/index.md
```

**只加这一行，不修改其他任何内容。**

若 `AGENTS.md` 和 `CLAUDE.md` 都存在，优先更新 `AGENTS.md`。

## 反向指引：什么值得写

这份文档的读者是 coding agent，不是人类。评判标准是：**读完后能更快、更准确地完成代码任务**。

**写这些**（高价值）：
- 非显而易见的文件职责（"这个文件不只是配置，启动时还执行了 X"）
- 类型别名的语义（`type UserId = string` — 实际是 UUID v4，不能随意构造）
- 调用链和初始化顺序依赖（"必须先初始化 A，再调用 B"）
- 已知陷阱和绕过方案（"不要直接用 X，因为 Y，改用 Z"）
- 模块间的隐式契约（"这个函数假设调用方已验证权限"）
- 重要副作用（"调用此函数会写磁盘缓存"）

**跳过这些**（低价值）：
- 函数名已能表达的信息（`getUserById` 不需要解释）
- 业务背景和需求历史
- 用户侧功能说明（README 的事）
- 代码注释里已写清楚的内容

## 文件约定

- 文档目录：`<项目根目录>/agent_docs/`
- 索引：`agent_docs/index.md`
- 模块文档：`agent_docs/<module-name>.md`（扁平结构，不嵌套子目录）
- `agent_docs/` 应提交到 git（不加入 `.gitignore`）
