; spec_accept_clone_consumer_after_ry_keeps_sibling.ll — ACCEPT, the DEAD SIBLING
; stays discharged (bd test_C_libtooling-kyy1; bd rhk5 round 2; Rule-13 r1B
; F-r1B-1, probe `b2n`). The C program:
;
;     q = m & 7; cq_theta(&q, .5); p = q & 3; u = p + q;
;     if (u == 10) cq_phi(PI);
;     q2 = q; cq_theta(&q2, .7);
;     s = h(m, p);                    // h(a, k) = k + 1, in another TU
;     return cq_measure(s) + cq_measure(q2);
;
; `u` is DEAD after the kickback; `p` is read by the clone call AFTER the second Ry,
; so `p` is the program's own live record across that Ry and must stay allocated.
; The ORACLE (main 9a230646) discharges `u` at the flag strip, BEFORE the Ry.
;
; ROUND 1 OF bd rhk5 LOST THAT DISCHARGE, and this file is its red-green pin. Clause
; (b′) made `p` an INTERIOR rail (its one consumer is a clone call, now provably a
; read), so `p` and `u` became ONE M-B component with ONE discharge point — anchored
; after ALL consumers, i.e. after the clone call, i.e. after the Ry on the borrowed
; parent `q`. Clause (d) then refused the whole component and `u` stood allocated
; and entangled across the Ry (`x ↦ (x&3, x+(x&3))` is injective, so `q` fully
; dephased and the user's phase oracle was erased), warned. Round 2 plans such a
; component both ways — whole, and split into its pre-rhk5 pieces with the (b′)
; rails as borrowed parents — and keeps the whole plan only when it discharges a
; SUPERSET of the pieces' rails. Here the whole plan discharges nothing, the piece
; `{u}` discharges `u`: the oracle's stream, byte for byte (measured).
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
  %s = call i32 @h(i32 %m, i32 %p)
  %ms = call i32 @cq_measure_si32(i32 %s)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %r = add nsw i32 %mq, %ms
  ret i32 %r
}

define i32 @h(i32 %a, i32 %k) {
  %r = add nsw i32 %k, 1
  ret i32 %r
}

; No warning: `p` is live across the Ry because the program reads it after — the
; clause-3 exemption — and `u` is gone before it.
; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define i32 @slice(
; LOWER: %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 3)
; LOWER-NEXT: %h_op1 = call i32 @cq_template_add_i32(i32 %h, i32 %h_op)
; LOWER-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase
; LOWER-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; THE DISCHARGE round 1 lost: the dead sibling `u`, before the Ry.
; LOWER-NEXT: call void @cq_template_add_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op1)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; LOWER-NEXT: %s = call i32 @__cq_q_h_10(i32 0, i32 %h_op)
; `p` is never discharged: a discharge after the clone would follow the Ry.
; LOWER-NOT: call void @cq_template_and_i32_hl_unc(
; LOWER: ret i32
