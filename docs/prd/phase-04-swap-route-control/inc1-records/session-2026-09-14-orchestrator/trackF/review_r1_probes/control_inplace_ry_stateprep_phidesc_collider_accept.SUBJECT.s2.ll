; ModuleID = '/Users/sorenwilkening/Desktop/CQ_f2phi/ir-pass/test/control_inplace_ry_stateprep_phidesc_collider_accept.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_f2phi/ir-pass/test/control_inplace_ry_stateprep_phidesc_collider_accept.ll"

define i32 @main() local_unnamed_addr {
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
  %h5 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h5, double 5.000000e-01)
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %h5, double -5.000000e-01)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h5, i32 %bf2)
  %out3 = call i32 @cqrt_alloc_i32(i32 0)
  %selop4 = call i32 @cqrt_alloc_i32(i32 -1)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %selop4, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %out, i32 %out3)
  call void @cqrt_x(i32 %bf2)
  call void @cqrt_cnot(i32 %h5, i32 %bf2)
  call void @cqrt_free(i32 %bf2)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out3, i32 2)
  %h6 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h6, double 5.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %out3, i32 2)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i1 @cqrt_measure_i1(i32 %h)
  %m7 = call i1 @cqrt_measure_i1(i32 %h5)
  %m8 = call i1 @cqrt_measure_i1(i32 %h6)
  %z1 = zext i1 %m to i32
  %z6 = zext i1 %m7 to i32
  %z9 = zext i1 %m8 to i32
  %a1 = add nsw i32 %z1, %z6
  %a2 = add nsw i32 %a1, %z9
  ret i32 %a2
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i1(i32, double)

declare void @cqrt_ry_i1_controlled(i32, i32, double)

declare i1 @cqrt_measure_i1(i32)
