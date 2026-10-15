; spec_accept_predicted_classical_round2_ry_between.ll — ACCEPT, warned (bd dm7f.22, batch 053).
; Sibling of spec_accept_predicted_classical_round2_mask_growth{,_ry}.ll: the same round-2
; mask-growth site (`t = h(q, y)`, `y` a 6.5 classical-call-arm merge `%out`, `t` tainted AT
; ROUND 1 by the SETTLE step), but `cq_theta(&y, .3)` sits BETWEEN the call and the `t > 3`
; region. From the batch-053 core reviewer's "Ry on y between the call and the region" probe
; (its hand-edited IR is reproduced here from C; @main and the clones are identical).
;
; What is pinned: the copy-out rail `T = __cq_q_h_11(Q, OUT)` holds `y + 1` of the PRE-rotation
; `y`, and the region reads `T` AFTER `cqrt_ry_i32(OUT, .3)`. No recompute from `y` can return `T`
; to |0> once `y` is rotated, so NO `__cq_q_h_11_unc` is emitted and `T` is never freed (R5: a
; rail not provably |0> is left allocated, never freed dirty). The consecutive-line chain in
; @main runs from the first alloc to `ret`, so it also proves `T` has no `cqrt_free`; the NOUNC
; prefix proves no `_unc` anywhere in the module. The `non-diagonal gate over a live derived
; record` warning names exactly this Ry. Stage 2b on the output: 10 cqrt_free sites, 10
; verified, 1 template rail left dirty (`T`, the accepted leak).
; RETIREMENT TRIGGER (L7): if a `__cq_q_h_11_unc` of `T` ever appears, it is valid only while `y`
; still holds the copied value (the Ry on `y` and the region commute, so a scheduler could move
; the Ry past the region); re-derive the stream by hand, never regenerate by reflex.
;
; 6 TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.
; Caller TU (-include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int ext_f(int a);
;   int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = m; cq_theta(&q, .5); int y = 0; if (q > 5) y = ext_f(7); int t = h(q, y); cq_theta(&y, .3); int q2 = n; cq_theta(&q2, .4); if (t > 3) cq_theta(&q2, .2); return cq_measure(q2) + cq_measure(q) + cq_measure(y); }
; Library TU 1: void g(int a); int h(int a, int k) { g(a); return k + 1; }
; Library TU 2: int f2(int a); void g(int a) { f2(a); }
; Library TU 3: int f3(int a); int f2(int a) { return f3(a) + 1; }
; Library TU 4: int f3(int a) { return a * 3; }
; Library TU 5: int ext_f(int a) { return a * 7 + 2; } int g2(int a, int b) { return a * b + 1; }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2>&1
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOUNC < %t.ll
; NOUNC-NOT: __cq_q_h_11_unc
; CHECK-NOT: error:
; CHECK: warning: {{.*}}in function main i32 (i32, ptr): cq rotation lowering: non-diagonal gate over a live derived record
; CHECK-NOT: error:
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 {{%[a-z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[E:%[a-z0-9_.]+]] = tail call i32 @ext_f(i32 noundef 7)
; CHECK-NEXT: [[C:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 [[Q]], i32 5)
; CHECK-NEXT: [[OUT:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[C]], i32 [[OUT]], i32 [[E]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 [[C]], i32 [[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 [[C]])
; CHECK-NEXT: [[T:%[a-z0-9_.]+]] = tail call i32 @__cq_q_h_11(i32 noundef [[Q]], i32 noundef [[OUT]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[OUT]], double 3.000000e-01)
; CHECK-NEXT: [[Q2:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 {{%[a-z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q2]], double 4.000000e-01)
; CHECK-NEXT: [[F:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 [[T]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 [[F]], i32 [[Q2]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 [[F]], i32 [[T]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 [[F]])
; CHECK-NEXT: {{%[a-z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 [[Q2]])
; CHECK-NEXT: {{%[a-z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 [[Q]])
; CHECK-NEXT: add nsw i32
; CHECK-NEXT: {{%[a-z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 [[OUT]])
; CHECK-NEXT: add nsw i32
; CHECK-NEXT: ret i32

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %10 = icmp sgt i32 %9, 5
  br i1 %10, label %11, label %13

11:                                               ; preds = %2
  %12 = tail call i32 @ext_f(i32 noundef 7) #5
  br label %13

13:                                               ; preds = %11, %2
  %14 = phi i32 [ %12, %11 ], [ 0, %2 ]
  %15 = tail call i32 @h(i32 noundef %9, i32 noundef %14) #5
  %16 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 3.000000e-01) #4
  %17 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 4.000000e-01) #4
  %18 = icmp sgt i32 %15, 3
  br i1 %18, label %19, label %21

19:                                               ; preds = %13
  %20 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 2.000000e-01) #4
  br label %21

21:                                               ; preds = %19, %13
  %22 = phi i32 [ %20, %19 ], [ %17, %13 ]
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #5
  %24 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %25 = add nsw i32 %24, %23
  %26 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  %27 = add nsw i32 %25, %26
  ret i32 %27
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  tail call void @g(i32 noundef %0) #5
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define void @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f2(i32 noundef %0) #5
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @f2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f3(i32 noundef %0) #5
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @f3(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483646, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 7
  %3 = add nsw i32 %2, 2
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @g2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = mul nsw i32 %1, %0
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
