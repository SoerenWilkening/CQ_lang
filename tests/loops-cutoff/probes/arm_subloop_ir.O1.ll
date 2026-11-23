; tests/loops-cutoff probe in IR (cq-6wzf3, CR rule 14 nested K-loops; TinyCC tcc_assemble_internal): two quantum-exit
; sub-loops of a K-loop, each with two exits into one continuation, the second inside the first's exit arm (base: a crash,
; the second's arm took its trip predicate from its header, which only the first unit holds, Cutoff.cpp). Written by hand;
; checked §6 against itself as the C program (cqcheck user).
; (local names stripped: opt -passes=strip)
source_filename = "arm_subloop_ir.O1.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @arm_loop2(i32 noundef %0, double noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  br label %4

4:                                                ; preds = %35, %2
  %5 = phi i32 [ %3, %2 ], [ %31, %35 ]
  %6 = phi i32 [ 0, %2 ], [ %32, %35 ]
  br label %7

7:                                                ; preds = %13, %4
  %8 = phi i32 [ %5, %4 ], [ %10, %13 ]
  %9 = mul i32 %8, 5
  %10 = add i32 %9, 1
  %11 = and i32 %10, 3
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %26, label %13

13:                                               ; preds = %7
  %14 = icmp eq i32 %11, 1
  br i1 %14, label %15, label %7, !llvm.loop !0

15:                                               ; preds = %13
  %16 = and i32 %10, 8
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %30

18:                                               ; preds = %24, %15
  %19 = phi i32 [ %10, %15 ], [ %21, %24 ]
  %20 = mul i32 %19, 3
  %21 = add i32 %20, 1
  %22 = and i32 %21, 3
  %23 = icmp eq i32 %22, 2
  br i1 %23, label %28, label %24

24:                                               ; preds = %18
  %25 = icmp eq i32 %22, 3
  br i1 %25, label %30, label %18, !llvm.loop !1

26:                                               ; preds = %7
  %27 = xor i32 %10, 7
  br label %30

28:                                               ; preds = %18
  %29 = xor i32 %21, 9
  br label %30

30:                                               ; preds = %28, %26, %24, %15
  %31 = phi i32 [ %27, %26 ], [ %10, %15 ], [ %29, %28 ], [ %21, %24 ]
  %32 = add i32 %6, %31
  %33 = and i32 %31, 16
  %34 = icmp eq i32 %33, 0
  br i1 %34, label %35, label %36

35:                                               ; preds = %30
  br label %4, !llvm.loop !2

36:                                               ; preds = %30
  ret i32 %32
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

!0 = distinct !{!0}
!1 = distinct !{!1}
!2 = distinct !{!2}
