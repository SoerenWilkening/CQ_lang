; control_phase_kickback_reject_bare_i1_trunc.ll — DECLINE (bd 3qlq.4), and the
; file that keeps `branch phase on a bare i1 condition` a DISCRIMINATOR now that
; the `_Bool` register shape accepts: a tainted `i1` that is NOT a register —
; here `trunc i32 %q to i1`, a DERIVED rail that `CastLowering` would mint as a
; fresh copy and that would need a mint+discharge design (a flag pattern with a
; different mint) rather than a gate on the user's rail. `isCondRailLeaf` is
; deliberately `cq_theta_i1`-only; a `zext`/`sext`, a `phi`, a template result,
; a clone `Argument` and a QRAM load keep this string for the same reason.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %t = trunc i32 %q to i1
  br i1 %t, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %n = call i32 @cq_measure_si32(i32 %q)
  ret i32 %n
}

; CHECK: cq controlled lowering: branch phase on a bare i1 condition under quantum control
