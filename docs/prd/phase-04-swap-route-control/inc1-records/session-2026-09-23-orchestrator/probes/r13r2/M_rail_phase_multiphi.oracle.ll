; ModuleID = 'M_rail_phase_multiphi.ll'
source_filename = "M_rail_phase_multiphi.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h7 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h7, double 5.000000e-01)
  call void @cqrt_rz_i1(i32 %h7, double 3.140000e+00), !cq.branchphase !0
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h7, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop2 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop2, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h7, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %bf3 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h7, i32 %bf3)
  %out4 = call i32 @cqrt_alloc_i32(i32 0)
  %selop5 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf3, i32 %selop5, i32 %out4)
  call void @cqrt_x(i32 %bf3)
  %selop6 = call i32 @cqrt_alloc_i32(i32 6)
  call void @cqrt_copy_i32_controlled(i32 %bf3, i32 %selop6, i32 %out4)
  call void @cqrt_x(i32 %bf3)
  call void @cqrt_cnot(i32 %h7, i32 %bf3)
  call void @cqrt_free(i32 %bf3)
  %m = call i32 @cqrt_measure_i32(i32 %out)
  %m8 = call i32 @cqrt_measure_i32(i32 %out4)
  %m9 = call i32 @cqrt_measure_i32(i32 %h)
  %s = add i32 %m, %m8
  %s2 = add i32 %s, %m9
  ret i32 %s2
}

declare void @cqrt_rz_i1(i32, double)

declare void @cqrt_x(i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_measure_i32(i32)

!0 = !{}
