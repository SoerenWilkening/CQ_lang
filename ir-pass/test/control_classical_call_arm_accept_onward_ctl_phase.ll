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
; `SwapRouteEmit` emits the coherent routed phase stream ON `%out`: mint the flag from
; `icmp(%out, 7)`, route `%out` into a |0> rail via `cqrt_cswap`, apply the VERBATIM
; uncontrolled `cqrt_rz` on the rail, route back, free the rail, `icmp_inv`-strip +
; free the flag (%out == %out0 under Rz, so the strip is valid — zero controlled Rz).
; The measure reads `%out`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0
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
  %p = call i32 @cq_phi_si32(i32 %y, double 0.25)     ; ONWARD controlled phase on %out
  br label %m2
m2:
  %pp = phi i32 [ %p, %ph ], [ %y, %merge ]
  %m = call i32 @cq_measure_si32(i32 %pp)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; The ccarm builds %out (2 controlled copies), then the onward controlled phase arm
; routes %out through a |0> rail under a flag minted from icmp(%out, 7) — the flag
; operand and the routed register are BOTH %out (the merge, not the original %q handle):
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT]], i32 7)
; CHECK:     %[[RAIL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[OUT]], i32 %[[RAIL]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[RAIL]], double 2.500000e-01)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[OUT]], i32 %[[RAIL]])
; CHECK:     call void @cqrt_free(i32 %[[RAIL]])
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[OUT]], i32 7)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; No surviving merge phi over the handle, no tainted branch, and the onward Rz is
; UNCONTROLLED (routed, zero controlled gates — the phase-arm mechanic), and the
; region ACCEPTS:
; CHECK-NOT: phi i32
; CHECK-NOT: cqrt_rz{{.*}}_controlled
; ACC-NOT: under quantum control
