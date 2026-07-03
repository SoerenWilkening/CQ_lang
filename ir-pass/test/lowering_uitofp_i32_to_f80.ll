; lowering_uitofp_i32_to_f80.ll — ACCEPT (bd 3c6m.5): the unsigned cross-domain
; int→long-double cast `uitofp i32 to x86_fp80` lowers to
; `cq_template_uitofp_i32_to_f80(handle)`. uitofp INCLUDES i1 (unlike sitofp);
; i32 is a representative width. Companion to lowering_sitofp_i32_to_f80.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cq_template_uitofp_i32_to_f80(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call x86_fp80 @cqrt_measure_f80(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = uitofp

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_ui32(i32, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @example() {
entry:
  %q = call i32 @cq_theta_ui32(i32 7, double 5.000000e-01)
  %f = uitofp i32 %q to x86_fp80
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %f)
  ret x86_fp80 %m
}
