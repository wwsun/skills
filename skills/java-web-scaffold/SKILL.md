---
name: java-web-scaffold
description: 初始化 java fullstack 工程（Java 21 + Spring Boot 3 + React 19 + MySQL + Redis）。只在用户明确输入 /java-web-scaffold 时才使用此技能，不要根据任务内容自动推断是否使用此 skill。
---

# java-web-scaffold

## 激活条件（必读）

**本 skill 仅在用户明确要求时使用。**
如果你是因为任务内容匹配而自动读取此文件，请停止并忽略本 skill。

## 技能简介

将 `~/projj/github.com/wwsun/java-web-starter` 模板复制并定制化为新项目。

模板技术栈：Java 21 + Spring Boot 3.2 + MyBatis-Plus + Spring Security + JWT + React 19 + Vite + TailwindCSS + shadcn/ui

---

## 工作流

### 第一步：一次性收集所有信息

**一轮对话**问完下面所有内容，不要分开多轮：

| 参数 | 说明 | 示例 |
|------|------|------|
| 项目名（kebab-case） | 目录名 / Maven artifactId | `meeting-room` |
| Maven groupId | Java 包名前缀 | `com.example` |
| 项目描述（可选） | 一句话说明用途 | `会议室预订管理系统` |
| 目标父目录 | 项目创建在哪里 | `~/projects` |

在询问时告诉用户会自动推导的值，避免他们困惑：
- **Java 包名**：`{groupId}.{项目名去掉连字符小写}` → 如 `com.example.meetingroom`
- **数据库名**：`{项目名连字符换下划线}_db` → 如 `meeting_room_db`
- **前端显示名**：项目名转 Title Case → 如 `Meeting Room`
- **项目目录**：`{目标目录}/{项目名}` → 如 `~/projects/meeting-room`

### 第二步：执行脚手架脚本

用户确认后运行（将 `SKILL_DIR` 替换为本 skill 文件所在目录）：

```bash
bash ~/.agents/skills/java-web-scaffold/scripts/scaffold.sh \
  --name "PROJECT_NAME" \
  --group "GROUP_ID" \
  --desc "DESCRIPTION" \
  --target "TARGET_DIR"
```

脚本会自动完成：
1. 复制模板（`rsync -a` 保留 `.claude/skills/` 软链接结构）
2. **合并** `.gitignore`：若目标已有，追加模板规则并去重；否则直接使用模板
3. 重命名 Java 包目录结构
4. 替换所有文件中的包名、项目名、数据库名，包括：
   - 后端：pom.xml、application.yml/dev/prod、logback-spring.xml、Java 源码
   - 前端：package.json、index.html 标题、MainLayout.tsx 侧边栏名称
   - 其他：docker-compose.yml、doc/sql/init.sql、scripts/api.sh
5. 清理 `.claude/settings.local.json` 中的旧路径引用
6. 生成 `.env`（自动生成 JWT 密钥）
7. 初始化/追加 git commit（支持已有 git repo）

> **两种模式均支持**：
> - 目标目录不存在 → 全新创建
> - 目标目录已存在（如已从 GitHub clone）→ 合并模板文件

### 第三步：汇报结果

脚本成功后，向用户展示：

1. **项目路径**
2. **关键替换确认**：
   - 包名：`com.music163.starter` → `{new_package}`
   - 数据库：`starter_db` → `{db_name}`
   - 前端标题：`frontend` → `{project_name}`
   - 侧边栏名称：`WebStarter` → `{display_name}`（自动由项目名转 Title Case）
3. **复制可用的快速启动命令**

---

## 快速启动模板（完成后发给用户）

```
✅ 项目初始化完成！

cd {PROJECT_DIR}

# 本地开发模式（推荐）
make dev-db          # 启动 MySQL（dev 环境无需 Redis，使用内存缓存）
make backend         # 新终端：启动后端（需 sdkman）
make frontend        # 新终端：启动前端

前端：  http://localhost:5173
API 文档：http://localhost:8080/doc.html
默认账号：admin / admin123

# 全栈 Docker 模式（含 Redis）
make up              # 一键构建并启动所有服务（首次约 10~20 分钟）
# 启动后访问 http://localhost:8090

添加业务模块：参考 doc/how-to-add-module.md（7 步流程）
```

---

## 错误处理

| 错误 | 处理方式 |
|------|----------|
| 目标目录已存在 | 直接 rsync 合并（支持已 clone 的 repo）；如有冲突告知用户 |
| 模板目录不存在 | 提示检查 `~/projj/github.com/wwsun/java-web-starter` 是否存在 |
| openssl 不可用 | 让用户手动运行 `openssl rand -hex 32` 并填入 `.env` 的 `JWT_SECRET` |

---

## 背景：模板结构

模板包含以下开箱即用的模块（新增业务模块时参考 `user/` 或 `role/` 的结构）：

- **auth** — JWT 双令牌认证（access 1h + refresh 7d）
- **user** — 用户管理 CRUD（`UserListPage` 为前端 CRUD 参考实现）
- **role** — 角色权限 RBAC
- **common** — 全局异常处理、限流、请求日志 AOP、统一响应格式

文档：`doc/architecture.md`、`doc/how-to-add-module.md`、`doc/api-convention.md`
