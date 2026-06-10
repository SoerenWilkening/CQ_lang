; control_swap_reject_stalecond_sunk_compare.ll — DECLINE: the chained-Ry
; stale-condition shape with the compare SCHEDULED BELOW the chained theta.
;
; SSA-identical to control_swap_reject_stalecond_chained_theta.ll — `%c` still
; reads the PRE-Ry value `%q` — but the pure `icmp` sits AFTER the chained
; `cq_theta` in the block. That is legal LLVM scheduling (Rule 9: never assume
; instruction order; opaque cq_* calls keep their order, pure instructions do
; not), and it evaded the original POSITIONAL guard, which scanned only the
; instructions between the compare and the branch: the pass ACCEPTED this
; layout and emitted the mint after `cqrt_ry(h, t2)` — byte-for-byte the
; wrong-arm unitary of the laid-out sibling fixture (verify-clean, clean flag,
; stream-vs-source fidelity cos^2(t2/2) = 0.848; investigation oracle
; investigation_mint_at_compare.py probe P2, confirmed against the in-tree
; pass 2026-06-10). The guard now also walks the condition's WIRE by SSA
; identity — seeded from the condition's full tainted backward PROVENANCE
; (condProvenance), not just the compare's direct operands — so a
; tainted-operand cq_theta user on the wire declines regardless of where the
; compare was scheduled (and regardless of pure arithmetic between the wire
; and the compare: control_swap_reject_stalecond_derived_cond.ll).
; Design-of-record:
; docs/design/rssa-swap-control/MINT_AT_COMPARE.md §4 (the decline is
; permanent — no flag-freeing compilation of this shape is source-exact).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %t2, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry on the wire
  %c = icmp sgt i32 %q, 5                             ; SUNK compare, STALE operand %q
  br i1 %c, label %arm, label %merge
arm:
  %q3 = call i32 @cq_phi_si32(i32 %q2, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q3, %arm ], [ %q2, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
