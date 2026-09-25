#!/usr/bin/env python3
"""norm.py A.trace B.trace : compare two traces after (1) eliding identity template
ops (add/sub/xor/or with literal 0, mul with literal 1) together with their _unc and
the free of their rail, renaming the result to its operand, and (2) canonical handle
renumbering by first appearance. Exit 0 if equal. Prints the elided count."""
import re, sys
IDENT = re.compile(r'cq_template_(add|sub|xor|or)_i(\d+)_hl\((h\d+), 0\) -> (h\d+)$|cq_template_mul_i(\d+)_hl\((h\d+), 1\) -> (h\d+)$')
def norm(path):
    L = open(path).read().splitlines()
    ren = {}; dead = set(); out = []; el = 0
    for l in L:
        mf = re.match(r'cqrt_free\((h\d+)\)$', l)
        if mf and mf.group(1) in ren: continue
        l2 = re.sub(r'\bh\d+\b', lambda m: ren.get(m.group(0), m.group(0)), l)
        m = IDENT.match(l2)
        if m:
            src = m.group(3) or m.group(6); dst = m.group(4) or m.group(7)
            ren[dst] = src; dead.add(src + "@" + dst); el += 1; continue
        # drop the matching _unc (first handle arg == renamed src, i.e. identity unc) and free
        mu = re.match(r'cq_template_(add|sub|xor|or)_i\d+_hl_unc\((h\d+), (h\d+), 0\)$|cq_template_mul_i\d+_hl_unc\((h\d+), (h\d+), 1\)$', l2)
        if mu:
            a = mu.group(2) or mu.group(4); b = mu.group(3) or mu.group(5)
            if a == b: continue
        out.append(l2)
    # drop frees of renamed identity rails: after renaming, a free of src that is followed by later uses is suspicious; count frees
    # canonical renumber
    canon = {}; res = []
    for l in out:
        res.append(re.sub(r'\bh\d+\b', lambda m: canon.setdefault(m.group(0), "H%d" % len(canon)), l))
    return res, el
a, ea = norm(sys.argv[1]); b, eb = norm(sys.argv[2])
# remove duplicate frees introduced by eliding: a free(Hx) where Hx is freed twice
def dedup(r):
    seen = set(); o = []
    for l in r:
        if l.startswith("cqrt_free("):
            if l in seen: continue
            seen.add(l)
        o.append(l)
    return o
a, b = dedup(a), dedup(b)
print(f"elided {ea}/{eb}", "EQUAL" if a == b else "DIFFERENT")
if a != b:
    import difflib; print("\n".join(list(difflib.unified_diff(a, b, lineterm=""))[:30]))
sys.exit(0 if a == b else 1)
