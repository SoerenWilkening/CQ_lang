; lowering_uncompute_escape_return.ll — Phase 5 Step 3 escape (PRD §4 bullet 6 /
; IMPLEMENTATION §4.3, decision 2.6). A tainted handle consumed by a `ReturnInst`
; ESCAPES the function — the caller owns it and uncomputes at the caller's own
; last-use point — so Phase 5 emits NO adjoint and NO `cqrt_free`, and (per 2.6)
; NO diagnostic: a return is a RECOGNIZED escape, silently skipped.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; The forward rotation still lowers, but the returned handle is never freed:
; CHECK:     call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 2.500000e-01)
; CHECK-NOT: cqrt_free
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define i32 @slice(i32 %x) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  ret i32 %h
}
