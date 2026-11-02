; tests/loops-cutoff entry probe in IR (cq-b58q, CR rules 14, 9): a K-loop header entered from two blocks outside
; the loop (a quantum branch, no preheader); the carried value's start is the select of its two incomings.
; Hand-written, value names stripped (opt -passes=strip); checked §6 against itself as the C program (cqcheck user).
source_filename = "entries_ir.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @en_quantum(i32 noundef %0, double noundef %1) #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 256
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = mul nsw i32 %3, 3
  br label %9

8:                                                ; preds = %2
  br label %9

9:                                                ; preds = %9, %8, %6
  %10 = phi i32 [ %7, %6 ], [ 7, %8 ], [ %13, %9 ]
  %11 = phi i32 [ 0, %6 ], [ 0, %8 ], [ %14, %9 ]
  %12 = mul nsw i32 %10, 5
  %13 = add nsw i32 %12, %11
  %14 = add nuw nsw i32 %11, 1
  %15 = shl i32 2, %11
  %16 = and i32 %15, %3
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %9

18:                                               ; preds = %9
  %19 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  ret i32 %19
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) #1

declare i32 @cq_measure_si32(i32 noundef) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "no-trapping-math"="true" "target-cpu"="penryn" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "target-cpu"="penryn" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
