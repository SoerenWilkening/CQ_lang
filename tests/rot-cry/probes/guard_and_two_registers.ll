; cq-a63l (CR rule 10, cq-oa67): see guard_and_two_registers.c (clang 19.1.7 -O1). A prep under a classical guard is
; merged outside it by rule 9 over the handles; merges naming two registers likewise.
; CHECK guarded_prep: call i32 @cqrt_alloc_i32(i32 5)
; CHECK two_regs: call i32 @cq_template_select_
source_filename = "guard.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @guarded_prep(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 9.000000e-01) #2
  %5 = icmp sgt i32 %1, 0
  %6 = icmp sgt i32 %4, %2
  %7 = select i1 %5, i1 %6, i1 false
  br i1 %7, label %8, label %10

8:                                                ; preds = %3
  %9 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 0x3FE6666666666666) #2
  br label %10

10:                                               ; preds = %8, %3
  %11 = phi i32 [ %9, %8 ], [ 3, %3 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %13 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %14 = mul nsw i32 %13, 10
  %15 = add nsw i32 %14, %12
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @two_regs(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 9.000000e-01) #2
  %5 = icmp sgt i32 %4, %1
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  %7 = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 3.000000e-01) #2
  br label %8

8:                                                ; preds = %6, %3
  %9 = phi i32 [ %7, %6 ], [ 1, %3 ]
  %10 = icmp slt i32 %4, %2
  br i1 %10, label %11, label %13

11:                                               ; preds = %8
  %12 = tail call i32 @cq_theta_si32(i32 noundef 4, double noundef 5.000000e-01) #2
  br label %13

13:                                               ; preds = %11, %8
  %14 = phi i32 [ %12, %11 ], [ %9, %8 ]
  %15 = add nsw i32 %2, %1
  %16 = icmp eq i32 %4, %15
  br i1 %16, label %17, label %19

17:                                               ; preds = %13
  %18 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2
  br label %19

19:                                               ; preds = %17, %13
  %20 = phi i32 [ %18, %17 ], [ %9, %13 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %22 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %23 = mul nsw i32 %22, 10
  %24 = add nsw i32 %23, %21
  %25 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %26 = mul nsw i32 %25, 100
  %27 = add nsw i32 %24, %26
  ret i32 %27
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
