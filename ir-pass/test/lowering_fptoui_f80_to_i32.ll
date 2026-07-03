; lowering_fptoui_f80_to_i32.ll — ACCEPT (bd 3c6m.5): the unsigned cross-domain
; long-double→int cast `fptoui x86_fp80 to i32` lowers to
; `cq_template_fptoui_f80_to_i32(handle)`. fptoui INCLUDES i1 target (unlike
; fptosi); i32 is a representative width.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cq_template_fptoui_f80_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: = fptoui

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i32 @cq_measure_ui32(i32)

define i32 @example(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %i = fptoui x86_fp80 %q to i32
  %m = call i32 @cq_measure_ui32(i32 %i)
  ret i32 %m
}
