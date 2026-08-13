; lowering_sub_qq_i32.ll — Q+Q `sub` (non-commutative) for the i32 ABI.
; Two theta handles flow through `sub i32 %a, %b` and lower to the
; symmetric QQ template `cq_template_sub_i32(handle, handle)`. Because
; `sub` is non-commutative the BirthOrder swap is GATED OFF: the source
; operand order (%a then %b) is preserved — the trace must read
; (first-born, second-born), not reordered.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 9)
; CHECK:     call i32 @cqrt_alloc_i32(i32 4)
; CHECK:     call i32 @cq_template_sub_i32(
;
; CHECK-NOT: call i32 @cq_template_sub_i32_hl(
; CHECK-NOT: call i32 @cq_template_sub_i32_lh(
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: sub i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 9, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  %c = sub i32 %a, %b
  ret void
}
