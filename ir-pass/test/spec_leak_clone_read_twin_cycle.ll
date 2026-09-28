; spec_leak_clone_read_twin_cycle.ll — LEAK + WARNING (bd rhk5 round 2; Rule-13 r1A
; F-r1A-5, probe `cyc_self_twin.ll`, body copied VERBATIM). The pre-supplied inner
; twin `@__cq_q_g_1_unc` CALLS ITSELF with `%k`. Walking it re-enters the
; (function, formal slot) being proved: a CYCLE, which refuses. The refusal is
; PROVISIONAL (it depends on the path) and is never memoised, so it cannot license
; the cycle through the cache (bd `tcpq`).
;
; WHAT THIS FILE PINS AND WHAT IT CANNOT. It goes red if the walk ever ADMITS a
; cycle (or does not terminate). It does NOT pin the cycle test alone: with the
; cycle test deleted, the walk recurses until the nesting cap and refuses anyway, so
; the two are mutually redundant for the VERDICT (r1A measured this). The cap is
; pinned on its own by spec_leak_clone_read_depth_cap.ll.
;
; ⚠ THIS FILE DOES NOT BY ITSELF DISTINGUISH THE FIX (Rule-13 r2B F-r2B-3): it is GREEN
; on the oracle (main 9a230646), on rhk5 round 1 and on round 2 — the program leaks on
; all three. What makes it a pin is the MUTANT MATRIX, which is NOT a ctest gate:
; `rhk5_probes/tools/mutants_r2.py` R3 (a cycle returns YES) turns it red and nothing
; else in the suite does (TRACK_RHK5.md §R2.5). If the cycle test regresses in a way
; R3 does not model, the shipped suite can stay green.
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
  call void @__cq_q_g_1_unc(i32 %out, i32 %k)
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
