; lowering_control_angle_nested_and.ll — Family B1, nested-AND diamond form
; (test_C_libtooling-cwk, adversarial-review test-gap finding). The un-flattened
; `if(a){if(b){ang=x;}}` shape (PRD §2.7): `entry -[a]-> {mid, merge}`,
; `mid -[b]-> {arm, merge}`, `arm -> merge`, with a 3-way merge `φ`. When that φ
; is a classical `double` rotation angle it is the nested-AND analog of the
; one-content-arm diamond cwk hole — `dissolveBranchPhi` would mislower it. The
; classical-FP merge guard is wired into the matchNestedAnd path too, so this is
; diagnosed before any region is built. This fixture exercises the third of the
; four guarded detection paths (the other two: lowering_control_angle_diamond.ll
; and lowering_control_angle_diamond_sym.ll; the fourth: the gated switch in
; lowering_control_angle_switch_gated.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: PHI nodes not grouped
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %x, double %y) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %a = icmp sgt i32 %q, 5
  br i1 %a, label %mid, label %merge
mid:
  %b = icmp slt i32 %q, 20
  br i1 %b, label %arm, label %merge
arm:
  br label %merge
merge:
  %ang = phi double [ %x, %arm ], [ %y, %mid ], [ %y, %entry ]
  %r = call i32 @cq_phi_si32(i32 %v, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
