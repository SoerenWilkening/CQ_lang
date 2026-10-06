; spec_reject_select_vector.ll — DECLINE (bd p3kd.7.1 decline fixture for the
; widened select gate, vector clause): a VECTOR select in a lifted callee. A vector
; lane has no scalar controlled copy, so `scanBody` keeps refusing a select that
; touches a vector (`InBodyControl`, at the original callee, during detection),
; exactly as the retired `isLiftableSelect`/`isLiftableFpSelect` pair did: no ABI
; width names a vector type, so the width clause of `isAdmissibleCloneSelect`
; refuses it (a separate vector clause was redundant; its mutant survived). The
; select is the body's first vector-touching instruction, so it is the select gate
; that fires, not the data-op whitelist's "vector SIMD" clause or the
; `extractelement` "unsupported instruction" clause after it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function helper i32 (i32, <2 x i32>): cq specialization: callee contains tainted control flow under quantum lift
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, <2 x i32> %v) {
entry:
  %t = icmp slt i32 %b, 5
  %s = select i1 %t, <2 x i32> %v, <2 x i32> zeroinitializer
  %e = extractelement <2 x i32> %s, i32 0
  ret i32 %e
}

define i32 @example(i32 %u0, <2 x i32> %w) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, <2 x i32> %w)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
