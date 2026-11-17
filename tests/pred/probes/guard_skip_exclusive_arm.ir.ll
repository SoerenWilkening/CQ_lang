; cq-pfpy (rules 8, 9): a classical guard's skip edge goes to the first later block whose classical projection
; meets the facts of the paths it turns away. Reduced by llvm-reduce from SoftFloat's softfloat_roundPackToExtF80
; (its quantum load made a cq_theta, its bus load a cq_phi). %13's classical edge into the return %15 falls
; through to %16, whose guard (!%14) turns the returned paths away. The skip went to %21 (its classical factor
; is true: a disjunction), so those paths ran %22's phase and asked for its flag (!%2 & (!%3 | !%19)) where %19,
; minted in %18, does not reach: an internal error at pred's joinAbove. The skip now goes to the return.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i8 @cq_theta_ui8(i8, double)

declare void @cq_phi(double)

define { i64, i16 } @f(i8 %0, i1 %1, i1 %2, i1 %3, i1 %4) {
  %6 = call i8 @cq_theta_ui8(i8 0, double 1.0)
  %7 = icmp eq i8 %6, 0
  switch i8 %0, label %9 [
    i8 1, label %8
    i8 0, label %8
  ]

8:
  ret { i64, i16 } zeroinitializer

9:
  br i1 %7, label %10, label %11

10:
  br label %11

11:
  %12 = phi i8 [ 1, %10 ], [ 0, %9 ]
  br i1 %1, label %13, label %21

13:
  %14 = icmp slt i32 0, 0
  br i1 %14, label %15, label %16

15:
  ret { i64, i16 } zeroinitializer

16:
  br i1 %2, label %20, label %17

17:
  br i1 %3, label %18, label %21

18:
  %19 = trunc i8 %12 to i1
  br i1 %19, label %20, label %21

20:
  ret { i64, i16 } zeroinitializer

21:
  br i1 %4, label %23, label %22

22:
  call void @cq_phi(double 3.000000e-01)
  ret { i64, i16 } zeroinitializer

23:
  ret { i64, i16 } zeroinitializer
}
