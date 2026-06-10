; lowering_reject_decl_prototype_theta.ll — DECLINE: user-declared
; @cq_theta_si32 with the WRONG prototype (missing the double angle
; parameter; CQ.h declares `int cq_theta_si32(int, double)`).
;
; The missing-angle shape is the nastiest of the wrong-prototype family
; (test_C_libtooling-pn2): RotationLowering reads `getArgOperand(1)` on a
; 1-arg call — out of range on a no-assert LLVM, so the CALLEE OPERAND leaks
; into the emitted cqrt_ry as its "angle" (verified 2026-06-10:
; `call void @cqrt_ry_i32(i32 %h, ptr @cq_theta_si32)` → Broken module,
; opt exit 134). The collection-time prototype guard declines loudly first,
; in the pass's source-located DiagnosticInfoUnsupported dialect.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32)                ; WRONG: must be i32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported declared prototype for cq_theta_si32
