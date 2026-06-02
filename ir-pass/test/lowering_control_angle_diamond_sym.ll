; lowering_control_angle_diamond_sym.ll — Family B1, symmetric diamond form
; (test_C_libtooling-cwk, WP8 path). The SYMMETRIC two-content-arm diamond
; (`if(q){ang=a;}else{ang=b;}`) analog of lowering_control_angle_diamond.ll:
; BOTH arms fall through to a common merge whose `φ` is a classical `double`
; rotation ANGLE. Like the one-content-arm diamond, `dissolveBranchPhi` would
; mislower the `phi double` as integer-handle data (cwk); the classical-FP merge
; guard rejects the symmetric diamond before a region is built, so the
; belt-and-braces guard on `matchSymmetricDiamond` is exercised, not dead.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armT, label %armF
armT:
  br label %merge
armF:
  br label %merge
merge:
  %ang = phi double [ %a, %armT ], [ %b, %armF ]
  %r = call i32 @cq_phi_si32(i32 %v, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
