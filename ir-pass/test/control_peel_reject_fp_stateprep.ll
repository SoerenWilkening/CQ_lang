; control_peel_reject_fp_stateprep.ll — DECLINE `state prep seed is proven equal to
; the condition register` (bd test_C_libtooling-b6ap, **SCOPE H-3 / OQ-2 — A REAL
; CAPABILITY COST, PINNED SO IT CANNOT MOVE SILENTLY**): an fp DATA MUX beside a
; drbq Inc-4 state-prep arm. Probe `p87_fp_mux` / hand peel `h87`.
;
; The peel gives F2 (`f2SeedPinnedByLiveRegister`) a new instruction — the peeled
; `select` — whose condition `%cq.peel.cond` is EXACTLY PINNED on both edges, and
; whose fp RESULT F2 cannot bound (it evaluates forward with `ConstantRange`, which
; is integer-only, plus exact `ConstantFold*`). CLAUDE.md records F2's rule as
; "a value it cannot bound that HAS an exactly-pinned operand DECLINES", so the
; conservative arm fires. It is an OVER-DECLINE, never a miscompile.
;
; ⚠ IT IS NOT A SEED COLLISION, and that is MEASURED: changing the seed from 0 to
; 7 (`h87b`) or the clone's literal to 99 (`h87e`) declines IDENTICALLY, while
; making the fp select's arms CONSTANTS (`h87d`) accepts at 25 lines, dropping the
; select entirely (`h87f`) accepts at 15, and swapping the arm for a `cq_phi`
; PHASE (`h87c`, committed as `control_peel_fp_datamux_phase.ll`) accepts at 21.
; The cell this costs is exactly `fp mux + state-prep arm`. Options, PRESENTED not
; decided (OQ-2): teach F2 to skip a select `SelectClassify` will claim, or keep
; the cell declined. Do NOT "fix" F2 from here — it is Rule-13 core with four
; adversarial rounds behind it.
;
; ⚠ RETIREMENT TRIGGER — bd `test_C_libtooling-rb9x`, increment R-1 (2026-09-13).
; R-1 taught F2 to exclude `MergePhiPeel`'s compare CLONES from its collider set
; (`TaintSet::PeelClones`, consulted at the equality TEST in
; `f2SeedPinnedByLiveRegister`). **THIS FILE STILL DECLINES, WITH THE SAME STRING
; AND FOR THE SAME REASON — MEASURED 2026-09-13 on the R-1 binary** — because
; R-1's exclusion filters an ANSWER and does not prune the WALK: `%cq.peel.cond`
; is still popped and its users are still modelled, so the fp select reachable
; only through it still fires `f2Model`'s conservative `!AnyPinnedOperand` arm.
; THIS FILE IS THE RED-GREEN WITNESS FOR THAT SPELLING. A version of R-1 (or of
; any successor narrowing) that dropped the clone from the users walk, or from
; the anchor/`Cand` seeding, would flip this module to an ACCEPT — an fp merge
; mux admitted with no argument at all, the L9 angle-vs-data wire-crossing
; family. If this file ever goes green, do not bless it: the exclusion has moved
; off the test, and that is the defect, not the fix. The deliberate capability
; cost recorded above (`fp mux + state-prep arm`) is unchanged by R-1.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`), one
; row of its P1-P9 DECLINE PARTITION. The peel is ACCEPT-ONLY and NEVER diagnoses:
; a shape that fails any clause is left BYTE-UNTOUCHED and reaches its existing
; loud owner unchanged. Over-declining is safe (Prime Directive); the peel's job is
; to remove a BOOKKEEPING over-decline, not to widen the accept class.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define i32 @example()  {
  %1 = tail call double @cq_theta_f64(double noundef 0.000000e+00, double noundef 3.000000e-01) 
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  %3 = icmp eq i32 %2, 1
  %4 = fadd double %1, 2.500000e+00
  br i1 %3, label %7, label %5

5:                                                ; preds = %0
  %6 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  br label %7

7:                                                ; preds = %5, %0
  %8 = phi double [ %1, %5 ], [ %4, %0 ]
  %9 = phi i32 [ %6, %5 ], [ 0, %0 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %2) 
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) 
  %12 = add nsw i32 %11, %10
  %13 = tail call double @cq_measure_f64(double noundef %8) 
  %14 = fptosi double %13 to i32
  %15 = add nsw i32 %12, %14
  ret i32 %15
}

declare double @cq_theta_f64(double noundef, double noundef) 

declare i32 @cq_theta_si32(i32 noundef, double noundef) 

declare i32 @cq_measure_si32(i32 noundef) 

declare double @cq_measure_f64(double noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
