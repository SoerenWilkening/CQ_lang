; lowering_byref_inline_multi_use.ll — bd g7ip: a VISIBLE by-ref producer with a
; DEEPER pure body `*out = (v*3)+1` read back TWICE. ByRefInline inlines the
; producer's operand cone ONCE (memoized), RAUWing BOTH read-back loads to the
; same inlined handle — so the caller's `r1 + r2` becomes a q+q add of that single
; producer with itself (== 2·(3v+1)), the faithful meaning of the source. Proves
; multi-load fan-out and multi-op cone cloning (flags preserved).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

define i32 @demo() {
  %cell = alloca i32, align 4
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  call void @mysplit(i32 %q, ptr %cell)
  %r1 = load i32, ptr %cell, align 4
  %r2 = load i32, ptr %cell, align 4
  %s = add i32 %r1, %r2
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

; CHECK-NOT:   @mysplit
; CHECK-NOT:   alloca
; CHECK-NOT:   load
; CHECK-LABEL: define i32 @demo()
; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:       %[[MUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:       %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[MUL]], i32 1)
; CHECK:       %[[SUM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[ADD]], i32 %[[ADD]])
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[SUM]])

define internal void @mysplit(i32 %v, ptr %out) {
  %a = mul nsw i32 %v, 3
  %b = add nsw i32 %a, 1
  store i32 %b, ptr %out, align 4
  ret void
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
