#!/usr/bin/env python3
"""reduce_twin.py <trace> <W> <SEEDLIT> — the Inc-4 CHAINED-TWIN reduction.

Two rewrites, in order, then handle-normalisation by first appearance:
 (i)  DELETE the seed rotation `cqrt_ry_<W>(h, 0x0p+0)` — a zero-angle Ry is the
      identity, so removing it is a physical identity, not a transformation
      under test.
 (ii) MOVE `cqrt_alloc_<W>(SEED) -> h` to immediately before the FIRST
      `cqrt_ry_<W>_controlled(f, h, .)` naming that h. A fresh-rail alloc
      COMMUTES with every gate that does not name its handle (it acts on a
      disjoint wire), so the move is a physical identity too.
"""
import re, sys

CALL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\((.*?)\)(?: -> (.*))?$")
HANDLE = re.compile(r"\bh(\d+)\b")

def parse(l):
    m = CALL.match(l.strip())
    if not m: return None
    a = [x.strip() for x in m.group(2).split(",")] if m.group(2) else []
    return m.group(1), a, m.group(3)

def normalise(lines):
    m, out = {}, []
    for l in lines:
        def sub(x):
            k = x.group(1)
            if k not in m: m[k] = str(len(m))
            return "h" + m[k]
        out.append(HANDLE.sub(sub, l))
    return out

def reduce_twin(lines, W, seed):
    # (i) drop the zero-angle seed Ry, remembering its handle
    zero = {"0x0p+0"}
    out, seeded = [], set()
    for l in lines:
        p = parse(l)
        if p and p[0] == "cqrt_ry_%s" % W and len(p[1]) == 2 and p[1][1] in zero:
            seeded.add(p[1][0]); continue
        out.append(l)
    # (ii) move the alloc of each seeded handle to just before its first cRy
    for h in sorted(seeded):
        ai = next((i for i, l in enumerate(out)
                   if (p := parse(l)) and p[0].startswith("cqrt_alloc_")
                   and p[2] == h and p[1] == [seed]), None)
        if ai is None: continue
        alloc = out.pop(ai)
        ci = next((i for i, l in enumerate(out)
                   if (p := parse(l)) and re.fullmatch(r"cqrt_ry_\w+_controlled", p[0])
                   and len(p[1]) == 3 and p[1][1] == h), None)
        out.insert(len(out) if ci is None else ci, alloc)
    return normalise(out)

if __name__ == "__main__":
    ls = [l.rstrip("\n") for l in open(sys.argv[1]) if l.strip()]
    print("\n".join(reduce_twin(ls, sys.argv[2], sys.argv[3])))
