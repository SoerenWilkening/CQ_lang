; predmux_guarded_vla_reject_trip_wrong_eq.ll —
; DECLINE (bd xdu2.8). In a loop, `q && m + 1 == n`: an EQUALITY guard, but
; between the extent and something that is not the trip count (extent = trips - 1
; here). Proof (T) matches the two sides structurally. Source: tests/e2e/railbank_guarded_vla_matrix.c CASE 13.
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
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 1
  %4 = tail call fastcc i32 @slice(i32 noundef %3, i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = icmp slt i32 %0, 1
  %4 = icmp slt i32 %1, 1
  %5 = or i1 %3, %4
  br i1 %5, label %50, label %6

6:                                                ; preds = %2
  %7 = zext nneg i32 %1 to i64
  %8 = tail call ptr @llvm.stacksave.p0()
  %9 = alloca i32, i64 %7, align 16
  %10 = zext nneg i32 %1 to i64
  br label %20

11:                                               ; preds = %20
  %12 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #4
  %13 = icmp sgt i32 %0, 0
  br i1 %13, label %14, label %27

14:                                               ; preds = %11
  %15 = icmp ne i32 %12, 0
  %16 = add nuw nsw i32 %1, 1
  %17 = icmp eq i32 %16, %0
  %18 = select i1 %15, i1 %17, i1 false
  %19 = zext nneg i32 %0 to i64
  br label %31

20:                                               ; preds = %6, %20
  %21 = phi i64 [ 0, %6 ], [ %25, %20 ]
  %22 = getelementptr inbounds i32, ptr %9, i64 %21
  %23 = trunc i64 %21 to i32
  %24 = add i32 %23, 3
  store i32 %24, ptr %22, align 4, !tbaa !6
  %25 = add nuw nsw i64 %21, 1
  %26 = icmp eq i64 %25, %10
  br i1 %26, label %11, label %20, !llvm.loop !10

27:                                               ; preds = %39, %11
  %28 = phi i32 [ 0, %11 ], [ %47, %39 ]
  %29 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  %30 = add nsw i32 %29, %28
  tail call void @llvm.stackrestore.p0(ptr %8)
  br label %50

31:                                               ; preds = %14, %39
  %32 = phi i64 [ 0, %14 ], [ %48, %39 ]
  %33 = phi i32 [ 0, %14 ], [ %47, %39 ]
  br i1 %18, label %34, label %39

34:                                               ; preds = %31
  %35 = getelementptr inbounds i32, ptr %9, i64 %32
  %36 = load i32, ptr %35, align 4, !tbaa !6
  %37 = icmp sgt i32 %36, 4
  %38 = icmp slt i32 %36, 9
  br label %39

39:                                               ; preds = %34, %31
  %40 = phi i1 [ %37, %34 ], [ false, %31 ]
  %41 = phi i1 [ %38, %34 ], [ false, %31 ]
  %42 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %40) #4
  %43 = zext i1 %42 to i32
  %44 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %41) #4
  %45 = zext i1 %44 to i32
  %46 = add nuw nsw i32 %33, %43
  %47 = add nuw nsw i32 %46, %45
  %48 = add nuw nsw i64 %32, 1
  %49 = icmp eq i64 %48, %19
  br i1 %49, label %27, label %31, !llvm.loop !13

50:                                               ; preds = %2, %27
  %51 = phi i32 [ %30, %27 ], [ 0, %2 ]
  ret i32 %51
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
