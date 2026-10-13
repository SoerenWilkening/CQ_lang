; control_swap_reject_stalecond_derived_cond.ll — DECLINE since bd test_C_libtooling-57ch.3 (batch 053;
; the diagnostic changed: the stale read is placed, a different hazard remains).
;
; The stale `add` is now PLACED (57ch.3) before `%q2`. What still declines is the
; condition wire: the derived condition's register relabels under `%q2` before the
; kickback consumes it (`2c`). The read-first twin (the `add` written before `%q2`,
; batch-053 L3 probe) declines with the same string on the pre-053 binary.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
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
; 2026-06-10). TWO independent guards now decline this module, in pass order:
;   1. the PASS-WIDE straight-line stale-record guard
;      (OpcodeLowering::declineStaleRecordOps, test_C_libtooling-uzb) fires
;      FIRST — `%d` itself is a stale pure producer scheduled after the
;      chained Ry, branch or no branch — and opt exits at the first
;      diagnostic, so its message is the one this fixture pins;
;   2. behind it, ArmClassify's provenance-seeded wire walk
;      (condProvenance + WireWalk, the test_C_libtooling-ee5 hardening)
;      still declines the REGION for layouts where no in-scope pure op is
;      itself stale — pinned by the sibling fixture
;      control_swap_reject_stalecond_derived_cond_preadd.ll (add scheduled
;      BEFORE the chained theta: guard 1 is silent there, the region declines
;      with "condition predates a non-diagonal gate under quantum control").
; Design-of-record:
; docs/design/rssa-swap-control/MINT_AT_COMPARE.md §4 (the decline is
; permanent — no flag-freeing compilation of this shape is source-exact).
;
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %t2, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry on the wire
  %d = add i32 %q, 1                                  ; stale %q, hidden behind the add
  %c = icmp sgt i32 %d, 5                             ; DERIVED condition
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}
