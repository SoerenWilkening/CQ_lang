; spec_reject_phantom_arg_read_range_attr.ll — DECLINE (bd test_C_libtooling-vsfp, the
; phantom-read BACKSTOP; hand-written IR). ⚠ Round 2: the name is kept, the attribute is not.
;
; Round 1 defeated the drop with `range(i32 1, 100)` on the dead parameter. Round 2 mirrors
; LLVM DAE, which STRIPS `range`/`nofpclass` when it rewrites an argument, so that slot is
; now dropped (pinned by spec_accept_dropped_arg_range_attr_stripped.ll). What the drop
; still refuses is an attribute it does not know — here a STRING attribute on the
; parameter — so the phantom operand (a 4.4 bool-select `%out`, which the twin never
; computes) reaches `specialize()`, the clone records slot 0 dead, and the backstop
; declines rather than keep that which-path rail alive across the later Ry on `b`.
;
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: {{.*}}cq specialization: quantum argument to a parameter the lifted callee never reads

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @h(i32 "cq.probe.opaque" %a, i32 %k) {
  %r = add i32 %k, 1
  ret i32 %r
}

define i32 @main(i32 %m) {
  %lo = trunc i32 %m to i1
  %b = call i1 @cq_theta_i1(i1 %lo, double 5.000000e-01)
  %p = select i1 %b, i32 9, i32 4
  %t = call i32 @h(i32 %p, i32 %m)
  %b2 = call i1 @cq_theta_i1(i1 %b, double 7.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b2)
  %mz = zext i1 %mm to i32
  %s = add i32 %t, %mz
  ret i32 %s
}
