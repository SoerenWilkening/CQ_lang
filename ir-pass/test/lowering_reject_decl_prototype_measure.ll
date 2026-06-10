; lowering_reject_decl_prototype_measure.ll — DECLINE: user-declared
; @cq_measure_f64 with the WRONG prototype (returns i32; CQ.h declares
; `double cq_measure_f64(double)`).
;
; The 42-name front-end surface is resolved BY NAME ONLY at collection time
; (TaintPropagation::resolveSources via WidthDispatch); nothing downstream
; re-checks the declared type. Without the collection-time prototype guard,
; MeasureLowering mints `call double @cqrt_measure_f64(i32 %h)` and RAUWs the
; i32-typed original measure result to it — loud (final verifier: Broken
; module, opt exit 134) but NOT the pass's source-located
; DiagnosticInfoUnsupported dialect (test_C_libtooling-pn2, found during the
; 5j5 review 2026-06-10; pre-existing, straight-line, no control flow).
;
; The guard validates each resolved cq_theta_*/cq_phi_*/cq_measure_* decl
; against its canonical CQ.h prototype at collection time and declines loudly
; on mismatch, lowering nothing.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_f64(double)            ; WRONG: must be double(double)

define i32 @example() {
entry:
  %a = call double @cq_theta_f64(double 2.718280e+00, double 5.000000e-01)
  %m = call i32 @cq_measure_f64(double %a)
  ret i32 %m
}

; CHECK: error{{.*}}cq measure lowering: unsupported declared prototype for cq_measure_f64
