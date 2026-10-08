; spec_accept_clone_f16_phi_merge.ll — ACCEPT (bd test_C_libtooling-p3kd.12).
; A lifted callee merges a quantum `half` through a PHI diamond:
;   half h(half b) { return b > 0 ? b + 1 : 2; }   (kept as a branch, hand IR)
; The clone's PredMux flatten turns the phi into a select, and main's control chain
; lowers it with the f16 controlled copy. This form lifted before p3kd.12 with NO
; fixture (the 2026-10-08 review traced it exact); its select twin was refused
; (spec_reject_fp_select_f16.ll, an accept now). Both widths answers now agree.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define internal i32 @__cq_q_h_1(
; CHECK:       %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f16_hl(i32 %{{[a-zA-Z0-9_.]+}}, half 0xH0000)
; CHECK:       %[[O:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f16(half 0xH0000)
; CHECK:       call void @cqrt_copy_f16_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[O]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:  %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f16(half 0xH4000)
; CHECK-NEXT:  call void @cqrt_copy_f16_controlled(i32 %[[F]], i32 %[[K]], i32 %[[O]])
; CHECK:       ret i32
declare half @cq_theta_f16(half, double)
declare half @cq_measure_f16(half)

define half @h(half %b) {
entry:
  %t = fcmp ogt half %b, 0xH0000
  br i1 %t, label %a, label %m
a:
  %v = fadd half %b, 0xH3C00
  br label %m
m:
  %r = phi half [ %v, %a ], [ 0xH4000, %entry ]
  ret half %r
}

define half @example(half %u0) {
entry:
  %q = call half @cq_theta_f16(half %u0, double 5.000000e-01)
  %r = call half @h(half %q)
  %m = call half @cq_measure_f16(half %r)
  ret half %m
}
