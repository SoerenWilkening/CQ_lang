#!/usr/bin/env python3
"""census.py OPT_A OPT_B — the DROP census A/B (bd vsfp's lesson: a decline fixture whose subject
the drop removes can keep its STRING under another owner, which no stdout/stderr A/B can see).
Over every corpus module (corpus.txt from ab.py --build) that contains the token `musttail`
(the only construct ev3m changes the drop for), run both binaries with CQ_DEADARG_DBG=1 and
compare the census lines. Prints the denominator and every module whose census differs."""
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

SP = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/nlfd/corpus"
A, B = sys.argv[1], sys.argv[2]
rows = [l.rstrip("\n").split("\t") for l in open(os.path.join(SP, "corpus.txt"))]
mods = [(st, tag, f) for st, tag, f in rows if f != "BUILD-FAIL" and "musttail" in open(f, errors="replace").read()]
print(f"denominator: {len(mods)} corpus modules containing `musttail` (of {len(rows)})")


def census(opt, f):
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", f, "-o", "/dev/null"], capture_output=True,
                       text=True, env=dict(os.environ, CQ_DEADARG_DBG="1"), timeout=600)
    return p.returncode, tuple(l for l in p.stderr.splitlines() if l.startswith("CQ_DEADARG_DBG"))


def one(x):
    st, tag, f = x
    return st, tag, census(A, f), census(B, f)


with ThreadPoolExecutor(4) as ex:
    res = list(ex.map(one, mods))
d = [r for r in res if r[2] != r[3]]
print(f"census movers: {len(d)}")
for st, tag, a, b in d:
    print(f"{st}\t{tag}\tA rc={a[0]} {len(a[1])} drop(s)\tB rc={b[0]} {len(b[1])} drop(s): {' | '.join(b[1])[:300]}")
