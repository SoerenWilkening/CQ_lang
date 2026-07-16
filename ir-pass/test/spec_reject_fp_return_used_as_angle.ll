; spec_reject_fp_return_used_as_angle.ll — bd 3c6m.54 ANGLE-SAFETY (Rule 3, the
; f64/angle miscompile family) — THE load-bearing boundary fixture for the lifted
; kmdc R1 gate. An fp-return clone is now admitted (the fp return copies out to an
; i32 handle). If the caller steers that returned handle into a rotation arg-1
; ANGLE, the top-level `declineTaintedAngle` fence catches it: `specialize` marks
; the clone result tainted, and a tainted rotation angle has no fixed unitary
; (angle = f(quantum value), value in superposition). This is the residual the
; kmdc doc anticipated ("even the returned i32 … is caught by taintedAngleGate") —
; now the SOLE fence for fp escaping toward a caller angle, since R1 no longer
; blocks the fp return. Declines LOUDLY (not verify-clean).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @helper(double %x) {
entry:
  %y = fmul double %x, 2.000000e+00
  ret double %y
}

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  ; the clone lowers (fp arg/return admitted); %r is the escaping i32 handle …
  %r = call double @helper(double %q)
  ; … steered into a rotation ANGLE slot — the tainted-angle fence declines.
  %p = call double @cq_phi_f64(double %q, double %r)
  %z = call double @cq_measure_f64(double %p)
  ret double %z
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
