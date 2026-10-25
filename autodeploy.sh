#!/usr/bin/env bash
# 自动部署：GitHub 有变更 → CT107 构建 → 推送到 N1（CT107 有 GitHub 出口）
set -uo pipefail
cd /opt/blogbuild || exit 1
PT=http://192.168.31.183:9000
git fetch -q origin main || exit 0
LOCAL=$(git rev-parse HEAD); REMOTE=$(git rev-parse origin/main)
[ "$LOCAL" = "$REMOTE" ] && exit 0
git reset -q --hard origin/main
rm -rf public && /usr/local/bin/hugo --minify -d public >/dev/null 2>&1 || { echo "build failed"; exit 1; }
tar -C public -czf /tmp/pub.tgz .
python3 /opt/blogbuild/upload.py
