; control_swap_select_f32.ll — ACCEPT: the f32 fp-DATA select (kjd1 Rule-13
; implementation clearance, f80-lens coverage minor: the un-staged set is
; {f16,f32,f64,f80} but the initial accept fixtures covered only f16/f64/f80 —
; nothing pinned emission of cqrt_copy_f32_controlled). Same six-step
; fcmp-minted merge, all-f32 symbols; classical false operand materialized at
; its real f32 width.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)

define float @example(float %u0, float %x) {
entry:
  %q   = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %c   = fcmp ogt float %q, 5.000000e-01
  %sel = select i1 %c, float %q, float %x
  %m   = call float @cq_measure_f32(float %sel)
  ret float %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float %u0)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f32_hl(i32 %[[Q]], float 5.000000e-01)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float 0.000000e+00)
; CHECK:     call void @cqrt_copy_f32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float %x)
; CHECK:     call void @cqrt_copy_f32_controlled(i32 %[[F]], i32 %[[XH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_fcmp_ogt_f32_hl_unc(i32 %[[F]], i32 %[[Q]], float 5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call float @cqrt_measure_f32(i32 %[[OUT]])
; CHECK-NOT: cqrt_copy_i
