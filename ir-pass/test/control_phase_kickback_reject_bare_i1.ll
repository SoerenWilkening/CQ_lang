; control_phase_kickback_reject_bare_i1.ll — DECLINE. A BARE TAINTED `i1`
; CONDITION, with no compare to mint a flag from (PRD §6.3 row 3; filed as
; INCREMENT 1b, owner question Q4's assumed answer).
;
;     _Bool b = cq_theta(b0, θ); if (b) cq_phi(θ);
;
; THIS IS AN OVER-DECLINE WITH A KNOWN CORRECT LOWERING, which is exactly why it
; gets its own message instead of riding the generic `control flow` one: `b` IS
; already the flag. The phase belongs directly on `b`'s own rail — no mint, no
; strip, no free, ONE gate — and the whole kickback derivation of §3 is the
; identity there. Building it means teaching the emitter a second, mint-free
; path, and Increment 1's accept class is the minted one.
;
; DO NOT "FIX" THIS BY WIDENING THE COMPARE CLAUSE: without a compare there is
; nothing for `lowerCompareToFlag` to mint from, so an accept here would either
; fabricate a flag or fire the gate on the wrong rail.
;
; ⚠ THAT SENTENCE USED TO CONTINUE "…and the same clause owns the COMPOUND
; `select i1` condition, which is P3/P4 and a SEPARATE increment". IT NO LONGER
; DOES, and correcting it here rather than deleting it is the point: part B
; SHIPPED P3, so `if (q == 5 && r == 3) cq_phi(θ)` — a `select i1 %a, i1 %b,
; i1 false` branch condition — now ACCEPTS and lowers through the shared
; condition NETWORK (`control_phase_kickback_and2.ll`). What still reaches this
; message is a root that is neither a compare nor a decomposable node: a bare
; tainted `i1` as here, a `trunc`/`freeze`/phi, or one of the two NOT-carrying
; logical-select complements (`control_phase_kickback_reject_tree_notform.ll`).
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  ret i1 %m
}

; CHECK: cq controlled lowering: branch phase on a bare i1 condition under quantum control
