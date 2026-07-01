; lowering_libm_mixed_arg.ll — bd 3c6m.2: the MIXED-ARG binary family
; ((fp, int) → fp). arg0 is the fp (width `wa`, from the result), arg1 the INTEGER
; exponent at a fixed width `wb` (ldexp/scalbn: i32; scalbln: i64). The symbol
; `cq_template_<op>_<wa>_<wb>[_hl|_lh]` preserves BOTH widths, and the classical
; operand's C type is PER-SHAPE — `_hl` carries the int `wb`, `_lh` the fp `wa`.
; NON-commutative (distinct operand types) → order preserved. Three shapes:
;   * ldexp HL — fp handle, int literal  → _hl(handle, i32 2)
;   * ldexp LH — fp literal, int handle  → _lh(double 3.0, handle)
;   * ldexp QQ — both handles            → base(handle, handle)
;   * scalbln  — the i64 exponent width  → _f64_i64_hl(handle, i64 2)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cq_template_ldexp_f64_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 2)
; CHECK:     call i32 @cq_template_ldexp_f64_i32_lh(double 3.000000e+00, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_ldexp_f64_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_scalbln_f64_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 2)
;
; CHECK-NOT: call {{.*}}@ldexp(
; CHECK-NOT: call {{.*}}@scalbln(
; CHECK-NOT: cq_template_ldexp_f64_f64

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_theta_si32(i32, double)
declare double @cq_measure_f64(double)
declare double @ldexp(double, i32)
declare double @scalbln(double, i64)

define double @ex(double %u) {
entry:
  %a = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %n = call i32 @cq_theta_si32(i32 2, double 7.000000e-01)
  %hl = call double @ldexp(double %a, i32 2)
  %lh = call double @ldexp(double 3.000000e+00, i32 %n)
  %qq = call double @ldexp(double %a, i32 %n)
  %sb = call double @scalbln(double %a, i64 2)
  %m0 = call double @cq_measure_f64(double %hl)
  %m1 = call double @cq_measure_f64(double %lh)
  %m2 = call double @cq_measure_f64(double %qq)
  %m3 = call double @cq_measure_f64(double %sb)
  %s0 = fadd double %m0, %m1
  %s1 = fadd double %s0, %m2
  %s2 = fadd double %s1, %m3
  ret double %s2
}
