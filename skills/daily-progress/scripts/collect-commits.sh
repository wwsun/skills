#!/bin/bash
# 收集指定时间范围内所有分支的 git 提交记录
# 用法: collect-commits.sh [--weekly]
# 默认时间范围：前一天 17:00 到今天 17:00
# --weekly: 同时输出本周（周一 17:00 到当前）的提交

set -euo pipefail

WEEKLY=false
if [[ "${1:-}" == "--weekly" ]]; then
  WEEKLY=true
fi

# 今天日期
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)

DAILY_SINCE="${YESTERDAY}T17:00:00"
DAILY_UNTIL="${TODAY}T17:00:00"

echo "=== DAILY COMMITS ==="
echo "TIME_RANGE: ${DAILY_SINCE} ~ ${DAILY_UNTIL}"
echo "---"

# 收集日报提交（所有分支，所有用户）
git log --all \
  --after="$DAILY_SINCE" --before="$DAILY_UNTIL" \
  --format="COMMIT|%H|%an|%ae|%ad|%s|%D" \
  --date=iso-strict \
  2>/dev/null || echo "NO_COMMITS"

if [[ "$WEEKLY" == "true" ]]; then
  echo ""
  echo "=== WEEKLY COMMITS ==="

  # 计算本周一的日期
  DOW=$(date +%u)  # 1=Monday, 7=Sunday
  DAYS_SINCE_MONDAY=$((DOW - 1))
  MONDAY=$(date -v-${DAYS_SINCE_MONDAY}d +%Y-%m-%d 2>/dev/null || date -d "last monday" +%Y-%m-%d)
  WEEKLY_SINCE="${MONDAY}T17:00:00"

  # 如果周一就是今天，从上周五 17:00 开始
  if [[ "$DAYS_SINCE_MONDAY" -eq 0 ]]; then
    LAST_FRIDAY=$(date -v-3d +%Y-%m-%d 2>/dev/null || date -d "last friday" +%Y-%m-%d)
    WEEKLY_SINCE="${LAST_FRIDAY}T17:00:00"
  fi

  echo "TIME_RANGE: ${WEEKLY_SINCE} ~ ${DAILY_UNTIL}"
  echo "---"

  git log --all \
    --after="$WEEKLY_SINCE" --before="$DAILY_UNTIL" \
    --format="COMMIT|%H|%an|%ae|%ad|%s|%D" \
    --date=iso-strict \
    2>/dev/null || echo "NO_COMMITS"
fi
