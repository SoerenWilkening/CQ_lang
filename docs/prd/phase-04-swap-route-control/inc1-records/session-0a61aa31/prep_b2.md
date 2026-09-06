# prep_b2 — Inc 1 prep (b2): resolve the 74 slices on the Inc-1 binary; regenerate goldens under the audit
Worktree: $SP/wt/prep-b, branch 3qlq-inc1-slices, rebased onto c4bd888 (Inc 1a + round-1 fixes + Inc 1b merged).
SUBJECT = $SP/wt/prep-b/build (mine).  ORACLE = $SP/wt/pre-3qlq/build.

## 2026-09-05 step 0 — context read + build started
Read: BRIEF_common, BRIEF_prep_b2_slices, BRIEF_prep_b_slices, progress/prep_b.md,
PRE_DISPOSITIONS.md §5 (7 OQs), OWNER_QUESTIONS.md (OQ-2..OQ-8 dispositions + F-L7-1/F-L5-1),
impl_inc1a.md, impl_inc1b.md, fix_r1.md (incl. the Inc-1b merge section), and the
`--epic 3qlq` section of tools/golden_multiset_audit.py (the four substitutions (a)-(d),
the 63-golden classification table, the _C_CAVEAT 15-keep-alive list).
Started `cmake -S . -B build` + `cmake --build build -j8` in the BACKGROUND
(logs $SP/progress/prep_b2_{cfg,build}.log). Configure CLEAN in 10.3s.
Next: sweep script for the 74 slices on the SUBJECT.

## 2026-09-05 step 1 (RESUMED after rate-limit kill) — build verified FRESH
`stat` on $SP/wt/prep-b/build/ir-pass/{cq-opt,libCQPass.so} = 2026-09-05 16:56:27 / 16:56:23;
newest ir-pass source = 16:51:59.  Build log tail = `BUILD_OK`, both targets linked.
NO rebuild needed.  git: branch 3qlq-inc1-slices, tip 135334d, worktree clean.
$SP/progress/prep_b2_slices.txt already holds the 74 slice names (measured by the killed run).
Re-read in this step: BRIEF_common, BRIEF_prep_b2_slices, BRIEF_prep_b_slices, prep_b.md,
PRE_DISPOSITIONS.md §5 (OQ-1..OQ-7), OWNER_QUESTIONS.md (OQ-2..OQ-8 + F-L7-1/F-L5-1),
and the audit's `--epic 3qlq` block (four substitutions (a)-(d), the 63-golden table,
the 15-slice `_C_CAVEAT` keep-alive list).
Next: read impl_inc1a.md / impl_inc1b.md / fix_r1.md, then the 74-slice sweep.

## 2026-09-05 step 2 — the 74-slice SUBJECT sweep (MEASURED)
Harness `$SP/progress/prep_b2_work/sweep_subj.sh` (stage 1 clang 19.1.7 `-I$WT/include
-include CQ.h -O1`; multi-TU via `llvm-link` for the 3 callers; stage 2 = SUBJECT
`$SP/wt/prep-b/build/ir-pass/cq-opt` + libCQPass.so; stage 2b STRICT; stage 3 links the
SUBJECT archives; stage 4 trace).  TSV: `$W/subj/dispositions.tsv`, artifacts `$W/subj/`.
⚠ first run had `declare -A` (bash 3.2) fail -> the 3 multi-TU rows were single-TU;
patched to a `case` and RE-RUN whole.  The numbers below are the SECOND run.

