; railwindow_reject_quantum_extent.ll — DECLINE (bd 01po.19 S4, addendum note
; 3): a VLA whose extent is a quantum value is a quantum-sized allocation; the
; handle walk needs a classical cell count.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
;
; SOURCE (clang -O1, verbatim below):
;   /* decline (note 3): a VLA whose extent is quantum */
;   int f(void) {
;     int n = 2;
;     cq_theta(&n, .3);
;     bool q[n + 1];
;     for (int i = 0; i < 2; i++) q[i] = 0;
;     for (int i = 0; i < 2; i++) cq_theta(&q[i], .5);
;     for (int i = 0; i < 2; i++) cq_theta(&q[i], .5);
;     return cq_measure(q[0]);
;   }
;   int main(void) { return f(); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function f i32 (): cq rail window: quantum array extent is a quantum value

; ModuleID = 'qextent.c'
source_filename = "qextent.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @f() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 3.000000e-01) #2
  %2 = add nsw i32 %1, 1
  %3 = zext i32 %2 to i64
  %4 = alloca i8, i64 %3, align 16
  store i16 0, ptr %4, align 16
  br label %5

5:                                                ; preds = %0, %5
  %6 = phi i64 [ 0, %0 ], [ %12, %5 ]
  %7 = getelementptr inbounds i8, ptr %4, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 5.000000e-01) #2
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %7, align 1, !tbaa !6
  %12 = add nuw nsw i64 %6, 1
  %13 = icmp eq i64 %6, 0
  br i1 %13, label %5, label %19, !llvm.loop !12

14:                                               ; preds = %19
  %15 = load i8, ptr %4, align 16, !tbaa !6, !range !10, !noundef !11
  %16 = trunc nuw i8 %15 to i1
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %16) #3
  %18 = zext i1 %17 to i32
  ret i32 %18

19:                                               ; preds = %5, %19
  %20 = phi i64 [ %26, %19 ], [ 0, %5 ]
  %21 = getelementptr inbounds i8, ptr %4, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = trunc nuw i8 %22 to i1
  %24 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %23, double noundef 5.000000e-01) #2
  %25 = zext i1 %24 to i8
  store i8 %25, ptr %21, align 1, !tbaa !6
  %26 = add nuw nsw i64 %20, 1
  %27 = icmp eq i64 %20, 0
  br i1 %27, label %19, label %14, !llvm.loop !15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @f()
  ret i32 %1
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

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
