; lowering_byref_frexpl_f80.ll — bd g387: by-ref math at the long-double width.
; frexpl(x86_fp80, int*) lowers exactly like frexp, with the fp width naming the
; templates (cq_template_frexp_f80 + cq_template_frexpexp_f80_to_i32 — the f80
; source, i32 exponent). The mantissa is measured as a long double here to avoid
; the f80->int cross-domain cast, which is a SEPARATE deferred gap (bd 3c6m.5),
; orthogonal to by-ref lowering.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f80(x86_fp80
; CHECK:     call i32 @cq_template_frexp_f80(i32 %[[Q:[a-zA-Z0-9_.]+]])
; CHECK:     call i32 @cq_template_frexpexp_f80_to_i32(i32 %[[Q]])
;
; CHECK-NOT: alloca
; CHECK-NOT: load
; CHECK-NOT: call {{.*}}@frexpl(
; CHECK-NOT: @cq_byref_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare i32 @cq_measure_si32(i32)
declare x86_fp80 @frexpl(x86_fp80, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define void @ex() {
entry:
  %e = alloca i32, align 4
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK00000000000000000000, double 5.000000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr %e)
  %m = call x86_fp80 @frexpl(x86_fp80 %q, ptr %e)
  %rm = call x86_fp80 @cq_measure_f80(x86_fp80 %m)
  %ev = load i32, ptr %e, align 4
  %re = call i32 @cq_measure_si32(i32 %ev)
  call void @llvm.lifetime.end.p0(i64 4, ptr %e)
  ret void
}
