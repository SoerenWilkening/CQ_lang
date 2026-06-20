; lowering_reject_intrinsic_fshl_dynamic_amount.ll — Phase 7.1 Increment E
; over-accept fence. Only the rotation form of fshl/fshr with a CONSTANT amount
; is curated (the inverse is rotate-by-(W-n), which needs n statically). Here
; arg0==arg1 (rotation) but the amount %n is DYNAMIC (a non-constant function
; argument), so isCuratedReversibleIntrinsic returns false (arg2 is not a
; ConstantInt) and the tainted call falls through to the loud kMsgUnknownCallee
; decline — no `cq_template_fshl` is emitted for a dynamic rotation amount.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_fshl

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @example(i32 %u, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.fshl.i32(i32 %q, i32 %q, i32 %n)   ; dynamic amount %n
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
