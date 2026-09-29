; spec_leak_clone_read_defined_template_name.ll — LEAK + WARNING, deliberately (bd
; test_C_libtooling-fb5y, a P1 against bd rhk5 round 1; Rule-13 r1A F-r1A-1, probe
; `a1f_evil_after_uncompute.ll`, body copied VERBATIM). The module PRE-SUPPLIES the
; inner twin `@__cq_q_g_1_unc`, which uncomputes `out` correctly and THEN calls a
; module-DEFINED `@cq_template_evil_i32(%k)` whose body is `cqrt_x(%k)`. Round 1's
; body walk admitted that call by its NAME (a `cq_template_*` forward producer "reads
; every operand"), proved `q` read-only across the outer clone call, and discharged
; the caller's chain AFTER the write: two `cqrt_free`s of non-|0⟩ rails, one
; entangled with `q` — a hidden measurement — at `opt` exit 0 with no warning and
; STRICT 2b clean (the reviewer's measurement). The ORACLE leaks and warns.
;
; Round 2 trusts a name ONLY for a callee this module merely DECLARES (the runtime
; ABI); a DEFINED callee must be recorded and walked (B4) or it refuses. So the walk
; refuses here, and the disposition is the oracle's. RED on round 1 (fa71e37a…),
; GREEN on the oracle and on round 2. The 2-TU C spelling of the same program is
; r1A's `a1c_c.c` (in the round-2 battery).
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

define internal void @__cq_q_g_1_unc(i32 %out, i32 %k) {
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %k, i32 5)
  call void @cqrt_free(i32 %h_op)
  %ev = call i32 @cq_template_evil_i32(i32 %k)
  ret void
}

define i32 @cq_template_evil_i32(i32 %x) noinline {
  call void @cqrt_x(i32 %x)
  ret i32 0
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
