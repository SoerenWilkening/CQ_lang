; lowering_reject_railbank_dynamic_lifetime_start_in_loop.ll — DECLINE (bd test_C_libtooling-xdu2.4, Rule-13 round-2 review B F-R2B-1).
;
; A runtime bank whose `llvm.lifetime.start` sits at the top of the WRITE-LOOP body
; (hand IR; clang emits no lifetime markers for a VLA). It dominates every access,
; which the first liveness fence accepted — but it runs every trip and kills the
; cells earlier trips wrote. The carve now also requires the start to run at most
; once (no cycle through its block).
; ⚠ A DS_Error decline writes 0 bytes to stdout; the property is pinned by the `not` inversion (Rule 12 (b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: array storage is not live at every access

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 1
  %4 = tail call fastcc i32 @slice(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %26, label %3

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = tail call ptr @llvm.stacksave.p0()
  %6 = alloca i32, i64 %4, align 16
  %7 = zext nneg i32 %0 to i64
  br label %10

8:                                                ; preds = %10
  %9 = zext nneg i32 %0 to i64
  br label %17

10:                                               ; preds = %3, %10
  %11 = phi i64 [ 0, %3 ], [ %14, %10 ]
  call void @llvm.lifetime.start.p0(i64 -1, ptr %6)
  %12 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %13 = getelementptr inbounds i32, ptr %6, i64 %11
  store i32 %12, ptr %13, align 4, !tbaa !6
  %14 = add nuw nsw i64 %11, 1
  %15 = icmp eq i64 %14, %7
  br i1 %15, label %8, label %10, !llvm.loop !10

16:                                               ; preds = %17
  tail call void @llvm.stackrestore.p0(ptr %5)
  br label %26

17:                                               ; preds = %8, %17
  %18 = phi i64 [ 0, %8 ], [ %24, %17 ]
  %19 = phi i32 [ 0, %8 ], [ %23, %17 ]
  %20 = getelementptr inbounds i32, ptr %6, i64 %18
  %21 = load i32, ptr %20, align 4, !tbaa !6
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #4
  %23 = add nsw i32 %22, %19
  %24 = add nuw nsw i64 %18, 1
  %25 = icmp eq i64 %24, %9
  br i1 %25, label %16, label %17, !llvm.loop !13

26:                                               ; preds = %1, %16
  %27 = phi i32 [ %23, %16 ], [ 0, %1 ]
  ret i32 %27
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

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

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
