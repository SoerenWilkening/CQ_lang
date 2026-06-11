; control_swap_reject_value_derived_tainted_angle.ll — DECLINE: a VALUE arm's
; DERIVED routed base carries a quantum-derived angle.
;
; The value-arm twin of control_swap_reject_tainted_angle_prebase.ll:
; `%pd = cq_phi(%p, sitofp(%p))` is the routed base of an otherwise accept-class
; value diamond (`if (q > 5) { pd = pd + 3 }`, condition disjoint from %pd).
; taintedAngleGate's base check never sees it — for a value arm the phase
; spine consumes nothing, so its Base is the arm's first binop, not the chain's
; real base. Without the value-path check the region is fully EMITTED and
; FLATTENED before RotationLowering's own angle guard fires (loud either way,
; but mutation must never precede detection — found by the WI-4 §8 adversarial
; review, 2026-06-11). classifyArms declines pre-mutation with the same
; source-located string as the phase-path twin.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %f  = sitofp i32 %p to double                    ; TAINTED angle producer
  %pd = call i32 @cq_phi_si32(i32 %p, double %f)   ; derived base, tainted angle
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = add i32 %pd, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %pd, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: error{{.*}}rotation angle under quantum control
; the value-arm defer/accept machinery must never run on this region
; CHECK-NOT: value-arm swap-route
; CHECK-NOT: cqrt_copy
