; spec_intermediate_unc_terminal_union_open_root_loop.ll — ACCEPT (bd
; test_C_libtooling-p3kd.13, R11 review round 3, F3): the terminal UNION through the
; frontier fixpoint GROWING on an open root, and the union in an ITERATION-LOCAL
; loop. Reviewer probe P6.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     int og(int m) { int q = m & 7; cq_theta(&q, .5); int a = q + 2;
;         int t = a * 5; cq_theta(&t, .4); int r = h(a); cq_theta(&r, .2);
;         int q1 = (m >> 3) & 7; cq_theta(&q1, .3); int t3 = q1 * 5; cq_theta(&t3, .45);
;         int w = q1 ^ 3; return cq_measure(q) + cq_measure(w); }
;     int le(int m) { int acc = 0; for (int j = 0; j < 2; j++) { int q = m ^ j;
;         cq_theta(&q, .5); int a = q + 2; int t = a * 5; cq_theta(&t, .4);
;         int r = h(a); cq_theta(&r, .2); acc += cq_measure(q); } return acc; }
;
; @og — NEW ACCEPT (main declines: `a` is consumed by the lifted call outside the
;   template group). The union adds an unrelated template t3 whose root q1 also
;   feeds the measured w (an OPEN root), so the plan goes through the frontier
;   fixpoint, growing the frontier on q1: {t, r, a} reverse LIFO at one point (r's
;   Ry, twin, free; t's Ry, `mul_unc`, free; `a`'s `add_unc`, free), t3 at its own.
; @le — NEW ACCEPT (main declines the same way): the union reverses t, r and `a`
;   IN-BODY, once per trip, against rails minted once per trip.
; Both take the `!TmplOk` branch's ACCEPT direction (R11 r5-r7; the decline direction
;   is the spec_intermediate_unc_terminal_union_reject_* family): the first frontier
;   borrows only the measured q and cuts nothing but q's own Ry, and only the
;   union's fixpoint borrows more (q1, an open root, in @og), cutting nothing but
;   q1's own Ry: so `GroupProbe::Cut` (the FINAL frontier, R11 r8) is empty.
;   A mutant requiring the union
;   to reverse-play the template terminals' whole first DAG declines @og (measured,
;   snapshot 4433275d: rc 1, `dead chain would free a measured register`).
; Stage 2b on this module: 11 frees verified, 0 violations, 0 left dirty.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; NOERR-NOT: error

; CHECK-LABEL: define i32 @og(
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
; CHECK:      %[[Q1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q1]], double 3.000000e-01)
; CHECK-NEXT: %[[T3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q1]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T3]], double 4.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T3]], double -4.500000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T3]], i32 %[[Q1]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T3]])
; The open root q1 stays allocated (it feeds the measured w):
; CHECK-NOT:  call void @cqrt_free(i32 %[[Q1]])
; CHECK:      ret i32

; CHECK-LABEL: define i32 @le(
; CHECK:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H2]], i32 2)
; CHECK-NEXT: %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[A2]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double 4.000000e-01)
; CHECK-NEXT: %[[R2:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[A2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R2]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R2]], double -2.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R2]], i32 %[[A2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T2]], i32 %[[A2]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T2]])
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[A2]], i32 %[[H2]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A2]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H2]])
; All of it in the loop body, before the back edge:
; CHECK:      br i1 %{{[0-9]+}}, label %{{[0-9]+}}, label %{{[0-9]+}}

declare i32 @cq_theta_si32(i32 noundef, double noundef) #1
declare i32 @cq_measure_si32(i32 noundef) #1

define i32 @og(i32 noundef %0) #0 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = add nsw i32 %3, 2
  %5 = mul nsw i32 %4, 5
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 4.000000e-01) #4
  %7 = tail call fastcc i32 @h(i32 noundef %4)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.000000e-01) #4
  %9 = lshr i32 %0, 3
  %10 = and i32 %9, 7
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 3.000000e-01) #4
  %12 = mul nsw i32 %11, 5
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 4.500000e-01) #4
  %14 = xor i32 %11, 3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %16 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %17 = add nsw i32 %16, %15
  ret i32 %17
}

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #2 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @le(i32 noundef %0) #0 {
  br label %3

2:
  ret i32 %14

3:
  %4 = phi i32 [ 0, %1 ], [ %14, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %15, %3 ]
  %6 = xor i32 %5, %0
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #4
  %8 = add nsw i32 %7, 2
  %9 = mul nsw i32 %8, 5
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 4.000000e-01) #4
  %11 = tail call fastcc i32 @h(i32 noundef %8)
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 2.000000e-01) #4
  %13 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %14 = add nsw i32 %13, %4
  %15 = add nuw nsw i32 %5, 1
  %16 = icmp eq i32 %5, 0
  br i1 %16, label %3, label %2
}
attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
