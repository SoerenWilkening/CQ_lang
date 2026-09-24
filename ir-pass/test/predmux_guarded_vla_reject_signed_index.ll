; predmux_guarded_vla_reject_signed_index.ll —
; DECLINE (bd xdu2.8). `if (q && k < m)` with `k` SIGNED: `k <s m` does not bound
; a negative `k`, and nothing proves `k >= 0`. Kills the signed-non-negativity
; conjunct of proof (I). Source: tests/e2e/railbank_guarded_vla_matrix.c CASE 8.
;
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s 2>&1 | %filecheck %s
; CHECK: gate=E4-gep
; CHECK: cq controlled lowering: control flow under quantum control
; ⚠ A DS_Error decline writes 0 bytes to stdout; the verdict is pinned by the `not`
; inversion and the leave line (Rule 12 (b)).

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 2
  %4 = sext i32 %0 to i64
  %5 = getelementptr ptr, ptr %1, i64 %4
  %6 = getelementptr i8, ptr %5, i64 -8
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = add nsw i32 %8, %0
  %10 = tail call fastcc i32 @slice(i32 noundef %3, i32 noundef %9)
  ret i32 %10
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = icmp slt i32 %0, 1
  br i1 %3, label %37, label %4

4:                                                ; preds = %2
  %5 = zext nneg i32 %0 to i64
  %6 = tail call ptr @llvm.stacksave.p0()
  %7 = alloca i32, i64 %5, align 16
  %8 = zext nneg i32 %0 to i64
  br label %14

9:                                                ; preds = %14
  %10 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #5
  %11 = icmp ne i32 %10, 0
  %12 = icmp slt i32 %1, %0
  %13 = and i1 %12, %11
  br i1 %13, label %21, label %27

14:                                               ; preds = %4, %14
  %15 = phi i64 [ 0, %4 ], [ %19, %14 ]
  %16 = getelementptr inbounds i32, ptr %7, i64 %15
  %17 = trunc i64 %15 to i32
  %18 = add i32 %17, 3
  store i32 %18, ptr %16, align 4, !tbaa !10
  %19 = add nuw nsw i64 %15, 1
  %20 = icmp eq i64 %19, %8
  br i1 %20, label %9, label %14, !llvm.loop !12

21:                                               ; preds = %9
  %22 = sext i32 %1 to i64
  %23 = getelementptr inbounds i32, ptr %7, i64 %22
  %24 = load i32, ptr %23, align 4, !tbaa !10
  %25 = icmp sgt i32 %24, 4
  %26 = icmp slt i32 %24, 9
  br label %27

27:                                               ; preds = %21, %9
  %28 = phi i1 [ %25, %21 ], [ false, %9 ]
  %29 = phi i1 [ %26, %21 ], [ false, %9 ]
  %30 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %31 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #5
  %32 = zext i1 %31 to i32
  %33 = add nsw i32 %30, %32
  %34 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %29) #5
  %35 = zext i1 %34 to i32
  %36 = add nsw i32 %33, %35
  tail call void @llvm.stackrestore.p0(ptr %6)
  br label %37

37:                                               ; preds = %2, %27
  %38 = phi i32 [ %36, %27 ], [ 0, %2 ]
  ret i32 %38
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
