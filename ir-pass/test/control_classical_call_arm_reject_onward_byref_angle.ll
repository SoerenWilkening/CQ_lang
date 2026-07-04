; control_classical_call_arm_reject_onward_byref_angle.ll — DECLINE (bd 0vvq
; Increment 1, the adversarial angle partition): a 6.5 classical-call arm whose
; UNTAINTED merge `%out` feeds an onward `frexp`, and the MANTISSA result (fp) is then
; used as the ROTATION ANGLE (arg 1) of a `cq_phi`.
;
; 0vvq re-runs g387 and lowers the `frexp` to `@cq_byref_*` markers (correct — the
; mantissa is a reversible producer). But a QUANTUM-DERIVED value driving a rotation
; ANGLE is the project-wide fp-angle limitation: `declineTaintedAngle` (RotationLowering)
; declines it loudly. This pins that the by-ref UNFREEZE does NOT launder a
; quantum-derived mantissa into a rotation angle (the angle fence is downstream of the
; marker and producer-agnostic — bd [fp-angle-fence-ordering-invariant]). NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}unsupported quantum-derived rotation angle
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_phi_si32(i32, double)
declare i32 @f(i32) #0
declare double @frexp(double, ptr)
define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %u = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %ecell = alloca i32
  %d = sitofp i32 %y to double
  %fr = call double @frexp(double %d, ptr %ecell)   ; mantissa (fp), quantum-derived
  %p = call i32 @cq_phi_si32(i32 %u, double %fr)     ; mantissa used as ROTATION ANGLE
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
