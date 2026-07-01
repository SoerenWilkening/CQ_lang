; lowering_reject_byref_inline_post_store.ll — bd g7ip MISS-SAFETY probe
; (caller-side). The out-cell is written AGAIN by the caller AFTER the by-ref call
; (`store 99, %cell`) before the read-back load — so the load reads 99, NOT the
; producer value. RAUWing that load to the inlined producer would be a silent
; miscompile. ByRefInline's caller-cell proof (the g387 `analyzeCell` discipline)
; requires every cell store to DOMINATE the call, so it SKIPS this shape; it falls
; through to the EXISTING loud specializer decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

define i32 @demo() {
  %cell = alloca i32, align 4
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  call void @mysplit(i32 %q, ptr %cell)
  store i32 99, ptr %cell, align 4
  %r = load i32, ptr %cell, align 4
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

define internal void @mysplit(i32 %v, ptr %out) {
  %r = add nsw i32 %v, 7
  store i32 %r, ptr %out, align 4
  ret void
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
