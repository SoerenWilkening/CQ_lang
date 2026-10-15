; control_swap_select_rail_other_register_measured.ll — ACCEPT (bd
; test_C_libtooling-r9e5, Rule-13 round-1 item F-B1R1-1's STOP pin): the
; condition rail `b` is a chained theta on a TEMPLATE parent `t = trunc q`, and
; what is measured before the select is `q` — the cast's SOURCE, a DIFFERENT
; physical register (the cast lowers OUT of place, `cq_template_trunc_i32_to_i1`
; mints a fresh rail). `railWireNamesBackward` collects `t` (in place under `b`)
; and does NOT enter its operands, so `cq_measure(q)` is not a measurement of the
; condition's wire and the merge lowers; the twin that measures `t` is the
; decline `control_swap_reject_select_rail_measured_template_parent.ll`. The
; measured `q` stays entangled with `t`/`b` through the cast — the register `b`
; is still quantum, and the merge controls on its own (unmeasured) rail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.ll
; RUN: %filecheck %s --check-prefix=CNCNT < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 2.000000e-01)
  %t = trunc i32 %q to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %r = add i32 %m, %mq
  ret i32 %r
}

; ORD: %h = call i32 @cqrt_alloc_i32(i32 3)
; ORD-NEXT: call void @cqrt_ry_i32(i32 %h, double 2.000000e-01)
; ORD-NEXT: %h_cast = call i32 @cq_template_trunc_i32_to_i1(i32 %h)
; ORD-NEXT: call void @cqrt_ry_i1(i32 %h_cast, double 5.000000e-01)
; ORD-NEXT: %[[N_m2:m[0-9]*]] = call i32 @cqrt_measure_i32(i32 %h)
; ORD-NEXT: %bf = call i32 @cqrt_alloc_i1(i1 false)
; ORD-NEXT: call void @cqrt_cnot(i32 %h_cast, i32 %bf)
; ORD-NEXT: %out = call i32 @cqrt_alloc_i32(i32 0)
; ORD-NEXT: call void @cqrt_xorc_i32_controlled(i32 %bf, i32 %{{[0-9a-zA-Z_.]+}}, i32 2)
; ORD-NEXT: call void @cqrt_x(i32 %bf)
; ORD-NEXT: call void @cqrt_xorc_i32_controlled(i32 %bf, i32 %{{[0-9a-zA-Z_.]+}}, i32 5)
; ORD-NEXT: call void @cqrt_x(i32 %bf)
; ORD-NEXT: call void @cqrt_cnot(i32 %h_cast, i32 %bf)
; ORD-NEXT: call void @cqrt_free(i32 %bf)
; ORD-NEXT: %[[N_m3:m[0-9]*]] = call i32 @cqrt_measure_i32(i32 %out)

; No non-diagonal gate on either user register from the merge, and nothing
; but the copy flag is ever freed.
; NOX-NOT: call void @cqrt_x(i32 %h)
; NOX-NOT: call void @cqrt_x(i32 %h_cast)
; NOX-NOT: @cqrt_cswap
; NOX-NOT: _unc(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; CNCNT-COUNT-2: call void @cqrt_cnot(
; CNCNT-NOT: call void @cqrt_cnot(
