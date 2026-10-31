; EXPECT: handle-in-classical-op
; cq-albd: a zext of a handle that also feeds a classical add is no rule-19 return.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @f(i64 %0, double %1) {
  %3 = call i32 @cqrt_alloc_i64(i64 %0)
  call void @cqrt_ry_i64(i32 %3, double %1)
  %4 = zext i32 %3 to i64
  %5 = add i64 %4, 1
  ret i64 %5
}

declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
