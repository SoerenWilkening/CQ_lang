; control_swap_reject_select_or_selfdup.ll — DECLINE (3c6m.12 design-review
; MAJOR): a SELF-OPERAND node (`or i1 %c, %c`; the `and` twin is identical).
; Per-Value flag memoization would resolve BOTH controls of the node's
; `cqrt_toffoli` to ONE rail — value-correct in trace semantics (g = c) yet an
; ill-formed physical 3-qubit gate (duplicated control wire) that no backend
; can realize, frozen into the golden at exit 0. The shape is non-canonical
; (InstCombine folds x∨x/x∧x to x), so it declines in `collectCondTree` rather
; than acquiring an unprobed peephole (Prime Directive). NOTE (Rule-13
; clearance): the CHECK-NOTs scan only stderr (opt writes no module on a
; nonzero-exit decline) — they pin the diagnostic's cleanliness; the
; no-mutation property lives in the `collectCondTree` detection reject.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: cq_template_icmp
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c   = or i1 %c1, %c1                    ; self-operand node
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
