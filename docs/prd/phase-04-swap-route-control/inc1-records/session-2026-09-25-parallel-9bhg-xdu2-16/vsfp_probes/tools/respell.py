#!/usr/bin/env python3
"""respell.py IN OUT CALLEE ARGIDX: copy a fixture, inserting a DEAD READ of parameter
ARGIDX at the top of @CALLEE's body (`%vsfp.read = mul <ty> %p, 3` / `fmul`), so the
parameter is no longer use_empty and bd vsfp's dead-argument drop cannot remove the
fixture's subject. Prints the inserted line."""
import re
import sys

src, dst, callee, idx = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
lines = open(src).read().split("\n")
out = []
done = False
i = 0
while i < len(lines):
    l = lines[i]
    out.append(l)
    m = re.match(r"^define [^@]*@" + re.escape(callee) + r"\((.*)\)[^{]*\{\s*$", l)
    if m and not done:
        # split params at top-level commas
        params, depth, cur = [], 0, ""
        for ch in m.group(1):
            if ch == "(":
                depth += 1
            if ch == ")":
                depth -= 1
            if ch == "," and depth == 0:
                params.append(cur.strip())
                cur = ""
            else:
                cur += ch
        if cur.strip():
            params.append(cur.strip())
        p = params[idx]
        ty = p.split()[0]
        name = p.split()[-1]
        assert name.startswith("%"), p
        # keep a leading label line if present
        j = i + 1
        while j < len(lines) and (lines[j].strip() == "" or re.match(r"^[\w.]+:", lines[j])):
            out.append(lines[j])
            j += 1
        op = "fmul" if ty in ("float", "double", "x86_fp80", "half", "fp128") else "mul"
        k = "3.000000e+00" if op == "fmul" else "3"
        if ty == "x86_fp80":
            k = "0xK4000C000000000000000"
        ins = f"  %vsfp.read = {op} {ty} {name}, {k}   ; bd vsfp: a DEAD READ keeps this parameter used"
        out.append(ins)
        print(ins.strip())
        done = True
        i = j
        continue
    i += 1
assert done, f"@{callee} not found"
open(dst, "w").write("\n".join(out))
