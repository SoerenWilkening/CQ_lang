; spec_accept_clone_consumer_after_ry_cond_rail.ll — ACCEPT, the chain's FIRST link
; stays discharged (bd test_C_libtooling-kyy1; bd rhk5 round 2; family member
; `k04`). The companion of spec_accept_clone_consumer_after_ry_keeps_sibling.ll with
; the clone reading the CONDITION rail instead:
;
;     p = q & 3; u = p + q; if (u == 10) cq_phi(PI); q2 = cq_theta(q, .7); s = h(m, u);
;
; `u` is read after the Ry, so it stays allocated. `p`'s only consumer is `u`'s
; producer, so the ORACLE discharges `p` right after `u`'s mint. Round 1 put `u`
; (via clause (b′)) and `p` in one component anchored after the clone call — past
; the Ry — and leaked both, warned. Round 2's per-component fallback plans the
; pre-rhk5 piece `{p}` and keeps it: the oracle's stream (measured).
;
; RED on round 1 (fa71e37a…), GREEN on the oracle and on round 2.
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
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %s = call i32 @h(i32 %m, i32 %u)
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
; LOWER: %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 3)
; LOWER-NEXT: %h_op1 = call i32 @cq_template_add_i32(i32 %h, i32 %h_op)
; THE DISCHARGE round 1 lost: `p`, right after its last reader.
; LOWER-NEXT: call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
; LOWER: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; LOWER-NEXT: %s = call i32 @__cq_q_h_10(i32 0, i32 %h_op1)
; LOWER-NOT: call void @cq_template_add_i32_unc(
; LOWER: ret i32
