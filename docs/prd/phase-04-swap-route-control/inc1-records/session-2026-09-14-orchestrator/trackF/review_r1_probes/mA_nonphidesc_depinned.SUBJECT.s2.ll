; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/mA_nonphidesc_depinned.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/mA_nonphidesc_depinned.ll"

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
  %h2 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h2, double 5.000000e-01)
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %h2, double -5.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out, i32 1)
  %h3 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h3, double 5.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %out, i32 1)
  call void @cqrt_free(i32 %h_cmp)
  %m = call i1 @cqrt_measure_i1(i32 %h)
  %m4 = call i1 @cqrt_measure_i1(i32 %h2)
  %m5 = call i1 @cqrt_measure_i1(i32 %h3)
  %z1 = zext i1 %m to i32
  %z6 = zext i1 %m4 to i32
  %z9 = zext i1 %m5 to i32
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
