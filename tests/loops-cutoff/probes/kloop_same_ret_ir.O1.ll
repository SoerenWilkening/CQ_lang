; tests/loops-cutoff probe in IR (cq-xuaam, CR rules 9 and 14; TinyCC decl, reduced): a quantum-exit loop of f left by two
; exits whose returns are both 0, so taint holds the merged return classical; g calls f with every argument quantum (base:
; cq-verify handle-in-classical-op in f's clones, the unit bound that phi to a rail of its exits, Cutoff.cpp). Written by
; hand; checked §6 against itself as the C program (cqcheck user).
; (local names stripped: opt -passes=strip)
source_filename = "kloop_same_ret_ir.O1.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i8 @cq_theta_ui8(i8, double)

declare i32 @cq_theta_si32(i32, double)

; Function Attrs: noinline
define internal i32 @f(i8 %0, i32 %1, i32 %2, i32 %3) #0 {
  %5 = trunc i8 %0 to i1
  %6 = lshr i8 %0, 1
  %7 = trunc i8 %6 to i1
  %8 = zext i8 %0 to i32
  %9 = icmp eq i32 %1, 0
  br label %10

10:                                               ; preds = %19, %16, %12, %4
  br i1 %5, label %11, label %19

11:                                               ; preds = %10
  br i1 %9, label %20, label %12

12:                                               ; preds = %11
  %13 = add i32 %8, %3
  %14 = icmp eq i32 %2, 0
  %15 = and i1 %7, %14
  br i1 %15, label %10, label %16

16:                                               ; preds = %12
  %17 = icmp eq i32 %13, 0
  br i1 %17, label %10, label %18

18:                                               ; preds = %16
  ret i32 0

19:                                               ; preds = %10
  br i1 %9, label %20, label %10

20:                                               ; preds = %19, %11
  ret i32 0
}

define i32 @g(i8 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i8 @cq_theta_ui8(i8 %0, double 1.000000e+00)
  %6 = call i32 @cq_theta_si32(i32 %1, double 1.000000e+00)
  %7 = call i32 @cq_theta_si32(i32 %2, double 1.000000e+00)
  %8 = call i32 @cq_theta_si32(i32 %3, double 1.000000e+00)
  %9 = call i32 @f(i8 %5, i32 %6, i32 %7, i32 %8)
  ret i32 %9
}

attributes #0 = { noinline }
