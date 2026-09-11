; control_peel_reject_identity_phi.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, P6): the second phi's two incomings are the SAME value
; (`phi i32 [5, %arm], [5, %entry]`). An identity phi is a live-range extender, not
; a mux; peeling it would mint a pointless flag, a pointless |0> out-rail and two
; controlled copies that write the same constant on both branches.
;
; It is also the degenerate shape PredMux's W5 fences for the same reason. Left
; alone it is harmless, and because it is the ONLY other phi here `soleMergePhi`
; still refuses — so the region keeps declining, which is OQ-3's measured cost
; (peel it anyway / erase it as a benign live-range phi / keep declining — not
; decided, and this fixture is what would move if it ever is).;
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
  br i1 %2, label %5, label %3

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ 5, %3 ], [ 5, %0 ]
  %7 = phi i32 [ %4, %3 ], [ 0, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1) 
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7) 
  %10 = add nsw i32 %9, %8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) 
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) 

declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
