#!/usr/bin/env python3
"""ab3.py — r3 reviewer's OWN A/B harness (independent of the implementer's ab.py).
usage: ab3.py BIN_A BIN_B LIST OUT.tsv [--env-a K=V] [--env-b K=V] [-j N] [--perturb BASENAME]
Per module: rc, sha256(stdout), sha256(FULL stderr) for each binary. A 0-byte or
missing input ABORTS the run (the empty-module ACCEPT trap). Classes:
  same | A2D | D2A | STREAM (both rc0, stdout differs) | STRING (both rc!=0, stderr differs)
  | WARN (both rc0, same stdout, stderr differs) | CRASH (rc not in {0,1}).
--perturb makes B's stdout hash for BASENAME wrong: the comparator's POSITIVE control.
Prints the DENOMINATOR first."""
import hashlib, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

args = sys.argv[1:]
def opt(flag, default=None, multi=False):
    vals = []
    while flag in args:
        i = args.index(flag); vals.append(args[i + 1]); del args[i:i + 2]
    return vals if multi else (vals[-1] if vals else default)
env_a = opt("--env-a", multi=True); env_b = opt("--env-b", multi=True)
J = int(opt("-j", "8")); perturb = opt("--perturb")
A, B, LST, OUT = args
files = [l.strip() for l in open(LST) if l.strip()]
for f in files:
    if not os.path.isfile(f) or os.path.getsize(f) == 0:
        sys.exit(f"ABORT: empty or missing input {f}")

def mkenv(extra):
    e = dict(os.environ)
    for k in ("CQ_OPT_DEBUG_ALLOC", "DYLD_INSERT_LIBRARIES", "RB8_ALLOC"):
        e.pop(k, None)
    for kv in extra:
        k, v = kv.split("=", 1); e[k] = v
    return e
EA, EB = mkenv(env_a), mkenv(env_b)

def run(b, env, f):
    r = subprocess.run([b, "-passes=cq-lowering", "-S", f, "-o", "-"], env=env, capture_output=True)
    return (r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16],
            hashlib.sha256(r.stderr).hexdigest()[:16],
            next((l.split("error:", 1)[1].strip()[:120] for l in r.stderr.decode("utf-8", "replace").splitlines() if "error:" in l), ""))

def one(f):
    ra = run(A, EA, f); rb = run(B, EB, f)
    if perturb and os.path.basename(f) == perturb:
        rb = (rb[0], "PERTURBED", rb[2], rb[3])
    if ra[:3] == rb[:3]: c = "same"
    elif ra[0] not in (0, 1) or rb[0] not in (0, 1): c = "CRASH"
    elif ra[0] == 0 and rb[0] != 0: c = "A2D"
    elif ra[0] != 0 and rb[0] == 0: c = "D2A"
    elif ra[0] == 0 and ra[1] != rb[1]: c = "STREAM"
    elif ra[0] == 0: c = "WARN"
    else: c = "STRING"
    return f, c, ra, rb

print(f"denominator: {len(files)} modules  A={A} {env_a}  B={B} {env_b}", flush=True)
with ThreadPoolExecutor(J) as ex:
    res = list(ex.map(one, files))
counts = {}
with open(OUT, "w") as o:
    for f, c, ra, rb in res:
        counts[c] = counts.get(c, 0) + 1
        o.write(f"{f}\t{c}\t{ra[0]}\t{rb[0]}\t{ra[1]}\t{rb[1]}\t{ra[2]}\t{rb[2]}\t{ra[3]}\t{rb[3]}\n")
print("counts:", " ".join(f"{k}={v}" for k, v in sorted(counts.items())), f"(total {len(res)})")
for f, c, ra, rb in res:
    if c != "same":
        print(f"  {c}\t{os.path.basename(f)}\trc {ra[0]}->{rb[0]}\t{ra[3][:70]!r} -> {rb[3][:70]!r}")
