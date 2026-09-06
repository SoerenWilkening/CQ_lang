# rebase_inc2 — progress

## 2026-09-06 step 0 — orientation
- Main checkout `/Users/sorenwilkening/Desktop/CQ_lang` on `main` at **a3c1513** (Inc 0 + Inc 1 LANDED). Not touched.
- My worktree: `$SP0/wt/inc2` = `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/0a61aa31-6fbe-43af-b2fd-a09b6d203ae5/scratchpad/wt/inc2`, branch `3qlq-inc2` at **87a90d7** (base dfb8e83).
- Landed-Inc-1-only binary for immediate use: `$SP/wt/fix-c1/build/ir-pass/{cq-opt,libCQPass.so}`.
- Next: read the records (impl_inc2.md, fix_inc2_r1.md, review_inc2_V1/V2, BRIEF_impl_inc2, RETIRE_SWAP_ROUTE_INC2_NOTES §1, PRD §7 + §0 E1), then rebase.

## 2026-09-06 step 1 — REBASE DONE (`git rebase a3c1513`), 15 commits replayed, 2 conflicts
- Backup ref `3qlq-inc2-prerebase` = 87a90d7 (pre-rebase tip).
- New tip: `a9cd880`; base = a3c1513.
- Overlap measured by `comm` over the two `git diff --name-only` lists: **SEVEN** files, not six
  (the brief's six + `ir-pass/src/ArithLowering.cpp`).
- CONFLICTS (2 of 7 overlap files):
  1. `ir-pass/test/control_swap_value_diamond_derived.ll` (commit 5b1d723) — Inc 1 migrated the
     fixture off the register `cq_phi` (DELETED the `%pd = cq_phi_si32(%p,0.9)` line and its
     `cqrt_rz_i32` CHECK); Inc 2 re-derived the whole CHECK block for the merge and added
     NOROUTE/FCNT/CCNT prefixes. Resolved = Inc-2 structure + Inc-1's migration note line.
     ⚠ MUST BE RE-DERIVED from the rebased binary (Inc 2's CHECKs still expect `cqrt_rz_i32`).
  2. `ir-pass/src/SwapRouteEmit.cpp` (commit 0efe1f0) — one include line; both sides edited the
     same comment. Resolved = BOTH includes (`ChainWalk.h` from Inc 1, the widened
     `CompareLowering.h` comment from Inc 2).
- AUTO-MERGED (no conflict, must still be verified BY INTENT): `ControlPlan.h`, `EmitInverse.cpp`,
  `ArithLowering.cpp`, `retire-swap-route-PRD.md`, `tests/e2e/CMakeLists.txt`, and the 1a8cae0
  `SwapRouteEmit.cpp` value-path rewrite (Inc 1's hunks are at lines 20-40/129/1249+/1356+/1594+,
  Inc 2's at 5-40/190-490 — disjoint apart from the file header).
- Next: verify the auto-merges by intent BEFORE building.

## 2026-09-06 step 2 — build + first lit + the three intent repairs (commit 3c7df8f)
- `cmake --build build -j8` in `$SP0/wt/inc2`: **BUILD_EXIT=0** (`rebase_inc2_build1.log`), BOTH
  CQPass and cq-opt.
- `lit ir-pass/test` (run 1, pre-repair): 1685 discovered, 1683 passed, 1 XFAIL, **1 FAILED** =
  `control_swap_value_diamond_derived.ll` — the ONLY red the rebase produced.
- Repairs (all MEASURED, see notes §3):
  1. `control_swap_value_diamond_derived.ll` RE-DERIVED from the rebased binary (one `CHECK-NEXT`
     for `cqrt_rz_i32` removed — Inc 1 deleted the `cq_phi` that produced it). Header rewritten:
     the file no longer pins a derivation, and says so.
  2. `tests/e2e/slice_control_value_derived.c` did NOT COMPILE (`cq_phi(p,0.9)` → "too many
     arguments"). Measured (a) delete the line → BYTE-IDENTICAL program+trace to
     `slice_control_value_diamond` (duplicate; OQ-5 precedent) vs (b) `p = cq_theta(p,0.9)` →
     accepts on ORACLE 52d7764 (29 lines, route), landed Inc-1 `main` (29, route) and HEAD
     (24, merge = diamond's 23 + one `cqrt_ry_i32`), STRICT 2b rc=0 on all three. **(b) kept**,
     golden regenerated.
  3. `EmitInverse.cpp` cswap-seam prose corrected by INTENT (it named NestedRouteEmit as live).
- `lit ir-pass/test` (run 2, post-repair): **1685 discovered · 1684 passed · 1 expectedly failed**,
  32.5 s, LIT_EXIT=0 (`rebase_inc2_lit2.log`).
- Fixture arithmetic: 1582 (dfb8e83) + 91 (Inc 1) = 1673 (a3c1513); 1582 + 12 (Inc 2) = 1594
  (87a90d7); 1673 + 12 = **1685** (HEAD). `ls ir-pass/test/*.ll | wc -l`.
- `add_test(NAME` in tests/e2e/CMakeLists.txt: 317 (base) → 338 (a3c1513, +21) / 330 (87a90d7,
  +13) → **351** (HEAD) = 317+21+13. No duplicate names, no duplicate slice sources (`uniq -d`).
- **cswap census (the epic goal): `grep -rn 'emitRoute(' ir-pass/src ir-pass/include` = 3 lines —
  the definition, the declaration and ONE call site `AbortParkEmit.cpp:396`.**
  `NestedRouteEmit.{cpp,h}` do not exist.
- Next: rebuild (EmitInverse comment), then the gate table.

## 2026-09-06 step 3 — the gate table (all measured on the REBASED binary at 3c7df8f)
| # | gate | command | result |
|---|---|---|---|
| 1 | `ir-pass-lit` | `lit ir-pass/test` | **1685 discovered · 1684 passed · 1 expectedly failed** (the standing `lowering_invert_add_i32.ll` XFAIL), 32.5 s, LIT_EXIT=0 |
| 2 | Inc-2 twin gates + slices, Inc-1 phase gates + perbit | `ctest -j6 -R 'e2e-value-.*-twin-identical\|e2e-phase-.*\|e2e-slice-control-value\|e2e-slice-control-switch-value\|perbit\|e2e-slice-control-phase'` | **40/40 PASSED**, 26.4 s |
| 3 | injection matrix (7 mutations × the value/switch ACCEPTS) | `W=… python3 inject.py <15 accepts>` | **15/15 controls clean · 0 NOT CAUGHT · 0 CONTROL FAILED**, rc=0 (`rebase_inc2_inject.log`). fix_inc2_r1 ran 14; the 15th is `control_swap_value_ifelse_head_out_of_place.ll` |
| 3b | stage 2b STRICT on those 15 | `free_pairing_check.py` (no `--allow-unproven`) | **15 clean / 0 violations** |
| 4 | cswap / Rz census, WHOLE corpus | lower all 1685 `ir-pass/test/*.ll`, scan the OUTPUT | 857 DECLINE, 828 accept. `cqrt_cswap` in the OUTPUT of **6** files: the 5 abort-park fixtures + `lowering_uncompute_interior_leak_unrecorded_route.ll`, whose 2 cswaps are **hand-written in its INPUT** (it is the M-B clause-(d2) leak probe, not an emitter output). **NON-i1 `cqrt_rz` in any output: 0.** `#cqrt_rz_i1 == #!cq.branchphase` in **every** fixture; totals **263 = 263** |
| 4b | source-level cswap census | `grep -rn 'emitRoute(' ir-pass/src ir-pass/include` | **3 lines: the definition, the declaration, and ONE call site `AbortParkEmit.cpp:396`.** `NestedRouteEmit.{cpp,h}` do not exist. THE EPIC'S CSWAP GOAL IS MET |
| 4c | kickback-record parity | `grep -rn 'CreateCall(Rz' / 'markBranchPhaseGate('` | **6 = 6 on HEAD, and 6 = 6 on `main` a3c1513** — the value path adds NONE |
| 5 | goldens vs the landed Inc 1 | `git diff --name-status a3c1513 HEAD -- 'tests/e2e/*.expected.log'` | **2 MODIFIED, 9 ADDED, 0 deleted.** The two modified are exactly the two route goldens Inc 2 already regenerated: `slice_control_value_diamond` and `slice_control_switch_value`. **ZERO phase goldens moved.** Goldens containing `cqrt_cswap`: 3 on main → **1** here (`slice_control_abort`). Non-i1 `cqrt_rz` in any golden, tree-wide: **0** |
| — | counts | `ctest -N` | HEAD **361** total / **351** `^e2e-` / **317** `^e2e-slice-`; main a3c1513 **348 / 338 / 308**. Delta +13/+13/+9 = Inc 2's 9 new slices + 4 `cmp` twin gates |
| — | fixtures | `ls ir-pass/test/*.ll \| wc -l` | **1685** = 1673 (main) + 12 (Inc 2) |

## 2026-09-06 step 4 — remaining gates + the PRD branch note (commit 6ee3ea3)
- `ctest -j6 -R 'e2e-loop-twin-matrix|e2e-loop-twin-quarantine-selftest'`: **2/2 PASSED**
  (matrix 209.2 s), CTEST_EXIT=0.
- `ctest -j4 -R '^e2e-' -E 'e2e-loop-twin-matrix'`: **100% passed, 0 failed out of 350**,
  140.1 s, CTEST_EXIT=0. With the matrix that is all **351** `^e2e-` entries green.
- `ctest -j6 -R 'runtime|frontend-lit'`: **9/9 PASSED**, 2.8 s.
- Doc: the PRD §0 status paragraph ("Increment 2 … is NOT [implemented]; `cqrt_cswap` is still
  minted by the value-arm path; `3qlq-inc2` owes a rebase") is true of `main` and FALSE on this
  branch — scoped to `main` + a dated branch note rather than rewriting a landed paragraph.
- Branch `3qlq-inc2` tip **6ee3ea3**, 17 commits above a3c1513, working tree clean, NOT pushed.
  Sources changed vs main: 7 files (`ControlPlan.h`, `SwapRouteEmit.h`, `SwitchRouteEmit.h`,
  `ArithLowering.cpp`, `EmitInverse.cpp`, `SwapRouteEmit.cpp`, `SwitchValueEmit.cpp`).
  `git diff --stat a3c1513 HEAD`: 55 files, +3427 / -917.

## OWNER QUESTION / residuals for round 2 (none of them mine to decide)
1. **The Inc-2 REVIEWER FLAG is NOT dissolved by Inc 1 — MEASURED.** `OWNER_QUESTIONS.md`
   says "after Inc 1 there is NO Rz lineage any more (cq_phi is register-free), so this class
   must be re-asked post-rebase". Re-asked: with `p = cq_theta(p, 0.9)` as the derivation the
   pre-hoisted select TWIN still DECLINES `cq controlled lowering: control flow under quantum
   control` on the rebased binary while the `br` diamond ACCEPTS, so `emitSelectRegion` is
   still reachable with a coherent ROTATION-lineage operand `SelectClassify` refuses at its own
   front door. Reproducers: `tests/e2e/slice_control_value_derived.c` (accept, 24 lines) and the
   same body with `int t = R(p); p = (q>5) ? t : p;` (decline). Notes §3.6. Round 2's first target.
2. **`control_swap_value_diamond_derived.ll` no longer pins a derivation.** Inc 1's landed
   migration deleted its `cq_phi`; I re-derived the CHECKs and said so in the header rather than
   re-spelling the BODY with `cq_theta` (that would reverse an Inc-1 landed decision). One line
   restores the property if the owner wants it. OQ-9 class.
3. **PRE-EXISTING doc item, on `main`, not a rebase defect:** `ir-pass/include/ChainWalk.h:204`
   says "Inc 2 turns on `emitRz`'s controlled arm and inherits the freeze". `git log -S` dates
   that line to `f92d95e` (the **drbq** epic), so "Inc 2" there means drbq Inc 2a — and 3qlq
   Inc 1 has since DELETED `emitRz`. Ambiguous reference on main; out of this rebase's scope.
4. Inc 2's own three owner questions are unchanged by the rebase: OQ-11 (Q+Q *condition* for
   value arms, one 4-line `if`), OQ-12 (run-time classical shift amount ≥ W), OQ-13 (the
   `value-arm swap-route` decline string names a retired mechanism — 6 sites, 28 fixtures).
5. Still owed on this branch: Rule-13 **round 2**, the clearance, and the landing. NOT pushed;
   no bd issue touched.
