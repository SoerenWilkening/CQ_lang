#!/usr/bin/env python3
# Focused ld80 (f80) re-census at a chosen opt level. Reuses full_census's cell
# derivation + bucketing; filters to the 37 long-double cells. bd 3c6m.51 epic.
#
# *** DO NOT USE THIS TO MINT A FRESH O1 BASELINE (bd eyfm). ***  The f80 view of
# the CURRENT census is derived by FILTERING the one source of truth:
#
#     python3 -c "import json;d=json.load(open('full_census_O1.json'));\
#     print({k:v for k,v in d.items() if k.endswith('.f80')})"
#
# A separately-probed ld80_census_O1.json existed until 2026-07-30 and drifted on
# EVERY increment that moved an f80 cell, because nothing regenerated it: by the
# time it was deleted it disagreed with the live census on 8 statuses and 13
# buckets, and its stale buckets 4x over-counted the very 'unknown callee' label
# bd 12c26a4 exists to prove was an artifact. This script is retained ONLY to
# reproduce the frozen O2 methodology snapshot (ld80_census_O2.json).
import sys, os, json
from pathlib import Path
HERE = Path("/Users/sorenwilkening/Desktop/CQ_lang/tools/library_coverage/full_surface")
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
import wprobe as WP
import probe as P
import full_census as FC

def main():
    lvl = WP.CENSUS_OPTLEVEL
    print(f"indexing corpus (opt={lvl})...", file=sys.stderr)
    defmap = WP.build_defmap()
    print(f"  {len(defmap)} syms", file=sys.stderr)
    from collections import defaultdict
    results, buckets = {}, defaultdict(list)
    n = 0
    for spec in P.MATHH_SPEC:
        base = spec["base"]
        if base in FC.KEEP or "macro" in spec["flags"] or spec["backend"]=="n/a":
            continue
        if "l" not in spec["variants"]:
            continue
        width, ctype, suf, lit = FC.VAR["l"]   # f80 / long double
        spelling = base + suf
        args = FC.cell_args(spec, width, ctype, lit)
        if args is None: continue
        rw = FC.ret_width(spec, width)
        if rw is None: continue
        st, diag, src = WP.probe(spelling, rw, args, 0, defmap)
        b = FC.bucket(st, diag)
        key = f"{spelling}.{width}"
        results[key] = {"status": st, "bucket": b, "diag": diag}
        buckets[b].append(key)
        n += 1
        print(f"  {spelling:14s} {b}", file=sys.stderr)
    out = HERE.parent / "full_surface" / f"ld80_census_{lvl}.json"
    json.dump(results, open(out,"w"), indent=1)
    comp = len(buckets.get("COMPILES", []))
    print(f"\n=== ld80 CENSUS @ {lvl}: {n} cells ===")
    print(f"COMPILES: {comp}/{n}   DECLINE: {n-comp}/{n}\n")
    for b, fns in sorted(buckets.items(), key=lambda x:-len(x[1])):
        print(f"  {len(fns):3d}  {b}")
        print(f"       {', '.join(sorted(fns))}")

if __name__ == "__main__":
    main()
