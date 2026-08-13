; control_swap_select_i8.ll — ACCEPT: tainted-condition integer-data `select` at
; a NON-i32 ABI width (the §6.3 width-fidelity probe). `abiWidthFromType(
; Sel->getType())` is read at emit time, BEFORE rotation lowering launders handles
; to i32, so the stream must be all-i8: `cqrt_alloc_i8` / `cqrt_copy_i8_controlled`
; / `cq_template_icmp_sgt_i8_hl`, with the classical operand at its real i8 width
; (the handle is always i32). A post-RAUW width read would force i32 — a silent
; width miscompile this fixture forecloses.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i8 @cq_theta_si8(i8, double)
declare i8 @cq_measure_si8(i8)
define i8 @example(i8 %u0, i8 %x) {
entry:
  %q   = call i8 @cq_theta_si8(i8 %u0, double 5.000000e-01)
  %c   = icmp sgt i8 %q, 5
  %sel = select i1 %c, i8 %q, i8 %x
  %m   = call i8 @cq_measure_si8(i8 %sel)
  ret i8 %m
}

; all-i8 stream; handle i32, classical operand i8:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %u0)
; CHECK:     call void @cqrt_ry_i8(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i8_hl(i32 %[[Q]], i8 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK:     call void @cqrt_copy_i8_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %x)
; CHECK:     call void @cqrt_copy_i8_controlled(i32 %[[F]], i32 %[[XH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i8_hl_unc(i32 %[[F]], i32 %[[Q]], i8 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i8 @cqrt_measure_i8(i32 %[[OUT]])
; CHECK-NOT: cqrt_alloc_i32
; CHECK-NOT: cqrt_copy_i32_controlled
