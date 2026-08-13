; lowering_fptosi_f80_to_i32.ll — ACCEPT (bd 3c6m.5): the cross-domain
; long-double→signed-int cast `fptosi x86_fp80 to i32` (C `(int)someLongDouble`)
; lowers to `cq_template_fptosi_f80_to_i32(handle)`. Mirror of the int→f80
; direction; the f80 SOURCE is tainted via cq_theta_f80.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f80(
; CHECK:     call i32 @cq_template_fptosi_f80_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fptosi
; CHECK-NOT: cq_theta_f80

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %i = fptosi x86_fp80 %q to i32
  %m = call i32 @cq_measure_si32(i32 %i)
  ret i32 %m
}
