# Merge-and-gate brief — landing 3: Track M (bd `boi6` D-B / `8xaw`, branch `mphi-rail-leaf`)

Instance of `../MERGE_BRIEF_TEMPLATE.md` (read it first). Model: opus. Worktree
`/Users/sorenwilkening/Desktop/CQ_mphi`, branch `mphi-rail-leaf` (base 8659a77; review r1 CLEAR-WITH-ITEMS →
FIX_M_R1 → review r2 **CLEAR-WITH-ITEMS** (`review_M_r2.md`: the edge is sound — a `SelectRegion` is a sink; the round-2 index is consistent by construction; `hcrg` customers byte-identical)), merging `main` at
`git -C /Users/sorenwilkening/Desktop/CQ_lang log -1 --format=%h` = landing 1 (Track C: `MeasureLowering.{h,cpp}`)
+ landing 2 (Track R-1: `TaintPropagation.h` `PeelClones`, `MergePhiPeel.cpp`, `ArmClassify.cpp` F2 test) +
this session's docs. Expected conflicts: `tests/e2e/CMakeLists.txt` (three appenders — keep ALL blocks in
order: landing 1's, landing 2's, then this track's); `$SES/trackM/GATES.md` (union in order); possibly NONE
in `ir-pass/src` (M touched `SelectClassify.{h,cpp}`, `SelectMergeEmit.cpp`, `RegionFlatten.cpp`,
`Specialization.cpp`, `SwapRouteEmit.cpp` (the graph), `ControlPlan.h`; R touched `ArmClassify.cpp`,
`MergePhiPeel.cpp`, `TaintPropagation.h`; C touched `MeasureLowering.*`) — disjoint files, but
`TaintPropagation.h`/`ControlPlan.h` are shared HEADERS: rebuild everything. If an `ir-pass/src` conflict
appears, STOP and report. You are the ONLY full-`ctest` runner right now.

## Landing-specific items (step 8), BEFORE step 3

A. Apply the round-2 review's items (fixture/comment only — no pass-source predicate change):
   1. **F2-1 (Rule-12 gap, MUST)**: in `ir-pass/test/control_swap_accept_select_mergephi_rail_then_kickback.ll`
      add the `CHECK:` that pins the kickback's TARGET and ANGLE — `cqrt_rz_i1(i32 %[[H_CMP]], double
      3.000000e-01)` between the lines the reviewer names (`:204`/`:205`); then re-run
      `review_M_r2_probes/rz_mutation.sh` (target moved onto `%h`/`%h4`/`%out3`; angle 0.3→0.9) — every mutant
      must now redden; `lit --filter` the fixture.
   2. **F2-2 (DOC)**: rewrite the F-M7 trigger comment at `SwapRouteEmit.cpp:2526-2536` — `declineRegion` IS
      called on a `SelectRegion` by the fix's own loop (`:2645`) and `Pending[select]>=1` now permits `!Done`;
      state that all three sites run before any emission (no live hazard).
   3. **F2-3 (LOW)**: add `NOX-NOT`/`NOFREE-NOT` on the merge-OUT rail (the user's measured answer register)
      to the 11 accept fixtures where it is missing (11/11 NOX, 8/11 NOFREE — `review_M_r2_probes/negcoverage.py`
      lists them); run `probes/impl/vacuity.py` afterwards (0 VACUOUS required) and `lit --filter` each.
   Item 2 is a source (comment) edit ⇒ the rebuild covers it; record the new hash.
B. `cq-opt-equivalence-full`: **OWED** (decline strings moved: `m05`/`p20` → later fences; analysis sites
   changed in `SelectClassify` and the `hcrg` graph).
C. Corpus ONCE on the merged binary over ALL corpora the template names PLUS `$SES/trackM/probes/impl`,
   `$SES/trackM/review_M_r{1,2}_probes`, `$SES/trackR/*probes*`, `$SES/trackC/*probes*`, `$SES/trackL/probes`.
   Expected movers vs ORACLE: DECLINE→ACCEPT on `control flow` at a select (M), on F2's string (R-1), on
   `operand not recognized` (C); string moves `control flow`→`condition measured before the control route`
   (`m05`) and →`condition predates a non-diagonal gate` (`p20`); 0 ACCEPT→DECLINE; 0 both-accept circuit
   changes; every accepting mover STRICT 2b. ⚠ md5s are not comparable ACROSS sweeps (the temp `ModuleID`
   changes) — compare within a row only.
D. Duplicate-body scan: M fixed 7 `NOROUTE-NOT: phi` fixtures in place (no renames) — run the scan anyway
   (three landings' fixtures now coexist).

## Customers (step 7) — the session's headline measurements, on the MERGED binary

* **C1** `$SES/probes/owner_file_2026-09-13.c`: exit 0, stderr 0 bytes, STRICT 2b, **29 lines**
  byte-identical to `tests/e2e/slice_control_cascade_two_bools.expected.log`; first 16 lines = `va.trace`
  lines 1–16.
* `$SES/probes/va.c` 19 = `va.trace`; `$SES/probes/vb.c`, `vc.c` 29 each (same string as C1's? measure).
* `$SES/trackM/probes/m16.c` (run-time `a`) 31; `probes/impl/i2_cmpladder.c` 21.
* `$SES/trackR/probes/b_A_intb0_boolb1.c` 22 = its golden; `$SES/trackC/probes/owner_2026-09-11_2218.c` 15.
* **C2** `$SES/probes/vd.c`: expected DECLINE F2's string (R-2 is an owner ruling) — record the anchor;
  ALSO measure `vd` with the third region's guard neutralised (`$SES/trackR/probes/v_vd_guard_neg.c`):
  expected ACCEPT now (M + R-1 landed) — line count and 2b.
* `$SES/trackR/review_R1_r1_probes`' and `review_integration_probes`' `G6_quantum_mux_values.c`: ACCEPT 26.

Record `$SES/trackM/MERGE_M_1.md` in the worktree + `GATES.md`. Final message per the template, plus the
C1/C2 lines verbatim.
