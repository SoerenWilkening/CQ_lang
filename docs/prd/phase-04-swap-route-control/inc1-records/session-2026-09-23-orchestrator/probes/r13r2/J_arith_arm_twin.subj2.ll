; ModuleID = 'J_arith_arm_twin.ll'
source_filename = "J_arith_arm_twin.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 7)
  %h_op2 = call i32 @cq_template_mul_i32_hl(i32 %h_op, i32 3)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 7)
  call void @cqrt_free(i32 %h_op)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h1, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op2, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h1, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %m3 = call i32 @cqrt_measure_i32(i32 %out)
  %m4 = call i1 @cqrt_measure_i1(i32 %h1)
  %z = zext i1 %m4 to i32
  %s = add i32 %m3, %z
  ret i32 %s
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
