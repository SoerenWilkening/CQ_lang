; control_select_arm_undef_refined_zero.ll — ACCEPT (bd test_C_libtooling-dm7f.81;
; owner ruling ruling-dm7f81-open-qs-2026-10-15 Q1, the same rule as
; owner-ruling-undef-seed-is-zero, bd z9t1).
;
; A whole-value `undef` merge arm is REFINED to the all-zero pattern and emits NO
; gate (`armWriteIsNoop`, MergeArmWrite.cpp): LangRef lets any value stand in for
; it, and as a literal operand the merge-discharge replay would clone it into a
; SECOND slot that `IMPLICIT_DEF` materialises as a different value
; (LiteralIntegrity.h guard 1). So `select i1 %f, double undef, double %v` writes
; exactly ONE controlled xor, of the classical %v under ¬f, and nothing for the
; undef arm. The control — an expression that merely CONTAINS an undef leaf still
; gets its literal write — is control_select_arm_constexpr_undef_materializes.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=ONE < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define double @example(
; CHECK:      %[[F:[0-9a-zA-Z_.]+]] = call i32 @cq_template_fcmp_uno_f64(
; CHECK-NEXT: %[[O:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_xorc_f64_controlled(i32 %[[F]], i32 %[[O]], double %v)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_fcmp_uno_f64_unc(i32 %[[F]],

; Exactly ONE write gate in the whole module, and it is the %v xor.
; ONE-COUNT-1: call void @cqrt_{{xorc|copy}}_f64_controlled(
; ONE-NOT:     call void @cqrt_{{xorc|copy}}_f64_controlled(

; The undef never reaches an emitted operand, and is never a rail.
; NEG-NOT: {{ undef[,)]}}
; NEG-NOT: @cqrt_alloc_f64(double undef)

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %v) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp uno double %q, %q
  %a = select i1 %c, double undef, double %v
  %m = call double @cq_measure_f64(double %a)
  ret double %m
}
