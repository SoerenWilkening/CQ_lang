; spec_accept_fp_select_fcmp_f16_cond.ll — ACCEPT (bd tkmn Inc 1). Pins the
; CROSS-WIDTH case, filed by the Inc-1 Rule-13 blast-radius lens (finding F3) as
; reachable-but-unfixtured: an `fcmp olt half` CONDITION feeding an `f64` select.
;
; THE ASYMMETRY THIS PINS, and why it is correct rather than a hole. The select
; RESULT whitelist above deliberately EXCLUDES f16 ("f16 declines (no coverage)"),
; but the compare-OPERAND fence admits {f16,f32,f64,f80} — so an f16 CONDITION is
; accepted while an f16 RESULT is not. Reading the result-width comment alone
; suggests f16 is uniformly out; it is not, and the two are genuinely INDEPENDENT
; axes: the condition width selects the compare template
; (`cq_template_fcmp_olt_f16_hl`, which ships), while the result width selects the
; controlled-copy template (`cqrt_copy_f64_controlled`, which also ships). Both
; resolve here, so the shape lowers correctly and must NOT be declined.
;
; bd p3kd.7.8: the clone's select is now lowered by MAIN's 4.4 SelectMergeEmit;
; main's inline strip (closing `cqrt_x`, the f16 compare `_unc` + free) is elided
; by the Bennett wrap, whose reverse is the EXACT mirror, so the f16 `_unc` now
; appears once, in the mirror. Trace on |n>: x = (double)n, xh = (half)x, f =
; [xh < 2.0]; sel gets 2.5 under f, then (f flipped) x under ¬f; r = fptosi(sel),
; the source's value. The mirror zeroes r, un-copies x, re-flips f, un-copies 2.5
; (sel -> |0>), then the fcmp/fptrunc/sitofp `_unc`s zero f, xh, x. Frees: x, xh,
; f, sel, r; the |2.5> rail is never freed (the CHECK-NEXT chain spans the body).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --implicit-check-not=cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x  = sitofp i32 %n to double
  %xh = fptrunc double %x to half
  %c  = fcmp olt half %xh, 0xH4000            ; f16 CONDITION
  %a  = select i1 %c, double 2.500000e+00, double %x   ; f64 RESULT
  %r  = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(i32 %n)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %n)
; CHECK-NEXT: %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptrunc_f64_to_f16(i32 %[[X]])
; The flag comes from the f16 compare grid — the condition-width axis.
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f16_hl(i32 %[[XH]], half 0xH4000)
; The copies come from the f64 controlled-copy grid — the result-width axis.
; CHECK-NEXT: %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: %[[FC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 2.500000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[FC]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[X]], i32 %[[SEL]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[SEL]])
; The Bennett copy-out and the exact mirror:
; CHECK-NEXT: %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[RES]])
; CHECK-NEXT: call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[R]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[X]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[FC]], i32 %[[SEL]])
; The f16 flag strip names its own rail, and the |const> rail FC is never freed.
; CHECK-NEXT: call void @cq_template_fcmp_olt_f16_hl_unc(i32 %[[F]], i32 %[[XH]], half 0xH4000)
; CHECK-NEXT: call void @cq_template_fptrunc_f64_to_f16_unc(i32 %[[XH]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[X]], i32 %n)
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[XH]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[RES]]
; CHECK-NEXT: }
