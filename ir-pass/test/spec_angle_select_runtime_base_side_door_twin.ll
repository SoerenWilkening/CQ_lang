; spec_angle_select_runtime_base_side_door_twin.ll — ACCEPT (bd
; test_C_libtooling-z0re, OWNER RULING 2026-09-28 option (a)): the HAND-INLINED TWIN
; of `spec_angle_select_runtime_base_side_door.ll` — `t = m + 1` in place of the
; spec-classical call (d88e probe a01T). On the ORACLE (main 9a230646) it DECLINED
; `rotation angle under quantum control` at S3 while the side door ACCEPTED; under the
; ruling S3 admits an untainted RUNTIME Ry-stem base and this CHECK block is the side
; door's, stream for stream.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01)
  %7 = add nsw i32 %5, 1
  %8 = icmp sgt i32 %6, 3
  %9 = select i1 %8, double 0x3FE6666666666666, double 2.000000e-01
  %10 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %9)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %13 = add nsw i32 %12, %11
  ret i32 %13
}

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[T:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
