; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/i02_kickback_parent_measured_after.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/i02_kickback_parent_measured_after.s1.ll"

define i32 @main() {
entry:
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 2.000000e-01)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  call void @cqrt_rz_i1(i32 %h, double 0x3FE6666666666666), !cq.branchphase !0
  %m = call i1 @cqrt_measure_i1(i32 %h)
  %zz = zext i1 %m to i32
  ret i32 %zz
}

declare void @cqrt_rz_i1(i32, double)

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare i1 @cqrt_measure_i1(i32)

!0 = !{}
