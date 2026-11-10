; EXPECT: cc-mismatch
; cq-5yuk9 (CR §1.4): the twin is `internal fastcc` as its forward, its call has the C calling convention.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @e(i32 %0) {
  %2 = call i32 @cqrt_alloc_i32(i32 %0)
  %3 = call fastcc i32 @__cq_q_h_1(i32 %2)
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %3, i32 %4)
  call void @__cq_q_h_1_unc(i32 %3, i32 %2)
  call void @cqrt_free(i32 %3)
  call void @cqrt_free(i32 %2)
  %5 = call i32 @cqrt_measure_i32(i32 %4), !cq.measure !0
  ret i32 %5
}

define internal fastcc i32 @__cq_q_h_1(i32 %0) unnamed_addr {
  %2 = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  ret i32 %2
}

define internal fastcc void @__cq_q_h_1_unc(i32 %out, i32 %0) unnamed_addr {
  call void @cq_template_add_i32_hl_unc(i32 %out, i32 %0, i32 3)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

!0 = !{}
