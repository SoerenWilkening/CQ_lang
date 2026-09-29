; spec_leak_clone_read_twin_unc_out.ll — LEAK + WARNING, deliberately (bd
; test_C_libtooling-rhk5). A member of the HOSTILE-TWIN family; its first member,
; spec_leak_clone_read_twin_writes_arg.ll, carries the full argument. The module
; PRE-SUPPLIES the inner twin `@__cq_q_g_1_unc`, which `Specialization::ensureTwin`
; reuses verbatim and `buildClone` records, and this twin WRITES its borrowed
; argument `%k` through the OUT slot of an adjoint (`cq_template_mul_i32_hl_unc(%k, %h_op, 5)` XORs onto `%k`).
; So the outer call `__cq_q_h_10(0, q)` does NOT leave `q`'s label alone,
; `cloneCallPreservesArg` must refuse it, the caller's chain `3q`, `3q ^ q` leaks
; and the lyyf-(B) warning stands — the ORACLE's disposition (main 9a230646).
; Pinned separately because clause (B2) admits an adjoint's READ slots only (`isUncHandleSlot` refuses slot 0); a mutant that admits any `_unc` slot turns this file red.
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

; The PRE-SUPPLIED twin: it WRITES `%k`.
define internal void @__cq_q_g_1_unc(i32 %out, i32 %k) {
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)
  call void @cq_template_mul_i32_hl_unc(i32 %k, i32 %h_op, i32 5)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %k, i32 5)
  call void @cqrt_free(i32 %h_op)
  ret void
}


; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
;
; LEAK-LABEL: define i32 @slice(
; LEAK: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LEAK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LEAK-NOT: call void @cq_template_xor_i32_unc(
; LEAK-NOT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LEAK: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; LEAK-LABEL: define internal void @__cq_q_g_1_unc(i32 %out, i32 %k)
; LEAK: call void @cq_template_mul_i32_hl_unc(i32 %k, i32 %h_op, i32 5)
