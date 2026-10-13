; spec_intermediate_unc_terminal_union.ll — ACCEPT, DISCHARGED (bd
; test_C_libtooling-p3kd.13, R11 review round 2, F1-r2 + INFO (a)): how a dead
; clone-result terminal and dead template terminals in one function are planned
; (TerminalGroups.h). The group first PROBES the union of both kinds; the union is
; emitted iff it plans out and is never worse than the template terminals alone
; (`neverWorse`, R11 rounds 4-8: when their own plan emits, the union reverse-plays
; every gate and frees every rail it would; when it does not, the union leaves
; nothing cut); otherwise the template terminals plan exactly as main and the
; clone terminals after them, silently.
;
; SOURCE (`clang -O1` IR below; review round 2 probes p3, p2 @f, p6 @e):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     int shared_interior(int m) { int q = m & 7; cq_theta(&q, .5); int a = q + 2;
;         int t = a * 5; cq_theta(&t, .4); int r = h(a); cq_theta(&r, .2);
;         return cq_measure(q); }
;     int interleaved(int m) { int q = m & 7; cq_theta(&q, .5); int r = h(q);
;         int t = q * 5; cq_theta(&t, .4); cq_theta(&r, .2); return cq_measure(q); }
;     int independent(int m) { int q1 = m & 7; cq_theta(&q1, .5);
;         int t = q1 * 5; cq_theta(&t, .4); int w = q1 ^ 3;
;         int q2 = m & 3; cq_theta(&q2, .25); int r = h(q2); cq_theta(&r, .2);
;         return cq_measure(w); }
;
; @shared_interior — THE UNION. `t` and `r` share the TEMPLATE interior `a`. Alone,
;   the template terminal leaves `a` open (the clone call consumes it outside the
;   group) and main declines LOUDLY (`dead chain would free a measured register`,
;   rc 1, measured on db4cf60a and on the round-1 split 12262d16). The union closes
;   it and reverses everything LIFO: r's Ry, r's twin, t's Ry, t's `mul`, `a`.
;   A lifted call where the template op `t2 = a * 7` would be no longer turns an
;   accepted program into a decline (that control lowers on every binary).
; @interleaved — THE UNION, again: r and t share the measured, borrowed q, and t's
;   reversal lands inside r's clause-(d) window; planned as one group the window
;   holds and r is reversed (the round-1 split leaked r, warned).
; @independent — THE SPLIT, a new emission: t's DAG is not closed (q1 also feeds the
;   measured w), so the union refuses and so does main for `t`; the clone's own
;   closed DAG {q2's Ry, h, r's Ry} then reverses on its own — the twin, r's free,
;   and q2's prep Ry undone (q2 is birth-frozen: a runtime seed, never freed).
;   Stage 2b on this module: 10 frees verified, 0 violations.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; NOERR-NOT: error

; CHECK-LABEL: define i32 @shared_interior(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[A]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[A]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double -2.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R]], i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T]], i32 %[[A]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; CHECK-LABEL: define i32 @interleaved(
; CHECK:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[R2:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H2]])
; CHECK-NEXT: %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H2]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R2]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R2]], double -2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T2]], i32 %[[H2]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T2]])
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R2]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R2]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H2]])

; CHECK-LABEL: define i32 @independent(
; CHECK:      %[[T3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T3]], double 4.000000e-01)
; CHECK-NOT:  call void @cqrt_free(i32 %[[T3]])
; CHECK:      %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q2]], double 2.500000e-01)
; CHECK-NEXT: %[[R3:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[Q2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R3]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R3]], double -2.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R3]], i32 %[[Q2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R3]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q2]], double -2.500000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(
; The template terminal t stays allocated, as on main (its DAG is not closed):
; CHECK-NOT:  call void @cqrt_free(i32 %[[T3]])
; CHECK:      ret i32

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @shared_interior(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = add nsw i32 %3, 2
  %5 = mul nsw i32 %4, 5
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 4.000000e-01) #1
  %7 = tail call fastcc i32 @h(i32 noundef %4)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.000000e-01) #1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %3)
  ret i32 %9
}

define i32 @interleaved(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = mul nsw i32 %3, 5
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 4.000000e-01) #1
  %7 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 2.000000e-01) #1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %3)
  ret i32 %8
}

define i32 @independent(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = mul nsw i32 %3, 5
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 4.000000e-01) #1
  %6 = xor i32 %3, 3
  %7 = and i32 %0, 3
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.500000e-01) #1
  %9 = tail call fastcc i32 @h(i32 noundef %8)
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.000000e-01) #1
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6)
  ret i32 %11
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nomerge nounwind }
