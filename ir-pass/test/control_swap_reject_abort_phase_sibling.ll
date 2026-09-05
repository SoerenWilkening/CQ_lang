; control_swap_reject_abort_phase_sibling.ll — Phase 7.2 Inc 3 DECLINE probe: a
; PHASE-class value (`%p = cq_phi(q)`, an Rz / relative-phase carrier) escapes via
; the sibling beside the abort park arm (PRD-7.2 §2.6 deferred interaction /
; §2.11-C-iii; the issue's RED->GREEN negative #2).
;
; Whether the §2.8 `cqrt_cswap` park preserves the relative phase on the surviving
; arm's escaping value is NOT yet proven, so `classifyAbortPark` CONSERVATIVELY
; DECLINES `phase-class value escaping` rather than asserting an outcome (a silent
; XOR/route of a phase dephases it — the verify-clean P0 0.585->0.500 family,
; Rule 7). Never silently route it onto the in-place phase-escape path.
;
;
; ===========================================================================
; 3qlq(prep_a2): HAND DECISION — RE-SPELLED. This fixture's construct was built
; on `%p = cq_phi_<sfx>(%q, θ)`: a value that CARRIES A RELATIVE PHASE. D1
; retires that idea outright — under the register-free surface a phase attaches
; to a BRANCH, never to a value — so the old module cannot be migrated, only
; re-spelled onto whatever of the property survives, or retired.
;
; WHAT SURVIVES. Same as its sibling fixture
; `control_swap_reject_phase_value_escaping.ll`: the F-L5-6 phase-carrier fence
; consults registers recorded PHASED AT EMISSION, so a KICKBACK region upstream
; of the abort park phases `%q`, and the park's sibling then escapes it. The
; pre-region `%p = cq_phi(%q, θ)` this file used to carry is a GLOBAL PHASE under
; D2 and would simply be deleted, taking the fixture's subject with it.
;
; ⚠ DISCRIMINATOR, measured both ways ($SP/progress/prep_a2_work/pv/):
;   * with the kickback (`abort.ll`, this module): `phase-class value escaping`
;   * without it (`abort_ctl.ll`, the SAME module minus the one `cq_phi` line):
;     `nested control flow` — a DIFFERENT clause, so the phase is what selects
;     this message.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: phase-class value escaping under quantum control

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %c0 = icmp eq i32 %q, 3
  br i1 %c0, label %ph, label %mid
ph:
  call void @cq_phi(double 2.500000e-01)   ; kickback — %q is PHASED from here on
  br label %mid
mid:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %cont
a:
  call void @abort()
  unreachable
cont:
  %m = call i32 @cq_measure_si32(i32 %q)   ; the phased value escapes in the sibling
  ret i32 %m
}
