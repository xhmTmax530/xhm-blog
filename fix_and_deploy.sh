#!/usr/bin/env bash
set -uo pipefail
cd /opt/blogbuild || exit 1
git fetch -q origin main || { echo "fetch failed"; exit 1; }
git reset -q --hard origin/main
python3 - <<'PY'
import re,glob
fixed=0
for f in glob.glob("content/**/*.md",recursive=True):
    s=open(f,encoding="utf-8").read()
    if not s.startswith("---"): continue
    parts=s.split("---",2)
    if len(parts)<3: continue
    fm=parts[1].splitlines(); out=[]; i=0; seen=False
    while i<len(fm):
        line=fm[i]
        if re.match(r"^categories:",line):
            seen=True; out.append('categories: ["技术"]'); i+=1
            while i<len(fm) and re.match(r"^\s*-\s",fm[i]): i+=1
            continue
        out.append(line); i+=1
    if not seen: out.append('categories: ["技术"]')
    new="---\n"+"\n".join(out)+"\n---"+parts[2]
    if new!=s: open(f,"w",encoding="utf-8").write(new); fixed+=1
print("normalized",fixed)
PY
rm -f "content/posts/测试图片上传.md" static/uploads/test-upload.png
rm -rf /tmp/verify
if ! /usr/local/bin/hugo --minify -d /tmp/verify >/tmp/hugo.log 2>&1; then
  echo "BUILD FAILED"; tail -6 /tmp/hugo.log; exit 1
fi
git add -A
git -c user.email=blog@local -c user.name=blog commit -qm "fix: 统一分类为技术、清理测试内容" || echo "(no changes)"
for i in 1 2 3; do git push -q origin main && { echo "pushed"; break; } || sleep 5; done
rm -rf public && cp -r /tmp/verify public
tar -C public -czf /tmp/pub.tgz .
python3 /opt/blogbuild/upload.py && git rev-parse HEAD > .last_deployed && echo "deployed $(git rev-parse --short HEAD)"
