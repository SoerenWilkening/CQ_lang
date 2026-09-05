; control_phase_kickback_reject_multiblock_arm.ll — DECLINE. A MULTI-BLOCK ARM:
; the `cq_phi` sits under a CLASSICAL branch nested inside the tainted arm
; (PRD §6.3 row 5).
;
; The region's flag is `q == 5`, but the gate fires only when `q == 5` AND the
; classical `cc == 0`. A kickback emits ONE gate on ONE flag, so accepting this
; would put the phase on the branch `q == 5` — a DIFFERENT unitary, on every run
; where `cc != 0`. There is a correct lowering (mint the conjunction, which is
; what P3's `cqrt_toffoli` node does for two TAINTED leaves) but it is not this
; increment's, and a classical conjunct is not even a leaf P3 recognizes.
;
; The classifier refuses it structurally rather than by reasoning about the inner
; branch: the arm block must be exactly `{ N × cq_phi, br }`, and this one's
; terminator is a CONDITIONAL br with no phase call in it at all.
;
; ⚠ THIS FIXTURE IS ALSO PRD §10.3 LENS 4 — P7's BOUNDARY — and that is a second,
; independent assertion, not a restatement. P7 DELETES every surviving
; `call void @cq_phi` after control lowering (owner decision D2: an uncontrolled
; or classically-controlled branch phase is a global phase). Its soundness is
; Rule 1's "there is no third path": by the time `deleteGlobalPhases` runs,
; `detectControlRegions` has CLAIMED or DECLINED every tainted `br`, so a survivor
; sits under CLASSICAL control only.
;
; The `not`-wrapped run line here is what refutes the failure mode. This module's `cq_phi` sits
; in a TAINTED arm of a DECLINED region. If P7 ran too early — or its walk missed
; the tainted branch above the call — the call would simply VANISH and this module
; would compile at exit 0 with the phase silently dropped: a wrong unitary,
; verify-clean, with no diagnostic anywhere. `not` requires exit NON-ZERO, and the
; CHECK requires it to be the CONTROL decline rather than P7's own
; `unclaimed branch phase` assert, so the ordering is pinned from both sides.
; (Prose above deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
;
; ⚠ THE `unclaimed branch phase` BRANCH IS UNREACHED BY THE WHOLE CORPUS, AND
; SAYING SO IS THE POINT (Rule-13 round-1 finding F-L8-3). That string has NO
; fixture — three files, this one among them, mention it in PROSE and none
; exercises it. It is Rule 1's assert inside `deleteGlobalPhases`: a surviving
; `cq_phi` whose block is reachable through a TAINTED branch condition. Lens L3
; probed 90+ shapes and could not reach it, for a structural reason worth
; carrying: every region kind that CLAIMS a tainted `br` also REMOVES it (the
; flatten, the abort park's `br label`, the loop lowering's bound), and every
; kind that declines exits `opt` at its first `DS_Error` — so on every reachable
; program state there is no tainted `br` left to find. Constructing a module that
; reaches it would itself be a third-path finding, not a fixture.
; The assert is nonetheless KEPT and is now correctly POSITIONED (F-L3-1 moved
; `deleteGlobalPhases` after the round-2 control fixpoint, which is where its
; premise is true), because the hazard it was written for is real: at the old
; position it could not see an ONWARD region's tainted branch at all, and that
; was the round's second CONFIRMED miscompile.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@cc = external global i32

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %cv = load volatile i32, ptr @cc, align 4
  %cc2 = icmp eq i32 %cv, 0
  br i1 %cc2, label %inner, label %armtail
inner:
  call void @cq_phi(double 9.000000e-01)
  br label %armtail
armtail:
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
