target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @f(i32 noundef %0) {
  %2 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %2, double 5.000000e-01)
  call void @cqrt_ry_i32(i32 %2, double -5.000000e-01)
  call void @cqrt_ry_i32(i32 %2, double 0x7FF8000000000000)
  %4 = call i32 @cqrt_measure_i32(i32 %2), !cq.measure !0
  ret i32 %4
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
!0 = !{}
