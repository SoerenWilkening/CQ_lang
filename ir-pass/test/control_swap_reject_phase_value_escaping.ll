; control_swap_reject_phase_value_escaping.ll — Phase 7.2 Inc 4 DECLINE: a
; tainted-condition `br` whose one exit `ret`s a PHASE-CLASS value (an `Rz` /
; `cq_phi` lineage). Returning a relative phase down a non-reconverging value exit
; is the §2.6 deferred park-coherence interaction: a data-copy of a phase is the
; Rule-7 dephasing leak (P0 0.585 → 0.500, a CNOT copies a basis label, not the
; phase). Conservatively DECLINED with the dedicated `phase-class value escaping`
; diagnostic (§2.11-C-iii), the SAME string `classifyAbortPark` fires for a phase
; sibling beside a recognized abort sink — here the sink is a plain value exit, so
; the OffPattern partition owns it.
;
; The phase check is gated on the ret operand being TAINTED, so a MEASURED return
; (`ret %m`, `%m = cq_measure …`, phase already collapsed) does NOT trip it — that
; is why control_swap_reject_nested_switch.ll's `ret`-of-measure arm stays generic.
; %p below is a raw `cq_phi` result (tainted, never measured), so it does.
;
;
; ===========================================================================
; 3qlq(prep_a2): HAND DECISION — RE-SPELLED. This fixture's construct was built
; on `%p = cq_phi_<sfx>(%q, θ)`: a value that CARRIES A RELATIVE PHASE. D1
; retires that idea outright — under the register-free surface a phase attaches
; to a BRANCH, never to a value — so the old module cannot be migrated, only
; re-spelled onto whatever of the property survives, or retired.
;
; WHAT SURVIVES, AND IT IS MORE THAN PREP_A EXPECTED. The phase-carrier fence is
; NOT vacuous: round-1 finding F-L5-6 widened it to
; `functionCarriesBranchPhase(F, taint)` — "is there a branch phase in F that is
; CONTROL-DEPENDENT on a tainted branch" — rather than scanning for a `cq_phi` in
; the value's own lineage, which the register-free surface had made unanswerable
; (the gate lands on a flag ancilla the register does not derive from).
;
; ⚠ SAY THE REACHABILITY CLAIM EXACTLY. fix_r1's table recorded this fence as
; "pinned by: none reachable" and its notes as "LATENT at this HEAD — no plain-C
; program reaches any of the three (each is held shut by an earlier shape
; fence)". This file corrects the FIRST of those and NOT the second: the fence is
; now PINNED, by the hand-written IR below, measured on `build/ir-pass/cq-opt`.
; It says NOTHING about plain-C reachability, which was not re-measured here and
; must not be inferred from a lit fixture.
;
; ⚠ DISCRIMINATOR, measured both ways ($SP/progress/prep_a2_work/pv/):
;   * with the kickback (`pret.ll`, this module):  `phase-class value escaping`
;   * without it (`pret_ctl.ll`, the SAME module minus the one `cq_phi` line):
;     `non-reconverging value exit` — a DIFFERENT clause. The phase is what
;     selects this message, not the non-reconverging exit it rides on.
;
; ===========================================================================
; RE-DERIVED by bd test_C_libtooling-dm7f.5 — the message above is HISTORY for this
; module. dm7f.5 merges the two `ret`s before detection (`unifyTaintedReturns`,
; ReturnMerge.cpp), so this module is now, up to names, the CFG `clang -O1` emits for
;     int example(int u0) { int q = u0; cq_theta(&q, .5);
;                           if (q > 5) { cq_phi(.7); return q; } return cq_measure(q); }
; (one `ret` of a φ of `%q` and the measured `%m`), and it declines with that twin's
; message, `impure phase arm` (measured on main 7b4e6359 from the C source above;
; the `cq_measure` sits in the region's other arm). It stays a decline for a reason
; that matters: the user's measurement runs only on the q <= 5 branches, a
; measurement UNDER quantum control, which no emitter may hoist or drop. This is the
; decline twin that keeps a normalized multi-exit with a measuring arm loud.
; The `phase-class value escaping` fence is NOT unpinned by the change: its
; population is now single-`ret` modules whose region merge has an outside
; predecessor, pinned by control_swap_reject_phase_value_escaping_outside_pred.ll.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: impure phase arm under quantum control

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)   ; the branch phase — %q is now PHASED
  ret i32 %q                               ; ... and escapes down a value exit
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
