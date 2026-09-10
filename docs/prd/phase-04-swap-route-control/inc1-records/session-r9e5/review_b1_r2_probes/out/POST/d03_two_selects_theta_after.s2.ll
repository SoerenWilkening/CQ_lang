; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/d03_two_selects_theta_after.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/d03_two_selects_theta_after.s1.ll"

define i32 @main() {
entry:
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop1 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf2)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  %selop4 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %selop4, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  %selop5 = call i32 @cqrt_alloc_i32(i32 9)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %selop5, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  call void @cqrt_cnot(i32 %h, i32 %bf2)
  call void @cqrt_free(i32 %bf2)
  call void @cqrt_ry_i1(i32 %h, double 3.000000e-01)
  %m = call i1 @cqrt_measure_i1(i32 %h)
  %m6 = call i32 @cqrt_measure_i32(i32 %out)
  %m7 = call i32 @cqrt_measure_i32(i32 %out3)
  %r = add i32 %m6, %m7
  ret i32 %r
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i1 @cqrt_measure_i1(i32)

declare i32 @cqrt_measure_i32(i32)
