; spec_stateprep_runtime_seed_side_door_twin.ll — ACCEPT (bd test_C_libtooling-z0re,
; OWNER RULING 2026-09-28 option (a)): the HAND-INLINED TWIN of
; `spec_stateprep_runtime_seed_side_door.ll` — `t = h(q, m)` replaced by h's
; classical return `t = m + 1`, single function, no specializer (d88e probe l12T).
;
; The twin defines the correct circuit. On the ORACLE (main 9a230646) it DECLINED at
; F1 (`state prep seed does not match the merge incoming` — a runtime seed, while
; F1 admitted literals only) while the side door ACCEPTED: the owner-scope bypass bd
; z0re filed. Under the ruling F1 admits the runtime seed, and this file's CHECK
; block is the side door's, stream for stream (the only difference in the module is
; the `add` in place of the clone call, which is classical and emits no gate).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01)
  %10 = add nsw i32 %5, 1
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 3.000000e-01)
  %12 = icmp sgt i32 %11, 3
  br i1 %12, label %13, label %15
13:
  %14 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01)
  br label %15
15:
  %16 = phi i32 [ %14, %13 ], [ %10, %2 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %19 = add nsw i32 %18, %17
  ret i32 %19
}

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:      %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %8)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q2]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q2]], i32 3)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[T:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q2]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q2]])
