; EXPECT: kept-rail-released
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = global i32 0

define void @f(i32 %0) {
  %2 = call i32 @__cq_mem()
  %3 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 ptrtoint (ptr @g to i64), i32 %3)
  call void @cqrt_free(i32 %3)
  ret void
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_free(i32)
