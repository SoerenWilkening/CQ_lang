; control_classical_call_arm_accept_onward_ctl_phase.ll — ACCEPT (yn71, Phase 4×6,
; the CONTROL case): a 6.5 classical-call arm whose UNTAINTED merge `%out` feeds a
; NEW TAINTED-condition diamond that applies a phase — `int y = 5; if (q>3) y = f(a);
; if (y > 7) y = cq_phi(y, .25); measure y`. The downstream `if (y > 7)` is a
; genuinely quantum-CONTROLLED branch (its condition `icmp sgt %out, 7` is a `%out`
; derivation — quantum data used as further quantum control), which dugh over-declined
; (`control flow under quantum control`) and yn71 now LOWERS as a routed phase arm.
;
; This is the TAINTED-condition twin of control_classical_call_arm_accept_onward_phase
; _downstream_if.ll (which has a CLASSICAL `i1 %cc` condition, lowered UNCONTROLLED via
; the 5j5 one-register lift). Here the condition is tainted, so
; `repropagateControlMerges` RE-DETECTS the diamond (`detectAndLowerOnwardControl`) and
; `SwapRouteEmit` emits the coherent CONTROL-IN-PLACE phase stream ON `%out`: mint the
; flag from `icmp(%out, 7)`, apply ONE `cqrt_rz_i32_controlled(flag, %out, θ)` — no work
; rail, no `cqrt_cswap` either way — then `icmp_inv`-strip + free the flag (%out == %out0
; because a controlled Rz is diagonal on BOTH branches of the flag, so the strip is
; valid). The measure reads `%out`.
;
; ⚠ THIS PARAGRAPH USED TO DESCRIBE THE ROUTE ("route into a |0> rail via `cqrt_cswap`
; … zero controlled Rz") and said so NINE LINES ABOVE this file's own
; own assertion of `call void @cqrt_rz_i32_controlled`. The FLAT phase path has lowered in
; place since bd drbq Inc 2a (2026-09-02); the 4.3 nest and the 4.5 switch keep the
; route. Corrected in the Inc-2a round-1 review (L3 F3).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_reject_partial_callee.ll (a VISIBLE partial body,
; also declined). Nothing else in this fixture changes; the body is inert.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]          ; UNTAINTED ccarm merge -> %out
  %c2 = icmp sgt i32 %y, 7                            ; tainted only AFTER the re-seed
  br i1 %c2, label %ph, label %m2                     ; NEW tainted control on %out
ph:
  call void @cq_phi(double 0.25)  ; ONWARD controlled phase on %out
  br label %m2
m2:
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; The ccarm builds %out (2 controlled copies), then the onward phase arm rotates
; %out IN PLACE under a flag minted from icmp(%out, 7) — the flag operand and the
; rotated register are BOTH %out (the merge, not the original %q handle). Since
; drbq Inc 2a that arm is one `cqrt_rz_i32_controlled` where it was the five-line
; swap route; the 6.5 classical-call arm above it is untouched.
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[OUT]], double 2.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; No surviving merge phi over the handle, no tainted branch, no swap route left
; on the onward region, and the region ACCEPTS:
; CHECK-NOT: phi i32
; CHECK-NOT: cqrt_cswap
; ACC-NOT: under quantum control
