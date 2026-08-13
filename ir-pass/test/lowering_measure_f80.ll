; lowering_measure_f80.ll — bd 3c6m.4: measurement at the long-double f80 ABI.
; A tainted x86_fp80 theta handle reaches `cq_measure_f80` and lowers to
; `cqrt_measure_f80(i32 handle)` → x86_fp80. `long double` IS a clean source/sink
; on x86-64 (unlike the deferred i128, whose C ABI shreds to {i64,i64}): the
; runtime returns x86_fp80 (trace-only 0). Proves cqrt_alloc_f80 + cqrt_measure_f80.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f80(x86_fp80 %u0)
; CHECK:     call x86_fp80 @cqrt_measure_f80(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: cq_theta_f80
; CHECK-NOT: cq_measure_f80(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @example(x86_fp80 %u0) {
entry:
  %a = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %a)
  ret x86_fp80 %m
}
