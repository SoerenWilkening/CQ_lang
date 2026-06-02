; lowering_control_angle_nested_and_3way.ll — Family B2, nested-AND, NEGATIVE
; (test_C_libtooling-byx, adversarial-review regression lock, 2026-06-03). A
; nested-AND merge `φ` with THREE DISTINCT angles — `if(a){ang=z; if(b){ang=x;}}`
; gives `φ [%x, %arm], [%z, %mid], [%y, %entry]`. Unlike the lowerable form
; (lowering_control_angle_nested_and.ll, where the `%mid` and `%entry` flag==0
; edges carry the SAME base), the two flag==0 edges here differ (%z vs %y), so it
; is NOT a 2-way-on-conjunction dispatch and `reduceAngleDiamondPhi` cannot
; reduce it to base + single controlled-difference.
;
; Detection must DIAGNOSE this (the base-equality guard on the Mid/Pred edges)
; rather than commit a region whose reducer then strands the φ as a dangling node
; ("PHI nodes not grouped" broken module). This locks the regression the
; adversarial review caught when classifyAngleMerge replaced the type-only
; unlowerableClassicalMergePhi guard.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: PHI nodes not grouped
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %x, double %y, double %z) {
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
  %ang = phi double [ %x, %arm ], [ %z, %mid ], [ %y, %entry ]
  %r = call i32 @cq_phi_si32(i32 %v, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
