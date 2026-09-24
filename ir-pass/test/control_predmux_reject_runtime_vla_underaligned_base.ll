; control_predmux_reject_runtime_vla_underaligned_base.ll — DECLINE (bd test_C_libtooling-xdu2.4, Rule-13 finding 3).
; 
; i64 cells (`long long p[n]`) whose runtime alloca is re-annotated `align 4` (its init
; stores too), while the arm-only `p[i]` load keeps `align 8`. The STRIDE conjunct passes
; (8 % 8 == 0), so only the BASE conjunct (alloca alignment >= load alignment) can refuse
; the speculation. The overaligned twin cannot pin it: its stride also fails. Kills
; injection mutant M9. The unmutated i64 module ACCEPTS (checked by hand, not a fixture).
; ⚠ A DS_Error decline writes 0 bytes to stdout; the property is pinned by the `not` inversion (Rule 12 (b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control
; CHECK-NOT: tainted value muxed

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, -1
  tail call fastcc void @run_bank(i32 noundef %3)
  tail call fastcc void @run_bank(i32 noundef %0)
  ret i32 0
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @run_bank(i32 noundef %0) unnamed_addr #1 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %60, label %3

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = tail call ptr @llvm.stacksave.p0()
  %6 = alloca i64, i64 %4, align 4
  %7 = alloca i32, i64 %4, align 16
  %8 = zext nneg i32 %0 to i64
  br label %13

9:                                                ; preds = %13
  %10 = alloca i32, i64 %4, align 16
  %11 = shl nsw i32 %0, 2
  %12 = zext nneg i32 %0 to i64
  br label %25

13:                                               ; preds = %3, %13
  %14 = phi i64 [ 0, %3 ], [ %20, %13 ]
  %15 = add nuw nsw i64 %14, 3
  %16 = getelementptr inbounds i64, ptr %6, i64 %14
  store i64 %15, ptr %16, align 4, !tbaa !6
  %17 = getelementptr inbounds i32, ptr %7, i64 %14
  %18 = trunc i64 %14 to i32
  %19 = add i32 %18, 2
  store i32 %19, ptr %17, align 4, !tbaa !10
  %20 = add nuw nsw i64 %14, 1
  %21 = icmp eq i64 %20, %8
  br i1 %21, label %9, label %13, !llvm.loop !12

22:                                               ; preds = %45
  %23 = tail call i32 @llvm.smax.i32(i32 %0, i32 1)
  %24 = zext nneg i32 %23 to i64
  br label %53

25:                                               ; preds = %9, %45
  %26 = phi i64 [ 0, %9 ], [ %48, %45 ]
  %27 = phi i32 [ %11, %9 ], [ %47, %45 ]
  %28 = phi i64 [ 0, %9 ], [ %46, %45 ]
  %29 = getelementptr inbounds i32, ptr %7, i64 %26
  %30 = load i32, ptr %29, align 4, !tbaa !10
  %31 = icmp slt i32 %27, %30
  br i1 %31, label %36, label %32

32:                                               ; preds = %25
  %33 = getelementptr inbounds i32, ptr %10, i64 %26
  %34 = load i32, ptr %33, align 4, !tbaa !10
  %35 = tail call i32 @cq_theta_si32(i32 noundef %34, double noundef 5.000000e-01) #5
  store i32 %35, ptr %33, align 4, !tbaa !10
  br label %36

36:                                               ; preds = %32, %25
  %37 = getelementptr inbounds i32, ptr %10, i64 %26
  %38 = load i32, ptr %37, align 4, !tbaa !10
  %39 = icmp eq i32 %38, 0
  br i1 %39, label %45, label %40

40:                                               ; preds = %36
  %41 = getelementptr inbounds i64, ptr %6, i64 %26
  %42 = load i64, ptr %41, align 8, !tbaa !6
  %43 = add nsw i64 %42, %28
  %44 = sub nsw i32 %27, %30
  br label %45

45:                                               ; preds = %36, %40
  %46 = phi i64 [ %43, %40 ], [ %28, %36 ]
  %47 = phi i32 [ %44, %40 ], [ %27, %36 ]
  %48 = add nuw nsw i64 %26, 1
  %49 = icmp eq i64 %48, %12
  br i1 %49, label %22, label %25, !llvm.loop !15

50:                                               ; preds = %53
  %51 = tail call i64 @cq_measure_sll(i64 noundef %46) #5
  %52 = tail call i32 @cq_measure_si32(i32 noundef %47) #5
  tail call void @llvm.stackrestore.p0(ptr %5)
  br label %60

53:                                               ; preds = %22, %53
  %54 = phi i64 [ 0, %22 ], [ %58, %53 ]
  %55 = getelementptr inbounds i32, ptr %10, i64 %54
  %56 = load i32, ptr %55, align 4, !tbaa !10
  %57 = tail call i32 @cq_measure_si32(i32 noundef %56) #5
  %58 = add nuw nsw i64 %54, 1
  %59 = icmp eq i64 %58, %24
  br i1 %59, label %50, label %53, !llvm.loop !16

60:                                               ; preds = %1, %50
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

declare i64 @cq_measure_sll(i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!7 = !{!"long long", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
