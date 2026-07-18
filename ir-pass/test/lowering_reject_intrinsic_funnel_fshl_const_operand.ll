; lowering_reject_intrinsic_funnel_fshl_const_operand.ll — Phase 7.1 Increment E,
; bd 20xt.1 over-accept fence. The general funnel shift is curated ONLY when BOTH
; data operands are runtime values (the two-word extract idiom). Here one operand
; is a ConstantInt (i32 12345): `(12345<<16)|(q>>16)` is NOT the word-extract
; idiom — instcombine folds `(C<<n)|(y>>(W-n))` to a plain shl/or, so a funnel
; with a literal high/low word never survives clang to reach the pass. The
; predicate rejects a ConstantInt data operand (isCuratedReversibleIntrinsic
; returns false), so the tainted call falls through to the loud kMsgUnknownCallee
; escape decline — no `cq_template_fshl` (of any shape) is emitted.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_fshl

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.fshl.i32(i32 %q, i32 12345, i32 16)   ; literal low word -> not curated
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
