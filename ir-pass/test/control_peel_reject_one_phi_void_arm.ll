; control_peel_reject_one_phi_void_arm.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, **the >=2-phi CONTAINMENT GATE / SCOPE OQ-5**): a data
; mux beside a VOID `cq_phi` PHASE arm. The merge holds exactly ONE phi — the mux —
; and the region defines no value at all, so peeling it would leave an empty merge
; and the region would lower as a flat kickback (probe `p60_phase_arm`, hand peel
; `h60`: ACCEPT 20 lines). The peel REFUSES it anyway.
;
; ⚠ THE GATE IS NOT TIDINESS — IT IS WHAT MAKES THE STAGE ACCEPT-MONOTONE BY
; CONSTRUCTION. A merge with >=2 phis cannot be claimed by ANY classifier today
; (all three `recoverRegion` recognizers go through `soleMergePhi`;
; `classifyPhaseKickback` admits phis in {none, ONE angle tail} and `phaseAngleTail`
; itself refuses a second; `classifyGuardedStoreArm` loud-declines on any merge
; phi; `classifyAbortPark` needs an `unreachable` arm; `lowerControlledIOSinks`
; demands `NumPhis == 0 || ValuePhi` and runs BEFORE this stage). So every site the
; peel touches declines loudly today — MEASURED as 0 RCDIFF / 0 DIAGDIFF / 0
; OUTDIFF over all 1776 pre-existing fixtures.
;
; Relaxing the gate to ">=1 phi the region does not define" means DECIDING WHICH
; PHI IS THE REGION'S, and getting that wrong on a ONE-phi merge would peel the
; region's own merge and break a shipped accept — the angle-tail control
; (`control_peel_angle_tail_unchanged_control.ll`) is the concrete example: its
; sole phi is a rotation ANGLE, and peeling it is the f64/angle wire-crossing.
; That widening is OQ-5 and is its own increment row, not a free line here.;
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
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %4, label %3

3:                                                ; preds = %0
  tail call void @cq_phi(double noundef 0x3FE6666666666666) 
  br label %4

4:                                                ; preds = %3, %0
  %5 = phi i32 [ 5, %3 ], [ 2, %0 ]
  %6 = tail call i32 @cq_measure_si32(i32 noundef %1) 
  %7 = tail call i32 @cq_measure_si32(i32 noundef %5) 
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) 

declare void @cq_phi(double noundef) 

declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
