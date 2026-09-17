#!/usr/bin/env python3
"""Gate-symbol MULTISET comparison of two traces, plus a per-rail mint/_unc/free
ledger. The trace loses rail identity across forms, so this reports SYMBOL counts
(comparable) and, separately, per-handle discharge status within ONE trace."""
import re, sys, collections

def load(p):
    return [l.rstrip("\n") for l in open(p) if l.strip()]

def sym(l):
    return l.split("(", 1)[0]

def ledger(lines):
    """handle -> (minted_by, unc'd?, freed?)"""
    mint = {}
    unc = collections.Counter()
    free = collections.Counter()
    for l in lines:
        s = sym(l)
        m = re.search(r"-> (h\d+)$", l)
        if m and (s.startswith("cqrt_alloc") or s.startswith("cq_template")):
            mint[m.group(1)] = s
        if s.endswith("_unc"):
            a = re.search(r"\(([^,)]+)", l)
            if a: unc[a.group(1).strip()] += 1
        if s == "cqrt_free":
            a = re.search(r"\((h\d+)\)", l)
            if a: free[a.group(1)] += 1
    return mint, unc, free

for p in sys.argv[1:]:
    L = load(p)
    c = collections.Counter(sym(l) for l in L)
    mint, unc, free = ledger(L)
    print("== %s  (%d lines) ==" % (p, len(L)))
    for k in sorted(c):
        print("   %-42s %d" % (k, c[k]))
    dirty = [h for h in mint if unc[h] == 0 and mint[h].startswith("cq_template")]
    leaked_alloc = [h for h in mint if free[h] == 0 and mint[h].startswith("cqrt_alloc")]
    dbl = [h for h in mint if unc[h] > 1 or free[h] > 1]
    print("   DIRTY template rails (mint, no _unc): %s" % sorted(dirty, key=lambda x: int(x[1:])))
    print("   alloc rails never freed             : %s" % sorted(leaked_alloc, key=lambda x: int(x[1:])))
    print("   MULTIPLY _unc'd or freed            : %s" % sorted(dbl, key=lambda x: int(x[1:])))
    print()

if len(sys.argv) == 3:
    a = collections.Counter(sym(l) for l in load(sys.argv[1]))
    b = collections.Counter(sym(l) for l in load(sys.argv[2]))
    print("== SYMBOL MULTISET DELTA (arg1 - arg2) ==")
    for k in sorted(set(a) | set(b)):
        if a[k] != b[k]:
            print("   %-42s %d vs %d   (%+d)" % (k, a[k], b[k], a[k] - b[k]))
    if a == b:
        print("   IDENTICAL")
