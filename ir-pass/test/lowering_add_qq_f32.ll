; lowering_add_qq_f32.ll — Per-width Q+Q fadd for the f32 ABI.
; Two tainted `qfloat_mid_t` handles flow through `fadd float` and must
; lower to `cq_template_fadd_f32(handle, handle)`. The float opcode
; selection uses `Type::isFloatTy()`; the handle is still i32 across
; every ABI width per PRD §"Width unification".

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_f32(float 1.500000e+00)
; CHECK:     call i32 @cqrt_alloc_f32(float 2.500000e+00)
; CHECK:     call i32 @cq_template_fadd_f32(

; CHECK-NOT: call i32 @cq_template_fadd_f32_hl(
; CHECK-NOT: cq_init_f32
; CHECK-NOT: fadd float

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qfloat_mid_t = type { float }

declare %qfloat_mid_t @cq_init_f32(float)

define void @example() {
entry:
  %a_struct = call %qfloat_mid_t @cq_init_f32(float 1.500000e+00)
  %a        = extractvalue %qfloat_mid_t %a_struct, 0

  %b_struct = call %qfloat_mid_t @cq_init_f32(float 2.500000e+00)
  %b        = extractvalue %qfloat_mid_t %b_struct, 0

  %c        = fadd float %a, %b
  ret void
}
