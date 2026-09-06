; control_swap_reject_switch_impure_phase.ll — DECLINE (G6): a STRAY op off the
; phase spine in a tainted `switch` case arm.
;
; `SwitchClassify.cpp:262-284` requires every case arm to be exactly
; `{ N × call void @cq_phi(double), br }` and nothing else. `RegionFlatten` ERASES
; the arm BLOCK, so an instruction the emitter neither replays nor scrubs is
; silently DROPPED from the IR — a user `cq_measure` vanishing, or a tainted op's
; `taint.*Calls` pointer dangling into a use-after-free. Over-declining is safe;
; dropping an instruction is not.
;
; ===========================================================================
; 3qlq(prep_a2): HAND DECISION, executing the Rule-13 flips-lens verdict on
; flip #12 (finding F2). TWO things changed and BOTH are stated because either
; one alone would leave a false claim standing.
;
; (1) ⚠ THE STRAY HAD TO BE RE-SPELLED, because the migration accidentally
;     removed it. The original stray was `%stray = add i32 %g0, 7` where `%g0`
;     was the phase call's RESULT. The class-A rewrite RAUW'd `%g0` to its arg-0
;     — the classical literal `i32 0` — leaving `add i32 0, 7`, an ALL-CONSTANT
;     instruction that `Fp80Union::foldConstantConeAndBranches` folds and erases
;     from `flattenPredMuxRegions`, which runs BEFORE `detectControlRegions`.
;     The arm was then genuinely `{1 × cq_phi, br}` and the module ACCEPTED — a
;     correct lowering of a program that no longer contains a stray, i.e. a LOST
;     SUBJECT, not an over-accept. (`Fp80Union.cpp` is byte-identical between the
;     ORACLE and the SUBJECT, so the erasure is pre-existing and not this epic's.)
;     The stray is now `add i32 %u0, 7`: classical, DEAD, and NOT all-constant, so
;     the prepass cannot fold it away. Measured: it survives to the classifier.
;
; (2) ⚠ THE ASSERTED STRING MOVED, and it moved for the switch AND the diamond.
;     This file used to assert `impure phase arm`. Under the register-free
;     surface the switch classifier returns `NotApplicable` and the generic G0–G11
;     fall-through owns the shape, so the rendered message is `control flow`.
;     `impure phase arm` is NOT dead — it is still rendered by the NEST (measured:
;     an outer nest arm that rotates the register the inner compare reads, and
;     `control_phase_nest_reject_merge_phi.ll`) — what changed is WHICH SHAPE
;     renders it. Asserting the old string here would pin a message this shape
;     can no longer produce.
;
; ⚠ WHY THIS FIXTURE HAD TO EXIST AGAIN AT ALL (lens finding F2): after the flip
; it was the ONLY fixture pinning `SwitchClassify`'s arm-content clause, and the
; seven `control_phase_switch_reject_*.ll` cover the non-empty default, grouped
; fall-through, a merge phi, scrutinee data use, a stale scrutinee, the `-O1`
; table fold and a tainted angle — NONE of them puts a non-phase instruction in a
; case arm. The clause works; it was simply unpinned. This is a Rule-12 coverage
; gap being closed, not a defect being fixed.
;
; DISCRIMINATOR (measured on `build/ir-pass/cq-opt`): delete the `%stray` line and
; the module ACCEPTS (two independent per-case eq-flag kickback quadruples). The
; tainted spellings (`add i32 %q, 7`, dead or live) decline on the same string and
; are the stronger cell; the classical-dead one below is the MINIMAL one that
; survives the constant-fold prepass.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  call void @cq_phi(double 1.000000e-01)
  %stray = add i32 %u0, 7                  ; classical, DEAD, and NOT all-constant
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
