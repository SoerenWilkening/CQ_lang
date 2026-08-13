; lowering_icmp_qq_arith_derived.ll — Phase 7.1 Increment A derived-operand
; positive (ARITH source of HandleWidth). One QQ-compare operand is the result
; of a tainted `add i32` (a Q+C `_hl` add), whose result handle records
; `HandleWidth = i32` (the add's own ABI width, recorded by ArithLowering's
; extended `promote`). It is compared `slt` against a second i32 theta handle
; (records i32). Both recovered widths AGREE (i32) → the bare-QQ
; `cq_template_icmp_slt_i32(i32, i32)` lowers. Proves the ArithLowering
; HandleWidth record feeds the Increment-A reader.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK:     call i32 @cq_template_icmp_slt_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; The add result handle (logical i32) drives a QQ — not an HL — compare.
; CHECK-NOT: = icmp slt
; CHECK-NOT: cq_template_icmp_slt_i32_hl(
; CHECK-NOT: cq_template_icmp_slt_i32_lh(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 9, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  ; `%d` is a derived tainted handle (add_hl); ArithLowering records its
  ; HandleWidth = i32, so the QQ compare against `%b` recovers i32 on both.
  %d = add i32 %a, 7
  %c = icmp slt i32 %d, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
