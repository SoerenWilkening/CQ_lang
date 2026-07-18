; lowering_reject_intrinsic_funnel_fshl_dynamic_amount.ll — Phase 7.1 Increment E,
; bd 20xt.1 over-accept fence. The GENERAL funnel shift (arg0 != arg1) is curated
; ONLY with a CONSTANT amount — the void `_unc` recompute needs the amount
; statically. Here both data operands are distinct thetas (the two-word idiom) but
; the amount %n is DYNAMIC (a runtime function argument), so the predicate's amount
; check (`!isa<ConstantInt>(arg2)`) fires BEFORE the rotation/general split and
; returns false. The tainted call rides the loud kMsgUnknownCallee escape decline —
; no `cq_template_fshl` (qql or hl) is emitted for a dynamic-amount funnel.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_fshl

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @example(i32 %u, i32 %v, i32 %n) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %v, double 2.500000e-01)
  %r = call i32 @llvm.fshl.i32(i32 %a, i32 %b, i32 %n)   ; general funnel, DYNAMIC amount %n
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
