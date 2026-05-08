---
name: repo-explorer
description: >
  深度探索和理解代码仓库的架构、核心模块、设计决策和工程化能力，帮助用户快速建立项目全局认知。
  当用户说"帮我了解这个项目"、"这个项目是怎么工作的"、"我刚 clone 了这个仓库"、
  "帮我分析这个代码库"、"这个项目的架构是什么"、"入口文件在哪"、"核心模块怎么组织的"、
  "这个项目用了什么设计模式"、"项目的数据架构是什么"、"这是个 AI 项目，怎么集成 LLM 的"
  时必须使用此技能。即使用户只是说"看看这个项目"或者分享了一个 GitHub 仓库链接，也应该触发此技能。
  特别适合需要快速上手新项目、做代码审查、技术调研或架构评审时使用。
---

# Repo Explorer

帮助用户在 15-20 分钟内建立对陌生代码库的系统性认知，生成一份三层结构的架构报告：**全景 → 核心系统 → 高级架构**。

**输出方式**：默认把报告输出到对话中。只有当用户明确说"保存到文件"或"写到 PROJECT_NOTES.md"时才写文件。

## 工作流程

按以下 5 个阶段探索，**广度优先**：先勾勒轮廓，再深入关键细节，避免过早陷入某个文件。

---

### 阶段 1：项目身份与工作流识别（约 2 分钟）

并行读取以下文件（有则读，没有跳过）：

