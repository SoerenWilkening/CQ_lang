; lowering_add_qq_f64.ll — Per-width Q+Q fadd for the f64 ABI (M16).
; Two tainted `qdouble_mid_t` handles flow through `fadd double` and
; must lower to `cq_template_fadd_f64(handle, handle)`. The float opcode
; selection uses `Type::isDoubleTy()`.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_f64(double 2.718280e+00)
; CHECK:     call i32 @cqrt_alloc_f64(double 3.141590e+00)
; CHECK:     call i32 @cq_template_fadd_f64(

; CHECK-NOT: call i32 @cq_template_fadd_f64_hl(
; CHECK-NOT: cq_init_f64
; CHECK-NOT: fadd double

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qdouble_mid_t = type { double }

declare %qdouble_mid_t @cq_init_f64(double)

define void @example() {
entry:
  %a_struct = call %qdouble_mid_t @cq_init_f64(double 2.718280e+00)
  %a        = extractvalue %qdouble_mid_t %a_struct, 0

  %b_struct = call %qdouble_mid_t @cq_init_f64(double 3.141590e+00)
  %b        = extractvalue %qdouble_mid_t %b_struct, 0

  %c        = fadd double %a, %b
  ret void
}
