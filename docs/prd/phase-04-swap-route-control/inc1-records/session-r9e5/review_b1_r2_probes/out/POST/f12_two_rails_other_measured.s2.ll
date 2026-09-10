; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/f12_two_rails_other_measured.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/f12_two_rails_other_measured.s1.ll"

declare i64 @cq_theta_si64(i64, double)

declare i64 @cq_measure_si64(i64)

define i32 @main() {
entry:
  %h = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_ry_i1(i32 %h, double 1.000000e-01)
  call void @cqrt_ry_i1(i32 %h, double 4.000000e-01)
  %h2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h2, double 2.000000e-01)
  call void @cqrt_ry_i1(i32 %h2, double 5.000000e-01)
  %m3 = call i1 @cqrt_measure_i1(i32 %h)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h2, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop1 = call i32 @cqrt_alloc_i32(i32 9)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h2, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %zz = zext i1 %m3 to i32
  %m4 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add i32 %m4, %zz
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
