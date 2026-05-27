#!/bin/bash
# 收集指定时间范围内所有分支的 git 提交记录
# 用法: collect-commits.sh [week]
# 默认时间范围：前一天 18:00 到今天 18:00
# week: 输出本周（周一 18:00 到当前）的提交

set -euo pipefail

MODE="${1:-day}"

# 今天日期
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)

DAILY_SINCE="${YESTERDAY}T18:00:00"
DAILY_UNTIL="${TODAY}T18:00:00"

if [[ "$MODE" == "week" ]]; then
  echo "=== WEEKLY COMMITS ==="

  # 计算本周一的日期
  DOW=$(date +%u)  # 1=Monday, 7=Sunday
  DAYS_SINCE_MONDAY=$((DOW - 1))
  MONDAY=$(date -v-${DAYS_SINCE_MONDAY}d +%Y-%m-%d 2>/dev/null || date -d "${DAYS_SINCE_MONDAY} days ago" +%Y-%m-%d)
  WEEKLY_SINCE="${MONDAY}T18:00:00"

  # 如果今天是周一，从上周五 18:00 开始
  if [[ "$DAYS_SINCE_MONDAY" -eq 0 ]]; then
    LAST_FRIDAY=$(date -v-3d +%Y-%m-%d 2>/dev/null || date -d "3 days ago" +%Y-%m-%d)
    WEEKLY_SINCE="${LAST_FRIDAY}T18:00:00"
  fi

  echo "TIME_RANGE: ${WEEKLY_SINCE} ~ ${DAILY_UNTIL}"
  echo "---"

  git log --all \
    --after="$WEEKLY_SINCE" --before="$DAILY_UNTIL" \
    --format="COMMIT|%H|%an|%ae|%ad|%s|%D" \
    --date=iso-strict \
    2>/dev/null || echo "NO_COMMITS"
else
  echo "=== DAILY COMMITS ==="
  echo "TIME_RANGE: ${DAILY_SINCE} ~ ${DAILY_UNTIL}"
  echo "---"

  git log --all \
    --after="$DAILY_SINCE" --before="$DAILY_UNTIL" \
    --format="COMMIT|%H|%an|%ae|%ad|%s|%D" \
    --date=iso-strict \
    2>/dev/null || echo "NO_COMMITS"
fi
