; Rule 4 shapes: commutative swap, fp NaN-constant rule (cq-5iy: a run-time literal commutes), compare flip, fma, fmuladd with classical product.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i1 @cq_measure_i1(i1)
declare double @llvm.fma.f64(double, double, double)
declare double @llvm.fmuladd.f64(double, double, double)

define i32 @int_swap(i32 %x0, double %t, i32 %c) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %a = add i32 %c, %x
  %s = sub i32 %c, %x
  %m = mul i32 %a, %s
  %r = call i32 @cq_measure_si32(i32 %m)
  ret i32 %r
}
; CHECK int_swap: @cq_template_add_i32_hl(i32 %{{x}}, i32 %{{a2}})
; CHECK int_swap: @cq_template_sub_i32_lh(i32 %{{a2}},

define double @fp_nan(double %x0, double %t, double %c) {
  %x = call double @cq_theta_f64(double %x0, double %t)
  %a = fadd double 1.5, %x
  %b = fadd double 0x7FF8000000000000, %a
  %d = fadd double %c, %b
  %e = fmul double %d, %d
  %r = call double @cq_measure_f64(double %e)
  ret double %r
}
; CHECK fp_nan: @cq_template_fadd_f64_hl(i32 %{{x}}, double 1.500000e+00)
; CHECK fp_nan: @cq_template_fadd_f64_lh(double 0x7FF8000000000000,
; CHECK fp_nan: @cq_template_fadd_f64_hl(i32 %{{t3}}, double %{{c}})
; CHECK fp_nan: @cq_template_fmul_f64(i32

define i1 @cmp_flip(i32 %x0, double %t, i32 %c) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %b = icmp slt i32 %c, %x
  %r = call i1 @cq_measure_i1(i1 %b)
  ret i1 %r
}
; CHECK cmp_flip: @cq_template_icmp_sgt_i32_hl(i32 %{{x}}, i32 %{{a2}})

define double @fma_shapes(double %x0, double %t, double %a, double %b) {
  %x = call double @cq_theta_f64(double %x0, double %t)
  %f1 = call double @llvm.fma.f64(double 2.0, double %x, double %b)
  %f2 = call double @llvm.fma.f64(double %a, double %f1, double 3.0)
  %f3 = call double @llvm.fmuladd.f64(double %a, double %b, double %f2)
  %r = call double @cq_measure_f64(double %f3)
  ret double %r
}
; CHECK fma_shapes: @cq_template_fma_f64_qll(i32 %{{x}}, double 2.000000e+00, double %{{a3}})
; CHECK fma_shapes: @cq_template_fma_f64_qll(i32 %{{f1}}, double %{{a}}, double 3.000000e+00)
; CHECK fma_shapes: fmul double %{{a}}, %{{b}}
; CHECK fma_shapes: @cq_template_fadd_f64_hl(i32 %{{f2}}, double %{{p}})
