#!/usr/bin/env python3
"""ab_full.py — review r1B_8e5r: oracle-vs-subject A/B comparing rc, FULL stdout
and FULL stderr (warnings included; ab.py kept only the first 'error:' line).
A NULL control (A vs A) is run first over the same list; its mover count is the
instrument's noise floor. usage: ab_full.py A B list [-j N]"""
import hashlib, os, subprocess, sys, collections
from concurrent.futures import ThreadPoolExecutor
def run(b, f):
    env = dict(os.environ); env.pop("CQ_OPT_DEBUG_ALLOC", None); env.pop("DYLD_INSERT_LIBRARIES", None)
    r = subprocess.run([b, "-passes=cq-lowering", "-S", f, "-o", "-"], env=env, capture_output=True)
    return r.returncode, hashlib.sha256(r.stdout).hexdigest()[:12], hashlib.sha256(r.stderr).hexdigest()[:12], r.stderr.decode(errors="replace")
def cls(ra, rb):
    if ra[:3] == rb[:3]: return "same"
    if ra[0] != rb[0]: return "RC"
    if ra[1] != rb[1]: return "STDOUT"
    return "STDERR_ONLY"
def sweep(A, B, files, j):
    with ThreadPoolExecutor(j) as ex:
        res = list(ex.map(lambda f: (f, run(A, f), run(B, f)), files))
    c = collections.Counter(cls(a, b) for _, a, b in res)
    return c, [(f, cls(a, b), a, b) for f, a, b in res if cls(a, b) != "same"]
A, B, lst = sys.argv[1:4]; j = int(sys.argv[5]) if len(sys.argv) > 5 else 5
files = [l.strip() for l in open(lst) if l.strip()]
nc, nm = sweep(A, A, files, j)
print(f"NULL (A vs A): denominator {len(files)} {dict(nc)}")
for f, c, a, b in nm: print("  null-mover", c, os.path.basename(f))
c, movers = sweep(A, B, files, j)
print(f"A vs B: denominator {len(files)} {dict(c)}")
for f, k, a, b in movers:
    print(f"  {k}\t{os.path.basename(f)}\trc {a[0]}->{b[0]}")
    if k == "STDERR_ONLY":
        import difflib
        for l in list(difflib.unified_diff(a[3].splitlines(), b[3].splitlines(), lineterm="", n=0))[:8]: print("     ", l[:200])
