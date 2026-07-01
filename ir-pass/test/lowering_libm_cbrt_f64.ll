; lowering_libm_cbrt_f64.ll — bd 3c6m.2: the DIRECT-libm same-width unary family.
; A tainted DIRECT `@cbrt` call (clang -O1 leaves it a direct libm call, NOT an
; `@llvm.*` intrinsic) lowers to the Class-2 additive producer
; `cq_template_cbrt_f64(handle)` — the SAME shape as the intrinsic `sin`, but
; recognized by EXACT NAME over a declaration-only libc extern (LibmLowering),
; never an Intrinsic::ID. A purely MEASURED cbrt is a live terminal (no `_unc`;
; the dead-lineage twin is proven by the e2e golden slice_libm).
;
; SAFETY: this is a fp-DATA use of `q` (arg-0 of cbrt). The angle fence — a
; tainted cbrt result reaching a rotation arg-1 — declines elsewhere
; (lowering_reject_libm_result_as_angle.ll), never here.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f64(double %u)
; CHECK:     call void @cqrt_ry_f64(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK:     call i32 @cq_template_cbrt_f64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @cqrt_measure_f64(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: call {{.*}}@cbrt(
; CHECK-NOT: cq_template_cbrt_f64_hl(
; CHECK-NOT: cq_template_cbrt_f64_unc

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @cbrt(double)

define double @ex(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @cbrt(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
