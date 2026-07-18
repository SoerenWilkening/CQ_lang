; spec_reject_fp_select_poison_arm.ll — DECLINE (bd 20xt.3 boundary, sibling of
; spec_reject_fp_select_undef_arm.ll): an fp select whose FALSE arm is `poison` — a
; NON-`ConstantFP` constant. `armLiftable` (isLiftableFpSelect) admits ONLY a
; concrete `ConstantFP` (or a non-constant derived value); `poison`/`undef`/
; `ConstantExpr` are not concrete materializable basis values, so the select stays
; InBodyControl (a safe over-decline, Prime Directive — materializing a `poison`
; rail via `cqrt_alloc_f<W>(poison)` has no defined basis value). The `poison` half
; of the ConstantFP-vs-other-constant fence.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_copy_f64_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x = sitofp i32 %n to double
  %c = icmp slt i32 %n, 0
  %a = select i1 %c, double %x, double poison   ; NON-ConstantFP constant → decline
  %r = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
