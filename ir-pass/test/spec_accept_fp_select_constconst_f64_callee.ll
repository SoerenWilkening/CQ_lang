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

; CHECK: define internal i32 @__cq_q_helper_1(i32 %c)
; CHECK: %[[F:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %c, i32 5)
; CHECK-NEXT: %[[SEL:.*]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; TRUE const (3.0) and FALSE const (1.0) each materialized to their own |const> rail.
; CHECK-NEXT: %[[T:.*]] = call i32 @cqrt_alloc_f64(double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[T]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[FA:.*]] = call i32 @cqrt_alloc_f64(double 1.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[FA]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[R:.*]] = call i32 @cq_template_fptoui_f64_to_i32(i32 %[[SEL]])
; Bennett reverse + proven-|0> frees; the two |const> rails are LEAKED (Rule 6).
; CHECK: call void @cq_template_fptoui_f64_to_i32_unc(i32 %[[R]], i32 %[[SEL]])
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %c, i32 5)
; CHECK: call void @cqrt_free(i32 %[[SEL]])
; CHECK-NOT: call void @cqrt_free(i32 %[[T]])
; CHECK-NOT: call void @cqrt_free(i32 %[[FA]])
