#!/usr/bin/env bash
# scaffold.sh — 基于 java-web-starter 初始化新全栈项目
# Usage: bash scaffold.sh --name <name> --group <groupId> [--desc <desc>] --target <dir>
#
# 支持两种模式：
#   a) 目标目录不存在 → 全新创建
#   b) 目标目录已存在（如已 git clone）→ 合并模板文件（.gitignore 做去重合并）

set -euo pipefail

TEMPLATE_DIR="$HOME/projj/github.com/wwsun/java-web-starter"

# ---------- 解析参数 ----------
PROJECT_NAME=""
GROUP_ID=""
DESCRIPTION=""
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --name)   PROJECT_NAME="$2"; shift 2 ;;
    --group)  GROUP_ID="$2";     shift 2 ;;
    --desc)   DESCRIPTION="$2";  shift 2 ;;
    --target) TARGET_DIR="$2";   shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_NAME" || -z "$GROUP_ID" || -z "$TARGET_DIR" ]]; then
  echo "用法: bash scaffold.sh --name <name> --group <groupId> [--desc <desc>] --target <dir>"
  exit 1
fi

# ---------- 推导值 ----------
# 包名：去掉连字符后小写，如 meeting-room -> meetingroom
ARTIFACT=$(echo "$PROJECT_NAME" | tr -d '-' | tr '[:upper:]' '[:lower:]')
NEW_PACKAGE="${GROUP_ID}.${ARTIFACT}"
NEW_PACKAGE_PATH="${NEW_PACKAGE//.//}"

