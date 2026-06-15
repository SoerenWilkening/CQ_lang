; control_swap_reject_select_coherent.ll — DECLINE: a COHERENT-operand select
; (4.4 WI-1 gate 5, the §16.7 conservative default; the channel-B dephasing
; case). A tainted value operand whose lineage ALSO feeds a downstream rotation
; cannot be safely CNOT-copied into the merge: the copy entangles `%out` (channel
; A) AND kills the operand's own marginal off-diagonal so the standalone
; downstream rotation is dephased (channel B). The shipped v1 default declines
; `control flow`; the exact coherent-vs-basis boundary is the binding §8 Rule-13
; clearance item, widened only by independent review — a green suite does NOT
; authorize widening this gate.
;
; `(q>5) ? q : x` where `%q` ALSO feeds a downstream `cq_phi(%q, …)`: the
; operand `%q` has a quantum use beyond the select, so `hasCoherentDownstreamUse`
; flags it. Gate 3 (angle) passes — `%sel` itself feeds only a measure — and
; gate 4 passes (i32), so the decline is squarely gate 5.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, i32 %q, i32 %x        ; operand %q is ALSO rotated below
  %qd  = call i32 @cq_phi_si32(i32 %q, double 3.000000e-01)  ; downstream rotation ON %q (channel B)
  %md  = call i32 @cq_measure_si32(i32 %qd)
  %ms  = call i32 @cq_measure_si32(i32 %sel)
  %r   = add i32 %md, %ms
  ret i32 %r
}
