; lowering_fadd_qq_f80.ll — bd 3c6m.4: per-width Q+Q fadd for the long-double
; f80 (x86_fp80) ABI. Two thetas allocate two x86_fp80 handles that flow through
; `fadd x86_fp80` and lower to `cq_template_fadd_f80(handle, handle)`. Proves the
; f80 binary surface (fadd_f80 Q+Q), regenerated from the YAML. This is the
; `long double` arithmetic underlying the `…l` math.h variants (e.g. fmodl→frem).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cqrt_alloc_f80(x86_fp80 %u0)
; CHECK:     call void @cqrt_ry_f80(
; CHECK:     call i32 @cqrt_alloc_f80(x86_fp80 %u1)
; CHECK:     call void @cqrt_ry_f80(
; CHECK:     call i32 @cq_template_fadd_f80(
;
; CHECK-NOT: call i32 @cq_template_fadd_f80_hl(
; CHECK-NOT: cq_theta_f80
; CHECK-NOT: fadd x86_fp80

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)

define void @example(x86_fp80 %u0, x86_fp80 %u1) {
entry:
  %a = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %b = call x86_fp80 @cq_theta_f80(x86_fp80 %u1, double 5.000000e-01)
  %c = fadd x86_fp80 %a, %b
  ret void
}
