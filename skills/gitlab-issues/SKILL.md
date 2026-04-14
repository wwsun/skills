---
name: gitlab-issues
description: 整理 GitLab 指定仓库的 issues，支持设置优先级 (P0/P1/P2) 和类型 (bugfix/feature) 标签，自动指派开发者 (sunweiwei01/shenxiaohan)，并生成每日汇总报告。当用户提到“整理 GitLab issues”、“生成 GitLab 报告”、“指派 issue”或“GitLab 统计”时，务必使用此技能。即使仓库路径未明确，也应协助识别。
---

# GitLab Issue Manager

此技能旨在自动化整理 GitLab 仓库中的 Issues。它通过 Python 辅助脚本 `scripts/gitlab_api.py` 与 GitLab API 交互。

## 核心功能

1. **设置标签 (Labeling)**: 支持 `P0`, `P1`, `P2`, `bugfix`, `feature`。
2. **自动指派 (Assignment)**:
   - 默认逻辑存储在 `rules.json` 中。
   - 包含 `agent`/`studio` 指派给 `sunweiwei01`，`template`/`publish` 指派给 `shenxiaohan`。
   - **动态更新**: 如果用户提出新的指派要求，务必使用 `write_to_file` 工具更新 `rules.json` 以持久化这些偏好。
3. **每日汇总报告 (Daily Report)**: 统计新 Issue、已关闭、高优先级和停滞 Issue 信息。

## 配置与规则管理

该技能使用 `rules.json` 管理用户映射和自动化规则：
- `assignees`: 用户名到 GitLab ID 的映射。
- `assignment_rules`: 包含 `keywords`（关键字列表）和 `assignee`（负责人用户名）的规则。

当你收到类似“以后把所有的登录问题都指派给张三”的指令时：
1. 更新 `assignees`（如果张三的 ID 已知）。
2. 在 `assignment_rules` 中添加或修改规则。
3. 使用 `write_to_file` 保存。

## 准备工作

确保环境中设置了以下变量：
- `GITLAB_TOKEN`: GitLab 个人访问令牌 (PAT)。
- `GITLAB_URL`: GitLab 实例地址 (默认 `https://g.hz.netease.com`)。
- `GITLAB_PROJECT_ID`: 项目路径 (例如 `tango/ai-agents/campaign-ai-studio`)。

## 使用指南

### 1. 生成汇总报告
当用户要求“汇总报告”或“Issue 概况”时：
- 运行命令: `python scripts/gitlab_api.py report`
- 解析输出的 JSON，并按照以下结构转换成 Markdown 报表返回：
  # GitLab Issue 每日汇总录
  - **新增 Issue**: [Count]
  - **已关闭 Issue**: [Count]
  - **高优先级 (P0/P1)**: [Count]
  - **停滞 (14天未更新)**: [Count]
  - **标签分类统计**: [Category Breakdown]
  
  ## 高优先级待办
  - [IID] [Title] ([Labels])
  
  ## 停滞提醒
  - [IID] [Title] (最后更新: [Date])

### 2. 整理与指派 Issue
当用户要求“整理 issue”或指派新 issue 时：
1. **识别开发者 ID**: 
   - 逻辑：`agent`/`studio` -> `sunweiwei01`, `template`/`publish` -> `shenxiaohan`。
   - 如果需要，先获取用户 ID: `python scripts/gitlab_api.py user <username>`。
2. **更新 Issue**:
   - 命令模板: `python scripts/gitlab_api.py update <iid> <labels_comma_separated> <assignee_ids_comma_separated>`
   - 示例: `python scripts/gitlab_api.py update 105 "P1,bugfix" "123"`

## 注意事项
- **停滞定义**: 14天未更新。
- **GitLab 版本**: 兼容 GitLab Community Edition 13.12.15 (使用 `/api/v4`)。
- **权限**: 确保 `GITLAB_TOKEN` 有足够的读写权限。
