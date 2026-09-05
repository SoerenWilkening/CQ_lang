; spec_reject_fp_arg_used_as_angle.ll — bd 3c6m.54 ANGLE-SAFETY (Rule 3, the
; f64/angle miscompile family). Even though a tainted fp ARG is now admitted, an fp
; value can NEVER reach a rotation arg-1 angle INSIDE a clone: `scanBody` rejects
; every `cq_theta`/`cq_phi` as `QuantumPrimitive`, so a clone body is provably
; rotation-free. Here the callee body uses its fp param as the angle of a
; `cq_phi_f64` — the body therefore CONTAINS a quantum primitive and declines with
; the `QuantumPrimitive` message (NOT `FpAbi`), before any fp arg is ever routed
; toward an angle slot. This proves the three-legged angle fence is structurally
; vacuous inside a clone (its precondition is enforced upstream by the rotation
; rejection).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @helper(double %x) {
entry:
  ; %x (the tainted fp param) used as the arg-1 ANGLE of a rotation — a quantum
  ; primitive in the body, so the whole clone declines QuantumPrimitive.
  call void @cq_phi(double %x)
  ret double 1.000000e+00
}

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r = call double @helper(double %q)
  %z = call double @cq_measure_f64(double %r)
  ret double %z
}

; CHECK: error{{.*}}cq specialization: callee contains a quantum primitive (cq_*); only classical functions are lifted
; CHECK-NOT: floating-point quantum argument or return has no reversible copy
