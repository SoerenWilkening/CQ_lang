; Hand-crafted post-lowering IR for the Phase 4 region-handling test.
;
; Two cqrt_template_add_i32 calls: one OUTSIDE any cq_when_* region (should
; be left alone), one INSIDE a cq_when_begin/end pair (should be substituted
; for the _controlled variant taking %h_cond as the extra first arg).
;
; cq_when_begin is declared taking i32 directly — the qint_mid_t→handle
; resolution at cq_when_begin sites is a cq-lowering extension out of scope
; for this region-mechanism validation.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32  @cqrt_alloc_classical_i32(i32)
declare i32  @cqrt_alloc_i32()
declare void @cqrt_template_add_i32(i32, i32, i32)
declare i64  @cqrt_measure(i32)
declare void @cq_when_begin(i32)
declare void @cq_when_end()

define i64 @example_when() {
entry:
  %h_cond = call i32 @cqrt_alloc_classical_i32(i32 1)
  %h_a    = call i32 @cqrt_alloc_classical_i32(i32 3)
  %h_b    = call i32 @cqrt_alloc_classical_i32(i32 5)
  %h_pre  = call i32 @cqrt_alloc_i32()
  %h_sum  = call i32 @cqrt_alloc_i32()

  ; Outside any region — must NOT be substituted.
  call void @cqrt_template_add_i32(i32 %h_a, i32 %h_b, i32 %h_pre)

  ; Inside cq_when region — MUST be substituted with the _controlled variant
  ; taking %h_cond as the first arg.
  call void @cq_when_begin(i32 %h_cond)
  call void @cqrt_template_add_i32(i32 %h_a, i32 %h_b, i32 %h_sum)
  call void @cq_when_end()

  %m = call i64 @cqrt_measure(i32 %h_sum)
  ret i64 %m
}
