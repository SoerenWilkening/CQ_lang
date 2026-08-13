; lowering_libm_lrintl_f80.ll — bd 3c6m.4: the CROSS-WIDTH `…l` path. clang -O1
; lowers `lrintl(long double) → long` to `@llvm.lrint.i64.f80` (fp → int of a
; DIFFERENT width). IntrinsicLowering's cross-width libm branch now admits the
; f80 source and reuses the CAST naming grammar → `cq_template_lrint_f80_to_i64`
; (a1 shape; handle is i32 on both sides). Result is i64, so the sink is the i64
; measure. Covers lrintl/llrintl/lroundl/llroundl.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f80(x86_fp80 %u0)
; CHECK:     call i32 @cq_template_lrint_f80_to_i64(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i64 @cqrt_measure_i64(
;
; CHECK-NOT: llvm.lrint

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)
declare i64 @llvm.lrint.i64.f80(x86_fp80)

define i64 @example(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %r = call i64 @llvm.lrint.i64.f80(x86_fp80 %q)
  %m = call i64 @cq_measure_sll(i64 %r)
  ret i64 %m
}
