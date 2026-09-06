; control_swap_value_reject_qq_cond.ll — DECLINE: a VALUE diamond whose
; condition is a Q+Q compare (bd test_C_libtooling-3qlq Inc 2).
;
; `if (q > r) { p = p*5; p = p+15; }` with q and r BOTH quantum. The pre-3qlq
; value emitter minted its flag through `lowerCompareToFlag` with an EMPTY
; qqWidth and therefore declined; the Inc-2 mechanism hands the region to the
; 4.4 `emitSelectRegion`, whose `qqSelectLeafWidth` DOES support a two-handle
; compare. Accepting here would have widened the accept class as an unreviewed
; SIDE EFFECT of a mechanism change, so `emitValueRegion` refuses a Q+Q
; condition explicitly, before any mutation.
;
; ⚠ MEASURED STRING CHANGE, deliberate. The pre-3qlq binary declines this module
; too (exit 1) but with `no template for opcode 'icmp i1' in tainted context` —
; a `diagnoseNoTemplate` fired downstream, not a control-dialect decline. The
; disposition is unchanged; only the message moved into the control dialect.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i32 %w0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 %w0, double 1.250000e-01)
  %c = icmp sgt i32 %q, %r          ; Q+Q condition
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %p, 5
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
; nothing is lowered: the decline is PRE-MUTATION (before the hoist)
; CHECK-NOT: cqrt_copy_i32_controlled
; CHECK-NOT: cqrt_cswap
