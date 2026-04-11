---
name: claude-md-expert
description: 创建、更新和优化 AGENTS.md 和 CLAUDE.md 配置文件。当用户请求初始化/改进项目配置、添加编码规范、设置 AI 代理规则时触发。项目中同时管理 AGENTS.md（通用 AI 规则）和 CLAUDE.md（Claude 专属配置），如果项目中不存在这两个文件，主动提议为用户同时创建它们。
---

# AGENTS.md & CLAUDE.md 管理指南

## 两个文件的分工

| 文件        | 定位                       | 使用场景                                    |
| :---------- | :------------------------- | :------------------------------------------ |
| `AGENTS.md` | 通用 AI 代理规则（跨工具） | Cursor、Zed、Claude Code、OpenCode 等均支持 |
| `CLAUDE.md` | Claude 专属配置            | Claude Code 专有特性（@imports、rules/ 等） |

**推荐做法**：将主要规则写在 `AGENTS.md`，`CLAUDE.md` 指向它并补充 Claude 专属内容：

```markdown
# CLAUDE.md

严格遵循 @AGENTS.md 中的规则。

## Claude 专属配置

<!-- 仅 Claude Code 支持的特性放这里 -->
```

## 工作流程

### 第一步：评估现状

检查项目中是否存在这两个文件：

- 两个都没有 → **同时创建** AGENTS.md 和 CLAUDE.md
- 只有 CLAUDE.md → 将内容迁移/扩展为 AGENTS.md，CLAUDE.md 改为指向它
- 只有 AGENTS.md → 创建简洁的 CLAUDE.md 指向它
- 两个都有 → 按用户需求更新

### 第二步：收集项目信息

在创建/更新前，了解：

- 项目类型和技术栈
- 常用构建/测试/lint 命令
- 代码风格偏好（语言版本、格式化工具等）
- 项目结构中的关键文件/目录
- 特殊注意事项或禁区

### 第三步：生成文件

---

## AGENTS.md 最佳实践

### 该做 / 不该做

最核心的内容，基于实际使用经验积累的规则：

```markdown
### 该做

- 使用 [框架版本]，确保代码与该版本兼容
- 使用 [状态管理方案]
- 默认使用小组件，优先聚焦的模块而非上帝组件
- 默认使用小改动，除非要求否则避免全仓库重写

### 不该做

- 不要硬编码颜色/配置
- 未经批准不要添加新的重量级依赖
```

**提示**：保持小而清晰，随着使用经验逐步扩展。

### 命令（优先文件级操作）

```markdown
### 命令

# 单文件类型检查（比全量构建快得多）

npm run tsc --noEmit path/to/file.tsx

# 单文件格式化

npm run prettier --write path/to/file.tsx

# 单文件 lint

npm run eslint --fix path/to/file.tsx

# 单文件测试

npm run vitest run path/to/file.test.tsx

# 明确要求时才运行完整构建

npm run build

注意：始终 lint、测试和类型检查修改过的文件。谨慎使用全项目构建。
```

**为什么用文件级命令**：单文件检查耗时几秒，全量构建耗时几分钟；快速反馈让 AI 愿意频繁验证，代码正确性更高。

### 安全和权限

```markdown
### 安全和权限

无需提示可直接执行：

- 读取文件、列出文件
- 单文件的 tsc、prettier、eslint
- 单个 vitest 测试

先询问确认：

- 安装依赖包
- git push
- 删除文件、修改权限
- 运行完整构建或端到端测试套件
```

### 项目结构提示

```markdown
### 项目结构

- 查看 `App.tsx` 了解路由
- 组件位于 `src/components`
- 工具函数位于 `src/lib`
- API 客户端位于 `src/api/client.ts`
```

**价值**：代理从正确位置开始探索，节省大量重复搜索时间。

### 好坏示例（可选）

```markdown
### 好的和坏的示例

- 避免 `Admin.tsx` 中的基于类的组件写法
- 参考 `Dashboard.tsx` 的 hooks 函数式组件写法
- 表单：复制 `src/components/Form.tsx` 的模式
- 数据请求：通过 `src/api/client.ts`，不要在组件内直接 fetch
```

### PR 检查清单（可选）

```markdown
### PR 检查清单

- 标题格式：`feat(scope): 简短描述`（Conventional Commits）
- 提交前：lint、类型检查、单元测试全部通过
- 改动小且聚焦，包含改了什么和为什么的简短说明
- 删除多余的 console.log 和调试注释
```

