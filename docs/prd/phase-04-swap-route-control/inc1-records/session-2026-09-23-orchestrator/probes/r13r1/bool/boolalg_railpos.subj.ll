; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/bool/boolalg_railpos.ll'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad/rev/bool/boolalg_railpos.ll"

define i32 @probe(i32 %u) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h11 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h11, double 5.000000e-01)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h11, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop1 = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h11, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h11, i32 %bf2)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  %selop4 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %selop4, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  %selop5 = call i32 @cqrt_alloc_i32(i32 6)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %selop5, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  call void @cqrt_cnot(i32 %h11, i32 %bf2)
  call void @cqrt_free(i32 %bf2)
  %bf6 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h11, i32 %bf6)
  %out7 = call i32 @cqrt_alloc_i32(i32 0)
  %selop8 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %bf6, i32 %selop8, i32 %out7)
  call void @cqrt_x(i32 %bf6)
  %selop9 = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_copy_i32_controlled(i32 %bf6, i32 %selop9, i32 %out7)
  call void @cqrt_x(i32 %bf6)
  call void @cqrt_cnot(i32 %h11, i32 %bf6)
  call void @cqrt_free(i32 %bf6)
  br label %merge

merge:                                            ; preds = %entry
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h11, i32 %h_cmp, i32 %g)
  %out10 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %out, i32 %out10)
  call void @cqrt_x(i32 %g)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %out3, i32 %out10)
  call void @cqrt_x(i32 %g)
  call void @cqrt_toffoli(i32 %h11, i32 %h_cmp, i32 %g)
  call void @cqrt_free(i32 %g)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i32 @cqrt_measure_i32(i32 %out10)
  %m12 = call i32 @cqrt_measure_i32(i32 %out7)
  %m13 = call i1 @cqrt_measure_i1(i32 %h11)
  %z = zext i1 %m13 to i32
  %s = add i32 %m, %m12
  %s2 = add i32 %s, %z
  ret i32 %s2
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)
