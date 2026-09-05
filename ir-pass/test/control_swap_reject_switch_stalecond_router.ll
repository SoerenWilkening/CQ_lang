; control_swap_reject_switch_stalecond_router.ll — DECLINE (bd tayx): the
; ANCESTOR-ALIAS ROUTER spelling of the switch stale scrutinee. The scrutinee
; %q = theta(%q0) is a rebased SSA name for %q0's physical handle; a chained
; theta whose arg-0 reaches that wire only through a one-register router phi
; ON THE OLD ALIAS %q0 was invisible to G10: the unowned-data-use scan covers
; users of %q only (the router is a user of %q0), and the wire walk ran with
; CrossValueRouting=false. The phase switch was ACCEPTED and emitted its
; N-way eq-flag route with every eq-flag minted AFTER the hidden Ry — the
; flags read the post-Ry basis while the SSA scrutinee denoted the pre-Ry
; record (pre-fix exit 0, `ry(.5); ry(.3); ry(.7); icmp_eq mints...`).
; Fixed by CrossValueRouting=true in the G10 wire walk.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_cswap
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %cc) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q  = call i32 @cq_theta_si32(i32 %q0, double 3.000000e-01)     ; rebase: ancestry {q, q0}
  br i1 %cc, label %x, label %y
x:
  br label %pre
y:
  br label %pre
pre:
  %r = phi i32 [ %q0, %x ], [ %q0, %y ]                           ; router on the OLD alias
  %g = call i32 @cq_theta_si32(i32 %r, double 7.000000e-01)       ; hidden Ry on q's wire
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  %m2 = call i32 @cq_measure_si32(i32 %g)
  ret i32 %m
}
