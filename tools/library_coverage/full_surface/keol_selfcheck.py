#!/usr/bin/env python3
"""bd keol MUTANT VALIDATION — a checker nobody has tried to fool is a checker
nobody should trust (bd memory gate-validation-not-corpus-silence-2026-07-31).

Corpus silence is not validation: the keol check is quiet on a good corpus by
construction, so "the census ran clean" proves nothing about it. This fools it
deliberately and asserts three things:

  (1) MASKING IS REAL.   With the arm cell's OWN .bc hidden, the UNGUARDED probe
      still returns a plausible COMPILER diagnostic ("unknown callee") rather
      than anything corpus-shaped. That is the defect keol exists to stop, and
      it is asserted here rather than quoted from the ticket.
  (2) THE GUARD FIRES.   `spelling not in defmap` is True for that same cell.
  (3) IT DISCRIMINATES.  An unrelated WITNESS cell in the same mutated run keeps
      its exact base status and bucket — the guard is not blanket-declining.

Plus a RESTORE assertion, so a failed run cannot leave the corpus mutated.

Run from tools/library_coverage/full_surface with BC/OPENLIBM set.
"""
import shutil, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))

import wprobe as WP
import full_census as FC

ARM_FN, ARM_BC = "erf", "s_erf.bc"   # a plain-COMPILES cell with a single entry .bc
WIT_FN = "cbrt"                       # unrelated control
ARGS, RETW = [("q", "f64")], "f64"

def snapshot(fns):
    """One defmap build; probe each fn that resolves. -> {fn: (in_defmap, status, bucket)}"""
    d = WP.build_defmap()
    out = {}
    for fn in fns:
        if fn not in d:
            out[fn] = (False, "no-body", "(unguarded probe below)")
            continue
        st, diag, _ = WP.probe(fn, RETW, ARGS, 0, d)
        out[fn] = (True, st, FC.bucket(st, diag))
    return d, out

def unguarded(d, fn):
    """What the census reported BEFORE keol: probe regardless of the defmap."""
    st, diag, _ = WP.probe(fn, RETW, ARGS, 0, d)
    return st, FC.bucket(st, diag)

def main():
    src = WP.BC / ARM_BC
    if not src.exists():
        print(f"FAIL setup: {src} missing — rebuild the corpus first")
        return 1

    print("=== BASE (corpus intact) ===")
    _, base = snapshot([ARM_FN, WIT_FN])
    for k, v in base.items():
        print(f"  {k:8s} in_defmap={v[0]} status={v[1]} bucket={v[2]}")

    # Stash NEXT TO the original, not in a TemporaryDirectory: a run killed
    # mid-mutant (these phases are minutes long — each rebuilds the whole defmap)
    # would take the temp dir's contents with it and silently cost the corpus a
    # .bc, which is precisely the corpus-incompleteness this check exists to
    # detect. A `.keol-stash` sibling survives the kill and is recoverable by
    # hand; the check also self-heals it on the next run.
    stash = src.with_suffix(".bc.keol-stash")
    if stash.exists():                     # recover from a previously killed run
        print(f"  (recovering orphaned stash {stash.name})")
        shutil.move(str(stash), str(src))
    shutil.move(str(src), str(stash))
    try:
        print("=== MUTANT (arm's own .bc hidden) ===")
        dm, mut = snapshot([ARM_FN, WIT_FN])
        for k, v in mut.items():
            print(f"  {k:8s} in_defmap={v[0]} status={v[1]} bucket={v[2]}")
        ust, ub = unguarded(dm, ARM_FN)
        print(f"  UNGUARDED probe of {ARM_FN}: status={ust} bucket={ub}")
    finally:
        shutil.move(str(stash), str(src))

    print("=== RESTORED ===")
    _, rest = snapshot([ARM_FN])
    print(f"  {ARM_FN:8s} in_defmap={rest[ARM_FN][0]} status={rest[ARM_FN][1]} "
          f"bucket={rest[ARM_FN][2]}")

    ok = True
    def check(label, cond, detail=""):
        nonlocal ok
        print(("  PASS  " if cond else "  FAIL  ") + label + ("" if cond else f"   <- {detail}"))
        ok = ok and cond

    print("=== ASSERTIONS ===")
    check("BASE: arm resolves and probes normally",
          base[ARM_FN][0] and base[ARM_FN][1] != "no-body", str(base[ARM_FN]))
    check("(1) MASKING IS REAL: unguarded probe of the bodyless arm reports a "
          "COMPILER blocker, not a corpus one",
          ub == "unknown callee (inner-call)", f"got {ub!r}")
    check("(2) GUARD FIRES: arm is absent from the mutated defmap",
          not mut[ARM_FN][0], f"in_defmap={mut[ARM_FN][0]}")
    check("(3) DISCRIMINATES: witness unchanged under the same mutation",
          mut[WIT_FN][0] and mut[WIT_FN][1:] == base[WIT_FN][1:],
          f"{mut[WIT_FN]} vs base {base[WIT_FN]}")
    check("RESTORE: arm back to its exact BASE status+bucket",
          rest[ARM_FN] == base[ARM_FN], f"{rest[ARM_FN]} vs {base[ARM_FN]}")
    print("RESULT:", "PASS" if ok else "FAIL")
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main())
