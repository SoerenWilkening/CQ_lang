; lowering_libm_cross_width.ll — bd 3c6m.2: the CROSS-WIDTH unary family (fp →
; INTEGER of a different width). Two recognition paths, ONE template surface:
;   * ilogb is a DIRECT libm call (LibmLowering) — f64 → i32.
;   * lrint is an `@llvm.lrint.i64.f<W>` INTRINSIC (IntrinsicLowering) — f64 → i64.
; Both reuse the CAST naming grammar `cq_template_<op>_<from>_to_<to>` (a1/ua1
; shapes — the handle is i32 on BOTH sides, so the signature is byte-identical to
; a same-width unary; only the NAME preserves both widths for a future backend).
; The measured result is a live terminal (no `_unc` here). The `from` width is
; read from the callee/intrinsic's declared param type — laundering-proof.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; ilogb: f64 → i32 (direct libm); lrint: f64 → i64 (intrinsic). Both templates
; are emitted, then both measured through the i32 handle (source-order schedule):
; CHECK:     call i32 @cq_template_ilogb_f64_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_lrint_f64_to_i64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i64 @cqrt_measure_i64(i32 %{{[a-zA-Z0-9_.]+}})
;
; The original calls are gone (an unused libm/intrinsic DECLARATION may linger —
; the pass replaces calls, not decls — so target the CALL form specifically):
; CHECK-NOT: call {{.*}}@ilogb(
; CHECK-NOT: call {{.*}}@llvm.lrint
; CHECK-NOT: cq_template_ilogb_i32
; CHECK-NOT: cq_template_lrint_i64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)
declare i32 @ilogb(double)
declare i64 @llvm.lrint.i64.f64(double)

define i64 @ex(double %u, double %v) {
entry:
  %a = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %b = call double @cq_theta_f64(double %v, double 6.000000e-01)
  %e = call i32 @ilogb(double %a)
  %l = call i64 @llvm.lrint.i64.f64(double %b)
  %me = call i32 @cq_measure_si32(i32 %e)
  %ml = call i64 @cq_measure_sl(i64 %l)
  %mez = zext i32 %me to i64
  %sum = add i64 %mez, %ml
  ret i64 %sum
}
