; lowering_control_angle_diamond_theta.ll — Family B1, NEGATIVE
; (test_C_libtooling-byx, adversarial-review lock). The classical-angle merge φ
; feeds a `cq_theta` (the Ry-prep rotation), NOT a `cq_phi`. The
; controlled-rotation-by-difference lowering (emitRz) only knows the `cq_phi_`
; family (it emits cqrt_rz[_controlled]); a `cq_theta` angle feed is therefore
; NOT lowerable and must be DIAGNOSED, not accepted into a region that emitRz then
; fails to lower (which would leave the rotation standing and the φ dangling — a
; broken module). The angle-feed guard accepts `cq_phi_` consumers only, so this
; falls through to the loud diagnostic.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: PHI nodes not grouped
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %ang = phi double [ %a, %arm ], [ %b, %entry ]
  %r = call i32 @cq_theta_si32(i32 %u, double %ang)  ; cq_theta angle feed — unlowerable
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
