; spec_leak_clone_read_weak_twin.ll — LEAK + WARNING, deliberately (bd
; test_C_libtooling-fb5y; Rule-13 r1A F-r1A-2, probe `a5_weak_twin.ll`, body copied
; VERBATIM). The pre-supplied inner twin `@__cq_q_g_1_unc` is READ-ONLY here — but
; `weak`, and r1A's `a5_strong_twin.c`, linked at stage 3, interposes a strong
; definition that ends in `cqrt_x(k)`. The walked body is not the body that runs.
; Round 1 proved the weak body read-only and discharged the caller's chain after
; the (link-time) write — the same two dirty frees as the defined-name route.
;
; Round 2 requires an EXACT definition (`hasExactDefinition()`: not `weak`,
; `linkonce`, `available_externally` or `extern_weak`), so the walk refuses and the
; disposition is the oracle's. RED on round 1 (fa71e37a…), GREEN on the oracle and on
; round 2 — this file needs no link: the refusal is visible in the lowered IR.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s --check-prefix=LEAK < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

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
  call void @cq_phi(double 3.141590e+00)
  br label %merge

merge:
  %ms = call i32 @cq_measure_si32(i32 %s)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %r = add nsw i32 %mq, %ms
  ret i32 %r
}

define i32 @g(i32 %k) noinline {
  %r = mul nsw i32 %k, 5
  ret i32 %r
}

define i32 @h(i32 %a, i32 %k) {
  %t = call i32 @g(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

declare void @cqrt_x(i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)

define available_externally void @__cq_q_g_1_unc(i32 %out, i32 %k) {
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %k, i32 5)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
;
; The caller's chain `3q`, `3q ^ q` is NOT discharged: the strip, then straight to the Ry.
; LEAK-LABEL: define i32 @slice(
; LEAK: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LEAK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LEAK-NOT: call void @cq_template_xor_i32_unc(
; LEAK-NOT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LEAK: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
