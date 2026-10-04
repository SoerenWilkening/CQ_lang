; control_phase_kickback_reject_bare_i1_loop_phi.ll — DECLINE (bd 3qlq.4): the
; LOOP-CARRIED `_Bool` — `for (…) { if (b) cq_phi(θ); cq_theta(&b, φ); }` —
; whose condition at the header is the rail PHI, not a `cq_theta_i1` call. It is
; the same physical rail after the round-2 collapse claims the phi, so the gate
; would belong on it; admitting the phi means asking `railPhiRootMint` (the drbq
; Inc-3 (b′) clause) and re-running the C-1 in-loop family — a follow-on with its
; own budget, not a widening of this increment. The INVARIANT-register loop
; (`..._rail_inloop_invariant.ll`) accepts; this is the residual beside it.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br label %header
header:
  %i = phi i32 [ 0, %entry ], [ %inc, %latch ]
  %b = phi i1 [ %b0, %entry ], [ %b2, %latch ]
  br i1 %b, label %arm, label %latch
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %latch
latch:
  %b2 = call i1 @cq_theta_i1(i1 %b, double 2.000000e-01)
  %inc = add nuw nsw i32 %i, 1
  %ex = icmp eq i32 %inc, 3
  br i1 %ex, label %exit, label %header
exit:
  %m = call i1 @cq_measure_i1(i1 %b2)
  ret i1 %m
}

; CHECK: cq controlled lowering: branch phase on a bare i1 condition under quantum control
