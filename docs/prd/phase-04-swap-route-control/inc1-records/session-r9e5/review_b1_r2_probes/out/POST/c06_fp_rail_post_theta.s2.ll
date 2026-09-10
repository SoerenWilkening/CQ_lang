; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/c06_fp_rail_post_theta.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/c06_fp_rail_post_theta.s1.ll"

define double @main() {
entry:
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
  %selop = call i32 @cqrt_alloc_f64(double 2.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop1 = call i32 @cqrt_alloc_f64(double 5.000000e+00)
  call void @cqrt_copy_f64_controlled(i32 %bf, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  call void @cqrt_ry_i1(i32 %h, double 3.000000e-01)
  %m2 = call i1 @cqrt_measure_i1(i32 %h)
  %m3 = call double @cqrt_measure_f64(i32 %out)
  ret double %m3
}

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_copy_f64_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i1 @cqrt_measure_i1(i32)

declare double @cqrt_measure_f64(i32)
