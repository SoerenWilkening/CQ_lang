; lowering_add_qc_f64.ll — Per-width Q+C fadd for the f64 ABI (M16).
; One tainted `qdouble_mid_t` handle, one double literal flow through
; `fadd double` and must lower to
; `cq_template_add_f64_hl(handle, classical)`.
;
; Spec: phases/phase2/PLAN.md §4.16.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_f64(double 1.414210e+00)
; CHECK:     call i32 @cq_template_add_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 6.250000e+00)

; CHECK-NOT: call i32 @cq_template_add_f64(i32 %{{.*}}, i32 %
; CHECK-NOT: cq_init_f64
; CHECK-NOT: fadd double

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qdouble_mid_t = type { double }

declare %qdouble_mid_t @cq_init_f64(double)

define void @example() {
entry:
  %a_struct = call %qdouble_mid_t @cq_init_f64(double 1.414210e+00)
  %a        = extractvalue %qdouble_mid_t %a_struct, 0

  %c        = fadd double %a, 6.250000e+00
  ret void
}
