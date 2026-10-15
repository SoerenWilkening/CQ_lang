; spec_accept_fp_select_const_arm.ll — ACCEPT (bd 20xt.3, the
; materialize-classical-arm widening): an fp select with ONE derived arm and ONE
; `ConstantFP` arm inside a Phase-6 lifted clone — `(n<0) ? (double)n : 0.0`. Was
; spec_reject_fp_select_const_arm.ll (the kmdc slice-1 two-derived-arm decline).
; 20xt.3 admits a `ConstantFP` arm: the derived TRUE arm (`sitofp`, tainted) is
; threaded AS-IS — captured + reverse-played (`sitofp_unc`) + freed proven-|0>;
; the FALSE `ConstantFP` 0.0 is materialized to a fresh `cqrt_alloc_f64(0.0)`
; |const⟩ rail and controlled-copied, then (before p3kd.7.8) LEFT allocated. This is
; the value/const half of the widening (spec_accept_fp_select_constconst_f80.ll is
; const/const). The consumer is a `fptosi` (an i32-return clone that fully lowers),
; NOT the former declaration-only `@ilogb` (which would now decline LATER as a
; nested call — the reason the reject fixture used it to isolate the SELECT gate).
;
; bd p3kd.7.8: main's 4.4 `SelectMergeEmit` now lowers the clone's select. The TRUE arm
; is still threaded as-is and the FALSE `ConstantFP` still gets its own materialized
; rail, but +0.0 has all-zero bits, so that rail is |0> (`isNullValue`, +0.0 only), is
; only ever a copy SOURCE, and the wrap now frees it with the other |0> rails; a
; non-zero constant rail is still left allocated (spec_accept_select_const_arms_int.ll).
; bd dm7f.81 SUPERSEDES the two paragraphs above: no classical arm is a rail any more;
; a +0.0 arm emits nothing, a nonzero one is a cqrt_xorc_<W>_controlled literal.
; The merge's trailing `cqrt_x` strip is elided in the forward, and the fptosi reads SEL.
; Hand trace, |n>: SEL = [n<0]·(double)n ⊕ ¬[n<0]·0.0; R = fptosi(SEL) copied out; the
; mirror zeroes R, undoes both copies around the replayed `cqrt_x`, then the compare
; and sitofp `_unc`s; every freed rail is |0>.
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

; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(i32 %n)
; The derived TRUE arm (tainted) is a data template — threaded AS-IS as a copy src.
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %n)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %n, i32 0)
; CHECK-NEXT: %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[X]], i32 %[[SEL]])
; (bd dm7f.81: the FALSE ConstantFP is +0.0, an all-zero bit pattern, so it emits NO write and NO ¬flag bracket, forward or reversed, and no source rail to free; a nonzero fp constant is a cqrt_xorc_f64_controlled literal — control_select_arm_xorc_imm.ll pins -0.0.)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[SEL]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[OUT]])
; Bennett mirror: the derived arm IS reversed (sitofp `_unc`); no gate ever writes the
; former materialized rail (gone since bd dm7f.81).
; CHECK-NEXT: call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[R]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[X]], i32 %[[SEL]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F]], i32 %n, i32 0)
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[X]], i32 %n)
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[OUT]]
; CHECK-NEXT: }
