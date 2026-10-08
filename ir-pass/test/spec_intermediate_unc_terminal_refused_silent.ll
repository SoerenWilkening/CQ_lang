; spec_intermediate_unc_terminal_refused_silent.ll — WARNING, LEFT ALLOCATED (bd
; test_C_libtooling-p3kd.13, R11 review round 1, F1): a DEAD clone-result TERMINAL
; whose dead-terminal plan is refused stays allocated with the existing M-A
; warning, exactly as before p3kd.13 — it never adds a loud decline, and it never
; changes the verdict of a template terminal beside it.
;
; SOURCE (`clang -O1` IR below; @arm is review round 1's probe p1_arm plus a dead
; template terminal `t`):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     int arm(int m, int k) { int q = m & 7; cq_theta(&q, .5); int r = h(q);
;         int t = q * 5; cq_theta(&t, .4);
;         if (k > 0) cq_theta(&r, .3); cq_theta(&r, .2); return cq_measure(q); }
;     int divergent(int m, int k) { int q = m & 7; cq_theta(&q, .5); int r = h(q);
;         if (k > 0) cq_theta(&r, .3); cq_theta(&r, .2); return k; }
;
; THE REGRESSION THIS PINS. p3kd.13 made an owned clone result a dead-terminal
; candidate; the first snapshot (048df10e) put it in the SAME group as the template
; terminals and let it inherit every loud decline of the dead-terminal spine:
;   @arm       rc 1, `cq uncompute: dead chain would free a measured register` —
;              the frontier retry refuses `r`'s Ry in the classical arm, and the
;              whole group, template `t` included, declined;
;   @divergent rc 1, `cq uncompute: dead chain spans divergent control-flow arms`.
; main db4cf60a never made `r` a terminal: rc 0, `r` left allocated, the warning.
; NOW clone terminals are planned AFTER the template groups, as their own groups,
; SILENTLY (Uncomputation `uncompute`, CloneProducer.h): `t` is reversed as on
; db4cf60a and `r` is left allocated with the warning — byte-identical to db4cf60a
; (measured). The refusals themselves are the spine's, pre-existing for templates
; (a dead rotated rail with a gate in a classical arm); not built here.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOTWIN < %t.ll

; WARN-NOT: error
; WARN: warning: {{.*}}in function arm{{.*}}non-diagonal gate over a live derived record
; WARN: warning: {{.*}}in function divergent{{.*}}non-diagonal gate over a live derived record
; WARN-NOT: error

; Round 2 (bd p3kd.13 R11 r2): each function first PROBES the union of its template
; and clone terminals; here the union refuses (the same spine refusals), so the
; split runs: `t` Loud exactly as on db4cf60a, `r` Silent. This file is the
; "union refuses, split still emits the templates" pin.
; The template terminal `t` is reversed and freed, as on db4cf60a:
; CHECK-LABEL: define i32 @arm(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; Neither clone rail is freed anywhere in its function (R5: a rail not provably
; |0> stays) — the windows below cover every line after its definition.
; CHECK-NOT:  call void @cqrt_free(i32 %[[R]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:  call void @cqrt_free(i32 %[[R]])
; CHECK:      ret i32
; CHECK-LABEL: define noundef i32 @divergent(
; CHECK:      %[[R2:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(
; CHECK-NOT:  call void @cqrt_free(i32 %[[R2]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[R2]], double 2.000000e-01)
; CHECK-NEXT: ret i32

; Neither clone rail is adjointed (no twin is even synthesized).
; NOTWIN-NOT: __cq_q_h_1_unc

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @arm(i32 noundef %0, i32 noundef %1) {
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #1
  %5 = tail call fastcc i32 @h(i32 noundef %4)
  %6 = mul nsw i32 %4, 5
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 4.000000e-01) #1
  %8 = icmp sgt i32 %1, 0
  br i1 %8, label %9, label %11

9:
  %10 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01) #1
  br label %11

11:
  %12 = phi i32 [ %10, %9 ], [ %5, %2 ]
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 2.000000e-01) #1
  %14 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %14
}

define noundef i32 @divergent(i32 noundef %0, i32 noundef returned %1) {
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #1
  %5 = tail call fastcc i32 @h(i32 noundef %4)
  %6 = icmp sgt i32 %1, 0
  br i1 %6, label %7, label %9

7:
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01) #1
  br label %9

9:
  %10 = phi i32 [ %8, %7 ], [ %5, %2 ]
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01) #1
  ret i32 %1
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nomerge nounwind }
