; ModuleID = 'K_multiphi_arith.ll'
source_filename = "K_multiphi_arith.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h3 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h3, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 7)
  %h_op4 = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h3, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h3, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %bf1 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h3, i32 %bf1)
  %out2 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %bf1, i32 %h_op4, i32 %out2)
  call void @cqrt_x(i32 %bf1)
  %selop = call i32 @cqrt_alloc_i32(i32 9)
  call void @cqrt_copy_i32_controlled(i32 %bf1, i32 %selop, i32 %out2)
  call void @cqrt_x(i32 %bf1)
  call void @cqrt_cnot(i32 %h3, i32 %bf1)
  call void @cqrt_free(i32 %bf1)
  br label %merge

merge:                                            ; preds = %entry
  %m = call i32 @cqrt_measure_i32(i32 %out)
  %m5 = call i32 @cqrt_measure_i32(i32 %out2)
  %m6 = call i1 @cqrt_measure_i1(i32 %h3)
  %z = zext i1 %m6 to i32
  %s = add i32 %m, %m5
  %s2 = add i32 %s, %z
  ret i32 %s2
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
