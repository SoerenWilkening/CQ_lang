; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/g08_rail_is_cond_and_arm.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/g08_rail_is_cond_and_arm.s1.ll"

declare i64 @cq_theta_si64(i64, double)

declare i64 @cq_measure_si64(i64)

define i32 @main() {
entry:
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_ry_i1(i32 %h1, double 0x3FE6666666666666)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1_controlled(i32 %bf, i32 %h, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_copy_i1_controlled(i32 %bf, i32 %h1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %out)
  %m2 = call i32 @cqrt_measure_i32(i32 %h_cast)
  ret i32 %m2
}

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1_controlled(i32, i32, i32)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)
