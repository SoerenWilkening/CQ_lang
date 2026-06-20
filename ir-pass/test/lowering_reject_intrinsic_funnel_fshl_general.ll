; lowering_reject_intrinsic_funnel_fshl_general.ll — Phase 7.1 Increment E
; over-accept fence (green forever). Only the ROTATION case of fshl/fshr is
; curated (arg0==arg1). The GENERAL (x!=y) funnel shift concatenates two
; DISTINCT operands and shifts — it is not a single-register bijection and is
; NOT enumerated. isCuratedReversibleIntrinsic returns false when arg0!=arg1
; (here %a and %b are two distinct thetas), so it falls through to the loud
; kMsgUnknownCallee decline — the curated fshl/fshr `_hl` rotation symbols are
; NOT emitted for a general funnel shift.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_fshl

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @example(i32 %u, i32 %v) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %v, double 2.500000e-01)
  %r = call i32 @llvm.fshl.i32(i32 %a, i32 %b, i32 5)   ; x != y -> general funnel
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
