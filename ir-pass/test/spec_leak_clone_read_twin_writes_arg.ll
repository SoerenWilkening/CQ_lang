; spec_leak_clone_read_twin_writes_arg.ll — LEAK + WARNING, deliberately (bd
; test_C_libtooling-rhk5; the ADVERSARIAL twin of
; spec_accept_clone_read_in_discharge_window_nested.ll). Same program — a nested
; clone `h -> g` called inside the discharge window of the derived chain `3q`,
; `3q ^ q` — except that the module PRE-SUPPLIES the inner twin
; `@__cq_q_g_1_unc`, and that twin WRITES its borrowed argument (`cqrt_x(%k)`).
;
; WHY THIS IS REACHABLE AND WHY IT MATTERS. `Specialization::ensureTwin` REUSES an
; existing `<clone>_unc` DEFINITION rather than synthesizing one (its own header
; records the bd xy9n consequence of that), and `buildClone` then records the reused
; function in `taint.SpecHandleArgMask` like any other twin. So "the specializer's
; record names it" does NOT mean "the specializer wrote its body", and a proof that
; stopped at the record would admit the outer call — `h`'s clone passes `%k` to this
; twin — and discharge the caller's chain on the claim that `q` is read-only across
; the call, when the call FLIPS `q`. `cloneCallPreservesArg` walks the twin body
; (clause (B4) recursing into it), meets `cqrt_x(%k)`, and refuses the WHOLE outer
; call: the caller's chain leaks and the lyyf-(B) warning stands — byte-identical in
; disposition to the oracle (main 9a230646), which refuses every clone call. (The
; hostile twin also breaks `h`'s own Bennett wrap; that is a pre-existing property of
; the pre-supplied-twin path, not this predicate's business, and not pinned here.)
;
; A MUTANT THAT TRUSTS THE RECORD — "a recorded twin preserves its arguments" —
; turns this file red (the chain adjoints appear before the second Ry).
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

; The PRE-SUPPLIED twin: it WRITES `%k` (one `cqrt_x`, never undone).
define internal void @__cq_q_g_1_unc(i32 %out, i32 %k) {
  call void @cqrt_x(i32 %k)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %k, i32 5)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %k, i32 5)
  call void @cqrt_free(i32 %h_op)
  ret void
}

; The chain is standing at the second Ry, so the owner's lyyf-(B) warning fires.
; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
;
; The outer call is still emitted, and still passes `q` to a body that reaches the
; hostile twin — which is exactly why the chain must NOT be discharged across it.
; LEAK-LABEL: define i32 @slice(
; LEAK: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LEAK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LEAK-NOT: call void @cq_template_xor_i32_unc(
; LEAK-NOT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LEAK: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; LEAK-LABEL: define internal void @__cq_q_g_1_unc(i32 %out, i32 %k)
; LEAK-NEXT: call void @cqrt_x(i32 %k)
