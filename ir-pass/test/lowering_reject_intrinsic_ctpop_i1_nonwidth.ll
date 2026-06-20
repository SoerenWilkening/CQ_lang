; lowering_reject_intrinsic_ctpop_i1_nonwidth.ll — Phase 7.1 Increment E
; over-accept fence: a curated id at a NON-TABLE width declines. The intrinsic
; table covers {i8,i16,i32,i64}; i1 (like the deferred i128, fp, and vector
; widths) is OUT. `widthInTableSet(ctpop, "i1")` is false, so
; isCuratedReversibleIntrinsic returns false and the tainted `@llvm.ctpop.i1`
; rides the loud kMsgUnknownCallee decline rather than minting an unresolved
; `cq_template_ctpop_i1` symbol (a link failure invisible to opt -verify).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_ctpop_i1

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i1 @llvm.ctpop.i1(i1)

define i1 @example(i1 %u) {
entry:
  %q = call i1 @cq_theta_i1(i1 %u, double 5.000000e-01)
  %r = call i1 @llvm.ctpop.i1(i1 %q)
  %m = call i1 @cq_measure_i1(i1 %r)
  ret i1 %m
}
