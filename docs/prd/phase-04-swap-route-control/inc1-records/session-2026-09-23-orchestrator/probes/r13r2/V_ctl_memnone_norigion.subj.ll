; ModuleID = 'V_ctl_memnone_norigion.ll'
source_filename = "V_ctl_memnone_norigion.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01)
  %h_op = call i32 @cq_template_and_i1_hl(i32 %h1, i1 false)
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_op)
  call void @cq_template_and_i1_hl_unc(i32 %h_op, i32 %h1, i1 false)
  call void @cqrt_free(i32 %h_op)
  %m2 = call i32 @cqrt_measure_i32(i32 %h)
  call void @cqrt_addc_i32(i32 %h_cast, i32 %m2)
  ret i32 %h_cast
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_addc_i32(i32, i32)

declare i32 @cq_template_and_i1_hl(i32, i1)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i1_hl_unc(i32, i32, i1)

declare void @cqrt_free(i32)
