#!/usr/bin/env python3
"""otrace.py TAG S1.ll... : compare the linked trace of an already-built stage-1 module
under the ORACLE and under TAG (args 5 7). Prints ORACLE-TRACE-IDENT / DIFF / verdicts."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import h  # noqa: E402

TAG = sys.argv[1]
BASE = __import__("os").environ.get("OT_BASE", "main")
for f in sys.argv[2:]:
    s1 = pathlib.Path(f)
    res = {}
    for t in (BASE, TAG):
        rc, msg, s2, err = h.opt(t, s1)
        if rc != 0:
            res[t] = ("DECL", msg[-100:])
            continue
        x, tr = h.linkrun(s2, ("5", "7"))
        res[t] = ("ACC", tr)
    a, b = res[BASE], res[TAG]
    if a[0] == b[0] == "ACC":
        c = "ORACLE-TRACE-IDENT" if a[1] == b[1] else "ORACLE-TRACE-DIFF"
    else:
        c = f"main={a[0]} {TAG}={b[0]}"
    print(f"{s1.name}\t{c}")
    if c == "ORACLE-TRACE-DIFF":
        import difflib
        for l in difflib.unified_diff(a[1].splitlines(), b[1].splitlines(), lineterm="", n=1):
            print("   ", l)
