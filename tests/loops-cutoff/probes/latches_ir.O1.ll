; tests/loops-cutoff latch probes in IR (cq-b58q, CR rule 14 "`continue` ... same chain"): K-loops with two latches,
; the form -O1 leaves when SimplifyCFG folds the latch merge away. Hand-written; each entry is checked §6 against
; itself as the C program (cqcheck user).
; Value names stripped (opt -passes=strip): the checker's drivers expect clang's numbering.
source_filename = "latches_ir.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ml2_both(i32 noundef %0, double noundef %1) #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %16, %11, %2
  %5 = phi i32 [ 1, %2 ], [ %13, %11 ], [ %18, %16 ]
  %6 = phi i32 [ 0, %2 ], [ %7, %11 ], [ %7, %16 ]
  %7 = add nuw nsw i32 %6, 1
  %8 = shl nuw i32 16, %6
  %9 = and i32 %8, %3
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %16, label %11

11:                                               ; preds = %4
  %12 = mul nsw i32 %5, 5
  %13 = add nsw i32 %12, 1
  %14 = and i32 %13, 64
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %4, label %22

16:                                               ; preds = %4
  %17 = mul nsw i32 %5, 3
  %18 = add nsw i32 %7, %17
  %19 = shl nuw i32 2, %6
  %20 = and i32 %19, %3
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %22, label %4

22:                                               ; preds = %16, %11
  %23 = phi i32 [ %13, %11 ], [ %18, %16 ]
  %24 = tail call i32 @cq_measure_si32(i32 noundef %23) #3
  ret i32 %24
}

; Function Attrs: nounwind ssp uwtable
define i32 @ml2_one(i32 noundef %0, double noundef %1) #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  br label %4

4:                                                ; preds = %14, %11, %2
  %5 = phi i32 [ 1, %2 ], [ %13, %11 ], [ %16, %14 ]
  %6 = phi i32 [ 0, %2 ], [ %7, %11 ], [ %7, %14 ]
  %7 = add nuw nsw i32 %6, 1
  %8 = shl nuw i32 16, %6
  %9 = and i32 %8, %3
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %14, label %11

11:                                               ; preds = %4
  %12 = mul nsw i32 %5, 5
  %13 = add nsw i32 %12, 1
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  br label %4

14:                                               ; preds = %4
  %15 = mul nsw i32 %5, 3
  %16 = add nsw i32 %7, %15
  %17 = shl nuw i32 2, %6
  %18 = and i32 %17, %3
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %4

20:                                               ; preds = %14
  %21 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  ret i32 %21
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) #1

declare i32 @cq_measure_si32(i32 noundef) #1

declare void @cq_phi(double noundef) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "no-trapping-math"="true" "target-cpu"="penryn" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "target-cpu"="penryn" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
