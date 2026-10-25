#!/usr/bin/env bash
# 自动部署：GitHub 有新的提交（且未部署过）→ 构建 → 推送 N1
set -uo pipefail
cd /opt/blogbuild || exit 1
LOG=/var/log/blog-autodeploy.log
ts(){ date '+%F %T'; }
git fetch -q origin main 2>/dev/null || true
if git rev-parse --verify -q origin/main >/dev/null 2>&1; then
  [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ] && git reset -q --hard origin/main
fi
H=$(git rev-parse HEAD)
LAST=$(cat .last_deployed 2>/dev/null || echo none)
if [ "$H" = "$LAST" ]; then exit 0; fi
echo "$(ts) deploying $H" >> "$LOG"
rm -rf public
if ! /usr/local/bin/hugo --minify -d public >/dev/null 2>&1; then
  echo "$(ts) build FAILED $H" >> "$LOG"; exit 1
fi
tar -C public -czf /tmp/pub.tgz . || { echo "$(ts) tar FAILED" >> "$LOG"; exit 1; }
if python3 /opt/blogbuild/upload.py >>"$LOG" 2>&1; then
  echo "$H" > .last_deployed
  echo "$(ts) deployed $H" >> "$LOG"
else
  echo "$(ts) upload FAILED $H" >> "$LOG"; exit 1
fi
