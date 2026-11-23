; tests/loops-cutoff probe in IR (cq-qesnu, CR rule 14 case 3 nested in case 3, rules 7, 9; TinyCC _tcc_backtrace): a
; case-3 sub-loop with two exits whose classical exit reaches its continuation only through its tail (arm, then join, which
; the outer trip's classical i == 0 also enters), and a phi of that tail joining a quantum value with a classical one, an
; integer and an address (base: 'a multi-exit sub-loop with no real edge into its continuation', Classical.cpp; a first fix
; took the tail's value where the quantum test is false, x0=8 y=8 x=0xe: 0x15, C 0xb). Written by
; hand after _tcc_backtrace's frame walk; checked §6 against itself as the C program (cqcheck user).
; (local names stripped: opt -passes=strip)
source_filename = "sub_tail_ir.O1.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @bt_tail(i64 noundef %0, i64 noundef %1, double noundef %2) {
  %4 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef %2)
  br label %5

5:                                                ; preds = %32, %3
  %6 = phi i32 [ %33, %32 ], [ 0, %3 ]
  %7 = phi i64 [ %30, %32 ], [ 0, %3 ]
  %8 = icmp eq i32 %6, 0
  br i1 %8, label %26, label %9

9:                                                ; preds = %5
  %10 = icmp ugt i64 %4, 4095
  br i1 %10, label %11, label %29

11:                                               ; preds = %9
  %12 = add nsw i32 %6, -1
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %23, label %17

14:                                               ; preds = %17
  %15 = add nsw i32 %18, -1
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %23, label %17, !llvm.loop !0

17:                                               ; preds = %14, %11
  %18 = phi i32 [ %15, %14 ], [ %12, %11 ]
  %19 = phi i64 [ %21, %14 ], [ %4, %11 ]
  %20 = mul i64 %19, 5
  %21 = add i64 %20, 1
  %22 = icmp ugt i64 %21, 4095
  br i1 %22, label %14, label %29, !llvm.loop !0

23:                                               ; preds = %14, %11
  %24 = phi i64 [ %4, %11 ], [ %21, %14 ]
  %25 = add i64 %24, 8
  br label %26

26:                                               ; preds = %23, %5
  %27 = phi i64 [ %25, %23 ], [ %1, %5 ]
  %28 = xor i64 %27, 3
  br label %29

29:                                               ; preds = %26, %17, %9
  %30 = phi i64 [ %7, %9 ], [ %28, %26 ], [ %7, %17 ]
  %31 = phi i1 [ true, %9 ], [ false, %26 ], [ true, %17 ]
  br i1 %31, label %35, label %32

32:                                               ; preds = %29
  %33 = add nuw nsw i32 %6, 1
  %34 = icmp eq i32 %33, 8
  br i1 %34, label %35, label %5, !llvm.loop !1

35:                                               ; preds = %32, %29
  %36 = phi i64 [ %30, %29 ], [ %30, %32 ]
  ret i64 %36
}

define i64 @bt_tail_ptr(i64 noundef %0, ptr noundef %1, double noundef %2) {
  %4 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef %2)
  br label %5

5:                                                ; preds = %33, %3
  %6 = phi i32 [ %34, %33 ], [ 0, %3 ]
  %7 = phi i64 [ %31, %33 ], [ 0, %3 ]
  %8 = icmp eq i32 %6, 0
  br i1 %8, label %26, label %9

9:                                                ; preds = %5
  %10 = icmp ugt i64 %4, 4095
  br i1 %10, label %11, label %30

11:                                               ; preds = %9
  %12 = add nsw i32 %6, -1
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %23, label %17

14:                                               ; preds = %17
  %15 = add nsw i32 %18, -1
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %23, label %17, !llvm.loop !0

17:                                               ; preds = %14, %11
  %18 = phi i32 [ %15, %14 ], [ %12, %11 ]
  %19 = phi i64 [ %21, %14 ], [ %4, %11 ]
  %20 = mul i64 %19, 5
  %21 = add i64 %20, 1
  %22 = icmp ugt i64 %21, 4095
  br i1 %22, label %14, label %30, !llvm.loop !0

23:                                               ; preds = %14, %11
  %24 = phi i64 [ %4, %11 ], [ %21, %14 ]
  %25 = inttoptr i64 %24 to ptr
  br label %26

26:                                               ; preds = %23, %5
  %27 = phi ptr [ %25, %23 ], [ %1, %5 ]
  %28 = icmp eq ptr %27, %1   ; the address itself differs between runs: only whether it is y's
  %ptr.is.y = zext i1 %28 to i64
  %29 = xor i64 %ptr.is.y, 3
  br label %30

30:                                               ; preds = %26, %17, %9
  %31 = phi i64 [ %7, %9 ], [ %29, %26 ], [ %7, %17 ]
  %32 = phi i1 [ true, %9 ], [ false, %26 ], [ true, %17 ]
  br i1 %32, label %36, label %33

33:                                               ; preds = %30
  %34 = add nuw nsw i32 %6, 1
  %35 = icmp eq i32 %34, 8
  br i1 %35, label %36, label %5, !llvm.loop !1

36:                                               ; preds = %33, %30
  %37 = phi i64 [ %31, %30 ], [ %31, %33 ]
  ret i64 %37
}

declare i64 @cq_theta_sl(i64 noundef, double noundef)

!0 = distinct !{!0}
!1 = distinct !{!1}
