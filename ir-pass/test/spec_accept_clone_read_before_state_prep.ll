; spec_accept_clone_read_before_state_prep.ll — ACCEPT, DISCHARGED (bd rhk5 round 2;
; the z0re Rule-13 reviewer's member of rhk5's class, probe `k3L`, literal seed). A
; clone call reading `q` sits between the derived chain (`p = 3q`, `u = p ^ q`) and
; the chain's consumer — here a CONTROLLED STATE PREP, `r = 6; if (u == 10)
; r = cq_theta(6, .2);`, lowered to `cqrt_ry_i32_controlled(flag, alloc(6), .2)`:
;
;     q = cq_theta(m & 7, .5); p = q * 3; u = p ^ q; s = h(m, q);
;     r = 6; if (u == 10) r = cq_theta(6, .2);
;     ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q) + cq_measure(r);
;
; ORACLE (main 9a230646): the chain leaks, entangled across the second Ry, warned.
; Round 1 and round 2: both chain rails discharged after the flag strip, before the
; Ry; the prepped register `h1` is frozen (never adjointed, never freed) exactly as
; it is without the clone. The 2-TU C pair `k3L.c`/`k3LT.c` (rhk5_probes/src) is
; EQUIV to its hand-inlined twin under tools/trace_twin_equiv.py on round 2 and DIFF
; on the oracle (measured). The RUNTIME-seed spelling `k3C` needs bd z0re and is
; checked on the composed binary at the merge gate, not here.
;
; RED on the oracle, GREEN on round 1 and round 2.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %s = call i32 @h(i32 %m, i32 %q)
  %c = icmp eq i32 %u, 10
  br i1 %c, label %arm, label %merge

arm:
  %rt = call i32 @cq_theta_si32(i32 6, double 2.000000e-01)
  br label %merge

merge:
  %r = phi i32 [ %rt, %arm ], [ 6, %entry ]
  %ms = call i32 @cq_measure_si32(i32 %s)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %t1 = add nsw i32 %mq, %ms
  %t2 = add nsw i32 %t1, %mr
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
; LOWER: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LOWER-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op2, i32 10)
; LOWER-NEXT: %h1 = call i32 @cqrt_alloc_i32(i32 6)
; LOWER-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 2.000000e-01)
; LOWER-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op2, i32 10)
; LOWER-NEXT: call void @cq_template_xor_i32_unc(i32 %h_op2, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op2)
; LOWER-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; The prepped register is never freed (frozen, Rule 6).
; LOWER-NOT: call void @cqrt_free(i32 %h1)
; LOWER: ret i32
