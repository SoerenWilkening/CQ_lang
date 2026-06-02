; lowering_control_angle_diamond_mixed_reject.ll — Family B1, NEGATIVE
; (test_C_libtooling-byx, adversarial-review regression lock). A diamond merge
; carrying BOTH a lowerable scalar-FP angle φ (%ang) AND an UNLOWERABLE sibling φ
; (%wide, i128). The angle alone would lower (fix (b)), but the i128 sibling has
; no lowering — building the region would leave it to dissolveBranchPhi /
; linearization and strand it ("PHI nodes not grouped" broken module), the exact
; cwk-fix-(a) hazard. Detection must classify the WHOLE merge and DIAGNOSE on the
; unlowerable sibling rather than partially lowering. (A naive "lower the first
; clean angle φ, else diagnose" short-circuits the diagnostic — this fixture
; forbids that regression.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: PHI nodes not grouped
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(i128)
define i32 @example(i32 %u0, double %a, double %b, i128 %x, i128 %y) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %ang = phi double [ %a, %arm ], [ %b, %entry ]   ; lowerable angle φ
  %wide = phi i128 [ %x, %arm ], [ %y, %entry ]    ; UNLOWERABLE sibling φ
  %r = call i32 @cq_phi_si32(i32 %u, double %ang)
  call void @sink(i128 %wide)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
