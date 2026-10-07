; spec_accept_fp_select_constconst_f64_callee.ll — ACCEPT (bd 20xt.3, the
; materialize-classical-arm widening). WAS control_swap_reject_select_fp_in_
; specialized_callee.ll — the kjd1 §5.9d tripwire that pinned a CONST/CONST fp
; select inside a Phase-6 lifted callee as declining `InBodyControl` (kjd1's
; fp-DATA un-staging was select-in-the-CALLER-narrow; adia then lifted the
; value/value clone fp select; 20xt.3 lifts the const-arm case). The kjd1 fence
; was a SCOPE fence ("not yet implemented"), NOT a soundness fence — a const/const
; clone-body fp select lowers by the SAME two-copy stream as value/value, each
; `ConstantFP` arm materialized to its own `cqrt_alloc_f64(<const>)` |const> rail
; (LEAKED, Rule 6) and controlled-copied into the |0> out rail; the `fptoui` reads
; the merge rail (p119.6 clone-HandleWidth) and the Bennett wrap reverse-plays +
; frees the tainted rails on |0>. `select i1 %t, double 3.0, double 1.0` is the
; f64+fptoui sibling of spec_accept_fp_select_constconst_f80.ll (f80+fptosi).
;
; bd p3kd.7.8: the clone's select is now lowered by MAIN's 4.4 SelectMergeEmit
; (the clone-only `lowerCloneSelect` is gone). Same two-copy stream with each
; const arm materialized; main's inline strip (closing `cqrt_x`, compare `_unc` +
; free) is elided by the Bennett wrap, whose reverse is the EXACT mirror. Trace on
; |c>: f = [c>5]; sel gets 3.0 under f, then (f flipped) 1.0 under ¬f; r =
; fptoui(sel) is 3 or 1, the source's value; the mirror zeroes r, un-copies 1.0,
; re-flips f, un-copies 3.0 (sel -> |0.0> = |0>), zeroes f. Frees: f, sel, r. The
; CHECK-NEXT chain covers the whole body, so it proves neither |const> rail is
; freed (the old tail-only CHECK-NOTs pinned that only after the last free).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %c) {
entry:
  %t  = icmp sgt i32 %c, 5
  %s  = select i1 %t, double 3.000000e+00, double 1.000000e+00  ; const/const fp select
  %si = fptoui double %s to i32
  ret i32 %si
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)                    ; quantum lift of helper
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}

; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %c)
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %c, i32 5)
; CHECK-NEXT: %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; TRUE const (3.0) and FALSE const (1.0) each materialized to their own |const> rail.
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[T]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 1.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[FA]], i32 %[[SEL]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptoui_f64_to_i32(i32 %[[SEL]])
; The Bennett copy-out, the exact mirror, then the proven-|0> frees; the two
; |const> rails T and FA are LEAKED (Rule 6): no free of them anywhere in the body.
; CHECK-NEXT: %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[RES]])
; CHECK-NEXT: call void @cq_template_fptoui_f64_to_i32_unc(i32 %[[R]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[FA]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[T]], i32 %[[SEL]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %c, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[RES]]
; CHECK-NEXT: }
