#!/usr/bin/env python3
"""ab.py BIN_A BIN_B OUT FILE... : run both binaries on every file (no env levers), compare exit code,
stdout sha-256 and stderr text. Refuses unreadable inputs; reports denominator and TOOLFAIL (rc>=126 except 134)."""
import sys, subprocess, hashlib, pathlib, concurrent.futures as cf
A, B, OUT = sys.argv[1:4]; files = sys.argv[4:]
def run(b, f):
    try:
        r = subprocess.run([b, "-passes=cq-lowering", "-S", f, "-o", "-"], capture_output=True, timeout=120)
        return r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16], r.stderr.decode(errors="replace")
    except subprocess.TimeoutExpired:
        return "TIMEOUT", "", ""
def one(f):
    if not pathlib.Path(f).is_file(): return f, "UNREADABLE", None, None
    a = run(A, f); b = run(B, f)
    return f, "SAME" if a == b else "MOVE", a, b
res = []
with cf.ThreadPoolExecutor(6) as ex:
    res = list(ex.map(one, files))
unread = [r for r in res if r[1] == "UNREADABLE"]
toolfail = [r for r in res if r[2] and (r[2][0] == "TIMEOUT" or (isinstance(r[2][0], int) and r[2][0] >= 126 and r[2][0] != 134))]
movers = [r for r in res if r[1] == "MOVE"]
with open(OUT, "w") as o:
    for f, s, a, b in movers:
        kind = "A->D" if a[0] == 0 and b[0] != 0 else "D->A" if a[0] != 0 and b[0] == 0 else ("DIAG" if a[0] != 0 else "STREAM" if a[1] != b[1] else "STDERR")
        ea = [l for l in a[2].splitlines() if "error" in l or "warning" in l][:1]
        eb = [l for l in b[2].splitlines() if "error" in l or "warning" in l][:1]
        o.write(f"{kind}\t{f}\n\tA rc={a[0]} {ea}\n\tB rc={b[0]} {eb}\n")
    o.write(f"DENOM={len(files)} MOVERS={len(movers)} UNREADABLE={len(unread)} TOOLFAIL={len(toolfail)}\n")
print(f"DENOM={len(files)} MOVERS={len(movers)} UNREADABLE={len(unread)} TOOLFAIL={len(toolfail)}")
