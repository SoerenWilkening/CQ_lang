; spec_intermediate_unc_terminal_union_multigroup.ll — ACCEPT (bd
; test_C_libtooling-p3kd.13, R11 review round 3, F3): three dead-terminal groups in
; one function — the regular group and two iteration-local loops. Reviewer probe P1.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     int mg(int m) { int acc = 0;
;       int q = m & 7; cq_theta(&q, .5); int r = h(q); int t = q * 5;
;       cq_theta(&t, .4); cq_theta(&r, .2); acc += cq_measure(q);          // regular
;       for (int j = 0; j < 2; j++) { int p = m ^ j; cq_theta(&p, .25); int r2 = h(p);
;         int t2 = p * 9; cq_theta(&t2, .15); cq_theta(&r2, .35);
;         acc += cq_measure(p); }                                          // loop A
;       for (int k = 0; k < 3; k++) { int s = m + k; cq_theta(&s, .45);
;         int t3 = s * 7; cq_theta(&t3, .55); acc += cq_measure(s); }      // loop B
;       return acc; }
;
; REGULAR — the union of interleaved t/r over the measured q: one LIFO reversal (r's
;   Ry, t's Ry, `mul_unc`, free t, r's twin, free r). main leaves r allocated.
; LOOP A — the union IN-BODY, once per trip (round 2's split leaked r2): the same
;   reversal over t2/r2. NEW.
; LOOP B — template-only: planned Loud, byte-identical to main.
; Stage 2b (review round 3): 9 frees verified, 0 violations, 0 left dirty.
;
; L9 DISCLOSURE (R11 r3 F2): the union delays t's reversal past r's Ry, so M-A's
; `non-diagonal gate over a live derived record` fires on MORE gates here than on
; main (4 against 2) although this stream frees everything and main leaves two rails
; dirty — M-A asks "allocated at the gate", not "reversed before the next gate on its
; lineage". The same false-positive class main shows for template-only unions;
; follow-up drafted in the p3kd.13 report. This file therefore pins no warning count.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; NOERR-NOT: error

; CHECK-LABEL: define i32 @mg(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double -2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; Loop A, in-body:
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; CHECK-NEXT: %[[R2:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[P]])
; CHECK-NEXT: %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 9)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double 1.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R2]], double 3.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R2]], double -3.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T2]], double -1.500000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T2]], i32 %[[P]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T2]])
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R2]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R2]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[P]])
; CHECK:      br i1 %{{[0-9]+}}, label %{{[0-9]+}}, label %{{[0-9]+}}
; Loop B, template-only, as main:
; CHECK:      %[[S:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[S]], double 4.500000e-01)
; CHECK-NEXT: %[[T3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[S]], i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T3]], double 5.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T3]], double -5.500000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T3]], i32 %[[S]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T3]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S]])

declare i32 @cq_theta_si32(i32 noundef, double noundef) #1
declare i32 @cq_measure_si32(i32 noundef) #1

define i32 @mg(i32 noundef %0) #0 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = mul nsw i32 %3, 5
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 4.000000e-01) #4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 2.000000e-01) #4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  br label %9

9:
  %10 = phi i32 [ %8, %1 ], [ %19, %9 ]
  %11 = phi i32 [ 0, %1 ], [ %20, %9 ]
  %12 = xor i32 %11, %0
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 2.500000e-01) #4
  %14 = tail call fastcc i32 @h(i32 noundef %13)
  %15 = mul nsw i32 %13, 9
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 1.500000e-01) #4
  %17 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 3.500000e-01) #4
  %18 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  %19 = add nsw i32 %18, %10
  %20 = add nuw nsw i32 %11, 1
  %21 = icmp eq i32 %11, 0
  br i1 %21, label %9, label %23

22:
  ret i32 %31

23:
  %24 = phi i32 [ %31, %23 ], [ %19, %9 ]
  %25 = phi i32 [ %32, %23 ], [ 0, %9 ]
  %26 = add nsw i32 %25, %0
  %27 = tail call i32 @cq_theta_si32(i32 noundef %26, double noundef 4.500000e-01) #4
  %28 = mul nsw i32 %27, 7
  %29 = tail call i32 @cq_theta_si32(i32 noundef %28, double noundef 5.500000e-01) #4
  %30 = tail call i32 @cq_measure_si32(i32 noundef %27) #5
  %31 = add nsw i32 %30, %24
  %32 = add nuw nsw i32 %25, 1
  %33 = icmp eq i32 %32, 3
  br i1 %33, label %22, label %23
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