**技术栈判断**
- `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `pom.xml` / `build.gradle`
- `.nvmrc` / `.tool-versions` / `Dockerfile` / `docker-compose.yml`

**项目描述**
- `README.md`（只读前 100 行）
- `ARCHITECTURE.md` / `docs/` 目录（如果存在）

**工作流扫描**
- `.github/workflows/` — CI/CD 流程（有哪些 pipeline，做什么）
- `Makefile` / `justfile` / `taskfile.yml` — 常用命令（build/test/lint/deploy）
- `scripts/` 目录顶层 — 有哪些自动化脚本
- `.husky/` / `.lefthook.yml` — 提交钩子（代码质量门禁）

从这些文件中提取：
- 项目**是什么**（一句话定位）
- 语言、框架、运行环境
- 开发→构建→测试→部署的工作流

**Monorepo 检测**：如果发现 `pnpm-workspace.yaml`、`lerna.json`、`nx.json`、`turbo.json`，或 `packages/`/`apps/` 目录下有多个子包：
1. 列出所有子包名称和用途
2. 识别用户最可能关心的核心包
3. 重点探索核心包，其他包点到为止

---

### 阶段 2：目录结构扫描（约 2 分钟）

列出顶层目录，对每个有意义的目录再列一层。跳过：`node_modules`、`.git`、`dist`、`build`、`coverage`、`__pycache__`、`.cache`。

识别目录角色：

| 目录名 | 通常代表 |
|--------|----------|
| `src/` `lib/` `pkg/` | 核心源码 |
| `app/` `pages/` `routes/` | 应用层/路由 |
| `api/` `server/` `handlers/` | 服务端逻辑 |
| `components/` `ui/` | UI 组件 |
| `utils/` `helpers/` `common/` | 工具函数 |
| `hooks/` | React Hooks |
| `store/` `state/` `context/` | 状态管理 |
| `models/` `entities/` `domain/` | 数据模型/领域对象 |
| `schema/` `migrations/` | 数据库 schema |
| `prompts/` `agents/` `chains/` | AI/LLM 相关 |
| `tests/` `__tests__/` `spec/` | 测试 |
| `scripts/` `bin/` | 构建/工具脚本 |
| `docs/` | 文档 |
| `packages/` `apps/` | Monorepo 子包 |

---

### 阶段 3：入口点定位（约 2 分钟）

找到代码从哪里"开始执行"：

**JS/TS 项目**
- `package.json` 的 `main`、`exports`、`bin` 字段
- 框架约定：Next.js→`app/`或`pages/`，Express→`server.js`/`app.js`，CLI→`bin/`

**Python 项目**
- `__main__.py`、`main.py`、`setup.py` 的 `entry_points`
- `pyproject.toml` 的 `[tool.poetry.scripts]`

**Go 项目**
- `main.go` 或 `cmd/*/main.go`

**Java/Kotlin 项目**
- 找 `@SpringBootApplication` 或 `main()` 所在类
- `src/main/java/` 顶层类

读入口文件，弄清楚它初始化了什么、串联了哪些模块。

---

### 阶段 4：核心系统与数据架构（约 5 分钟）

**找到核心业务逻辑**

从入口点出发，沿调用链找到"实质性工作"在哪里发生。读 3-5 个最关键的文件（读核心部分，不需要逐行读完）。

重点理解：
1. **请求/数据从哪里进来** → 经过哪些处理 → 从哪里出去
2. **模块之间如何通信**（直接调用？事件？消息队列？）
3. **是否存在状态机或生命周期**（请求处理阶段、组件生命周期、任务状态流转）

**核心抽象识别**

找出 3-5 个最重要的概念/类型（`Agent`、`Session`、`Provider`、`Repository` 等），理解：
- 职责边界在哪里
- 彼此关系如何
- 关键字段和方法签名（不需要实现细节）

读 `types.ts`、`interfaces/`、核心 class 定义来提取这些信息。

**数据架构探索**

并行扫描：
- `models/` `entities/` `domain/` — 核心数据模型
- `schema/` `migrations/` `prisma/schema.prisma` — 数据库 schema
- `*.sql` 顶层文件 — DDL 定义
- `openapi.yaml` / `swagger.json` — API 契约（也反映数据结构）
- 配置中的数据库/缓存连接（了解存储技术选型）

识别：核心实体有哪些，它们如何关联，数据在哪里持久化、在哪里缓存。

---

### 阶段 5：高级架构分析（约 4 分钟）

**设计模式识别**

在阅读代码时留意以下信号：
- **依赖注入**：构造函数注入、IoC 容器（`@Injectable`、`container.register`）
- **策略模式**：一组实现同一接口的类，运行时切换（`Provider`、`Adapter`、`Handler`）
- **插件/扩展机制**：动态注册、钩子系统（`plugin.register`、`hooks.on`）
- **观察者/事件**：事件总线、EventEmitter、消息订阅
- **工厂模式**：`createXxx`、`XxxFactory`
- **装饰器/中间件**：链式处理、`use(middleware)`
- **Repository 模式**：数据访问层抽象

**AI 与工程化能力**（仅 AI 项目）

如果发现 `openai`、`anthropic`、`langchain`、`llamaindex` 等依赖，或 `prompts/`、`agents/`、`chains/` 目录，深入探索：
- **LLM 集成**：用了哪个 SDK，如何调用，是否有抽象层
- **Prompt 管理**：prompts 在哪里定义，是硬编码还是模板化
- **上下文管理**：如何构建/压缩/截断上下文窗口
- **Agent 设计**：是否有 ReAct/Tool Use 模式，工具如何注册和调用
- **工程化**：是否有 prompt 版本管理、评估框架、可观测性（tracing）

---

### 阶段 6：生成三层架构报告

---

## 报告结构

```markdown
# [项目名] 架构报告

---

## 第一层：全景

### 项目定位
[一句话说清楚：这是什么，解决什么问题，面向谁]

### 技术栈
- 语言：
- 框架：
- 构建工具：
- 测试框架：
- 数据库/存储：
- 主要运行环境：

### 核心架构风格
[整体是什么架构风格：分层架构/六边形架构/微服务/插件式/事件驱动/MVC/CQRS 等。
一段话解释为什么选这种风格，以及它带来了什么约束。]

### 工作流
[开发→构建→测试→部署的完整流程，说明有哪些自动化门禁]

例：
```
开发  →  git commit（husky: lint-staged）
       →  push（CI: lint + unit tests）
       →  PR merge（CI: integration tests + build）
       →  main branch（CD: 自动部署到 staging）
       →  手动触发（部署到 production）
```

---

## 第二层：核心系统

### 核心子系统
[列出 3-5 个核心子系统，每个说明职责边界和它解决的问题]

例：
- **认证系统**（`src/auth/`）— 处理登录、token 生命周期、权限校验。与业务逻辑完全解耦，通过中间件注入。
- **任务调度器**（`src/scheduler/`）— 管理异步任务队列，支持重试和优先级。依赖 Redis，与业务无关。

### 核心模块
[关键文件/类/接口，说明职责和关键字段/方法签名]

例：
- **`Agent`**（`src/agents.ts`）— 表示一个 AI 编码工具，定义技能目录路径和安装检测逻辑
  - 关键字段：`id`、`name`、`skillsDir`、`isUniversal`
- **`Skill`**（`src/types.ts`）— 一个可安装的技能单元，来自 SKILL.md 解析
  - 关键字段：`name`、`description`、`path`、`frontmatter`

### 核心数据流
[用多级缩进 ASCII 图展示主要请求/数据的流转，每步标注文件名和函数名]

例：
```
用户输入源地址
  → source-parser.ts: parseSource()     # 判断 github/gitlab/local/well-known
  → [远程] git.ts: cloneRepo()          # clone 到临时目录
  → skills.ts: discoverSkills()         # 递归找 SKILL.md，解析元数据
  → installer.ts: installSkillForAgent() # symlink 或 copy
  → skill-lock.ts: updateLock()         # 更新锁文件
```

### 关键文件速查
| 想了解什么 | 去哪里找 |
|------------|----------|
| [基于项目实际内容填写] | [具体文件路径] |

---

## 第三层：高级架构

### 设计模式
[列出项目实际使用的设计模式，每个说明在哪里用、解决了什么问题]

例：
- **策略模式**（`src/providers/`）— 多个 LLM Provider 实现同一 `ModelProvider` 接口，运行时按配置切换，方便新增供应商
- **中间件链**（`src/middleware/`）— 请求处理通过 `use()` 串联，每个中间件只关心自己的职责

### 逻辑架构
[用分层图展示模块间的依赖方向和边界。箭头表示"依赖/调用"]

例（分层架构）：
```
CLI / API 层     ←  用户交互入口
    ↓
Service 层       ←  业务编排，无技术细节
    ↓
Core 层          ←  核心领域逻辑
    ↓
Adapter 层       ←  外部系统适配（DB、API、文件系统）
```

例（模块依赖图）：
```
cli.ts
  ↓ 依赖
add.ts / remove.ts    ←→    config.ts
  ↓ 依赖                        ↓
installer.ts              schema-validator.ts
  ↓ 依赖
git.ts   skill-lock.ts   skills.ts
```

### 数据架构
[核心数据模型、它们之间的关系、数据在哪里流动和持久化]

例：
```
User (1) ──── (N) Session
  └── (N) Permission
           └── Resource

持久化：User/Permission → PostgreSQL
        Session token  → Redis（TTL 24h）
        文件上传       → S3
```

### AI 与工程化能力
[仅 AI 项目填写。不是 AI 项目直接删除此节]

- **LLM 集成**：[SDK、调用方式、是否有抽象层]
- **Prompt 管理**：[在哪里定义、是否模板化、如何版本控制]
- **上下文管理**：[如何构建/压缩上下文]
- **Agent 设计**：[ReAct/Tool Use 模式、工具注册方式]
- **工程化**：[是否有评估框架、tracing、可观测性]

### 架构决策
[ADR 风格。只写真的有决策权衡的地方，没有就跳过整节]

例：
- **为什么用 symlink 而不是 copy 安装技能**
  — 权衡：symlink 让源目录变更立即生效，但依赖源目录存在；copy 更稳定，但更新麻烦
  — 决策：选 symlink，因为技能通常从本地开发目录安装，更新频率高

- **为什么不用 ORM**
  — 权衡：ORM 降低 SQL 学习成本，但这个项目查询复杂，ORM 生成的 SQL 难以优化
  — 决策：直接用 query builder，保留对 SQL 的完全控制
```

---

## 报告生成原则

**要做的：**
- 目录树注释说明"为什么"而不只是"是什么"
- 数据流描述具体到文件和函数级别
- 设计模式要说明"在哪里用、解决什么问题"，不只是列名字
- 逻辑架构图要体现依赖方向（谁依赖谁）
- 架构决策必须写出权衡，没有权衡就不是决策
- AI 与工程化能力只在真正是 AI 项目时才写

**不要做的：**
- 不要试图读完所有文件
- 不要在报告里复制粘贴代码片段
- 不要对用户没问的东西发表评判
- 不要生成虚假的目录结构或模块
- 不要未经用户要求就保存文件
- 不要在非 AI 项目里强行填写"AI 与工程化能力"节

---

## 后续对话模式

生成报告后，主动提示用户可以继续深挖：

> "报告已生成。你可以继续问我：
> - '认证模块是怎么实现的？'
> - '找找哪里处理了 webhook 事件'
> - 'X 和 Y 模块之间的关系是什么'
> - '这里为什么用策略模式而不是 if-else？'
> - 或者直接说你想深入了解的功能点"

在后续对话中，基于已有的探索结果快速定位，不需要重新扫描整个项目。
