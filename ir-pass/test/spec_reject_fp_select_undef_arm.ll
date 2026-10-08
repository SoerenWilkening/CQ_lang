; spec_reject_fp_select_undef_arm.ll — DECLINE (bd 20xt.3 boundary): an fp select
; whose FALSE arm is a NON-`ConstantFP` constant (`undef`). The 20xt.3 widening
; admits a concrete `ConstantFP` arm (materialized to a `cqrt_alloc_f<W>(<const>)`
; |const⟩ rail), but `undef`/`poison`/`ConstantExpr` are not concrete
; materializable basis values — `armLiftable` (isLiftableFpSelect; `armAdmissible`
; in `isAdmissibleCloneSelect` since bd p3kd.7.1) requires
; `!isa<Constant> || isa<ConstantFP>`, so an `undef` arm stays InBodyControl (a
; safe over-decline, Prime Directive). The ConstantFP-vs-other-constant edge pin
; for the value/const + const/const accept set (spec_accept_fp_select_const_arm.ll,
; spec_accept_fp_select_constconst_f80.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; (R10, 2026-10-08: the CHECK-NOT lines that followed the error were removed as vacuous —
; opt exits on the first DS_Error and prints no IR, so nothing can follow it.)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x = sitofp i32 %n to double
  %c = icmp slt i32 %n, 0
  %a = select i1 %c, double %x, double undef   ; NON-ConstantFP constant → decline
  %r = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
