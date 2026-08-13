; lowering_mul_qc_i32.ll — Q+C `mul` (commutative) for the i32 ABI. A
; theta handle times an i32 literal lowers to the HL shape
; `cq_template_mul_i32_hl(handle, classical)`. `mul` is commutative, so the
; literal canonicalizes to the RHS regardless of source side (here it is
; already on the right).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 7)
; CHECK:     call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 6)
;
; CHECK-NOT: call i32 @cq_template_mul_i32(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: mul i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  %c = mul i32 %a, 6
  ret void
}
