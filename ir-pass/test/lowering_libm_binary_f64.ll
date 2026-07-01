; lowering_libm_binary_f64.ll — bd 3c6m.2: the DIRECT-libm same-width BINARY
; family. Pins the three operand shapes AND the commutativity policy:
;   * atan2 is NON-commutative (operand order is semantic) → distinct `_hl`/`_lh`
;     symbols, source order PRESERVED (atan2(q,3.0)→_hl(h,3.0); atan2(3.0,q)→
;     _lh(3.0,h)).
;   * hypot is COMMUTATIVE → qq+hl only (no `_lh`); the QQ form orders operands by
;     BirthOrder (lower→LHS) for a stable trace.
; Same additive-producer shape as the intrinsic pow/fmin (dataTemplateFn), keyed
; by EXACT NAME over a declaration-only extern.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; atan2 HL — handle left, literal right, order preserved:
; CHECK:     call i32 @cq_template_atan2_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 3.000000e+00)
; atan2 LH — literal left, handle right (the distinct non-commutative symbol):
; CHECK:     call i32 @cq_template_atan2_f64_lh(double 4.000000e+00, i32 %{{[a-zA-Z0-9_.]+}})
; hypot QQ — commutative, two handles:
; CHECK:     call i32 @cq_template_hypot_f64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: call {{.*}}@atan2(
; CHECK-NOT: call {{.*}}@hypot(
; CHECK-NOT: cq_template_hypot_f64_lh

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @atan2(double, double)
declare double @hypot(double, double)

define double @ex(double %u, double %v) {
entry:
  %a = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %b = call double @cq_theta_f64(double %v, double 6.000000e-01)
  %hl = call double @atan2(double %a, double 3.000000e+00)
  %lh = call double @atan2(double 4.000000e+00, double %a)
  %qq = call double @hypot(double %a, double %b)
  %s0 = call double @cq_measure_f64(double %hl)
  %s1 = call double @cq_measure_f64(double %lh)
  %s2 = call double @cq_measure_f64(double %qq)
  %sum = fadd double %s0, %s1
  %sum2 = fadd double %sum, %s2
  ret double %sum2
}
