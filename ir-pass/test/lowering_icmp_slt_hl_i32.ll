; lowering_icmp_slt_hl_i32.ll — Q+C data-position compare. A tainted handle
; `slt` a right-hand literal lowers to the HL flag template
; `cq_template_icmp_slt_i32_hl(handle, literal)`, returning an i32 flag
; handle (NOT i1; IMPLEMENTATION §1.2). Width is the OPERAND data width
; (i32), recovered from the classical operand — the handle operand is an
; i32-laundered theta result whose original width is gone.
;
; The flag handle flows straight to a measure: `cq_measure_i1` consumes the
; (now i32) flag and lowers to `cqrt_measure_i1(i32 handle)`, which LAUNDERS
; the cross-type i1→i32 RAUW (the transient mistyped intrinsic call is erased
; by measure lowering). This is the verify-clean WP4 realization of §1.2's
; "the flag handle flows to data/measure" — the `zext` bridge of §1.2's
; worked example is a WP5 cast-lowering concern (the zext is not lowered in
; WP4, so a zext consumer would leave a malformed instruction). The second
; RUN line GUARDS the cross-type RAUW (risk R2; assertions-OFF LLVM-19).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 10)
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; The bare `icmp` instruction must be gone (lowered); guard precisely so the
; substring inside `cq_template_icmp_slt_i32_hl` does not trip the CHECK-NOT.
; CHECK-NOT: = icmp
; CHECK-NOT: _i32_lh
; CHECK-NOT: cq_theta_si32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  ; Tainted handle slt a right-hand literal → `_hl`, predicate unchanged.
  %c = icmp slt i32 %a, 10
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
