; ModuleID = 'N_rail_phase_only.ll'
source_filename = "N_rail_phase_only.ll"

define i32 @probe() {
entry:
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  call void @cqrt_rz_i1(i32 %h, double 3.140000e+00), !cq.branchphase !0
  %m = call i1 @cqrt_measure_i1(i32 %h)
  %z = zext i1 %m to i32
  ret i32 %z
}

declare void @cqrt_rz_i1(i32, double)

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare i1 @cqrt_measure_i1(i32)

!0 = !{}
