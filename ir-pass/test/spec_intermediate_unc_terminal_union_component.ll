; spec_intermediate_unc_terminal_union_component.ll — ACCEPT (bd
; test_C_libtooling-p3kd.13, R11 review round 3, F3): the terminal UNION planned
; through the measured-rail FRONTIER — whole-group (@mo) and PER COMPONENT with the
; clone in a classical arm (@rf). Reviewer probe P5.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h2(int a, int b) { return a * 3 + b; }
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     int mo(int m) { int q = m & 7; cq_theta(&q, .5); int p = (m >> 3) & 7;
;         cq_theta(&p, .35); int a = p + 2; int t = a * 5; cq_theta(&t, .4);
;         int r = h2(a, q); cq_theta(&r, .2); return cq_measure(q); }
;     int rf(int m) { int q = m & 7; cq_theta(&q, .5); int t = q * 5; cq_theta(&t, .4);
;         if (m > 3) { int r = h(q); cq_theta(&r, .2); } return cq_measure(q); }
;
; @mo — NEW ACCEPT. A two-handle clone reads the OWNED template rail `a` (of the dead
;   root p; `a = p + 2` is M-C's in-place `addc`) and the BORROWED measured q.
;   Template-only, t is not closed (`a` feeds h2) and main leaves it allocated
;   silently; the union is measured-upstream and plans whole-group with q borrowed:
;   r's Ry and twin, t's Ry and `mul_unc`, then p's `addc` and prep Ry undone (p is
;   birth-frozen — a runtime seed — so it is reverse-played but never freed).
; @rf — NEW ACCEPT. The clone terminal is in a CLASSICAL ARM; the union's single
;   point would be divergent, so it is planned per component: t at its own anchor in
;   the entry block, exactly as main, and r's reversal INSIDE the arm.
; Stage 2b (review round 3): 12 frees verified, 0 violations, 0 left dirty.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; NOERR-NOT: error

; CHECK-LABEL: define i32 @mo(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 3.500000e-01)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[P]], i32 2)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h2_11(i32 noundef %[[P]], i32 noundef %[[Q]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double -2.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h2_11_unc(i32 %[[R]], i32 %[[P]], i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T]], i32 %[[P]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[P]], i32 -2)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double -3.500000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT:  call void @cqrt_free(i32 %[[P]])
; CHECK:      ret i32

; CHECK-LABEL: define i32 @rf(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T2]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T2]])
; CHECK-NEXT: icmp sgt
; CHECK-NEXT: br i1
; CHECK:      %[[R2:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R2]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R2]], double -2.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R2]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R2]])
; CHECK-NEXT: br label
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[H]])

declare i32 @cq_theta_si32(i32 noundef, double noundef) #1
declare i32 @cq_measure_si32(i32 noundef) #1

define i32 @mo(i32 noundef %0) #0 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = lshr i32 %0, 3
  %5 = and i32 %4, 7
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.500000e-01) #4
  %7 = add nsw i32 %6, 2
  %8 = mul nsw i32 %7, 5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 4.000000e-01) #4
  %10 = tail call fastcc i32 @h2(i32 noundef %7, i32 noundef %3)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01) #4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  ret i32 %12
}

define internal fastcc i32 @h2(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

define i32 @rf(i32 noundef %0) #0 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = mul nsw i32 %3, 5
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 4.000000e-01) #4
  %6 = icmp sgt i32 %0, 3
  br i1 %6, label %7, label %10

7:
  %8 = tail call fastcc i32 @h(i32 noundef %3)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #4
  br label %10

10:
  %11 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  ret i32 %11
}

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #2 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}
attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
