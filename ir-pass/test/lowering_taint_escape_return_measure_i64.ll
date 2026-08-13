; lowering_taint_escape_return_measure_i64.ll — ACCEPT boundary probe for the
; non-i32 return guard (test_C_libtooling-udw). The guard keys on OPERAND TAINT,
; not on the function's return width: a `cq_measure` result is a CLASSICAL value
; (measure is the taint SINK — its result is never tainted), so `ret i64 %m` is
; well-typed (the i64 `cqrt_measure_i64` result, not an i32 handle) and must lower
; cleanly. A wrong implementation that declined every non-i32 ret would reject this.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @example(i64 %u0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %m = call i64 @cq_measure_sll(i64 %q)
  ret i64 %m                                       ; classical measure result — well-typed
}

; The forward rotation lowers and the measure returns an i64 classical value:
; CHECK:     call void @cqrt_ry_i64(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK:     %[[M:[a-zA-Z0-9_.]+]] = call i64 @cqrt_measure_i64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     ret i64 %[[M]]
; CHECK-NOT: cq taint escape
