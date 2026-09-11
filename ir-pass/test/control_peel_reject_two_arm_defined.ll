; control_peel_reject_two_arm_defined.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, P3/P4): TWO `cq_theta` state preps in ONE arm, so BOTH
; merge phis are ARM-DEFINED. P3 (every incoming AVAILABLE AT THE PRED) fails for
; each, so TWO phis fail and P4 leaves the region WHOLLY UNTOUCHED. Probe
; `p88_two_preps`.
;
; ⚠ THIS IS THE DECLINE THAT MUST SURVIVE, and it is what bounds the whole
; increment: peeling one of the two would leave a merge that STILL has >1 phi and
; STILL declines, i.e. buy nothing and hand a half-normalised module to the next
; reviewer. A genuine multi-value arm merge is not a fused pair of regions.;
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
  %2 = icmp sgt i32 %1, 3
  br i1 %2, label %3, label %6

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  %5 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 9.000000e-01) 
  br label %6

6:                                                ; preds = %3, %0
  %7 = phi i32 [ %4, %3 ], [ 0, %0 ]
  %8 = phi i32 [ %5, %3 ], [ 0, %0 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %1) 
  %10 = tail call i32 @cq_measure_si32(i32 noundef %7) 
  %11 = add nsw i32 %10, %9
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) 
  %13 = add nsw i32 %11, %12
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) 

declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
