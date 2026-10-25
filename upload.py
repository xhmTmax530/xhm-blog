import json,urllib.request,io,tarfile,os
pt="http://192.168.31.183:9000"
tok=json.loads(urllib.request.urlopen(urllib.request.Request(f"{pt}/api/auth",
  data=json.dumps({"Username":"admin","Password":"Nsfocus@2027xhmljj"}).encode(),
  headers={"Content-Type":"application/json"})).read())["jwt"]
def api(p,d=None,m="GET",raw=False):
    r=urllib.request.Request(f"{pt}/api/endpoints/3/docker{p}",data=d,method=m)
    r.add_header("Authorization",f"Bearer {tok}")
    r.add_header("Content-Type","application/x-tar" if raw else "application/json")
    return urllib.request.urlopen(r,timeout=180)
for c in json.load(api("/containers/json?all=1")):
    if c["Names"][0].startswith("/blogseed"):
        api("/containers/%s?force=1&v=1" % c["Id"], m="DELETE")
cid=json.load(api("/containers/create?name=blogseed",json.dumps({
  "Image":"docker.m.daocloud.io/library/node:22-alpine","Cmd":["sleep","90"],
  "HostConfig":{"Binds":["blog_public:/out"]}}).encode(),"POST"))["Id"]
api("/containers/%s/start" % cid, b"", "POST")
src=io.BytesIO(open("/tmp/pub.tgz","rb").read()); buf=io.BytesIO()
out=tarfile.open(fileobj=buf,mode="w")
with tarfile.open(fileobj=src,mode="r:gz") as t:
    for m in t.getmembers():
        m.name=m.name.lstrip("./")
        if not m.name: continue
        out.addfile(m, t.extractfile(m) if m.isfile() else None)
out.close()
api("/containers/%s/archive?path=/out" % cid, buf.getvalue(), "PUT", raw=True)
api("/containers/%s?force=1&v=1" % cid, m="DELETE")
print("deployed", os.path.getsize("/tmp/pub.tgz"), "bytes")
