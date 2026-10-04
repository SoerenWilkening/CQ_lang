; control_phase_kickback_reject_mergephi_value_arm.ll — DECLINE (bd `3qps`,
; Track P). GREEN ON BOTH BINARIES, and the header says exactly what it pins so
; it cannot rot into a claim about a subject it does not have (Rule 12(c)).
;
; THE SHAPE: `bool r = ...; cq_theta(&r, ...); if (b0) r = !r; if (r) cq_phi(φ);` — the
; merge φ of a VALUE arm, not of an `InPlaceRotation` one, feeding the kickback.
;
; WHAT IT ACTUALLY PINS. The decline fires at the VALUE region itself, BEFORE the
; kickback's step 5c is ever reached: block order puts the prep-shaped diamond's
; `br` first, `classifyArms` reaches the `fg9k` value-arm-on-a-rail-condition
; refusal, and `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`),
; so one module yields exactly one diagnostic. The string is therefore
; `bare i1 register condition` — the VALUE arm's, not the kickback's.
;
; ⚠ SO THIS IS NOT THE PIN FOR RUNG 0's CLASS CONJUNCT, and pretending otherwise
; is how a fixture ends up pinning nothing. That conjunct
; (`ClassArm == InPlaceRotation`) is pinned by
; `control_swap_reject_select_mergephi_{other_class,value_region}.ll` at the 4.4
; select — and because bd `3qps` made `preppedRailPhiRegionIdx` ONE SHARED
; SPELLING rather than a second copy (Rule 14), those files pin the predicate for
; BOTH consumers. A kickback-side twin is not constructible in a single module:
; any region that reaches a non-`InPlaceRotation` verdict declines at that region
; first.
;
; What this file DOES pin is the Rule-1 property that matters here: there is no
; third path. A φ whose region is claimed as something else never silently
; reaches the phase emitter — the module stops, loudly, with `opt` exit non-zero.
;
; ⚠ RETIREMENT TRIGGER: when bd `fg9k` lands (the value arm on a bare rail
; condition), this module's FIRST diagnostic changes or disappears. Re-derive the
; string from the binary then; if it becomes an accept, this file must be
; re-pointed at whatever then declines first, not deleted.

; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %r = call i1 @cq_theta_i1(i1 false, double 7.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %x = xor i1 %r, true
  br label %merge
merge:
  %b1 = phi i1 [ %x, %arm ], [ %r, %entry ]
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK: cq controlled lowering: bare i1 register condition under quantum control