### 卡住时（可选）

```markdown
### 卡住时

- 询问澄清问题、提出简短计划，或打开带注释的草稿 PR
- 未经确认不要推送大型推测性改动
```

### 嵌套 AGENTS.md（大型项目）

在子目录添加专属 `AGENTS.md`，代理读取最近的文件：

```
/api/AGENTS.md          # API 子模块规则
/packages/ui/AGENTS.md  # UI 包开发规则
```

---

## CLAUDE.md 最佳实践

### 核心原则

- **少即是多**：前沿 LLM 能可靠遵循约 150-200 条指令，Claude Code 系统提示已占用约 50 条
- **长度限制**：根目录 CLAUDE.md 建议 < 300 行，越短越好
- **通用性优先**：只包含每个会话都需要的信息

### Claude 专属特性

**@imports 语法**

```markdown
查看 @README.md 了解项目概述
查看 @docs/api-patterns.md 了解 API 约定
查看 @package.json 了解可用的 npm 脚本
```

- 支持相对路径、绝对路径、用户级路径（`@~/.claude/my-preferences.md`）
- 导入可递归，但避免创建引用迷宫

**`.claude/rules/` 模块化规则（大型项目）**

```
your-project/
├── AGENTS.md                   # 通用 AI 规则
├── CLAUDE.md                   # Claude 专属 + 指向 AGENTS.md
└── .claude/
    └── rules/
        ├── code-style.md       # 代码风格
        ├── testing.md          # 测试约定
        └── security.md         # 安全要求
```

`.claude/rules/` 中所有 markdown 文件自动加载，无需手动 import。

**子目录 CLAUDE.md**：仅当 Claude 处理该目录代码时按需加载，适合 monorepo。

### 关键指令强调

```markdown
**重要**：永远不要直接修改 migrations 文件夹
**必须**：提交前运行测试
**禁止**：提交 .env 文件
```

> 谨慎使用，仅标记真正关键的规则。滥用强调等于没有强调。

---

## 文件模板

### AGENTS.md 模板

```markdown
# AGENTS.md

## 该做

- [列出项目约定和最佳实践]

## 不该做

- [列出禁止事项]

## 命令

# 单文件类型检查

[tsc 命令] path/to/file

# 单文件格式化

[prettier 命令] path/to/file

# 单文件 lint

[lint 命令] path/to/file

# 测试

[test 命令] path/to/file.test

# 完整构建（谨慎使用）

[build 命令]

注意：始终检查修改过的文件，谨慎使用全量构建。

## 安全和权限

无需提示：读文件、单文件检查/测试
先询问：安装依赖、git push、删除文件、全量构建

## 项目结构

- [关键文件/目录说明]

## PR 检查清单

- 标题：`type(scope): 描述`
- lint、类型检查、测试全绿
- 改动小且聚焦
```

### CLAUDE.md 模板（指向 AGENTS.md）

```markdown
# CLAUDE.md

严格遵循 ./AGENTS.md 中的规则。

## 扩展文档

- @docs/architecture.md - 架构说明
- @docs/testing.md - 测试规范
```

### CLAUDE.md 独立模板（不使用 AGENTS.md 时）

```markdown
# 项目名

一句话项目描述。

## 代码风格

- [具体格式化和模式偏好]

## 常用命令

- `npm run dev` - 开发服务器
- `npm run test` - 运行测试
- `npm run lint` - ESLint 检查

## 架构

- `/src` - 源码目录
- `/tests` - 测试文件

## 注意事项

- **禁止**：提交 .env 文件
- [其他重要警告]

## 扩展文档

- @docs/api-patterns.md - API 约定
```

---

## 维护策略

### 实时补充

当 AI 做出不符合预期的假设时，立即更新：

> "把这条加入 AGENTS.md：永远使用 logger 而不是 console.log"

### 定期审查

每隔几周检查：删除过时的、合并冗余的、澄清模糊的。

### 从 PR review 中更新

PR review 发现未记录的约定时，立即添加。形成"现实问题 → 指令更新 → 预防未来问题"的反馈循环。

## 避免的反模式

1. **不要用作 linter**：代码风格用 ESLint/Prettier 工具处理
2. **不要自动生成后放任不管**：`/init` 产出仅供参考，需手工精炼
3. **不要堆砌命令**：只保留最常用的关键命令
4. **不要放代码片段**：易过时，改用文件引用
5. **不要所有内容都标记为"重要"**：滥用强调等于没有强调
