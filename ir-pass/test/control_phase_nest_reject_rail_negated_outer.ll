; control_phase_nest_reject_rail_negated_outer.ll — DECLINE (bd 3qlq.4): the
; depth-2 nest whose OUTER level is a bare rail with the arm on the FALSE
; successor (`if (!b) { cq_phi; if (q==5) cq_phi; }`). The outer arm's own
; phases could ride `rz(h, −θ)`, but the conjunction ancilla `g = ¬b ∧ f`
; realizes a negated control by `cqrt_x`-BRACKETING that control, and this
; increment's invariant is that no non-diagonal gate is ever emitted on a user's
; register. `Toff(¬a,b,g) = CNOT(b,g)·Toff(a,b,g)` would lift it with no gate on
; `a` — filed, not built. Refused by the classifier AND re-asked by the emitter
; before its first emission.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i32 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %b, label %merge, label %mid
mid:
  call void @cq_phi(double 2.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %inner, label %merge
inner:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %n = call i32 @cq_measure_si32(i32 %q)
  %r = add i32 %n, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: branch phase on a bare i1 condition under quantum control
