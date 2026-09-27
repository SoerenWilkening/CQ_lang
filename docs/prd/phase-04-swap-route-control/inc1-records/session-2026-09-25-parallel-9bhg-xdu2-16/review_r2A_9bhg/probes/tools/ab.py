#!/usr/bin/env python3
# ab.py <bin> <list> <out.tsv> [env KEY=VAL]: exit, sha256(stdout), sha256(stderr), first error line
import sys, subprocess, hashlib, concurrent.futures as cf, os
b, lst, out = sys.argv[1:4]
env = dict(os.environ)
for kv in sys.argv[4:]:
    k, v = kv.split("=", 1); env[k] = v
files = [l.strip() for l in open(lst) if l.strip()]
def one(f):
    r = subprocess.run([b, "-passes=cq-lowering", "-S", f, "-o", "-"], capture_output=True, env=env)
    err = r.stderr.decode(errors="ignore")
    e1 = next((l.split("error: ")[-1] for l in err.splitlines() if "error: " in l), "")
    if not e1 and r.returncode not in (0, 1):
        e1 = "CRASH:" + (err.strip().splitlines() or ["?"])[0][:100]
    return f, r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16], hashlib.sha256(r.stderr).hexdigest()[:16], e1.replace("\t", " ")
with cf.ThreadPoolExecutor(10) as ex, open(out, "w") as o:
    for f, rc, so, se, e1 in ex.map(one, files):
        o.write(f"{os.path.basename(f)}\t{rc}\t{so}\t{se}\t{e1}\n")
print(f"{len(files)} modules -> {out}")
