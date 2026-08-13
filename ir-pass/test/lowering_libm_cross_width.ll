; lowering_libm_cross_width.ll — p119: the CROSS-WIDTH rounding SURVIVORS (fp →
; INTEGER of a different width). lrint/llrint are `@llvm.lrint.i64.f<W>` /
; `@llvm.llrint.i64.f<W>` INTRINSICS (IntrinsicLowering) that codegen to the
; HARDWARE cvtsd2si — round-to-nearest-even — so they are kept survivors. They
; reuse the CAST naming grammar `cq_template_<op>_<from>_to_<to>` (a1/ua1 shapes —
; the handle is i32 on BOTH sides, so the signature is byte-identical to a
; same-width unary; only the NAME preserves both widths for a future backend).
; (ilogb was a DIRECT libm call — removed under p119 as a library function; and
; lround/llround, round-half-away, are libcalls — also removed.)
; The measured result is a live terminal (no `_unc` here). The `from` width is
; read from the intrinsic's declared param type — laundering-proof.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; lrint: f64 → i64; llrint: f64 → i64. Both templates are emitted, then both
; measured through the i32 handle (source-order schedule):
; CHECK:     call i32 @cq_template_lrint_f64_to_i64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_llrint_f64_to_i64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i64 @cqrt_measure_i64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i64 @cqrt_measure_i64(i32 %{{[a-zA-Z0-9_.]+}})
;
; The original intrinsic calls are gone (an unused DECLARATION may linger — the
; pass replaces calls, not decls — so target the CALL form specifically):
; CHECK-NOT: call {{.*}}@llvm.lrint
; CHECK-NOT: call {{.*}}@llvm.llrint
; CHECK-NOT: cq_template_lrint_i64
; CHECK-NOT: cq_template_llrint_i64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i64 @cq_measure_sl(i64)
declare i64 @llvm.lrint.i64.f64(double)
declare i64 @llvm.llrint.i64.f64(double)

define i64 @ex(double %u, double %v) {
entry:
  %a = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %b = call double @cq_theta_f64(double %v, double 6.000000e-01)
  %e = call i64 @llvm.lrint.i64.f64(double %a)
  %l = call i64 @llvm.llrint.i64.f64(double %b)
  %me = call i64 @cq_measure_sl(i64 %e)
  %ml = call i64 @cq_measure_sl(i64 %l)
  %sum = add i64 %me, %ml
  ret i64 %sum
}
