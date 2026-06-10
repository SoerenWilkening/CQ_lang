; control_swap_reject_stalecond_derived_cond.ll — DECLINE: the chained-Ry
; stale-condition shape with the stale operand HIDDEN behind a pure add (a
; DERIVED condition).
;
; Same wire as control_swap_reject_stalecond_{chained_theta,sunk_compare}.ll —
; the condition's value is a predicate of the PRE-Ry `%q` — but the compare
; reads `%d = add i32 %q, 1`, not `%q` itself, so the stale operand sits one
; pure wire-hop behind the compare. Derived (arithmetic-mediated) conditions
; are an ACCEPTED region shape, and the original wire-walk guard seeded only
; the compare's DIRECT tainted operands (`%d`), never reaching `%q`'s chained
; `cq_theta` user: the pass ACCEPTED this layout and emitted
; `cq_template_add_i32_hl(%h, 1)` AFTER `cqrt_ry(%h, %t2)` while the source
; `%d` denotes the pre-Ry value — the identical wrong-arm/wrong-record unitary
; of the sibling fixtures, verify-clean (confirmed against the pre-fix tree
; 2026-06-10). The guard now seeds the wire-walk from the condition's full
; tainted backward PROVENANCE (condProvenance), so a tainted-operand cq_theta
; user anywhere on the condition's provenance wire declines regardless of how
; many pure ops separate the compare from the wire (Rule 9: position is not
; provenance). Design-of-record:
; docs/design/rssa-swap-control/MINT_AT_COMPARE.md §4 (the decline is
; permanent — no flag-freeing compilation of this shape is source-exact).
; The same stale-record family with NO branch (straight-line
; `d = q + 1; measure(d)` after a chained theta) is outside this guard's
; reach — tracked pass-wide as a separate bug (OpcodeLowering domain).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %t2, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry on the wire
  %d = add i32 %q, 1                                  ; stale %q, hidden behind the add
  %c = icmp sgt i32 %d, 5                             ; DERIVED condition
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
