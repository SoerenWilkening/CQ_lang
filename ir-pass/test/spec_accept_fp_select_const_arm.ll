; spec_accept_fp_select_const_arm.ll — ACCEPT (bd 20xt.3, the
; materialize-classical-arm widening): an fp select with ONE derived arm and ONE
; `ConstantFP` arm inside a Phase-6 lifted clone — `(n<0) ? (double)n : 0.0`. Was
; spec_reject_fp_select_const_arm.ll (the kmdc slice-1 two-derived-arm decline).
; 20xt.3 admits a `ConstantFP` arm: the derived TRUE arm (`sitofp`, tainted) is
; threaded AS-IS — captured + reverse-played (`sitofp_unc`) + freed proven-|0>;
; the FALSE `ConstantFP` 0.0 is materialized to a fresh `cqrt_alloc_f64(0.0)`
; |const⟩ rail and controlled-copied, then LEFT allocated (leaked, Rule 6). This is
; the value/const half of the widening (spec_accept_fp_select_constconst_f80.ll is
; const/const). The consumer is a `fptosi` (an i32-return clone that fully lowers),
; NOT the former declaration-only `@ilogb` (which would now decline LATER as a
; nested call — the reason the reject fixture used it to isolate the SELECT gate).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x = sitofp i32 %n to double
  %c = icmp slt i32 %n, 0
  %a = select i1 %c, double %x, double 0.000000e+00
  %r = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK: define internal i32 @__cq_q_mhelper_1(i32 %n)
; The derived TRUE arm (tainted) is a data template — threaded AS-IS as a copy src.
; CHECK: %[[X:.*]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %n)
; CHECK: %[[F:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %n, i32 0)
; CHECK-NEXT: %[[SEL:.*]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[X]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; The FALSE ConstantFP (0.0) materialized to its OWN |const> rail, ¬flag-copied.
; CHECK-NEXT: %[[FC:.*]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[FC]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[R:.*]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[SEL]])
; Bennett reverse: the derived arm IS reversed (sitofp `_unc`) and freed; the
; materialized |const> rail [[FC]] is NEVER reversed and NEVER freed (leaked).
; CHECK: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[X]], i32 %n)
; CHECK: call void @cqrt_free(i32 %[[X]])
; CHECK: call void @cqrt_free(i32 %[[SEL]])
; CHECK-NOT: call void @cqrt_free(i32 %[[FC]])
; CHECK: ret
