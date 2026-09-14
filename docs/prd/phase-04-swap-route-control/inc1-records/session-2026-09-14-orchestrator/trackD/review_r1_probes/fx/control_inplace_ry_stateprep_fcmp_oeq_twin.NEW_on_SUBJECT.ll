; ModuleID = 'fx/control_inplace_ry_stateprep_fcmp_oeq_twin.NEW.ll'
source_filename = "fx/control_inplace_ry_stateprep_fcmp_oeq_twin.NEW.ll"

define double @example(double %u0) {
entry:
  %h = call i32 @cqrt_alloc_f64(double %u0)
  call void @cqrt_ry_f64(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_fmul_f64_hl(i32 %h, double 2.000000e+00)
  call void @cqrt_ry_f64(i32 %h_op, double 9.000000e-01)
  %m = call double @cqrt_measure_f64(i32 %h_op)
  %m1 = call double @cqrt_measure_f64(i32 %h_op)
  %s = fadd double %m, %m1
  ret double %s
}

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare i32 @cq_template_fmul_f64_hl(i32, double)

declare double @cqrt_measure_f64(i32)
