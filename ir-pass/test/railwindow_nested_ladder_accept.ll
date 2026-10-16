; railwindow_nested_ladder_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19.34.4`,
; R11 round 1 C-F1: an over-decline the 01po.19.34 nested admission exposed).
;
; A TRIANGULAR nest: `for i in 1..3 { for j < i { if (q[j]) Ry(q[i], .) } }`.
; The control cell q[j] and the target cell q[i] are never the same cell (j
; runs 0..i-1), but `isKnownNonZero` of the cell difference {-i,+,1}<j-loop>
; asks about every value of the type, so the window versioned the pair and its
; aliased copy refused itself as a self-controlled gate: loud `aliased cell
; indices make a quantum control its own target`. `railWindowDistinct` now also
; asks SCEV whether the difference is nonzero over the loop it recurs in
; (`nonZeroOverLoop`: affine, constant step, |step| * symbolic-max-BTC below
; half the ring, start and end value strictly on one side of 0). The decline
; twin, where j reaches i, is railwindow_nested_ladder_reject_self_control.ll.
;
; ANALYTIC CHECK (independent scratch state-vector of the SOURCE, and replay of
; the trace — they agree to 1e-6; no simulator in the repo): q[0..3] ends in
;   0000 +0.852525  1000 +0.109698  1001 +0.282161  1010 -0.295295
;   1011 +0.177649  1100 +0.045613  1101 -0.034074  1110 -0.177154
;   1111 -0.167840
; (q[0] first), nothing else. Stage 2b proves the control/target pair with its
; own relational counter bound (`_iv_sym`): 0 violations, 0 unproven.
;
; SOURCE (clang -O1, verbatim below):
;   /* H5: nested ladder, cross-trip aliasing (q[j] targets of earlier outer trips become controls) */
;   #include <stdio.h>
;   #include <math.h>
;   int main(void) {
;       bool q[4];
;       for (int i = 0; i < 4; i++) q[i] = 0;
;       cq_theta(&q[0], 1.1);
;       for (int i = 1; i < 4; i++) {
;           for (int j = 0; j < i; j++) {
;               if (q[j]) cq_theta(&q[i], 0.3 + 0.7 * i + 0.2 * j);
;           }
;       }
;       for (int i = 0; i < 4; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK: [[V0:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 [[V0]], double 1.100000e+00)
; CHECK: [[V1:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i1(i1 {{%[-a-zA-Z$._0-9]+}})
; CHECK: {{^}}[[INNER:[0-9]+]]:{{.*}}; preds = {{.*}}%[[INNER]]{{(,|$)}}
; CHECK: call void @cqrt_ry_i1_controlled(i32 [[C:%[-a-zA-Z$._0-9]+]], i32 [[T:%[-a-zA-Z$._0-9]+]], double {{%[-a-zA-Z$._0-9]+}})
; CHECK: br i1 {{%[-a-zA-Z$._0-9]+}}, label %{{[0-9]+}}, label %[[INNER]]
; CHECK: call i1 @cqrt_measure_i1(i32 {{%[-a-zA-Z$._0-9]+}})
; CHECK-NOT: call {{.*}}@cq

; ModuleID = 'ladder.c'
source_filename = "ladder.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  store i32 0, ptr %1, align 4
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00) #7
  %3 = zext i1 %2 to i8
  store i8 %3, ptr %1, align 4, !tbaa !6
  br label %4

4:                                                ; preds = %0, %10
  %5 = phi i64 [ 1, %0 ], [ %11, %10 ]
  %6 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %7 = trunc nuw nsw i64 %5 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 0x3FE6666666666666, double 3.000000e-01)
  br label %13

10:                                               ; preds = %26
  %11 = add nuw nsw i64 %5, 1
  %12 = icmp eq i64 %11, 4
  br i1 %12, label %31, label %4, !llvm.loop !10

13:                                               ; preds = %4, %26
  %14 = phi i64 [ 0, %4 ], [ %27, %26 ]
  %15 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %14
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !13, !noundef !14
  %17 = trunc nuw i8 %16 to i1
  br i1 %17, label %18, label %26

18:                                               ; preds = %13
  %19 = load i8, ptr %6, align 1, !tbaa !6, !range !13, !noundef !14
  %20 = trunc nuw i8 %19 to i1
  %21 = trunc nuw nsw i64 %14 to i32
  %22 = uitofp nneg i32 %21 to double
  %23 = tail call double @llvm.fmuladd.f64(double %22, double 2.000000e-01, double %9)
  %24 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %20, double noundef %23) #7
  %25 = zext i1 %24 to i8
  store i8 %25, ptr %6, align 1, !tbaa !6
  br label %26

26:                                               ; preds = %13, %18
  %27 = add nuw nsw i64 %14, 1
  %28 = icmp eq i64 %27, %5
  br i1 %28, label %10, label %13, !llvm.loop !15

29:                                               ; preds = %31
  %30 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

31:                                               ; preds = %10, %31
  %32 = phi i64 [ %39, %31 ], [ 0, %10 ]
  %33 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %32
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !13, !noundef !14
  %35 = trunc nuw i8 %34 to i1
  %36 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %35) #6
  %37 = zext i1 %36 to i32
  %38 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %37)
  %39 = add nuw nsw i64 %32, 1
  %40 = icmp eq i64 %39, 4
  br i1 %40, label %29, label %31, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !11, !12}
!16 = distinct !{!16, !11, !12}
