#!/usr/bin/env python3
# Full-surface injection census — the width/by-ref/int-ret widening of
# inject_census.py the roadmap intended. Imports probe.py's MATHH_SPEC as the
# authoritative surface, expands each base fn across its width variants (f/d/l),
# injects the REAL openlibm body per cell, runs cq-lowering, records the actual
# blocking capability. Skips the hardware keep-set (recognition-covered, no
# injectable body), macros, and by-design. Reuses wprobe.py's pipeline.
import sys, json, os
from pathlib import Path
from collections import defaultdict
# probe.py lives one dir up (tools/library_coverage); wprobe.py sits alongside.
sys.path.insert(0, str(Path(__file__).resolve().parent))          # wprobe
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))   # probe
import wprobe as WP
import probe as P

# variant key -> (census width, c-type, spelling suffix, fp-const literal)
VAR = {"f": ("f32","float","f","0.5f"), "": ("f64","double","","0.5"), "l": ("f80","long double","l","0.5L")}
KEEP = set(P.HARDWARE_KEEP_SET.split())   # recognition-covered; no injectable body

def cell_args(spec, width, ctype, lit):
    """Map a spec's arg kinds to wprobe arg descriptors (arg0 tainted)."""
    out = []
    for i, a in enumerate(spec["args"]):
        if a == "fp":
            out.append(("q", width) if i == 0 else (f"c:{ctype}:{lit}",))
        elif a == "int":   out.append(("c:int:2",))
        elif a == "long":  out.append(("c:long:2",))
        elif a == "int*":  out.append(("ref:int",))
        elif a == "fp*":   out.append((f"ref:{ctype}",))
        elif a == "str":   return None   # nan("") — no taintable input
        else: return None
    return out

def ret_width(spec, width):
    r = spec["ret"]
    if r == "fp":   return width
    if r == "long": return "sl"
    return None   # int-return macros — skipped

def bucket(st, diag):
    d = diag.lower()
    if st == "COMPILES": return "COMPILES"
    if st.startswith("exit0"): return "uninlined(harness)"
    if "nested control" in d: return "L6 nested control"
    if "control flow inside a loop" in d: return "in-loop control"
    if "arm rewrites a condition" in d: return "§3c clobber"
    if "control flow under quantum" in d: return "control (flat/diamond)"
    if "unknown callee" in d: return "unknown callee (inner-call)"
    if "unsupported instruction" in d: return "unsupported opcode"
    if "stored to memory" in d or "store" in d: return "memory-store (Shadow)"
    if "reversible copy" in d or "specialization" in d: return "fp-copy/specialization"
    if "loop" in d: return "loop-carried"
    if "angle" in d: return "angle-fence"
    return "other: " + d[:50]

def main():
    print("indexing openlibm corpus...", file=sys.stderr)
    defmap = WP.build_defmap()
    print(f"  {len(defmap)} syms / {len(list(WP.BC.glob('*.bc')))} bc", file=sys.stderr)
    results = {}
    buckets = defaultdict(list)
    n_cells = 0
    for spec in P.MATHH_SPEC:
        base = spec["base"]
        if base in KEEP: continue                 # hardware keep-set (recognition)
        if "macro" in spec["flags"]: continue      # not a real call
        if spec["backend"] == "n/a": continue      # by-design (nan)
        for v in spec["variants"]:
            width, ctype, suf, lit = VAR[v]
            spelling = base + suf
            args = cell_args(spec, width, ctype, lit)
            if args is None: continue
            rw = ret_width(spec, width)
            if rw is None: continue
            # ld80 f80 uses x86_fp80; sqrt-family keep already skipped.
            st, diag, src = WP.probe(spelling, rw, args, 0, defmap)
            b = bucket(st, diag)
            results[f"{spelling}.{width}"] = {"status": st, "bucket": b, "diag": diag}
            buckets[b].append(f"{spelling}.{width}")
            n_cells += 1
            print(f"  {spelling:12s} {width:4s} {b}", file=sys.stderr)
    json.dump(results, open("full_census_results.json","w"), indent=1)
    print(f"\n=== FULL-SURFACE CENSUS: {n_cells} injectable cells ===")
    comp = len(buckets.get("COMPILES", []))
    print(f"COMPILES: {comp}/{n_cells}   DECLINE: {n_cells-comp}/{n_cells}\n")
    for b, fns in sorted(buckets.items(), key=lambda x: -len(x[1])):
        print(f"  {len(fns):3d}  {b}")
        print(f"       {', '.join(sorted(fns))}")

if __name__ == "__main__":
    main()
