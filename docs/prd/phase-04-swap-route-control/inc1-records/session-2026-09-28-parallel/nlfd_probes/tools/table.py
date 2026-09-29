#!/usr/bin/env python3
"""table.py ORACLE.txt SUBJECT.txt — render two pairs.py outputs as a markdown table:
subject | twin | ORACLE verdict (+ the oracle subject's status) | SUBJECT verdict (+ status)."""
import re
import sys


def load(p):
    d = {}
    for line in open(p):
        f = line.split()
        if len(f) >= 4 and f[2] == "vs":
            s = line.split("| S:")[1].split("| T:")[0].strip()
            d[(f[1], f[3])] = (f[0], s)
    return d


def short(s):
    if s.startswith("opt=0"):
        w = re.search(r"warn=(\d+)", s).group(1)
        dirty = re.search(r"of which (\d+) left dirty", s)
        ln = re.search(r"lines=(\d+)", s).group(1)
        return f"exit 0, warn {w}, dirty {dirty.group(1) if dirty else '?'}, {ln} lines"
    m = re.match(r"opt=(-?\d+)\s*(.*)", s)
    rc, e = m.group(1), m.group(2)
    if rc != "1":
        return f"ABORT (exit {rc})"
    e = e.split("):", 1)[-1].strip() if "):" in e else e
    return f"decline: {e[:70]}"


a, b = load(sys.argv[1]), load(sys.argv[2])
print("| subject | twin | ORACLE | SUBJECT |")
print("|---|---|---|---|")
for k in a:
    va, sa = a[k]
    vb, sb = b.get(k, ("MISSING", ""))
    mark = " ⟵" if va != vb else ""
    print(f"| `{k[0].replace('cells/', '')}` | `{k[1].replace('cells/', '')}` | {va} — {short(sa)} | **{vb}** — {short(sb)}{mark} |")
