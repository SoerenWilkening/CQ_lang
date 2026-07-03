; control_swap_reject_nested_stalecond_router.ll — DECLINE (bd tayx clearance,
; probe p16): the ROUTER spelling of the nested stale condition — the chained
; theta's arg-0 reaches the outer condition's wire only through a
; one-register value-routing phi. Same absent-guard root cause as
; control_swap_reject_nested_stalecond_direct.ll; this spelling additionally
; pins that the new per-level guard walks with CrossValueRouting=true (the
; tayx posture — a router forwards the same physical handle), matching the
; flat diamond/switch/select fixtures.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b, i1 %cc) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %cc, label %x, label %y
x:
  br label %pre
y:
  br label %pre
pre:
  %r  = phi i32 [ %q, %x ], [ %q, %y ]                        ; one-register router
  %g2 = call i32 @cq_theta_si32(i32 %r, double 7.000000e-01)  ; router-hidden Ry on q's wire
  %c1 = icmp sgt i32 %q, 5                                    ; outer compare: pre-Ry record
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call i32 @cq_phi_si32(i32 %q, double %b)
  %c2 = icmp slt i32 %g, 9
  br i1 %c2, label %arm, label %merge
arm:
  %h  = call i32 @cq_phi_si32(i32 %g, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %pre ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  %m2 = call i32 @cq_measure_si32(i32 %g2)
  ret i32 %m
}
