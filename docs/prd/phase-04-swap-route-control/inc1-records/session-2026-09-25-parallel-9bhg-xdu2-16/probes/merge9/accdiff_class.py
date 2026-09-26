#!/usr/bin/env python3
"""Classify every ACC-DIFF pair on TAG: is the ONLY difference that the twin
uncomputes+frees one rail (`cqrt_ry_<W>(hN, -x)` then `cqrt_free(hN)`, both
ADDED on the T side, nothing removed, same args, same exit)? Prints each pair as
DEAD-REG-ONLY or OTHER (with the diff)."""
import difflib
import pathlib
import re
import subprocess
import sys

P = pathlib.Path(__file__).resolve().parent / "p"
tag = sys.argv[1]
for b in sys.argv[2:]:
    verdict = "DEAD-REG-ONLY"
    shown = []
    for args in ("5 7", "2 9"):
        out = {}
        for v in ("C", "T"):
            r = subprocess.run([str(P / f"{b}{v}.{tag}.exe")] + args.split(),
                               capture_output=True, text=True)
            out[v] = r.stdout.splitlines() + [f"exit={r.returncode}"]
        d = [l for l in difflib.unified_diff(out["C"], out["T"], lineterm="", n=0)
             if not l.startswith(("---", "+++", "@@"))]
        minus = [l for l in d if l.startswith("-")]
        plus = [l[1:] for l in d if l.startswith("+")]
        ok = False
        if not minus and len(plus) == 2:
            mm = re.fullmatch(r"cqrt_ry_\w+\((h\d+), -0x[0-9a-fp.+-]+\)", plus[0])
            ok = bool(mm) and plus[1] == "cqrt_free(" + mm.group(1) + ")"
        if not ok:
            verdict = "OTHER"
            shown += [f"  args={args}"] + ["    " + l for l in d]
    print(f"{b:6} {verdict}")
    for l in shown:
        print(l)
