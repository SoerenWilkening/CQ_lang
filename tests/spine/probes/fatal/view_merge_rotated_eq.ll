; FATAL: cq: unimplemented: spine: a rule 10 merge through a representation change whose constant incoming 0 arrives on an edge where its register may have been changed by
; cq-5ajv: the view phi's constant incoming arrives from the entry, where the cq_theta that minted the
; register already rotated it (its operand was rebound to the pre-rotation copy, so no binding names
; the rail). Was silent wrong output (the constant read as the rotated rail); the i1 form (rot-cry) stops too.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) #1
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
define i32 @w3e() {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0.3) #1
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.0) #1
  br i1 %2, label %3, label %6
3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0.7) #1
  %5 = zext i1 %4 to i8
  br label %6
6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  %8 = icmp eq i8 %7, 0
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2)
  %12 = zext i1 %9 to i32
  %13 = zext i1 %10 to i32
  %14 = zext i1 %11 to i32
  %15 = shl i32 %13, 1
  %16 = shl i32 %14, 2
  %17 = or i32 %12, %15
  %18 = or i32 %17, %16
  ret i32 %18
}
attributes #1 = { nomerge }
