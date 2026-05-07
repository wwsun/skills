---
name: move-skill
description: 将 .Codex/skills 中的技能迁移到 .agents/skills 目录，并在原位置创建软链接，实现跨工具共享。当用户说"把某个 skill 移动到 agents"、"迁移技能"、"共享 skill 到 .agents"、"把 skill 放到 agents 目录"、"sync skill to agents"时使用此技能。适合将本地专属的 Codex 技能升级为跨工具可用的共享技能。
---

# 迁移 Skill 到 .agents/skills

将技能从 `.Codex/skills/` 迁移到 `.agents/skills/`，并在原位置建立软链接，使技能可被多个 AI 工具共享。

## 第一步：确认范围（全局 vs 项目）

先询问用户：

> 请问要迁移的是**全局技能**还是**项目内技能**？
> - **全局**：`~/.Codex/skills/` → `~/.agents/skills/`（影响所有项目）
> - **项目内**：`./.Codex/skills/` → `./.agents/skills/`（仅当前项目）

根据回答确定源目录和目标目录：

| 类型 | 源目录 | 目标目录 |
|------|--------|----------|
| 全局 | `~/.Codex/skills/` | `~/.agents/skills/` |
| 项目内 | `./.Codex/skills/` | `./.agents/skills/` |

## 第二步：列出可迁移的技能

列出源目录中**尚未是软链接**的技能（已经是软链接的说明已经迁移过了）：

```bash
# 全局
for d in ~/.Codex/skills/*/; do
  name=$(basename "$d")
  if [ ! -L "$d" ]; then
    echo "$name"
  fi
done

# 项目内
for d in ./.Codex/skills/*/; do
  name=$(basename "$d")
  if [ ! -L "$d" ]; then
    echo "$name"
  fi
done
```

将结果展示给用户，询问：

> 以下技能尚未迁移，请告诉我要迁移哪个（或哪些）：
> - skill-a
> - skill-b
> - ...

## 第三步：执行迁移（需用户确认）

用户指定技能名后，**展示操作计划并请用户确认**，然后执行：

### 操作步骤

假设要迁移 `<skill-name>`，源目录为 `<src_base>`，目标目录为 `<dst_base>`：

```bash
# 1. 确保目标父目录存在
mkdir -p <dst_base>

# 2. 检查目标位置是否已有同名目录（避免覆盖）
if [ -e "<dst_base>/<skill-name>" ]; then
  echo "错误：目标位置已存在 <dst_base>/<skill-name>，请手动处理后再试"
  exit 1
fi

# 3. 移动技能目录
mv <src_base>/<skill-name> <dst_base>/<skill-name>

# 4. 在原位置创建软链接
# 注意：软链接使用相对路径，便于目录整体移动时仍然有效
# 全局：~/.Codex/skills/<skill-name> -> ../../.agents/skills/<skill-name>
# 项目内：./.Codex/skills/<skill-name> -> ../../.agents/skills/<skill-name>
ln -s ../../.agents/skills/<skill-name> <src_base>/<skill-name>

# 5. 验证软链接是否正确
ls -la <src_base>/<skill-name>
```

### 验证结果

迁移完成后确认：

```bash
# 确认软链接存在且指向正确
ls -la <src_base>/<skill-name>
# 应输出类似：lrwxr-xr-x  skill-name -> ../../.agents/skills/skill-name

# 确认技能内容可访问
ls <dst_base>/<skill-name>/
# 应看到 SKILL.md 等文件
```

## 注意事项

- **软链接使用相对路径** `../../.agents/skills/<skill-name>`，这样即使整个 home 目录被移动，链接依然有效
- 如果目标位置已存在同名目录（说明 `.agents/skills/` 中已有该技能），**不要覆盖**，告知用户手动处理
- 迁移后，Codex 和其他支持 `.agents/skills/` 的工具都能使用该技能
- 如果用户想同时迁移多个技能，逐个执行即可，每次迁移前都确认
