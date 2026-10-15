; railwindow_s5_reject_update_two_cells.ll — DECLINE (bd `test_C_libtooling-01po.19` S5 R11 round 1,
; finding A-F1 (R7); the one predicate `railWindowWritesBack`, RailWindow.h).
;
; ONE RESULT, TWO CELLS. `x = a ^ b` is stored into BOTH q[2k] and q[2k+1]. On
; c16aacb6 it lowered in place on q[2k]'s rail and both cells were handed that
; ONE handle, so `cq_theta(&q[1], .3)` rotated q[0] too: P(q0=0) .7498 where
; the program's (two independent cells) value is .8356 (reviewer's scratch
; state-vector, review_s5A/p6sv.py) — a verify-clean silent miscompile. A
; result stored into a second cell is never an in-place target (condition (1)
; of `railWindowWritesBack`); the copy into the second cell is bd 01po.19.13.
;
; SOURCE (clang -O1, verbatim below):
;   int main(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .5 + .2 * i);
;     int r = 0;
;     for (int k = 0; k < 2; k++) {
;       bool a = q[2 * k], b = q[2 * k + 1];
;       bool x = a ^ b;
;       q[2 * k] = x; q[2 * k + 1] = x;
;       r = 2 * r + cq_measure(b);
;     }
;     cq_theta(&q[1], .3);
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq rail window: quantum array not lowered yet (bd 01po.19), needs S5 cell update not written back once on every path (bd 01po.19.14){{$}}

; ModuleID = 'railwindow_s5_reject_update_two_cells.c'
source_filename = "railwindow_s5_reject_update_two_cells.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 2.000000e-01, double 5.000000e-01)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 4
  br i1 %13, label %20, label %2, !llvm.loop !12

14:                                               ; preds = %20
  %15 = getelementptr inbounds i8, ptr %1, i64 1
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef 3.000000e-01) #5
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %15, align 1, !tbaa !6
  br label %39

20:                                               ; preds = %2, %20
  %21 = phi i64 [ %36, %20 ], [ 0, %2 ]
  %22 = phi i32 [ %35, %20 ], [ 0, %2 ]
  %23 = shl nuw nsw i64 %21, 1
  %24 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %23
  %25 = load i8, ptr %24, align 2, !tbaa !6, !range !10, !noundef !11
  %26 = or disjoint i64 %23, 1
  %27 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %26
  %28 = load i8, ptr %27, align 1, !tbaa !6, !range !10, !noundef !11
  %29 = trunc nuw i8 %28 to i1
  %30 = icmp ne i8 %25, %28
  %31 = zext i1 %30 to i8
  store i8 %31, ptr %24, align 2, !tbaa !6
  store i8 %31, ptr %27, align 1, !tbaa !6
  %32 = shl nsw i32 %22, 1
  %33 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %29) #4
  %34 = zext i1 %33 to i32
  %35 = or disjoint i32 %32, %34
  %36 = add nuw nsw i64 %21, 1
  %37 = icmp eq i64 %21, 0
  br i1 %37, label %20, label %14, !llvm.loop !15

38:                                               ; preds = %39
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %48

39:                                               ; preds = %14, %39
  %40 = phi i64 [ 0, %14 ], [ %49, %39 ]
  %41 = phi i32 [ %35, %14 ], [ %48, %39 ]
  %42 = shl nsw i32 %41, 1
  %43 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %40
  %44 = load i8, ptr %43, align 1, !tbaa !6, !range !10, !noundef !11
  %45 = trunc nuw i8 %44 to i1
  %46 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %45) #4
  %47 = zext i1 %46 to i32
  %48 = or disjoint i32 %42, %47
  %49 = add nuw nsw i64 %40, 1
  %50 = icmp eq i64 %49, 4
  br i1 %50, label %38, label %39, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

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
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
