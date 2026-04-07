---
name: claude-md-expert
description: 创建、更新和优化 CLAUDE.md 配置文件。当用户请求初始化/改进 CLAUDE.md、改进项目配置、添加编码规范时触发。
---

# CLAUDE.md 管理指南

## 核心原则

### 少即是多

- **控制指令数量**：前沿 LLM 能可靠遵循约 150-200 条指令，Claude Code 系统提示已占用约 50 条
- **长度限制**：根目录 CLAUDE.md 建议 < 300 行，越短越好（参考：HumanLayer 仅 60 行）
- **通用性优先**：只包含每个会话都需要的信息，避免任务特定内容
- **上下文宝贵**：CLAUDE.md 中的每一行都在与实际工作争夺注意力

### 四要素内容

| 类型           | 描述                 | 示例                                       |
| :------------- | :------------------- | :----------------------------------------- |
| **项目上下文** | 项目简介、技术栈     | "带 Stripe 集成的 Next.js 电商应用"        |
| **代码风格**   | 格式化规范、模式偏好 | ES 模块语法、命名导出、TypeScript 严格模式 |
| **命令**       | 构建、测试、部署脚本 | `npm run dev`、`npm run test`              |
| **注意事项**   | 项目特定警告、禁区   | 不可修改的文件、特殊 API 要求              |

## 文件位置层级

| 位置                     | 范围 | 用途                       |
| :----------------------- | :--- | :------------------------- |
| `~/.claude/CLAUDE.md`    | 全局 | 个人通用偏好               |
| `项目根/CLAUDE.md`       | 项目 | 团队共享配置（提交到 git） |
| `项目根/CLAUDE.local.md` | 项目 | 个人本地配置（gitignore）  |
| `子目录/CLAUDE.md`       | 模块 | 特定模块上下文，按需加载   |

> **注意**：文件名大小写敏感，必须是 `CLAUDE.md`（大写 CLAUDE，小写 .md）。

## 渐进式披露

### @imports 语法

`CLAUDE.md` 支持用 `@path/to/file` 语法导入其他文件，保持主文件精简：

```markdown
查看 @README.md 了解项目概述
查看 @docs/api-patterns.md 了解 API 约定
查看 @package.json 了解可用的 npm 脚本
```

- 支持相对路径、绝对路径
- 支持用户级文件：`@~/.claude/my-preferences.md`
- 导入可递归，但避免创建引用迷宫

### agent_docs 目录结构

```
agent_docs/
├── building.md          # 构建指南
├── testing.md           # 测试规范
├── code_conventions.md  # 代码规范
└── architecture.md      # 架构说明
```

在 CLAUDE.md 中引用：

```markdown
## 扩展文档

需要时参阅：

- @agent_docs/building.md - 构建和部署
- @agent_docs/testing.md - 测试相关
```

### .claude/rules/ 模块化规则（大型项目）

对于需要跨团队协作的大型项目，可将规则拆分到独立文件：

```
your-project/
├── CLAUDE.md                   # 主项目指令
└── .claude/
    └── rules/
        ├── code-style.md       # 代码风格（前端团队维护）
        ├── testing.md          # 测试约定
        └── security.md         # 安全要求（安全团队维护）
```

`.claude/rules/` 中所有 markdown 文件**自动加载**，无需手动 import。适合不同团队独立维护各自规则集的场景。

### 子目录 CLAUDE.md

子目录中的 `CLAUDE.md` **按需加载**（仅当 Claude 处理该目录代码时），适合 monorepo：

```
/api/CLAUDE.md        # API 特定约定
/packages/ui/CLAUDE.md  # UI 组件开发规则
```

## 避免的反模式

1. **不要用作 linter**：代码风格用 ESLint/Prettier 处理
2. **不要自动生成后放任不管**：`/init` 产出仅供参考，需手工精炼删减
3. **不要堆砌命令**：只保留最常用的关键命令
4. **不要放代码片段**：易过时，改用文件引用
5. **不要所有内容都标记为"重要"**：滥用强调等于没有强调

## 关键指令强调

对于绝对必须遵循的规则，使用强调措辞提高注意力：

```markdown
**重要**：永远不要直接修改 migrations 文件夹
**必须**：提交前运行测试
**禁止**：提交 .env 文件
```

> 谨慎使用，仅标记真正关键的规则。

## 完整模板

```markdown
# 项目名

一句话项目描述（如：带 Stripe 集成的 Next.js 14 电商应用）。

## 代码风格

- TypeScript 严格模式，不使用 `any` 类型
- 使用命名导出，不使用默认导出
- ES 模块语法 (import/export)

## 常用命令

- `npm run dev` - 开发服务器（端口 3000）
- `npm run test` - 运行测试
- `npm run test:e2e` - 端到端测试
- `npm run lint` - ESLint 检查
- `npm run db:migrate` - 数据库迁移

## 架构

- `/app` - Next.js App Router 页面和布局
- `/components/ui` - 可复用 UI 组件
- `/lib` - 工具和共享逻辑

## 注意事项

- **禁止**：提交 .env 文件
- **重要**：/api/webhooks/stripe 必须验证签名
- 产品图片存储在 Cloudinary，不是本地

## 扩展文档

- @docs/authentication.md - 认证流程详情
- @docs/api-patterns.md - API 约定
```

## 维护策略

### 在工作时实时补充

当 Claude 做出不符合预期的假设时，立即要求更新：

> "把这条加入我的 CLAUDE.md：永远使用 logger 而不是 console.log"

有机地构建文件，而非试图预先预测所有内容。

### 定期审查优化

每隔几周，要求 Claude 审查并优化：

> "审查这个 CLAUDE.md 并提出改进建议"

重点检查：删除过时的、合并冗余的、澄清模糊的、清理冲突的。

### 从代码审查中更新

PR review 发现未记录的约定时，立即添加到 CLAUDE.md。这创建了"现实问题 → 指令更新 → 预防未来问题"的反馈循环。

## 工作流程

1. **评估现状**：检查是否存在 CLAUDE.md，了解项目结构
2. **收集需求**：了解用户需要记录什么（约定、命令、注意事项）
3. **分类内容**：区分通用（每次会话需要）vs 任务特定（按需引用）
4. **精简表达**：用最少的文字传达清楚，删除显而易见的内容
5. **选择结构**：单文件 / @imports / .claude/rules/ 按项目规模选择
6. **迭代优化**：鼓励用户从实际使用中持续补充规则

## 添加指令的方式

在 Claude Code 中，直接要求 Claude 编辑 CLAUDE.md：

> "添加到我的 CLAUDE.md：[你的规则]"

> **注意**：早期版本的 `#` 键盘快捷键已在 Claude Code v2.0.70 中移除，当前推荐直接要求 Claude 编辑文件。
