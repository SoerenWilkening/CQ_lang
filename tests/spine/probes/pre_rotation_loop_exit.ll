; cq-eglo (CR rule 2, f684858: pre-rotation copies per path and trip): an in-place rotation inside a classically
; bounded loop of a value defined per trip (the header phi), whose pre-rotation value is read after the loop's exit
; (y = x + 1 of the last completed trip). The Ry hits a fresh copy per trip and x keeps its value; the exit read the
; rotated rail before (wrong values).
; CHECK p2: %{{c}} = call i32 @cqrt_alloc_i32(i32 0)
; CHECK p2: call void @cqrt_copy_i32(i32 %{{x}}, i32 %{{c}})
; CHECK p2: call void @cqrt_ry_i32(i32 %{{c}}, double %{{t}})
; USERCHECK p2
; Source:
;   int p2(int x0, double t, int n) { int x = x0, y = 0;
;     for (int i = 0;; i++) { cq_theta(&x, t); if (i >= n) break; y = x + 1; }
;     int m = cq_measure(x); return m + y * 3; }
; ModuleID = 'p2.c'
source_filename = "p2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p2(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %14, label %9

6:                                                ; preds = %14
  %7 = mul i32 %15, 3
  %8 = add i32 %7, 3
  br label %9

9:                                                ; preds = %6, %3
  %10 = phi i32 [ %8, %6 ], [ 0, %3 ]
  %11 = phi i32 [ %18, %6 ], [ %4, %3 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %13 = add nsw i32 %12, %10
  ret i32 %13

14:                                               ; preds = %3, %14
  %15 = phi i32 [ %18, %14 ], [ %4, %3 ]
  %16 = phi i32 [ %17, %14 ], [ 0, %3 ]
  %17 = add nuw nsw i32 %16, 1
  %18 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef %1) #2
  %19 = icmp eq i32 %17, %2
  br i1 %19, label %6, label %14, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.unroll.disable"}
