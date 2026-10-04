; spec_accept_clone_consumer_before_ry_whole_plan.ll — ACCEPT, the WHOLE (b′) plan
; wins (bd test_C_libtooling-kyy1; bd rhk5 round 2; family member `k05`). The CONTROL
; for round 2's per-component fallback: the same program as
; spec_accept_clone_consumer_after_ry_keeps_sibling.ll with the clone call moved
; BEFORE the Ry:
;
;     p = q & 3; u = p + q; if (u == 10) cq_phi(PI); s = h(m, p); q2 = q; cq_theta(&q2, .7);
;
; Now the component `{p, u}` anchored after the clone call lies wholly before the Ry,
; clause (d) holds, and the whole plan discharges BOTH rails — a strict superset of
; the pre-rhk5 piece `{u}`, so the fallback must NOT take over. The ORACLE discharges
; only `u` and leaves `p` dead and entangled across the Ry (warned); round 1 and
; round 2 discharge both (measured). A fallback that always preferred the pieces
; would turn this file red — which is why it exists.
;
; RED on the oracle, GREEN on round 1 and on round 2.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = and i32 %q, 3
  %u = add nsw i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 3.141590e+00)
  br label %merge

merge:
  %s = call i32 @h(i32 %m, i32 %p)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %ms = call i32 @cq_measure_si32(i32 %s)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %r = add nsw i32 %mq, %ms
  ret i32 %r
}

define i32 @h(i32 %a, i32 %k) {
  %r = add nsw i32 %k, 1
  ret i32 %r
}

; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define i32 @slice(
; LOWER: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER-NEXT: %s = call i32 @__cq_q_h_10(i32 0, i32 %h_op)
; Both chain rails, LIFO, after the clone (the last reader of `p`), before the Ry.
; LOWER-NEXT: call void @cq_template_add_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op1)
; LOWER-NEXT: call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
