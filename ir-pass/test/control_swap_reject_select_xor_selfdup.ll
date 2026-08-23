; control_swap_reject_select_xor_selfdup.ll — DECLINE (bd 3c6m.67): a
; SELF-OPERAND xor node (`xor i1 %c1, %c1`), the xor member of the family whose
; `or`/`and` twins are pinned by control_swap_reject_select_or_selfdup.ll.
;
; READ THAT FIXTURE'S CORRECTED RATIONALE FIRST (bd big5) AND DO NOT RESTATE THE
; RETRACTED PREMISE HERE. Aliased CONTROLS of an out-of-place gate whose target
; is a fresh |0⟩ rail are CASE A and perfectly realizable; for XOR the network is
; even MORE obviously fine than for or/and — `cnot(c,G); cnot(c,G)` is literally
; the identity, so G stays |0⟩, which is the CORRECT value of `c ⊕ c`. There is
; no unrealizable gate and no defect.
;
; THE FENCE IS KEPT ANYWAY, as a SCOPED conservative decline (Prime Directive),
; and it costs nothing: InstCombine folds `x ⊕ x` to `false`, so the shape is
; unreachable from -O1 C, and rail aliasing cannot mint it either (every leaf
; mints its OWN fresh flag rail — control_swap_accept_select_and_aliased_leaf.ll
; composes exactly that and still gets three distinct rails). It also falls out
; of the existing code rather than being added: `collectCondTree`'s self-operand
; test sits AFTER the opcode check, so admitting Xor to that check inherits the
; fence with no new line. Widening it would buy nothing measurable while adding
; an unprobed accept path.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_cnot
; CHECK-NOT: cq_template_icmp
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c   = xor i1 %c1, %c1                   ; self-operand node
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
