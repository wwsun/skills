---
name: gitlab-issues
description: 自动化整理 GitLab Issues。支持一键执行完整流程：自动为新增 Issue 打标 (tag) 和指派 (assign)，并生成包含新增、优先关注及分类统计的每日汇总报告。支持动态更新配置规则。
---

# GitLab Issue Manager

此技能旨在自动化管理 GitLab 仓库中的 Issues。它通过 `scripts/gitlab_api.py` 与 GitLab API 交互，并根据 `rules.json` 执行逻辑。

## 核心功能

1. **完整自动化流程 (Complete Workflow)**:
   - **自动打标与指派**: 扫描无标签或无指派人的 Opened Issues。
   - **多重匹配**: 若命中多个关键字，将叠加所有相关标签。
   - **默认配置**: 若无关键字命中，自动应用默认标签 (如 `P2`, `feature`)。
   - **自动汇总**: 处理完成后自动生成当日概况报告。

2. **配置管理 (Dynamic Rules)**:
   - 规则存储在 `rules.json` 中。
   - 你可以通过聊天指令（如“以后把 A 分给 B”）要求 AI 更新该文件。

## 使用指南

### 1. 执行完整整理流程 (推荐)
当你要求“整理仓库”、“执行今日任务”或“看看昨天的 issue”时：
- 运行命令: `python scripts/gitlab_api.py workflow`
- **处理逻辑**:
  - `agent`/`studio` 相关 -> 指派给 `sunweiwei01`, 打标 `P1`, `feature`。
  - `template`/`publish` 相关 -> 指派给 `shenxiaohan`, 打标 `P1`, `feature`。
  - `bug`/`fix`/`error` 相关 -> 打标 `bugfix`, `P0`。
- **输出报表**: 按照以下 Markdown 结构返回：

  # GitLab Issue 每日执行结果
  > 已自动整理 N 个新增 Issue。

  ## 📅 今日新增 (24h)
  - [IID] [Title] (创建于: [Time])

  ## 🔥 建议优先关注 (P0/P1/Bugfix)
  - [IID] [Title] ([Labels])

  ## 📊 待完成分类统计
  - [Label Name]: [Count]

### 2. 仅生成汇总报告
- 运行命令: `python scripts/gitlab_api.py report`

### 3. 环境配置
确保设置以下变量：
- `GITLAB_TOKEN`: 个人访问令牌。
- `GITLAB_PROJECT_ID`: 项目路径 (e.g., `tango/ai-agents/some-repo`)。

## 注意事项
- 兼容 GitLab CE 13.12.15。
- 逻辑更新：所有规则匹配采用“叠加”模式。
