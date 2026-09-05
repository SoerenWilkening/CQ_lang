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
; NOT vacuous: round-1 finding F-L5-6 widened it to consult registers recorded as
; PHASED AT EMISSION rather than by scanning for a `cq_phi` in the lineage, and
; fix_r1 shipped that as "LATENT — unreachable at HEAD, pinned by: none
; reachable". MEASURED here on `build/ir-pass/cq-opt`: it IS reachable, from the
; register-free surface, by the shape below — a KICKBACK arm that also `ret`s the
; register it phased. So the fence keeps a fixture, and fix_r1's "none reachable"
; is corrected by this file rather than by prose.
;
; ⚠ DISCRIMINATOR, measured both ways ($SP/progress/prep_a2_work/pv/):
;   * with the kickback (`pret.ll`, this module):  `phase-class value escaping`
;   * without it (`pret_ctl.ll`, the SAME module minus the one `cq_phi` line):
;     `non-reconverging value exit` — a DIFFERENT clause. The phase is what
;     selects this message, not the non-reconverging exit it rides on.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: phase-class value escaping under quantum control

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
