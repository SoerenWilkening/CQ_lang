; lowering_taint_mixed_suffix.ll — Width-parametric taint sources (M14).
; Two distinct front-end suffixes (`si32` and `ui32`) coexist in the
; same module. Each init must be picked up as a separate taint source;
; the resulting handles flow through a single tainted `add i32` that
; lowers to Q+Q. Confirms M14's enumeration walks the full suffix list
; rather than matching a single fixed name.
;
; Pre-M15 layering: only i32-ABI suffixes (`si32`, `ui32`) are safe
; downstream. Non-i32-ABI suffixes lift with M15.
;
; Spec: phases/phase2/PLAN.md §4.14.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; CHECK:     call i32 @cqrt_alloc_i32(i32 11)
; CHECK:     call i32 @cqrt_alloc_i32(i32 13)
; CHECK:     call i32 @cq_template_add_i32(
; CHECK:     call i32 @cqrt_measure_i32(

; CHECK-NOT: cq_init_si32
; CHECK-NOT: cq_init_ui32
; CHECK-NOT: cq_measure_si32
; CHECK-NOT: cq_measure_ui32
; CHECK-NOT: extractvalue
; CHECK-NOT: insertvalue
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t  = type { i32 }
%quint_mid_t = type { i32 }

declare %qint_mid_t  @cq_init_si32  (i32)
declare %quint_mid_t @cq_init_ui32  (i32)
declare i32          @cq_measure_si32(%qint_mid_t)

; Init `a` as si32, init `b` as ui32. The mixed-suffix add must still
; lower to Q+Q (both operands tainted via different init sources).
define i32 @mixed() {
entry:
  %a_struct = call %qint_mid_t  @cq_init_si32(i32 11)
  %a        = extractvalue %qint_mid_t %a_struct, 0

  %b_struct = call %quint_mid_t @cq_init_ui32(i32 13)
  %b        = extractvalue %quint_mid_t %b_struct, 0

  %c        = add i32 %a, %b

  %c_struct = insertvalue %qint_mid_t poison, i32 %c, 0
  %m        = call i32 @cq_measure_si32(%qint_mid_t %c_struct)

  ret i32 %m
}
