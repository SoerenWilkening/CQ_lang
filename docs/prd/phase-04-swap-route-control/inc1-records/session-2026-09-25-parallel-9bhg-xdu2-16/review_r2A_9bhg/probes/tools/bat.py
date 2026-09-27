#!/usr/bin/env python3
# bat.py <bins> <names...>: table exit/msg, accept -> 2b rc + trace hash for args (5 7),(2 9); prints trace diff vs twin on request
import sys, json, concurrent.futures as cf; sys.path.insert(0, '.')
from h import *
bins = sys.argv[1].split(','); names = sys.argv[2:]
def one(b):
    s1, e = build(b)
    res = {}
    if not s1: return b, {"gen": e}
    for bn in bins:
        rc, msg, s2, stderr = opt(bn, b)
        warns = sorted(set(l.split("): ")[-1] for l in stderr.splitlines() if l.startswith("warning")))
        r = {"rc": rc, "msg": msg, "warn": warns}
        if s2:
            c, l = check2b(s2); r["2b"] = (c, l[-1][l[-1].find('rail mint'):] if l else "")
            tr = []
            for a in (["5", "7"], ["2", "9"]):
                x, t = linkrun(s2, a, f"{b}.{bn}.{a[0]}")
                tr.append((x, t))
            r["trace"] = tr
        res[bn] = r
    return b, res
out = {}
with cf.ThreadPoolExecutor(8) as ex:
    for b, r in ex.map(one, names): out[b] = r
json.dump(out, open(O / "bat_last.json", "w"), indent=1)
for b in names:
    r = out[b]
    if "gen" in r: print(b, "GEN", r["gen"][:200]); continue
    row = []
    for bn in bins:
        x = r[bn]
        row.append(f"{bn}:{x['rc']}:{(x['msg'][-70:] if x['rc'] else 'ACC')}{' W' if x['warn'] else ''}")
    print(f"{b:6s} " + " | ".join(row))
