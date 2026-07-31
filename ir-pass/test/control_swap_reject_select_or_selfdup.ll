; control_swap_reject_select_or_selfdup.ll — DECLINE (3c6m.12 design-review
; MAJOR): a SELF-OPERAND node (`or i1 %c, %c`; the `and` twin is identical).
; Per-Value flag memoization would resolve BOTH controls of the node's
; `cqrt_toffoli` to ONE rail.
;
; *** RATIONALE CORRECTED 2026-07-31 (bd big5). *** This header used to say that
; is "an ill-formed physical 3-qubit gate (duplicated control wire) that no
; backend can realize". THAT PREMISE IS FALSE, by owner ruling — the same refuted
; claim bd big5 removed from three other sites, and leaving it here would be the
; exact propagation mechanism that issue exists to stop. Aliased CONTROLS of an
; out-of-place gate whose TARGET is a fresh |0> rail are CASE A: `toffoli(c,c,G)`
; is simply `cnot(c,G)` (AND of x with itself is x). The network as written is
; already alias-correct too — the OR node is `cnot(L,G); cnot(Rv,G);
; toffoli(L,Rv,G)` (XOR-XOR-AND), NOT an X-bracketed De Morgan, so with L == Rv
; it yields G = c for both `and` and `or`, and the §5 reverse strip returns G to
; |0> exactly. There is no defect here and no unrealizable gate.
;
; THE FENCE IS KEPT ANYWAY, as a SCOPED conservative decline (Prime Directive) of
; a shape reachable from NEITHER -O1 C (InstCombine folds x∨x / x∧x to x) NOR
; rail aliasing (every leaf mints its OWN fresh flag rail, so two distinct leaves
; are never one rail — pinned by
; control_swap_accept_select_and_aliased_leaf.ll). Widening it would buy nothing
; measurable while adding an unprobed accept path. Contrast the LEAF axis, which
; WAS reachable from four lines of plain C and is now accepted — see
; control_swap_accept_select_rail_alias_cond.ll and the corrected rationale at
; the `collectCondTree` node fence in SelectClassify.cpp. NOTE (Rule-13
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
