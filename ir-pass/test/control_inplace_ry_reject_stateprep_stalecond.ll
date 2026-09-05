; control_inplace_ry_reject_stateprep_stalecond.ll — DECLINE (P1 /
; `condWireDisposition` → `DeclineNow`): the condition's wire carries a
; non-diagonal gate that is NOT provably post-region.
;
; A classical guard rotates `q` between the compare and the branch, so the flag
; would be minted from a basis the region's own stream has already moved. This is
; the fence PRD §14.5's P1 paragraph says Inc 4 does NOT touch, and the accept
; side of it is `control_inplace_ry_stateprep_post_region_theta_cond.ll` (a
; PROVABLY post-region `cq_theta` on `q`, which P1's §13.4b widening admits
; because a rotation arm's entire emitted stream lands before `BI`). The pair is
; what makes "P1 needs no edit" a measurement.
;
; Measured IDENTICAL on the pre-Inc-4 oracle.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

@OPQ = external global i32

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 5
  %o  = load volatile i32, ptr @OPQ, align 4
  %gc = icmp eq i32 %o, 0
  br i1 %gc, label %pre, label %join
pre:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  br label %join
join:
  %qj = phi i32 [ %q2, %pre ], [ %q, %entry ]
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %join ]
  %mq = call i32 @cq_measure_si32(i32 %qj)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
