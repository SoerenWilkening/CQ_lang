; lowering_measure_i16.ll — Width-parametric measure lowering for the
; i16 ABI: `cq_measure_si16` lowers to `cqrt_measure_i16` (returning
; i16). The handle is i32 across every ABI width; only the return type
; varies.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_i16(i16 99)
; CHECK:     call i16 @cqrt_measure_i16(i32
;
; CHECK-NOT: cq_theta_si16
; CHECK-NOT: cq_measure_si16
; CHECK-NOT: cqrt_measure_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i16 @cq_theta_si16(i16, double)
declare i16 @cq_measure_si16(i16)

define i16 @example() {
entry:
  %a = call i16 @cq_theta_si16(i16 99, double 5.000000e-01)
  %m = call i16 @cq_measure_si16(i16 %a)
  ret i16 %m
}
