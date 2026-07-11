#!/usr/bin/env python3
# Synthesis of the full-depth peel census (bd 3c6m). Merges the census-mode
# full-stack blocker sets (peel_census_results.json) with the normal first-blocker
# run (first_blocker_refreshed.json), folds raw blocker classes into the campaign
# LEVERS, and produces the capability-combination -> function table + the
# cells-unlocked-per-lever ranking that drives the L6 (3c6m.14) sequencing
# decision. Also emits the harness-artifact quick-win list and the C-physics check.
import json, sys
from collections import defaultdict, Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
cm = json.load(open(HERE / "peel_census_results.json"))       # census-mode full stack
fb = json.load(open(HERE / "first_blocker_refreshed.json"))   # normal first blocker

# raw blocker class -> campaign LEVER + bd ticket. Per 3c6m.13, a const-global
# table read UNDER tainted control is the control lever (L6), not a QROM lever.
LEVER = {
    # CONTROL lever — 3c6m.14 (L6 general nested tainted control) + the existing
    # swap-route control emitter (flat/diamond/select/switch/§3c).
    "L6-nested-control":       ("CONTROL", "3c6m.14"),
    "control-flat-diamond":    ("CONTROL", "3c6m.14/swap-route"),
    "classical-mux":           ("CONTROL", "3c6m.14/select-merge"),
    "qram-read-under-control": ("CONTROL", "3c6m.13->3c6m.14"),
    "clobber-3c":              ("CONTROL", "swap-route §3c"),
    # SHADOW lever — tainted scratch memory (alloca array / bit-pattern cell).
    "shadow-store":            ("SHADOW",  "iw81.13/u9pl/38t2"),
    "shadow-dynamic":          ("SHADOW",  "iw81.13"),
    "shadow-alias":            ("SHADOW",  "iw81.13"),
    # LOOP lever — classically-bounded loop over tainted body.
    "in-loop-control":         ("LOOP",    "7.3/8h7d"),
    "loop-carried":            ("LOOP",    "7.3/8h7d"),
    "qram-in-loop":            ("LOOP",    "iw81.13 (QRAM-in-loop)"),
    # INNER-CALL — un-inlined tainted call (mostly corpus/closure artifact under
    # Rule 18; residual keep-set-leaf calls need recognizer). 3c6m.11 L2.
    "unknown-callee":          ("INNER-CALL", "3c6m.11 (L2/harness)"),
    # SPECIALIZE — fp quantum arg/return on a surviving call (5po2). Also fires on
    # a recursive body (tgamma) that cannot fully inline.
    "fp-specialization":       ("SPECIALIZE", "5po2"),
    "fp-copy":                 ("SPECIALIZE", "5po2"),
    # OPCODE (deep) — the Payne-Hanek int-array kernel opcode gap (sin/cos/tan).
    "unsupported-opcode":      ("OPCODE", "3c6m (Payne-Hanek kernel)"),
    # generic escapes (rare; fold to ESCAPE)
    "taint-escape-consume":    ("ESCAPE", "-"),
    "escape-return":           ("ESCAPE", "-"),
    "taint-escape":            ("ESCAPE", "-"),
}

# C-physics wall classes (from PARITY_MAP.md) — NONE of the above are these.
C_PHYSICS = {"forged-inttoptr", "atomics", "exceptions", "indirectbr",
             "general-aliasing", "coherent-when"}

def lever_set(rec):
    lv = set()
    for b in rec.get("blockers", []):
        cls = b["class"]
        if cls in LEVER:
            lv.add(LEVER[cls][0])
    return lv

cells = sorted(set(cm) | set(fb))
merged = {}
for k in cells:
    lcm = lever_set(cm.get(k, {}))
    lfb = lever_set(fb.get(k, {}))
    levers = lcm | lfb            # union: census-mode depth + first-blocker (loops)
    fully = cm.get(k, {}).get("fully_inlined", True) and fb.get(k, {}).get("fully_inlined", True)
    compiles = (not levers)
    merged[k] = {
        "levers": sorted(levers),
        "compiles": compiles,
        "fully_inlined": fully,
        "first_blocker": [b["class"] for b in fb.get(k, {}).get("blockers", [])][:1],
        "census_classes": sorted(set(b["class"] for b in cm.get(k, {}).get("blockers", []))),
        "uninlined_calls": (not fully),
    }

# ---- reporting ----
print("=" * 78)
print("FULL-DEPTH PEEL CENSUS — capability-combination -> function map")
print(f"  {len(cells)} census-runnable cells (reconciled ISO C11 surface)")
print("=" * 78)

comp = [k for k, v in merged.items() if v["compiles"]]
print(f"\nCOMPILES (0 levers needed): {len(comp)} -> {comp}")

# lever prevalence
prev = Counter()
for v in merged.values():
    for L in v["levers"]:
        prev[L] += 1
print("\nCELLS TOUCHING EACH LEVER (a cell may need several):")
for L, n in prev.most_common():
    print(f"  {n:3d}  {L}")