# 展示名：连字符转空格后首字母大写，如 meeting-room -> Meeting Room
DISPLAY_NAME=$(echo "$PROJECT_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')

OLD_PACKAGE="com.music163.starter"
OLD_PACKAGE_PATH="com/music163/starter"

# 数据库名：连字符换下划线
DB_NAME="${PROJECT_NAME//-/_}_db"

# 展开 ~ 符号
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
PROJECT_DIR="${TARGET_DIR%/}/${PROJECT_NAME}"

echo "=============================="
echo "  java-web-scaffold"
echo "=============================="
echo "  项目名称:  $PROJECT_NAME"
echo "  显示名称:  $DISPLAY_NAME"
echo "  包名:      $NEW_PACKAGE"
echo "  数据库:    $DB_NAME"
echo "  目标路径:  $PROJECT_DIR"
echo "=============================="
echo ""

# ---------- 前置检查 ----------
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "❌ 模板目录不存在: $TEMPLATE_DIR"
  exit 1
fi

# ---------- [1/7] 复制/合并模板（rsync 保留软链接） ----------
echo "[1/7] 复制模板（保留软链接）..."

# rsync -a 保留软链接（不展开），--no-g --no-o 避免权限问题
# --filter=':- .gitignore' 让 rsync 自动跳过模板 .gitignore 中列出的文件
# （如 backend/target/、frontend/node_modules/、frontend/dist/ 等）
rsync -a --no-g --no-o \
  --filter=':- .gitignore' \
  --exclude='.git' \
  --exclude='.gitignore' \
  --exclude='.env' \
  "$TEMPLATE_DIR/" "$PROJECT_DIR/"

# ---------- [2/7] 合并 .gitignore ----------
echo "[2/7] 合并 .gitignore..."

TEMPLATE_GITIGNORE="$TEMPLATE_DIR/.gitignore"
TARGET_GITIGNORE="$PROJECT_DIR/.gitignore"

if [[ -f "$TARGET_GITIGNORE" ]]; then
  # 已有 .gitignore（如从 GitHub clone）→ 追加模板内容并去重
  echo "" >> "$TARGET_GITIGNORE"
  echo "# ---- merged from java-web-starter ----" >> "$TARGET_GITIGNORE"
  # 只追加模板中有而目标中没有的行（跳过空行和注释行的去重）
  while IFS= read -r line; do
    if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
      echo "$line" >> "$TARGET_GITIGNORE"
    elif ! grep -qxF "$line" "$TARGET_GITIGNORE" 2>/dev/null; then
      echo "$line" >> "$TARGET_GITIGNORE"
    fi
  done < "$TEMPLATE_GITIGNORE"
  echo "   合并到已有的 .gitignore"
else
  # 全新目录 → 直接复制
  cp "$TEMPLATE_GITIGNORE" "$TARGET_GITIGNORE"
  echo "   使用模板 .gitignore"
fi

# ---------- [3/7] 重命名 Java 包目录 ----------
echo "[3/7] 重命名 Java 包目录..."
OLD_JAVA_PATH="$PROJECT_DIR/backend/src/main/java/$OLD_PACKAGE_PATH"
NEW_JAVA_PATH="$PROJECT_DIR/backend/src/main/java/$NEW_PACKAGE_PATH"

mkdir -p "$(dirname "$NEW_JAVA_PATH")"
mv "$OLD_JAVA_PATH" "$NEW_JAVA_PATH"

# 清理遗留的空父目录
find "$PROJECT_DIR/backend/src/main/java" -type d -empty -delete 2>/dev/null || true

# ---------- [4/7] 替换包名和项目标识 ----------
echo "[4/7] 替换包名和项目标识（后端 + 前端）..."

# Java 源码：替换包声明和 import
find "$PROJECT_DIR/backend/src" -name "*.java" -exec \
  sed -i '' "s|${OLD_PACKAGE}|${NEW_PACKAGE}|g" {} \;

# pom.xml
sed -i '' "s|<groupId>com.music163</groupId>|<groupId>${GROUP_ID}</groupId>|g" \
  "$PROJECT_DIR/backend/pom.xml"
sed -i '' "s|<artifactId>starter</artifactId>|<artifactId>${PROJECT_NAME}</artifactId>|g" \
  "$PROJECT_DIR/backend/pom.xml"
sed -i '' "s|<name>java-web-starter</name>|<name>${PROJECT_NAME}</name>|g" \
  "$PROJECT_DIR/backend/pom.xml"
if [[ -n "$DESCRIPTION" ]]; then
  sed -i '' "s|<description>.*</description>|<description>${DESCRIPTION}</description>|" \
    "$PROJECT_DIR/backend/pom.xml"
fi

# application.yml：应用名
sed -i '' "s|name: java-web-starter|name: ${PROJECT_NAME}|g" \
  "$PROJECT_DIR/backend/src/main/resources/application.yml"

# application-dev.yml：数据库名、日志包名
sed -i '' "s|starter_db|${DB_NAME}|g" \
  "$PROJECT_DIR/backend/src/main/resources/application-dev.yml"
sed -i '' "s|${OLD_PACKAGE}: DEBUG|${NEW_PACKAGE}: DEBUG|g" \
  "$PROJECT_DIR/backend/src/main/resources/application-dev.yml"

# application-prod.yml：数据库名、日志包名、Redis key prefix
sed -i '' "s|starter_db|${DB_NAME}|g" \
  "$PROJECT_DIR/backend/src/main/resources/application-prod.yml"
sed -i '' "s|${OLD_PACKAGE}: INFO|${NEW_PACKAGE}: INFO|g" \
  "$PROJECT_DIR/backend/src/main/resources/application-prod.yml"
sed -i '' "s|key-prefix: \"starter:\"|key-prefix: \"${PROJECT_NAME}:\"|g" \
  "$PROJECT_DIR/backend/src/main/resources/application-prod.yml"

# docker-compose.yml：容器名、数据库名、网络名
for keyword in mysql redis nginx backend frontend; do
  sed -i '' "s|starter-${keyword}|${PROJECT_NAME}-${keyword}|g" \
    "$PROJECT_DIR/docker-compose.yml"
done
sed -i '' "s|starter_db|${DB_NAME}|g" "$PROJECT_DIR/docker-compose.yml"
sed -i '' "s|starter-network|${PROJECT_NAME}-network|g" "$PROJECT_DIR/docker-compose.yml"

# doc/sql/init.sql：数据库名
sed -i '' "s|starter_db|${DB_NAME}|g" "$PROJECT_DIR/doc/sql/init.sql"

# frontend/package.json：项目名
sed -i '' "s|\"name\": \"frontend\"|\"name\": \"${PROJECT_NAME}\"|g" \
  "$PROJECT_DIR/frontend/package.json"

# scripts/api.sh：token 缓存目录名
sed -i '' "s|/tmp/.starter-api|/tmp/.${PROJECT_NAME}-api|g" \
  "$PROJECT_DIR/scripts/api.sh"

# logback-spring.xml：应用名
sed -i '' "s|value=\"starter\"|value=\"${PROJECT_NAME}\"|g" \
  "$PROJECT_DIR/backend/src/main/resources/logback-spring.xml"

# frontend/index.html：页面标题
sed -i '' "s|<title>frontend</title>|<title>${PROJECT_NAME}</title>|g" \
  "$PROJECT_DIR/frontend/index.html"

# frontend/src/layouts/MainLayout.tsx：侧边栏名称、breadcrumb 项目名
sed -i '' "s|WebStarter|${DISPLAY_NAME}|g" \
  "$PROJECT_DIR/frontend/src/layouts/MainLayout.tsx"
sed -i '' "s|starter-baseline|${PROJECT_NAME}|g" \
  "$PROJECT_DIR/frontend/src/layouts/MainLayout.tsx"

# ---------- [5/7] 清理 Claude 配置 ----------
echo "[5/7] 更新 Claude 配置..."

SETTINGS_FILE="$PROJECT_DIR/.claude/settings.local.json"
if [[ -f "$SETTINGS_FILE" ]]; then
  # 替换所有旧项目绝对路径为新路径
  TEMPLATE_PATH_ESCAPED="${TEMPLATE_DIR//\//\\/}"
  PROJECT_PATH_ESCAPED="${PROJECT_DIR//\//\\/}"
  sed -i '' "s|${TEMPLATE_DIR}|${PROJECT_DIR}|g" "$SETTINGS_FILE"
  # 替换旧容器名引用（如 starter-mysql → project-mysql）
  sed -i '' "s|starter-mysql|${PROJECT_NAME}-mysql|g" "$SETTINGS_FILE"
fi

# ---------- [6/7] 创建 .env ----------
echo "[6/7] 创建 .env 文件..."

if [[ ! -f "$PROJECT_DIR/.env" ]]; then
  cp "$TEMPLATE_DIR/.env.example" "$PROJECT_DIR/.env"
  JWT_SECRET=$(openssl rand -hex 32)
  sed -i '' "s|change-me-strong-password|dev-local-password|g" "$PROJECT_DIR/.env"
  sed -i '' "s|change-me-run-openssl-rand-hex-32|${JWT_SECRET}|g" "$PROJECT_DIR/.env"
  echo "   .env 已创建（JWT_SECRET 已随机生成）"
else
  echo "   .env 已存在，跳过"
fi

# ---------- [7/7] 初始化/更新 Git ----------
echo "[7/7] Git..."
cd "$PROJECT_DIR"

if [[ -d ".git" ]]; then
  # 已有 git 仓库（如从 GitHub clone）→ 新增提交
  git add .
  git commit -q -m "chore: scaffold from java-web-starter" 2>/dev/null || echo "   无变更需提交"
else
  # 全新 → init
  git init -q
  git add .
  git commit -q -m "chore: initialize project from java-web-starter"
fi

# ---------- 完成 ----------
echo ""
echo "✅ 项目已就绪：$PROJECT_DIR"
echo ""
echo "下一步操作："
echo ""
echo "  cd $PROJECT_DIR"
echo ""
echo "  # 启动依赖服务"
echo "  docker compose up -d mysql redis"
echo ""
echo "  # 启动后端"
echo "  cd backend && mvn spring-boot:run"
echo ""
echo "  # 启动前端（新终端）"
echo "  cd $PROJECT_DIR/frontend && npm install && npm run dev"
echo ""
echo "  前端地址：    http://localhost:5173"
echo "  API 文档：    http://localhost:8080/doc.html"
echo "  默认账号：    admin / admin123"
echo ""
echo "  新增业务模块：参考 doc/how-to-add-module.md"
