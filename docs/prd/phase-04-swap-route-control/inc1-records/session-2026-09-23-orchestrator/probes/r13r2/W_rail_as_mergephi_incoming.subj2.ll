; ModuleID = 'W_rail_as_mergephi_incoming.ll'
source_filename = "W_rail_as_mergephi_incoming.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h5 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h5, double 5.000000e-01)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h5, i32 %bf)
  %out = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1_controlled(i32 %bf, i32 %h5, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h5, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %bf1 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h5, i32 %bf1)
  %out2 = call i32 @cqrt_alloc_i32(i32 0)
  %selop3 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf1, i32 %selop3, i32 %out2)
  call void @cqrt_x(i32 %bf1)
  %selop4 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %bf1, i32 %selop4, i32 %out2)
  call void @cqrt_x(i32 %bf1)
  call void @cqrt_cnot(i32 %h5, i32 %bf1)
  call void @cqrt_free(i32 %bf1)
  br label %merge

merge:                                            ; preds = %entry
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %out)
  %m6 = call i32 @cqrt_measure_i32(i32 %out2)
  %m7 = call i32 @cqrt_measure_i32(i32 %h)
  call void @cqrt_addc_i32(i32 %h_cast, i32 %m6)
  call void @cqrt_addc_i32(i32 %h_cast, i32 %m7)
  ret i32 %h_cast
}

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_copy_i1_controlled(i32, i32, i32)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i1(i32, double)

declare void @cqrt_addc_i32(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)
