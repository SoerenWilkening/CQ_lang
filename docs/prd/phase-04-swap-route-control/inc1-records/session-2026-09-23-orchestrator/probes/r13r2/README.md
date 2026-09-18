# Rule-13 ROUND 2 probes — bd `test_C_libtooling-fn1q` increment 2 (the round-1 FIXES)

Authored by a SECOND independent reviewer (neither the implementer nor round 1).
Verdict **CLEAR-WITH-ITEMS** — **0 P1**, 2 P2, 4 P3.

```
ORACLE      1b396ed08b01b8ecac7…   SUBJECT-v1 a179aba6192dbe963c7b… (has the round-1 P1)
SUBJECT-v2  a0e31e0316496f71a684… (the fixes — the binary under review)
```

## What the round could NOT break

Its own 2130-fixture corpus A/B, **gate-stream hashed WITH OPERANDS** (round 1's
fixture gate drops them): ORACLE→v2 `0 A→D, 4 D→A, 0 stream moves`; v1→v2 exactly
**2 files** move, both of them the two the fixes are about. **Zero collateral.**
FIX A survived all five attack shapes (dead chained rail entangled with a measured
register, non-linear chain, two rails, rail-then-rotation, rail as a merge-phi
incoming) — each either declines on all three binaries or emits a closed chain; no
leaked forward gate. The `continue` placement converges and `MaybeDead` is iterated
nowhere else. FIX B did not re-break edit (3), and the round built the case the brief
asked for — an xor whose operand is a rail from a DIFFERENT producer — and measured
the swap correct there too, so the operand test is a SCOPE filter, not a correctness
one.

It also measured **three further accept surfaces byte-identical to their
if-converted twins** (a real arithmetic arm at both polarities, `and i1 %rail, %cmp`,
`or i1 %rail, %cmp`), so the "an ACCEPT, not a STREAM" clearance argument holds well
beyond the constant-arm fixtures that ship.

## The two P2s, both fixed at the source

| probe | finding |
|---|---|
| `U_residue_orphan_rail_memnone.ll` (+ controls `T_residue_orphan_rail.ll`, `Y_pre_existing_probe.ll`, `X_phi_orphan.ll`) | ⚠ **P2-1 — "there is exactly ONE place this pass erases" is FALSE.** `simplifyFlattenResiduesInFunction`'s `RecursivelyDeleteTriviallyDeadInstructions` reproduces the round-1 P1 verbatim and FIX A does not reach it: exit 0, **0 bytes stderr**, no `cqrt_alloc_i1`, no `cqrt_ry_i1`. Capped at P2 by two MEASUREMENTS — it needs a `memory(none)` attribute `CQ.h` cannot emit (`T` is the control), and it is **PRE-EXISTING** (`Y` shows the ORACLE deleting the rail for a compare-conditioned region). ⚠ *"Pre-existing" is true of the defect and FALSE of its population.* Comment corrected at the source; hole filed as **bd `test_C_libtooling-cfmv`**. `X` is the unproven `isCondRailPhiShape` half — stated unproven, not safe. |
| — (source reading) | ⚠ **P2-2 — two comments in one change CONTRADICTED each other.** The `buildNegation` arm claimed `collectCondTree` reads `xor(rail, i1 const)` "the shape it has carried since bd 3qlq.4". **False**: `SelectClassify.cpp` refuses an `xor` with a constant operand, and bd `3qlq.4`'s shape is `xor %b, %c`, two NON-constants. The code is safe — the arm-swap fold removes the xor first — but a reader who believed it would conclude the fold is removable, which round 1 measured turns the negated polarity into a claim-then-decline. **The fold is load-bearing, not cosmetic.** Corrected at the source. |

## The P3s

* **P3-1 (measured, fixed).** The `RAIL` prefix claimed "read ONLY as a control" but
  pinned only `cqrt_x`/`cqrt_free`: an injected `cqrt_ry_i1`/`cqrt_rz_i1` on the
  user's register was **MISSED** — the Rule-7 class. Now anchored at the rail's own
  preparation with negatives for both rotations, and `dead_rail_survives` gets exact
  whole-file negatives (it emits no `cqrt_x`/`cqrt_rz` at all). ⚠ **Re-validated with
  a CLEAN NULL CONTROL, and the first re-validation harness was broken**: it derived
  prefixes by scanning comment lines instead of the RUN lines, so the unmutated
  output "failed" — a harness that runs a different command than lit measures itself,
  not the fixtures. All three injections are CAUGHT on all three fixtures with
  `NULL=0`.
* **P3-2 (unproven, recorded as such).** `run()` also tracks a SWITCH SCRUTINEE with
  no grammar check, so a `@cq_theta_si32` CALL can reach `track()` without being a
  cond-tree node, and `isCondRailLeaf` is `cq_theta_i1`-only. Round 2 could not build
  a module where it dies. Comment now says **unproven in both directions**.
* **P3-3 (instrument, not a defect).** `entangle.py` reports `DIRTY FREE` on the
  boolalg fixture; it is an over-report (toffoli modelled by UNION, per its own
  docstring) and appears IDENTICALLY on the twin the ORACLE accepts.
* **P3-4 (fixed).** The twin `diff` compared symbol names only; measured identical
  WITH operands (52/52), so it now compares operands and carries a `test -s` vacuity
  guard. ⚠ The limit stays and is written into the fixture: **both sides run under the
  SUBJECT binary**, so "the ORACLE accepts the twin" is prose, not a gate — the
  `ACCEPT-IDENTICAL` blind spot.

## ⚠ The round's own harness caveat, recorded per L10

Its first twin comparison reported `IDENTICAL (0 gates)` on **two empty files** before
it added a vacuity guard and a null control. That is the `empty-module-accepts-vacuity-trap`
in a new place, found by the reviewer against itself.
