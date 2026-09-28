; spec_leak_clone_read_depth_cap.ll — LEAK + WARNING (bd rhk5 round 2; r1A F-r1A-5).
; The d4 caller with its clone call nesting SIXTEEN `noinline` helpers: 17
; (function, formal) pairs, one more than `kMaxCloneNesting`, so the proof refuses and
; the caller's chain leaks with the lyyf-(B) warning — the oracle's disposition. See
; spec_accept_clone_read_depth_at_cap.ll for why this is an over-leak, pinned
; deliberately, and its retirement trigger.
;
; ⚠ THIS FILE DOES NOT BY ITSELF DISTINGUISH THE FIX (Rule-13 r2B F-r2B-3): it is GREEN
; on the oracle (main 9a230646), on rhk5 round 1 and on round 2 — the program leaks on
; all three. What makes it a pin is the MUTANT MATRIX, which is NOT a ctest gate:
; `rhk5_probes/tools/mutants_r2.py` R4 (cap deleted) turns it red (TRACK_RHK5.md
; §R2.5). Its companion spec_accept_clone_read_depth_at_cap.ll IS red on the oracle,
; but what it pins about the CAP (lower it and it goes red) also rests on mutant R5.
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

define i32 @h(i32 %a, i32 %k) {
  %t = call i32 @g1(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g1(i32 %k) noinline {
  %t = call i32 @g2(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g2(i32 %k) noinline {
  %t = call i32 @g3(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g3(i32 %k) noinline {
  %t = call i32 @g4(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g4(i32 %k) noinline {
  %t = call i32 @g5(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g5(i32 %k) noinline {
  %t = call i32 @g6(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g6(i32 %k) noinline {
  %t = call i32 @g7(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g7(i32 %k) noinline {
  %t = call i32 @g8(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g8(i32 %k) noinline {
  %t = call i32 @g9(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g9(i32 %k) noinline {
  %t = call i32 @g10(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g10(i32 %k) noinline {
  %t = call i32 @g11(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g11(i32 %k) noinline {
  %t = call i32 @g12(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g12(i32 %k) noinline {
  %t = call i32 @g13(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g13(i32 %k) noinline {
  %t = call i32 @g14(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g14(i32 %k) noinline {
  %t = call i32 @g15(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g15(i32 %k) noinline {
  %t = call i32 @g16(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g16(i32 %k) noinline {
  %r = mul nsw i32 %k, 5
  ret i32 %r
}

; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; LEAK-LABEL: define i32 @slice(
; LEAK: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LEAK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LEAK-NOT: call void @cq_template_xor_i32_unc(
; LEAK-NOT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LEAK: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
