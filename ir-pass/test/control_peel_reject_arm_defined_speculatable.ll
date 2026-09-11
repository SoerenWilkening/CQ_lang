; control_peel_reject_arm_defined_speculatable.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, P3): the sibling phi's arm incoming is a SPECULATABLE
; `mul` defined IN THE ARM, and the arm also holds a `cq_theta` (so PredMux's E4
; refuses to claim the region — its speculatability gate is what separates this
; from `control_peel_predmux_unchanged_control.ll`). Probe
; `h30b_armdefined_speculatable`.
;
; ⚠ **THE PEEL MUST NEVER HOIST**, and "speculatable" is exactly the tempting case:
; the `mul` could legally be moved to the pred, which would make its phi peelable.
; Hoisting a tainted op out of an arm changes WHICH GATES RUN UNCONDITIONALLY —
; that is PredMux's E4-gated job (it claims and ERASES the whole arm), and this
; stage's contract is the opposite: leave the arm, the CFG and the region's own phi
; exactly where they are, and move only phis whose values ALREADY execute at the
; pred. P3 is a DOMINANCE question, never a movability one. TWO phis therefore fail
; P3 here, so P4 leaves the region wholly untouched.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`).

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define i32 @example()  {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  %c = icmp sgt i32 %b0, 3
  br i1 %c, label %arm, label %merge

arm:
  %t1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  %d = mul nsw i32 %b0, 7
  br label %merge

merge:
  %b1 = phi i32 [ %t1, %arm ], [ 0, %entry ]
  %s = phi i32 [ %d, %arm ], [ 0, %entry ]
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %b0) 
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %b1) 
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %s) 
  %x1 = add nsw i32 %m0, %m1
  %x2 = add nsw i32 %x1, %m2
  ret i32 %x2
}
declare i32 @cq_theta_si32(i32 noundef, double noundef) 
declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