# capability combination -> cells
combos = defaultdict(list)
for k, v in merged.items():
    combos[tuple(v["levers"])].append(k)
print("\nCAPABILITY-COMBINATION -> CELLS (the peel result):")
for combo, ks in sorted(combos.items(), key=lambda x: (len(x[0]), -len(x[1]))):
    label = "+".join(combo) if combo else "COMPILES"
    print(f"  [{len(ks):3d}] {label}")
    print(f"        {', '.join(sorted(ks))}")

# The L6 decision: CONTROL-alone vs CONTROL+X
def needs(v, only):
    return set(v["levers"]) == set(only)
def needs_control_plus(v, extra):
    return set(v["levers"]) == {"CONTROL"} | set(extra)

control_alone = [k for k, v in merged.items() if needs(v, ["CONTROL"])]
print("\n" + "=" * 78)
print("L6 (3c6m.14) DECISION SUPPORT")
print("=" * 78)
print(f"\nCONTROL-lever ALONE unlocks ({len(control_alone)} cells) — the pure-L6 target set:")
print(f"  {sorted(control_alone)}")
for extra_name, extra in [("LOOP", ["LOOP"]), ("SHADOW", ["SHADOW"]),
                          ("INNER-CALL", ["INNER-CALL"]), ("SPECIALIZE", ["SPECIALIZE"]),
                          ("SHADOW+LOOP", ["SHADOW", "LOOP"]),
                          ("SHADOW+LOOP+OPCODE", ["SHADOW", "LOOP", "OPCODE"])]:
    s = [k for k, v in merged.items() if needs_control_plus(v, extra)]
    if s:
        print(f"\nCONTROL + {extra_name} ({len(s)} cells):")
        print(f"  {sorted(s)}")

# any cell WITHOUT control?
no_control = [k for k, v in merged.items() if v["levers"] and "CONTROL" not in v["levers"]]
print(f"\nCells needing work but NOT the control lever ({len(no_control)}):")
for k in sorted(no_control):
    print(f"  {k:16s} {merged[k]['levers']}")

# how many cells does CONTROL participate in
with_control = [k for k, v in merged.items() if "CONTROL" in v["levers"]]
print(f"\nCONTROL lever participates in {len(with_control)}/{len(cells)} cells "
      f"({100*len(with_control)//len(cells)}%).")

# harness-artifact quick-wins (uninlined calls = corpus/closure/keep-set-leaf)
quickwin = [k for k, v in merged.items() if v["uninlined_calls"]]
print("\n" + "=" * 78)
print(f"HARNESS-ARTIFACT candidates (surviving un-inlined calls): {len(quickwin)}")
print("=" * 78)
print(f"  {sorted(quickwin)}")

# C-physics check
cphys = [k for k, v in merged.items()
         if any(c in C_PHYSICS for c in v["census_classes"])]
print("\n" + "=" * 78)
print("C-PHYSICS WALL CHECK")
print("=" * 78)
print(f"  cells hitting a C-physics wall class: {len(cphys)} -> {cphys}")
print(f"  => every libm decline is B-RECOGNITION (achievable). ZERO C-physics walls."
      if not cphys else "  => WALL FOUND (unexpected!)")

# ---- sibling inference: a corpus-masked cell (surviving un-inlined call, so its
# body's structure is hidden) inherits the lever set of an INLINED sibling of the
# same base function (a different width that fully inlined). This projects the
# "corpus-fixed" capability set — what the cell needs once the harness/corpus
# closure artifact is removed.
import re
def base_of(cell):
    return re.sub(r'(f|l)$', '', cell.rsplit('.', 1)[0])

projected = {}
for k, v in merged.items():
    lv = set(v["levers"])
    if v["uninlined_calls"] and lv <= {"INNER-CALL", "SPECIALIZE"}:
        b = base_of(k)
        sib = set()
        for s, sv in merged.items():
            if s != k and base_of(s) == b and not sv["uninlined_calls"] and sv["levers"]:
                sib |= set(sv["levers"])
        if sib:
            lv = (lv - {"INNER-CALL"}) | sib   # keep SPECIALIZE, drop pure closure noise
    projected[k] = sorted(lv)

proj_control = [k for k, l in projected.items() if "CONTROL" in l]
proj_none    = [k for k, l in projected.items() if not l]
print("\n" + "=" * 78)
print("CORPUS-FIXED PROJECTION (masked cells inherit inlined-sibling set)")
print("=" * 78)
print(f"  CONTROL participates in {len(proj_control)}/{len(cells)} cells after corpus/closure fix "
      f"({100*len(proj_control)//len(cells)}%).")
print(f"  COMPILES-projected: {sorted(proj_none)}")
genuine_noctrl = [k for k, l in projected.items() if l and "CONTROL" not in l]
print(f"  Cells still without CONTROL after projection: {sorted(genuine_noctrl)}")

for k in merged:
    merged[k]["projected_levers"] = projected[k]

json.dump(merged, open(HERE / "peel_census_merged.json", "w"), indent=1)
print(f"\nwrote peel_census_merged.json")
