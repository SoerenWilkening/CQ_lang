; lowering_reject_decl_prototype_phi.ll — DECLINE: user-declared
; @cq_phi_si32 with the WRONG prototype (float angle; CQ.h declares
; `int cq_phi_si32(int, double)`).
;
; Without the collection-time prototype guard (test_C_libtooling-pn2) the
; tainted-operand path emits `call void @cqrt_rz_i32(i32 %h, float ...)`
; against the (i32, double) runtime signature — loud (Broken module, opt
; exit 134) but not the pass's source-located DiagnosticInfoUnsupported
; dialect. The theta here is CORRECT and is accepted by the validator; only
; the malformed cq_phi_si32 declaration declines.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, float)           ; WRONG: must be i32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %p = call i32 @cq_phi_si32(i32 %q, float 2.500000e-01)
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported declared prototype for cq_phi_si32
