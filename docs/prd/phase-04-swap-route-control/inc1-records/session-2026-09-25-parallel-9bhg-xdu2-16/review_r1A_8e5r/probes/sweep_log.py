#!/usr/bin/env python3
"""sweep_log.py BIN MODE LISTFILE OUTDIR [-j N]
Runs BIN -passes=cq-lowering on every module of LISTFILE under CQ_OPT_DEBUG_ALLOC=MODE
(MODE 'system' = unset), with CQ_SCRUB_LOG=OUTDIR/logs/<i>.log. Writes OUTDIR/results.tsv:
index, module, rc, sha256(stdout)[:12], first error line, number of log events.
Prints the DENOMINATOR first and a class count (rc) at the end."""
import hashlib, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
b, mode, lst, out = sys.argv[1:5]
j = int(sys.argv[6]) if len(sys.argv) > 6 and sys.argv[5] == "-j" else 8
files = [l.strip() for l in open(lst) if l.strip()]
os.makedirs(f"{out}/logs", exist_ok=True)
print(f"denominator: {len(files)} modules  BIN={b} MODE={mode}", flush=True)
def one(t):
    i, f = t
    env = dict(os.environ)
    env.pop("CQ_OPT_DEBUG_ALLOC", None)
    if mode != "system":
        env["CQ_OPT_DEBUG_ALLOC"] = mode
    lg = f"{out}/logs/{i}.log"
    if os.path.exists(lg):
        os.remove(lg)
    env["CQ_SCRUB_LOG"] = lg
    r = subprocess.run([b, "-passes=cq-lowering", "-S", f, "-o", "-"], env=env, capture_output=True)
    h = hashlib.sha256(r.stdout).hexdigest()[:12]
    err = ""
    for line in r.stderr.decode("utf-8", "replace").splitlines():
        if "error:" in line:
            err = line.split("error:", 1)[1].strip()[:160]
            break
    n = sum(1 for _ in open(lg)) if os.path.exists(lg) else 0
    return (i, f, r.returncode, h, err, n)
with ThreadPoolExecutor(j) as ex:
    res = list(ex.map(one, list(enumerate(files))))
rcs = {}
with open(f"{out}/results.tsv", "w") as o:
    for i, f, rc, h, err, n in res:
        rcs[rc] = rcs.get(rc, 0) + 1
        o.write(f"{i}\t{f}\t{rc}\t{h}\t{err}\t{n}\n")
print("rc counts:", rcs, "total", len(res))
print("modules with log events:", sum(1 for r in res if r[5]))