**60 ACCEPT (exit 0) · 14 DECLINE (exit 1).**  stage 2b STRICT: 59 PASS, 1 FAIL
(`slice_loop_break_qq_phase`, which ships `--allow-unproven` — and is OQ-5's DELETE).
The 14 declines:
  10 x `slice_control_inplace_ry_loop*` — 8 `condition predates a non-diagonal gate`
      (OQ-3's set) + `_grover` `control flow inside a loop body` + `_grover_unrolled`
      `control flow`   ⚠ the two `_grover` ones are NOT in OQ-3's list of 8
  slice_control_phase_grover_loop  `cq taint escape: tainted value muxed by a
      classical-condition ...`   ⚠⚠ FINDING F-B2-1: a NEW §6.5 slice, PRD P6, whose
      hand-unrolled twin ACCEPTS (32 lines).  impl_inc1a measured `p6_rolled2` (rolled
      Grover K=3) ACCEPTING at 33 lines — so this is a shape difference, to be diagnosed.
  slice_control_phase_nest_deep    `impure phase arm`   (OQ-7 disposition: leaves CMake)
  slice_control_switch_phase       `cq QRAM access: const-global table read under
      tainted control` (OQ-11/OQ-4, the `-O1` table fold — expected, no P5 e2e customer)
  slice_select_rail_alias_cond     `cq_measure_<sfx> operand not recognized` (OQ-5)
Next: diagnose F-B2-1, then execute OQ-2 (15 keep-alive), OQ-3 (8+? loop), OQ-5, OQ-7.

## 2026-09-05 step 3 — F-B2-1 DIAGNOSED: a SLICE defect, not an Inc-1 one (MEASURED)
`slice_control_phase_grover_loop.c` seeds `int q = 0;` and puts the FIRST `cq_theta`
INSIDE the loop, so `-O1` builds the header phi `%5 = phi i32 [0,%entry],[%10,%latch]` —
a CLASSICAL constant merged with a tainted value. `declineClassicalMuxes` refuses it.
Two-line probes, BOTH binaries ($W/probe/pg{1,2}.c):
  pg1 `int q=0; for(i<3) q=cq_theta(q,.3); measure` →
      SUBJ `cq taint escape: tainted value muxed by a classical-condition phi`
      ORAC `cq taint escape: tainted value muxed by a classical-condition phi`   IDENTICAL
  pg2 (same + one `q=cq_theta(q,.3)` BEFORE the loop) → SUBJ exit 0, ORAC exit 0
So the decline is PRE-EXISTING and arm-class-independent; the shipped
`slice_control_grover_loop.c` (which ACCEPTS) already puts its seed theta before the loop,
and impl_inc1a's accepting `p6_rolled2` probe does too. FIX = move the seed out of the
loop in the new slice + its unrolled twin (no golden exists for either yet).

## 2026-09-05 step 3b — the two `_grover` inplace-Ry slices: MIGRATION consequence, both binaries
`slice_control_inplace_ry_loop_grover_unrolled` has NO loop and still declines
`control flow`. CAUSE (measured on its stage-1 IR): with `cq_phi` register-free the two
consecutive `if (q==5) cq_phi(PI); if (q==3) r=cq_theta(r,.9);` are fused by SimplifyCFG
into ONE `switch i32 %1, [5 -> phase arm, 3 -> Ry arm]` — a MIXED-arm switch, §6.3.
The ORACLE declines both `_grover` slices with the SAME strings
($SP/progress/pre_dispositions.tsv), so this is the migration's stage-1 shape, not Inc 1.
They join OQ-3's set: 10 `slice_control_inplace_ry_loop*` slices to re-base, not 8.

## 2026-09-05 step 4 — F-B2-1 fix + OQ-3 (10 slices) — ALL 12 NOW ACCEPT, EVERY TWIN IDENTICAL
F-B2-1: seed `cq_theta` moved OUT of the loop in `slice_control_phase_grover_loop.c` and
its unrolled twin (body reordered to `if O; ry; if R0; ry` so the two files stay one
activation apart).  MEASURED on the SUBJECT: both exit 0, 2b STRICT PASS, **33 trace lines,
BYTE-IDENTICAL**; K-independence re-measured on the LOWERED IR — `@slice` is **25 lines at
K=3 and 25 at K=1000**.  The trace is the P6 stream verbatim (ry · icmp mint · rz_i1 ·
icmp `_unc` · free) ×6, zero `cqrt_cswap`, zero `_controlled`, zero non-i1 `cqrt_rz`.
OQ-3 (8 slices): `q = cq_theta(q, 0.05);` ADDED after every `cq_phi(0.1);` (the uncontrolled
`cq_phi` KEPT — D2 deletes it, class (c)).  MEASURED: 8/8 exit 0, 2b STRICT PASS,
16/16 · 18/18 · 27/27 · 21/21 lines, all FOUR twin pairs BYTE-IDENTICAL.
  ⚠ the two `_leak` slices emit the F-L7-2 warning `cq rotation lowering: non-diagonal gate
  over a live derived record` (rolled 1×, unrolled 2× — per REGION, not a trace difference);
  their traces are identical.  That warning is OWNER_QUESTIONS' open severity question.
OQ-3 (the 2 `_grover` slices): the S† `cq_theta` MOVED to sit BETWEEN the two `if`s, which
is what stops SimplifyCFG fusing a phase arm and an Ry arm into one mixed switch.
MEASURED: both exit 0, 2b PASS, **26 lines, BYTE-IDENTICAL**.
All 12 files carry a `⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-3 / prep-b2)` header block naming
the measurement and the reason.  Next: OQ-2, the 15 keep-alive slices.

## 2026-09-05 step 5 — OQ-2: the 15 keep-alive slices rewritten as DERIVED-CONDITION KICKBACKS
Every `cq_phi(θ);` keep-alive site (18 sites, 15 files) became `if (<dead terminal> <cmp> k)
cq_phi(θ);`.  MEASURED on the SUBJECT: **15/15 exit 0, 2b STRICT PASS**.
⚠ TWO THINGS HAD TO BE MEASURED RATHER THAN ASSUMED, and both changed the edit:
 (1) `slice_compare_qq`: `if (eq == 1)` collapses to `br i1 (icmp eq i32 %p, %q)` — a Q+Q
     branch condition — and declines `no template for opcode 'icmp i1' in tainted context`.
     Fixed with `int acc = eq + pi; if (acc == 4)`, which keeps the Q+Q compare LIVE and
     makes the BRANCH condition Q+C.  Golden now carries `cq_template_icmp_eq_i32_unc`.
 (2) A plain `==` against a constant is FOLDED THROUGH an invertible op, so five sites
     silently lost the very symbol they exist for. MEASURED folds: `bswap(c)==K` -> `c==K'`;
     `clz(c)==12` -> a range test on c; `sext(b)==K` -> `b==K`; `-fc==K` -> `fc==-K`;
     `(a<<2)^9==9` -> a mask test. Re-spelled as ORDERED compares (`d > 100u`, `b > 100`,
     `t > 100`) or Q+Q ops against a SECOND tainted register (`d + (int)c`,
     `lb * (long)cq_theta(y,.35)`, `fn * cq_theta(z,.45)`).
RECOVERED `_unc` SYMBOLS, measured in the new traces (`grep -o 'cq_template_.*_unc'`):
  bswap_i32 · ctlz_i32 · ctpop_i32 · fma_f64_qlq · fmin_f64 · fshl_i32_qql · fadd_f16 ·
  fadd_f80 · and_i64_hl (the i40 mask) · bitcast_f80_to_i80/lshr_i80_hl/trunc_i80_to_i16/
  zext_i16_to_i64 (fp80 union) · shl_i32_hl + cqrt_xorc_i32 + mul_i32 (dead_dag) ·
  shl_i32_lh + sub_i32_lh + sext_i32_to_i64 + fneg_f32 (dead_shapes) · icmp_eq_i32 (Q+Q).
**ZERO of the 15 lost coverage**; no `cq_measure` fallback was needed.
Each file carries a `⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-2 / prep-b2)` header naming the
old idiom, the new one, the recovered symbol, and the fold measurement.

## FINDING F-B2-2 (for the reviewers — message truth + fence LOCATION, not a miscompile)
A Q+Q branch-phase condition — plain C `int p=cq_theta(x,.1); int q=cq_theta(y,.2);
if (p == q) cq_phi(.3);` ($SP/progress/prep_b2_work/probe/qq1.c) — declines on the SUBJECT
with `no template for opcode 'icmp i1' in tainted context` and on the ORACLE with
`cq controlled lowering: control flow under quantum control`. Both loud, both exit 1.
TWO things worth a reviewer's eye: (a) impl_inc1a.md's "What is LEFT" item 4 states the
message is "byte-identical to the oracle's for the same shape" — MEASURED IT IS NOT;
(b) the subject's string is emitted by the OPCODE layer, i.e. the CONTROL layer did not
refuse the shape and the decline is carried by a MISSING TEMPLATE downstream. The shipped
fixture `control_phase_kickback_reject_qq_compare.ll` pins exactly that string, so there is
no drift risk today, but a fence that holds because a template is absent is the weakest
kind. Not mine to decide.

## 2026-09-05 step 6 — the 71 goldens, the audit, and the enable (MEASURED)
FINAL SWEEP (after every source edit): `sweep_subj.sh $(cat prep_b2_slices_final.txt)`
-> **71/71 exit 0 · 71/71 stage 2b STRICT PASS · 71/71 link + trace**.
(74 - 3: `slice_loop_break_qq_phase`, `slice_control_phase_nest_deep`,
`slice_control_switch_phase` left the registration set — §OQ-5/OQ-7/OQ-11.)
Goldens installed: 61 regenerated + 10 new.
AUDIT: `python3 tools/golden_multiset_audit.py --epic 3qlq --selftest` -> **PASS,
0 survivors** (25 mutants + 10 controls + 2 tolerance pins).
`... --epic 3qlq --rev 52d7764 <the 71>` (log prep_b2_audit3.log):
  **33 SUBSTITUTION-ONLY · 1 AMBIGUOUS-d · 1 AMBIGUOUS-ca · 10 NEW-FILE · 26 FINDING**
  and the 26 FINDINGs are EXACTLY the 26 REWRITTEN PROGRAMS (15 OQ-2 + 10 OQ-3 +
  1 OQ-5), each listed in inc1-records/GOLDEN_REGEN.md. **0 unexplained diffs.**
 ⚠ NOTE the audit CRASHES (`FileNotFoundError`) if a DELETED golden is in its
  default changed-file set; run it on an explicit list. Recorded, not fixed (the
  tool is prep-c's).
TREE-WIDE SCANS (the standing witnesses):
  `cqrt_rz_i1` with a NEGATIVE angle: **0** of 303 goldens  <- the F-L7-1 witness
  `cqrt_rz_<W>_controlled`:            **0**
  non-`i1` `cqrt_rz`:                  **0** (56 goldens carry a `cqrt_rz`, all _i1)
  `cqrt_rz_i1` lines total:            **161**
 -> PRD §5's "not emitted" table is true at the only layer that LINKS.
⚠ THE (b)-NEST MODEL WAS CONFIRMED BY MEASUREMENT. The audit's nest row was a
  TRANSCRIPTION of PRD §3 onto SelectMergeEmit's `and` node, one golden, unmeasured,
  with the instruction "diff it against this model and fix whichever is wrong".
  `slice_control_nested_phase` audits SUBSTITUTION-ONLY with observed == expected:
  -9 [alloc_i32 x2, cswap x4, free, rz_i32 x2] +5 [alloc_i1, rz_i1 x2, toffoli x2],
  cswap 4->0, toffoli 0->2. The model and the compiler AGREE.
⚠ THE (d) TOLERANCE FIRED AND PASSED: recovered A = fl(B+D) = 0x1.ccccccccccccep-1
  vs the new trace's 0x1.ccccccccccccdp-1 — ONE ULP, err 1.110e-16, tol 3.331e-16.
CMake: the `set_tests_properties(... DISABLED TRUE)` call DELETED (13 entries live;
the 14th, `e2e-slice-control-phase-nest-deep`, was removed instead of enabled).

## 2026-09-05 step 7 — THE 74-SLICE DISPOSITION TABLE (measured SUBJECT vs PRE_DISPOSITIONS' analytic class)
`expected` is PRE_DISPOSITIONS.md §4's ANALYTIC column (written before any lowering existed).
`measured` is the FINAL sweep on $SP/wt/prep-b/build (after this agent's source edits).
| slice | kind | expected class (analytic) | MEASURED on the SUBJECT | note |
|---|---|---|---|---|
| `onward_ctl_phase_caller` | migrated | P1 | ACCEPT, 17 lines, 2b PASS |  |
| `slice_bitint` | migrated | P7 + PURPOSE LOST | ACCEPT, 18 lines, 2b PASS |  |
| `slice_classical_if_gate` | migrated | P7 ×2 | ACCEPT, 6 lines, 2b PASS |  |
| `slice_classical_switch_gate` | migrated | P7 ×7 | ACCEPT, 6 lines, 2b PASS |  |
| `slice_compare_qq` | migrated | P7 + PURPOSE LOST | ACCEPT, 26 lines, 2b PASS |  |
| `slice_control_angle_select_rz` | migrated | P2 | ACCEPT, 13 lines, 2b PASS |  |
| `slice_control_angle_select_rz_twin` | migrated | P1 + P7 | ACCEPT, 10 lines, 2b PASS |  |
| `slice_control_cond_datause` | migrated | §6.3 DECLINE | ACCEPT, 10 lines, 2b PASS |  |
| `slice_control_cond_onward_phase` | migrated | P7 | ACCEPT, 19 lines, 2b PASS |  |
| `slice_control_grover_2iter` | migrated | P1 ×4 | ACCEPT, 28 lines, 2b PASS |  |
| `slice_control_grover_derived_oracle` | migrated | P1 ×2 | ACCEPT, 19 lines, 2b PASS |  |
| `slice_control_grover_derived_oracle_2iter` | migrated | P1 ×4 | ACCEPT, 35 lines, 2b PASS |  |
| `slice_control_grover_derived_oracle_offset` | migrated | P1 ×2 | ACCEPT, 22 lines, 2b PASS |  |
| `slice_control_grover_loop` | migrated | P6 ×2 | ACCEPT, 23 lines, 2b PASS |  |
| `slice_control_grover_loop_derived` | migrated | P6 ×2 | ACCEPT, 45 lines, 2b PASS |  |
| `slice_control_grover_loop_derived_unrolled` | migrated | P1 ×4 | ACCEPT, 45 lines, 2b PASS |  |
| `slice_control_grover_loop_dynamic` | migrated | P6 ×2 | ACCEPT, 33 lines, 2b PASS |  |
| `slice_control_grover_loop_leading_gate` | migrated | P6 | ACCEPT, 21 lines, 2b PASS |  |
| `slice_control_grover_loop_leading_gate_unrolled` | migrated | P1 ×2 | ACCEPT, 21 lines, 2b PASS |  |
| `slice_control_grover_loop_offset` | migrated | P6 | ACCEPT, 18 lines, 2b PASS |  |
| `slice_control_grover_loop_offset_unrolled` | migrated | P1 ×2 | ACCEPT, 18 lines, 2b PASS |  |
| `slice_control_grover_loop_range_oracle` | migrated | P6 / P3 | ACCEPT, 19 lines, 2b PASS |  |
| `slice_control_grover_loop_range_oracle_unrolled` | migrated | P3 ×2 | ACCEPT, 19 lines, 2b PASS |  |
| `slice_control_grover_loop_two_regs` | migrated | P6 ×2 | ACCEPT, 30 lines, 2b PASS |  |
| `slice_control_grover_loop_two_regs_unrolled` | migrated | P1 ×4 | ACCEPT, 30 lines, 2b PASS |  |
| `slice_control_grover_loop_unrolled` | migrated | P1 ×4 | ACCEPT, 23 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 16 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_grover` | migrated | P6 (phase) + drbq Inc-3 (Ry arm) | ACCEPT, 26 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_grover_unrolled` | migrated | P1 ×2 + drbq Inc-1 (Ry arms) | ACCEPT, 26 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_leading_gate` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 18 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_leading_gate_unrolled` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 18 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_leak` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 21 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_leak_unrolled` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 21 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_two_regs` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 27 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_two_regs_unrolled` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 27 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_unrolled` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 16 lines, 2b PASS |  |
| `slice_control_nested_phase` | migrated | P4 | ACCEPT, 15 lines, 2b PASS |  |
| `slice_control_phase_andcond` | NEW | P3 | ACCEPT, 17 lines, 2b PASS |  |
| `slice_control_phase_angle_select` | NEW | P2 | ACCEPT, 10 lines, 2b PASS |  |
| `slice_control_phase_angle_select_runtime_arms` | NEW | P2, run-time arms | ACCEPT, 10 lines, 2b PASS |  |
| `slice_control_phase_diamond` | migrated | §6.3 DECLINE | ACCEPT, 8 lines, 2b PASS |  |
| `slice_control_phase_grover` | NEW | P1 ×4 | ACCEPT, 22 lines, 2b PASS |  |
| `slice_control_phase_grover_loop` | NEW | P6 | ACCEPT, 33 lines, 2b PASS |  |
| `slice_control_phase_grover_loop_unrolled` | NEW | P1 ×6 | ACCEPT, 33 lines, 2b PASS |  |
| `slice_control_phase_ifelse_derived` | migrated | §6.3 DECLINE + a NEW shape | ACCEPT, 11 lines, 2b PASS |  |
| `slice_control_phase_ifne` | migrated | P1 | ACCEPT, 9 lines, 2b PASS |  |
| `slice_control_phase_nest` | NEW | P3 | ACCEPT, 17 lines, 2b PASS |  |
| `slice_control_phase_nest_deep` | NEW | P4 **or** §6.3 mixed-arm DECLINE | DECLINE: cq controlled lowering: impure phase arm under quantum contr | OQ-7 DELETED |
| `slice_control_phase_perbit_loop` | NEW | P6 | ACCEPT, 39 lines, 2b PASS |  |
| `slice_control_phase_perbit_loop_k32` | NEW | P6 | ACCEPT, 291 lines, 2b PASS |  |
| `slice_control_phase_perbit_loop_unrolled` | NEW | P1 ×4 | ACCEPT, 39 lines, 2b PASS |  |
| `slice_control_seq_grover` | migrated | P1 ×2 | ACCEPT, 15 lines, 2b PASS |  |
| `slice_control_seq_regions` | migrated | P1 ×2 | ACCEPT, 11 lines, 2b PASS |  |
| `slice_control_switch_eqfold` | migrated | §6.3 DECLINE | ACCEPT, 8 lines, 2b PASS |  |
| `slice_control_switch_phase` | migrated | NONE — P5 loses its only plain-C customer | DECLINE: cq QRAM access: const-global table read under tainted contro | OQ-4/11 UNREGISTERED |
| `slice_ctlz_idiom_loop` | migrated | P7 + PURPOSE LOST | ACCEPT, 46 lines, 2b PASS |  |
| `slice_f16` | migrated | P7 + PURPOSE LOST | ACCEPT, 17 lines, 2b PASS |  |
| `slice_f80` | migrated | P7 + PURPOSE LOST | ACCEPT, 20 lines, 2b PASS |  |
| `slice_fp80_union_unc` | migrated | P7 + PURPOSE LOST | ACCEPT, 32 lines, 2b PASS |  |
| `slice_funnel_fshl_qq` | migrated | P7 + PURPOSE LOST | ACCEPT, 17 lines, 2b PASS |  |
| `slice_intrinsic_bswap` | migrated | P7 + PURPOSE LOST | ACCEPT, 13 lines, 2b PASS |  |
| `slice_intrinsic_ctlz` | migrated | P7 + PURPOSE LOST | ACCEPT, 20 lines, 2b PASS |  |
| `slice_intrinsic_ctpop` | migrated | P7 + PURPOSE LOST | ACCEPT, 13 lines, 2b PASS |  |
| `slice_intrinsic_fma` | migrated | P7 + PURPOSE LOST | ACCEPT, 19 lines, 2b PASS |  |
| `slice_intrinsic_fpmath` | migrated | P7 + PURPOSE LOST | ACCEPT, 15 lines, 2b PASS |  |
| `slice_loop_break_qq_phase` | migrated | P7 | ACCEPT 187 lines | OQ-5 DELETED |
| `slice_loop_iter_local` | migrated | P7 + PURPOSE LOST | ACCEPT, 18 lines, 2b PASS |  |
| `slice_loop_phase_accum` | migrated | P7 | ACCEPT, 3 lines, 2b PASS |  |
| `slice_select_rail_alias_cond` | migrated | DECLINE `cq_measure_<sfx> operand not recognized` | ACCEPT, 17 lines, 2b PASS |  |
| `slice_uncompute_dead_dag` | migrated | P7 + PURPOSE LOST | ACCEPT, 22 lines, 2b PASS |  |
| `slice_uncompute_dead_shapes` | migrated | P7 + PURPOSE LOST | ACCEPT, 43 lines, 2b PASS |  |
| `slice_uncompute_interior_region_derived_cond` | migrated | P1 | ACCEPT, 19 lines, 2b PASS |  |
| `spec_select_caller` | migrated | P7 | ACCEPT, 12 lines, 2b PASS |  |
| `spec_twoarm_caller` | migrated | P7 | ACCEPT, 30 lines, 2b PASS |  |

### Where MEASURED differs from the ANALYTIC expectation (12 rows), and why
| slice(s) | expected | measured | why |
|---|---|---|---|
| the 4 `§6.3 DECLINE` rows (`..._phase_diamond`, `..._cond_datause`, `..._switch_eqfold`, `..._phase_ifelse_derived`) | DECLINE (N>1 `cq_phi` per arm) | **ACCEPT** | OQ-6 was DECIDED before implementation: N `cqrt_rz_i1` on ONE minted flag, exact, no arithmetic. PRD §6.3's stated ground ("summing angles is the 2b rounding class again") is a Ry-stem ground that does not survive D1. Implemented by impl_inc1a. `..._ifelse_derived` also needed OQ-8 (the merge-tail `phi double` angle select), also implemented. |
| the 8 `DECLINE condition predates a non-diagonal gate` rows (`slice_control_inplace_ry_loop*`) | DECLINE | **ACCEPT** | OQ-3 disposition executed here: `q = cq_theta(q, 0.05);` added as the loop-variant maker. The DECLINE the analytic column predicted is exactly what I measured BEFORE the rewrite. |
| `slice_select_rail_alias_cond` | DECLINE `cq_measure_<sfx> operand not recognized` | **ACCEPT** | OQ-5 disposition executed here: 3 of 5 lineages retired, 2 kept. Same: the predicted DECLINE is what I measured before the rewrite. |
| `slice_control_phase_grover_loop` | P6 (accept) | ACCEPT after a SOURCE FIX | finding F-B2-1 — see step 3. It declined `tainted value muxed by a classical-condition phi` as prep-b wrote it, on BOTH binaries. |
| `slice_control_inplace_ry_loop_grover{,_unrolled}` | P6 / P1×2 + drbq | ACCEPT after a SOURCE FIX | step 3b — `-O1` fused the phase `if` and the Ry `if` into ONE mixed-arm switch. Declines identically on the ORACLE. |

**No row where the compiler ACCEPTED something the record expected to DECLINE for a
CORRECTNESS reason.** Every accept above is either an orchestrator decision taken
before implementation (OQ-6/OQ-8) or a slice this agent rewrote under an explicit
disposition (OQ-2/OQ-3/OQ-5), and in the two F-B2 cases the pre-rewrite measurement
matches the oracle byte-for-byte.

## 2026-09-05 step 8 — `ctest -j6 -R '^e2e-'` (log prep_b2_e2e2.log, 1187.58 s)
**99% tests passed, 3 failed of 328.** Every red explained, and each names its owner:

1. `e2e-angle-select-rz-twin-identical` — **MINE, FIXED after that run** by retiring the
   gate. It asserted `compare_files` between the Rz angle select and its BY-DIFFERENCE
   manual twin, and under D2 that assertion is FALSE: the twin's leading `cq_phi(0.3)` is
   UNCONTROLLED, i.e. a GLOBAL PHASE the pass DELETES. MEASURED:
     subject `x(f); rz_i1(f,0x1.3333333333333p-2); x(f); rz_i1(f,0x1.ccccccccccccdp-1)`
     twin    `rz_i1(f, 0x1.3333333333334p-1)`   ( = fl(0.9-0.3) )
   Same state up to e^{i0.3}. Both slices KEEP their registration and their golden and
   both PASS individually (re-measured after the reconfigure: 2/2 Passed); the `fl(A-B)`
   relation is written into both headers and is hand-checkable. drbq Inc-4's state-prep
   group is the precedent ("a `compare_files` gate would assert something FALSE").
   prep-d's OQ-15 already recorded that NO byte-identity twin exists for this stem at all.
   → after `cmake -S . -B build` the e2e layer is **327 entries** (328 − this gate).
2. `e2e-fixture-guard-liveness` — **NOT MINE** (prep-a / the fixture re-derive). It fails
   on 7 SKIPs, and I verified every one: `lowering_io_tape_rz_preserving`,
   `lowering_live_record_mb_{router_phi,sibling_alias}_accept`,
   `lowering_uncompute_interior_leak_{region_wire_measured,route_in_interval}`,
   `lowering_uncompute_interior_region_{chain,routed_base}` — each has **2**
   `@cq_phi_<sfx>` references (`grep -c '@cq_phi_[a-z0-9]'`), i.e. each is in the retired
   family and the pass now declines it (rc=1), so its anchored NOFREE guard is unchecked.
   0 DEAD guards. impl_inc1b reported the identical failure for the identical reason.
3. `e2e-loop-twin-matrix` — **NOT MINE** (prep-d2; round-1 finding F-L5-7 + OQ-18).
   `274 cells — 50 ACCEPT-IDENTICAL, 33 DECLINE, 191 other; 15 quarantined`. Its GENERATOR
   emits programs on the RETIRED two-argument surface, so they fail at stage 1
   (`clang` error, `'cq_phi' declared here` in the log). It needs `--phi-surface void`
   and regenerated tables, which is prep-d2's brief.

## FINDING F-B2-3 — four slices whose SUBJECT was the uncontrolled Rz (recorded, NOT rewritten)
All four audit SUBSTITUTION-ONLY class (c) — D2 working as written — but their goldens
no longer exercise what their headers claim. MEASURED, golden then -> now:
  slice_classical_if_gate       1 rz -> 0 (6 lines)  the FIRES/does-NOT-fire contrast is gone
  slice_classical_switch_gate   2 rz -> 0 (6 lines)  byte-identical to the above now
  slice_loop_phase_accum        3 rz -> 0 (3 lines)  the loop body was ONE cq_phi; body empty
  slice_control_cond_onward_phase 1 rz -> 0 (19 lines) the ONWARD phase is gone; the 4.5
      switch DATA-MUX half is intact (3 mints, 3 controlled copies, 3 strips, 3 frees)
(+ spec_select_caller / spec_twoarm_caller lose a trailing onward phase line each and
keep their whole specialization stream — listed for completeness, no action needed.)
NOT rewritten deliberately: the remedy is the same CLASS of decision the orchestrator
took for OQ-2/OQ-3/OQ-5 and is not mine. Proposed one-liners are in GOLDEN_REGEN.md §12.

## 2026-09-05 step 9 — spot checks and two counts the docs agent will need
FLAGSHIP (PRD §1's own example). `diff 52d7764:slice_control_seq_grover.expected.log`
against the new one is EXACTLY two lines, class (a), and nothing else:
  -cqrt_rz_i32_controlled(h1, h0, 0x1.921fb54442d18p+1)  +cqrt_rz_i1(h1, 0x1.921fb54442d18p+1)
  -cqrt_rz_i32_controlled(h2, h0, 0x1.921fb54442d18p+1)  +cqrt_rz_i1(h2, 0x1.921fb54442d18p+1)
The phase now lands on the FLAG; `h0` is an operand of no gate but the compare.
D4's PER-BIT idiom (`slice_control_phase_perbit_loop`) emits per activation:
`and_i32_hl` -> `icmp_eq_i32_hl` -> `x` -> `rz_i1` -> `x` -> `icmp_unc` -> `and_unc` ->
TWO frees — i.e. the derived rail IS discharged inside the iteration (round-1 F-L5-1's
fix, visible in the golden). K-INDEPENDENCE re-measured on the LOWERED IR:
`@slice` is **25 lines at K=4 and 25 at K=32**.
COUNTS THAT MOVED and that CLAUDE.md/docs will need:
  * e2e ctest entries: **327** (`ctest -N -R '^e2e-'`), from 327 pre-existing + 14 prep-b
    registrations − 1 (nest-deep, removed) − 1 (loop-break-qq-phase, removed)
    − 1 (control-switch-phase, removed) − 1 (angle-select-rz-twin-identical, retired)
    ... i.e. 341 as prep-b left it, minus those 4, and 13 of the 14 now ENABLED.
  * `--allow-unproven` slices: **4**, not five — `e2e-slice-loop-break{,-qq,-qq-derived,-qq-i64}`.
    `slice_loop_break_qq_phase` was the fifth and is deleted (OQ-5). CLAUDE.md's
    "The five `e2e-slice-loop-break*` entries pass `--allow-unproven`" is now stale.
  * goldens in tests/e2e: **303** (295 + 10 new − 2 deleted).

## 2026-09-05 step 10 — FINAL `ctest -j6 -R '^e2e-'` (log prep_b2_e2e3.log)
**99% tests passed, 2 failed out of 327. Total 738.33 s.**
The 2 reds are the two NOT-MINE ones already diagnosed in step 8:
  `e2e-fixture-guard-liveness`  (prep-a / the fixture re-derive; 7 SKIPs, each fixture
      verified to carry 2 `@cq_phi_<sfx>` references, 0 DEAD guards)
  `e2e-loop-twin-matrix`        (prep-d2; its GENERATOR emits retired-surface programs
      and fails at stage 1 — the log's `'cq_phi' declared here` note)
`e2e-angle-select-rz-twin-identical` is GONE from the run (retired, §9) and both of its
slices pass in the 327.
SCOPE CHECK: `git diff --name-only 135334d HEAD | grep -v '^tests/e2e/' | grep -v inc1-records`
= **NONE**. 108 files changed, +2174 / -778, all inside the brief's allowed set.

# ======================= HAND-BACK (prep_b2) =======================

## 1. What shipped
Branch `3qlq-inc1-slices` in `$SP/wt/prep-b`, **7 commits** on top of `135334d`
(prep-b's tip after the orchestrator's rebase onto c4bd888 + the audit merge):
```
11c506c  F-B2-1 seed-outside-loop fix + OQ-3 re-base of the 10 inplace-Ry loop slices
6cd17cc  OQ-2 — the 15 keep-alive slices rewritten as derived-condition kickbacks
e2b1d13  OQ-5/OQ-7/OQ-11 dispositions (2 slices deleted, switch_phase unregistered,
         rail_alias trimmed from 5 lineages to 2)
92dd233  71 goldens regenerated on the Inc-1 binary + audited; 13 ctest entries ENABLED;
         inc1-records/GOLDEN_REGEN.md
d868b14  retire e2e-angle-select-rz-twin-identical (D2 deletes the twin's global phase)
8ced6b5  GOLDEN_REGEN.md §10/§11 — the 74-slice disposition table + the e2e reds
f05a08c  F-B2-3 — four slices whose subject was the uncontrolled Rz (recorded, NOT rewritten)
dc45595  final e2e numbers
```
**108 files changed, +2174 / −778.** SCOPE VERIFIED:
`git diff --name-only 135334d HEAD | grep -v '^tests/e2e/' | grep -v inc1-records` = **NONE**.
Nothing in `ir-pass/`, `runtime/`, `include/`, `tools/` was touched.

  * 28 `.c` REWRITTEN under an explicit disposition (15 OQ-2 + 10 OQ-3 + 1 OQ-5 + the 2
    F-B2-1 files), each with a `⚠ REWRITTEN PROGRAM` header naming the measurement
  * 71 goldens: **61 regenerated + 10 new**
  * 2 goldens + 3 `.c` + 4 ctest registrations REMOVED (§6 / §9 of GOLDEN_REGEN.md)
  * `docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md` — 476 lines

## 2. What I ran (only this)
| gate | result |
|---|---|
| full pipeline (1 → 2 → **STRICT** 2b → 3 → 4) on all 71 slices, SUBJECT binary | **71/71 exit 0 · 71/71 2b PASS · 71/71 link+trace** |
| `golden_multiset_audit.py --epic 3qlq --selftest` | **PASS, 0 survivors** (25 mutants + 10 controls + 2 tolerance pins) |
| `golden_multiset_audit.py --epic 3qlq --rev 52d7764 <the 71>` | 33 SUBSTITUTION-ONLY · 1 AMBIGUOUS-d · 1 AMBIGUOUS-ca · 10 NEW-FILE · **26 FINDING**, and the 26 are EXACTLY the 26 REWRITTEN PROGRAMS. **0 unexplained diffs.** |
| `ctest -j6 -R '^e2e-'` (final) | **325 passed / 2 failed of 327**, 738.33 s |
| tree-wide golden scans | `cqrt_rz_i1` with a NEGATIVE angle **0**; `cqrt_rz_<W>_controlled` **0**; non-`i1` `cqrt_rz` **0** of 303 goldens; `cqrt_rz_i1` lines **161** |
| K-independence, LOWERED IR | phase-grover-loop 25 lines at K=3 and K=1000; perbit 25 at K=4 and K=32 |
NOT RUN (deliberately, Rule 19 + brief): `ir-pass-lit`, `frontend-lit`, `runtime`,
`cq-opt-equivalence`, the full `ctest`. I changed no pass source and no `.ll` fixture,
so none of them can witness my edits; the orchestrator owns the full-suite gate.

## 3. Findings that are NOT mine to decide
* **F-B2-1** (RESOLVED as a slice defect, not a compiler one) — a loop whose taint
  SOURCE is inside the body declines `tainted value muxed by a classical-condition phi`
  on BOTH binaries. Pre-existing, arm-class-independent. Two-line reproducer in
  `$SP/progress/prep_b2_work/probe/pg{1,2}.c`. Fixed in the slice; no owner action.
* **F-B2-2** (OPEN, for the reviewers) — a Q+Q branch-phase condition declines on the
  SUBJECT with `no template for opcode 'icmp i1' in tainted context` and on the ORACLE
  with `cq controlled lowering: control flow under quantum control`. Both loud. TWO
  things: (a) `impl_inc1a.md` "What is LEFT" item 4 claims the message is
  "byte-identical to the oracle's for the same shape" — **MEASURED IT IS NOT**;
  (b) the subject's string comes from the OPCODE layer, so the CONTROL layer did not
  refuse the shape and the decline rests on a MISSING TEMPLATE downstream. The fixture
  `control_phase_kickback_reject_qq_compare.ll` pins that exact string, so there is no
  drift risk today, but a fence that holds because a template is absent is the weakest
  kind. Reproducer `$SP/progress/prep_b2_work/probe/qq1.c`.
* **F-B2-3** (OPEN, recorded NOT rewritten) — four slices whose SUBJECT was the
  uncontrolled Rz now test nothing: `slice_classical_if_gate` (1 rz → 0, 6 lines),
  `slice_classical_switch_gate` (2 → 0, 6 lines, now byte-identical to the former),
  `slice_loop_phase_accum` (3 → 0, 3 lines, the loop body is empty),
  `slice_control_cond_onward_phase` (1 → 0; the switch DATA-MUX half survives, the
  ONWARD phase does not). All audit SUBSTITUTION-ONLY class (c) — D2 working as
  written — which is exactly why a green suite cannot see it. Proposed one-line
  remedies in GOLDEN_REGEN.md §12; the decision is the same CLASS the orchestrator
  took for OQ-2/OQ-3/OQ-5 and is not mine.
* **AUDIT-TOOL DEFECT (prep-c's)** — `golden_multiset_audit.py` raises
  `FileNotFoundError` when a DELETED golden is in its default changed-file set. Run it
  on an explicit list. Not fixed here (out of my file scope).
* **A DOC COUNT THAT IS NOW STALE** — CLAUDE.md says "The five `e2e-slice-loop-break*`
  entries pass `--allow-unproven`". It is **four** now: `slice_loop_break_qq_phase` was
  the fifth and is deleted (OQ-5). For the docs agent.
* Two POSITIVE results worth carrying rather than filing:
  - the audit's **(b)-NEST shape was a MODEL** ("diff it against this model and fix
    whichever is wrong"); the real trace AGREES line-for-line — `slice_control_nested_phase`
    audits SUBSTITUTION-ONLY with observed == expected, cswap 4→0, toffoli 0→2.
  - the **(d) tolerance FIRED AND PASSED**: recovered `A = fl(B+D) = 0x1.ccccccccccccep-1`
    vs the new trace's `0x1.ccccccccccccdp-1` — ONE ULP, err 1.110e-16, tol 3.331e-16.
    An `==` there would have failed the flagship golden.

## 4. What is left
1. The **2 e2e reds**, both with a named owner and neither a lowering change:
   `e2e-fixture-guard-liveness` (prep-a / fixture re-derive — 7 retired-family fixtures
   the pass now declines, 0 DEAD guards) and `e2e-loop-twin-matrix` (prep-d2 — its
   generator emits retired-surface programs; needs `--phi-surface void`).
2. **F-B2-2** and **F-B2-3** need a ruling (above).
3. **P5 (phase switch) still has no e2e customer** — `slice_control_switch_phase.c` is
   kept in the tree UNREGISTERED with the measurement in its header; the capability is
   pinned in lit. OQ-11's table-fold recognizer is the only way to give it one.
4. **The aliased-operand COMPARE has no spelling left in CQ at any width** (§5.3):
   `cq_template_{icmp_slt_i32,icmp_eq_i32,fcmp_olt_f64,fcmp_oge_f64}(h,h)` and their four
   `_unc` twins have left the corpus. Only the ARITHMETIC alias survives. Recorded, not
   worked around.

## 2026-09-05 step 11 — audit RE-RUN at the final tree state (prep_b2_audit_final.log)
IDENTICAL to the step-6 run, so no later edit moved a golden:
  `AMBIGUOUS-ca 1 · AMBIGUOUS-d 1 · FINDING 26 · NEW-FILE 10 · SUBSTITUTION-ONLY 33`
  = **71**, and `routes collapsed: 1 region(s), 1 arm(s), 79 rz gate(s)`.
`--selftest` re-run: **PASS, 0 survivors**.
The tool exits 1 because of the 26 FINDINGs; every one is a REWRITTEN PROGRAM in
inc1-records/GOLDEN_REGEN.md §5. That is the tool working as its own docstring predicts
("FIFTEEN of the 31 (c) goldens will legitimately come back as FINDINGS, and that is the
tool working, not a bug in it") — the other eleven are OQ-3's loop family and OQ-5's
alias slice, both dispositioned before I started.
Branch `3qlq-inc1-slices` tip **dc45595**, working tree CLEAN.

## 2026-09-05 step 12 — ORCHESTRATOR REMEDY: F-B2-3's four slices REWRITTEN (all MEASURED)
Instruction received mid-session; all four §12 remedies applied, plus one thing the
proposal did not anticipate (the twin, below). Full pipeline, stage 2b **STRICT**:

| slice | new idiom | golden lines | 2b |
|---|---|---|---|
| `slice_classical_if_gate` | `if (taken) q1 = cq_theta(q1,.25);` / `if (nottaken) q2 = cq_theta(q2,.75);` | 6 → **7** | PASS |
| `slice_classical_switch_gate` | every arm's `cq_phi(θ)` → `q<n> = cq_theta(q<n>, θ)` (7 sites) | 6 → **8** | PASS |
| `slice_loop_phase_accum` | `for (i<n) { if (q == 2.0) cq_phi(0.1); q = cq_theta(q, 0.05); }` | 3 → **18** | PASS |
| `slice_loop_phase_accum_unrolled` | NEW hand-unrolled twin (3 activations, no loop) | **18** | PASS |
| `slice_control_cond_onward_phase` | `int t = r + argc; if (t == 10) cq_phi(0.25);` | 19 → **26** | PASS |

WHAT EACH PROVES AGAIN (read off the goldens, not asserted):
  * if_gate — `q1` now carries `ry(0x1p-1)` AND `ry(0x1p-2)`; `q2` carries only its
    base `ry`. The FIRES / does-NOT-fire CONTRAST is back, and `cq_theta` is in place
    so the merge phi is still a pure renaming for `liftOneRegisterMergePhi`.
  * switch_gate — `q1` gets base `ry(0.5)` + case 2's `ry(0.5)` + `ry(0.55)` (the
    2-GATE ARM is visible again); `q2` takes the DEFAULT arm, base `ry` only. Before
    the remedy this golden was BYTE-IDENTICAL to if_gate's.
  * loop_phase_accum — 3 × (`fcmp_oeq_f64_hl` mint · `cqrt_rz_i1` · `_unc` strip ·
    `cqrt_free`) with the flag minted, stripped and freed INSIDE its own iteration.
  * cond_onward_phase — the `dugh` second round now has TWO consumers of `%out`: an
    onward `cq_template_add_i32_hl(h1, 1)` + its `_unc`, AND an onward kickback region
    (mint, `cqrt_rz_i1`, strip, 2 frees). The 4.5 data-mux half is untouched.

⚠ THE ONE-LINE PROPOSAL WAS WRONG IN TWO PLACES AND BOTH HAD TO BE MEASURED:
 1. `for (...) q = cq_theta(q,.1);` replaces a PHASE with a ROTATION (Rule 7) — the
    orchestrator's kickback is what shipped. But a kickback needs a LOOP-VARIANT
    condition register: without a body gate on `q`, `-O1` LICM-hoists the `fcmp` and
    the program declines `condition predates a non-diagonal gate` (drbq.12 / row W).
    Hence the trailing `cq_theta` — the drbq Inc-3 Grover shape — inside the body.
 2. `if (r == 9) cq_phi(.25);` **DECLINES**: `-O1` HOISTS the compare INTO the switch,
    giving the merge a SECOND phi `%6 = phi i1 [false],[false],[true],[false]` beside
    the i32 data mux → `cq controlled lowering: control flow under quantum control`
    (the C1 multi-phi row). `t = r + argc` defeats the hoist; with `argc == 1`,
    `t == 10` IS `r == 9` (the `case 5` arm the original comment named). The TRACE is
    independent of the run-time value — the kickback is quantum control.
NEW SLICE + NEW GATE (not in the proposal, and it closes a standing prose claim):
  `slice_loop_phase_accum.c`'s header has asserted byte-identity with a manual unroll
  since Phase 7.3 Inc 1 and **there was no twin in the tree**. Added
  `slice_loop_phase_accum_unrolled.c`, `e2e-slice-loop-phase-accum-unrolled`, and the
  `cmp` gate `e2e-loop-phase-accum-twin-identical`. MEASURED **BYTE-IDENTICAL**, 18
  lines each.
AUDIT over all **72** changed goldens (explicit list — the tool crashes on a deleted
golden in its default set, noted for prep-c):
  **29 SUBSTITUTION-ONLY · 1 AMBIGUOUS-d · 1 AMBIGUOUS-ca · 11 NEW-FILE · 30 FINDING**,
  and the 30 FINDINGs are EXACTLY the 30 REWRITTEN PROGRAMS — verified by `comm` in
  BOTH directions, empty each way. `--selftest`: PASS, 0 survivors.
TREE-WIDE re-scan: 304 goldens · negative-angle `cqrt_rz_i1` **0** · non-i1 `cqrt_rz`
  **0** · `cqrt_rz_<W>_controlled` **0** · `cqrt_rz_i1` lines **168** (was 161, +7).
CTEST as instructed: `ctest -j6 -R '^e2e-slice-(classical|loop-phase|control-cond-onward)'`
  → **7/7 PASSED** (20.5 s), and `e2e-loop-phase-accum-twin-identical` → **PASSED**.
  e2e layer is now **329** entries (327 + the twin slice + its `cmp` gate).
Commit `1dfc025`.

## 2026-09-05 step 13 — FINAL full e2e AFTER the remedies (prep_b2_e2e4.log)
`ctest -j6 -R '^e2e-'` → **99% tests passed, 2 failed out of 329**, 635.78 s.
The SAME two reds as before, unchanged and both NOT mine:
  `e2e-fixture-guard-liveness` (prep-a / fixture re-derive) · `e2e-loop-twin-matrix` (prep-d2).
Delta vs the pre-remedy run: 327 → **329** entries (+ the twin slice, + its `cmp` gate),
325 → **327** passing, reds unchanged at 2.
Branch tip **1dfc025**, working tree CLEAN.
