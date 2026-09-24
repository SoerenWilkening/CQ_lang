; lowering_reject_railbank_literal_cell.ll — DECLINE (bd test_C_libtooling-xdu2.4, Rule-13 review A F-1 / round-2 P3).
;
; SOURCE: tests/e2e/railbank_dynamic_matrix.c CASE_LITERAL_CELL_FIXED at clang -O1:
; `int c[3] = {0}; for (i<3) { int t = cq_theta(c[i], .25); if (c[i] != 0) c[i] = t; }`
; beside a PredMux-claimed Grover arm on `b[]`, then `cq_measure(c[i])`. The zero seed
; makes the arm's condition constant, PASS H folds the emptied arm to a select, and a
; PredMux residue fold in the same function reduces it to the LITERAL — so the bank
; parked `store i32 0` (handle 0, a live and then FREED rail) and measured it three
; times. The HEAD oracle ACCEPTED this (pre-existing P1). The postcondition
; `declineNonHandleBankStores`, run after every folder in BOTH entry points, is the
; only owner: pinned here at the IR layer so deleting it cannot go green in lit.
; The decline is an over-decline of well-defined C (bd xdu2.9), never a miscompile.
; ⚠ A DS_Error decline writes 0 bytes to stdout; the property is pinned by the `not` inversion (Rule 12 (b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: a cell parks a value that is not a rail handle

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.run_bank.p = private unnamed_addr constant [3 x i32] [i32 3, i32 4, i32 5], align 4
@__const.run_bank.z = private unnamed_addr constant [3 x i32] [i32 2, i32 3, i32 4], align 4

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  tail call fastcc void @run_bank()
  ret i32 0
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @run_bank() unnamed_addr #1 {
  %1 = alloca [3 x i32], align 4
  %2 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(12) %1, i8 0, i64 12, i1 false)
  br label %4

3:                                                ; preds = %11
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %2, i8 0, i64 3, i1 false)
  br label %14

4:                                                ; preds = %0, %11
  %5 = phi i64 [ 0, %0 ], [ %12, %11 ]
  %6 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %5
  %7 = load i32, ptr %6, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.500000e-01) #5
  %9 = icmp eq i32 %7, 0
  br i1 %9, label %11, label %10

10:                                               ; preds = %4
  store i32 %8, ptr %6, align 4, !tbaa !6
  br label %11

11:                                               ; preds = %10, %4
  %12 = add nuw nsw i64 %5, 1
  %13 = icmp eq i64 %12, 3
  br i1 %13, label %3, label %4, !llvm.loop !10

14:                                               ; preds = %3, %36
  %15 = phi i64 [ 0, %3 ], [ %39, %36 ]
  %16 = phi i32 [ 12, %3 ], [ %38, %36 ]
  %17 = phi i32 [ 0, %3 ], [ %37, %36 ]
  %18 = getelementptr inbounds [3 x i32], ptr @__const.run_bank.z, i64 0, i64 %15
  %19 = load i32, ptr %18, align 4, !tbaa !6
  %20 = icmp slt i32 %16, %19
  br i1 %20, label %27, label %21

21:                                               ; preds = %14
  %22 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %15
  %23 = load i8, ptr %22, align 1, !tbaa !13, !range !15, !noundef !16
  %24 = trunc nuw i8 %23 to i1
  %25 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %24, double noundef 5.000000e-01) #5
  %26 = zext i1 %25 to i8
  store i8 %26, ptr %22, align 1, !tbaa !13
  br label %27

27:                                               ; preds = %21, %14
  %28 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %15
  %29 = load i8, ptr %28, align 1, !tbaa !13, !range !15, !noundef !16
  %30 = trunc nuw i8 %29 to i1
  br i1 %30, label %31, label %36

31:                                               ; preds = %27
  %32 = getelementptr inbounds [3 x i32], ptr @__const.run_bank.p, i64 0, i64 %15
  %33 = load i32, ptr %32, align 4, !tbaa !6
  %34 = add nsw i32 %33, %17
  %35 = sub nsw i32 %16, %19
  br label %36

36:                                               ; preds = %27, %31
  %37 = phi i32 [ %34, %31 ], [ %17, %27 ]
  %38 = phi i32 [ %35, %31 ], [ %16, %27 ]
  %39 = add nuw nsw i64 %15, 1
  %40 = icmp eq i64 %39, 3
  br i1 %40, label %41, label %14, !llvm.loop !17

41:                                               ; preds = %36, %41
  %42 = phi i64 [ %47, %41 ], [ 0, %36 ]
  %43 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %42
  %44 = load i8, ptr %43, align 1, !tbaa !13, !range !15, !noundef !16
  %45 = trunc nuw i8 %44 to i1
  %46 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %45) #5
  %47 = add nuw nsw i64 %42, 1
  %48 = icmp eq i64 %47, 3
  br i1 %48, label %52, label %41, !llvm.loop !18

49:                                               ; preds = %52
  %50 = tail call i32 @cq_measure_si32(i32 noundef %37) #5
  %51 = tail call i32 @cq_measure_si32(i32 noundef %38) #5
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %2) #5
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %1) #5
  ret void

52:                                               ; preds = %41, %52
  %53 = phi i64 [ %57, %52 ], [ 0, %41 ]
  %54 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %53
  %55 = load i32, ptr %54, align 4, !tbaa !6
  %56 = tail call i32 @cq_measure_si32(i32 noundef %55) #5
  %57 = add nuw nsw i64 %53, 1
  %58 = icmp eq i64 %57, 3
  br i1 %58, label %49, label %52, !llvm.loop !19
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{!14, !14, i64 0}
!14 = !{!"_Bool", !8, i64 0}
!15 = !{i8 0, i8 2}
!16 = !{}
!17 = distinct !{!17, !11, !12}
!18 = distinct !{!18, !11, !12}
!19 = distinct !{!19, !11, !12}
