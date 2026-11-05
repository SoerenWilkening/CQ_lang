; cq-j5mq: classically bounded loops with several classical exit edges into one exit block (shapes of tests/spine/loop_exit_join.cpp).
; ModuleID = '/tmp/ee.bc'
source_filename = "exit_edges.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)

declare i32 @cq_measure_si32(i32)

declare void @cq_phi(double)

define i32 @two_exits(i32 %0, double %1, i32 %2, i32 %3, double %4) {
  %6 = call i32 @cq_theta_si32(i32 %0, double %1)
  %7 = icmp sgt i32 %2, 0
  br i1 %7, label %12, label %8

8:                                                ; preds = %18, %16, %5
  %9 = phi i32 [ 0, %5 ], [ %19, %18 ], [ 100, %16 ]
  %10 = call i32 @cq_measure_si32(i32 %6)
  %11 = add i32 %10, %9
  ret i32 %11

12:                                               ; preds = %18, %5
  %13 = phi i32 [ %19, %18 ], [ 0, %5 ]
  %14 = icmp eq i32 %6, %13
  br i1 %14, label %15, label %16

15:                                               ; preds = %12
  call void @cq_phi(double %4)
  br label %16

16:                                               ; preds = %15, %12
  %17 = icmp eq i32 %13, %3
  br i1 %17, label %8, label %18

18:                                               ; preds = %16
  %19 = add nuw nsw i32 %13, 1
  %20 = icmp eq i32 %19, %2
  br i1 %20, label %8, label %12
}

define i32 @arm_exits(i32 %0, double %1, i32 %2, i32 %3, double %4) {
  %6 = call i32 @cq_theta_si32(i32 %0, double %1)
  %7 = icmp eq i32 %6, 3
  br i1 %7, label %9, label %8

8:                                                ; preds = %5
  br label %18

9:                                                ; preds = %15, %5
  %10 = phi i32 [ %16, %15 ], [ 0, %5 ]
  %11 = icmp eq i32 %6, %10
  br i1 %11, label %12, label %13

12:                                               ; preds = %9
  call void @cq_phi(double %4)
  br label %13

13:                                               ; preds = %12, %9
  %14 = icmp eq i32 %10, %3
  br i1 %14, label %18, label %15

15:                                               ; preds = %13
  %16 = add nuw nsw i32 %10, 1
  %17 = icmp eq i32 %16, %2
  br i1 %17, label %18, label %9

18:                                               ; preds = %15, %13, %8
  %19 = phi i32 [ 5, %8 ], [ %16, %15 ], [ 100, %13 ]
  %20 = call i32 @cq_measure_si32(i32 %6)
  %21 = add i32 %20, %19
  ret i32 %21
}

define i32 @nested_exits(i32 %0, double %1, i32 %2, i32 %3, double %4) {
  %6 = call i32 @cq_theta_si32(i32 %0, double %1)
  %7 = icmp sgt i32 %2, 0
  br i1 %7, label %8, label %20

8:                                                ; preds = %17, %5
  %9 = phi i32 [ %18, %17 ], [ 0, %5 ]
  br label %10

10:                                               ; preds = %16, %8
  %11 = phi i32 [ %13, %16 ], [ 0, %8 ]
  %12 = icmp eq i32 %6, %11
  call void @cq_phi(double %4)
  %13 = add i32 %11, 1
  %14 = icmp eq i32 %13, %3
  %15 = icmp eq i32 %13, %9
  br i1 %15, label %20, label %16

16:                                               ; preds = %10
  br i1 %14, label %17, label %10

17:                                               ; preds = %16
  %18 = add nuw nsw i32 %9, 1
  %19 = icmp eq i32 %18, %2
  br i1 %19, label %20, label %8

20:                                               ; preds = %17, %10, %5
  %21 = phi i32 [ 0, %5 ], [ %9, %17 ], [ %9, %10 ]
  %22 = call i32 @cq_measure_si32(i32 %6)
  %23 = add i32 %22, %21
  ret i32 %23
}
