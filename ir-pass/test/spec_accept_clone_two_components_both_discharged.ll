; spec_accept_clone_two_components_both_discharged.ll — ACCEPT, BOTH chains
; discharged (bd test_C_libtooling-kyy1; bd rhk5 round 2). Two derived chains over
; one register `q`, one M-B component each:
;
;   A (the rhk5 win)   pa = q*3; ua = pa ^ q; s1 = h(m, q);  if (ua == 10) cq_phi(PI);
;   B (the kyy1 shape) pb = q & 3; ub = pb + q;              if (ub == 5)  cq_phi(.25);
;   then q2 = q; cq_theta(&q2, .7); s2 = h(m, pb); (the clone consumer of pb is AFTER the Ry)
;
; ORACLE (main 9a230646): A leaks (the clone call in A's window is a "mutation" of
; `q`), B's dead `ub` is discharged — warned. ROUND 1: A discharged, B's `ub` lost
; (clause (b′) merged pb/ub into one component anchored past the Ry) — warned.
; ROUND 2: BOTH — the union of the two, no warning (measured).
;
; WHY THIS FILE EXISTS: it is the only fixture that pins the PER-COMPONENT fallback
; in `collectInteriorPlansMode` on its own. In a function with ONE component, the
; function-level backstop in `collectInteriorPlans` (plan with and without clause
; (b′), keep ON only if it discharges a superset) reaches the same stream alone, so a
; mutant that disabled the per-component step would stay green there. Here the
; backstop alone would have to pick ONE of "A discharged" and "ub discharged": with
; the per-component step disabled, ON = {A's rails} is not a superset of OFF =
; {ub}, the backstop falls back to OFF, and A's discharge below disappears.
;
; RED on the oracle and on round 1 (fa71e37a…), GREEN on round 2.
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
  %pa = mul nsw i32 %q, 3
  %ua = xor i32 %pa, %q
  %s1 = call i32 @h(i32 %m, i32 %q)
  %ca = icmp eq i32 %ua, 10
  br i1 %ca, label %arma, label %mida

arma:
  call void @cq_phi(double 3.141590e+00)
  br label %mida

mida:
  %pb = and i32 %q, 3
  %ub = add nsw i32 %pb, %q
  %cb = icmp eq i32 %ub, 5
  br i1 %cb, label %armb, label %merge

armb:
  call void @cq_phi(double 2.500000e-01)
  br label %merge

merge:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %s2 = call i32 @h(i32 %m, i32 %pb)
  %m1 = call i32 @cq_measure_si32(i32 %s1)
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %t1 = add nsw i32 %m1, %m2
  %t2 = add nsw i32 %t1, %mq
  ret i32 %t2
}

define i32 @h(i32 %a, i32 %k) {
  %r = add nsw i32 %k, 1
  ret i32 %r
}

; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define i32 @slice(
; LOWER: %s1 = call i32 @__cq_q_h_10(i32 0, i32 %h)
; Chain A, discharged after its strip (the rhk5 win):
; LOWER: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op2, i32 10)
; LOWER-NEXT: call void @cq_template_xor_i32_unc(i32 %h_op2, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op2)
; LOWER-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; Chain B's dead `ub`, discharged after its strip (the oracle's discharge, kept):
; LOWER: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op4, i32 5)
; LOWER-NEXT: call void @cq_template_add_i32_unc(i32 %h_op4, i32 %h, i32 %h_op3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op4)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; LOWER-NEXT: %s2 = call i32 @__cq_q_h_10(i32 0, i32 %h_op3)
