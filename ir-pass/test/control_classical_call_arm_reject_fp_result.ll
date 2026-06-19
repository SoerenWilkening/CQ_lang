; control_classical_call_arm_reject_fp_result.ll — fp-result reject (DD-7 /
; WI-5.5, the f64 trap): a PURE classical call inside a tainted-condition diamond
; arm whose result is FLOATING-POINT. The merge `φ` is then `double`, which has a
; VALID `abiWidthFromType` ("f64") yet NO `cqrt_copy_<W>_controlled` — an fp value
; under tainted control is categorically a rotation ANGLE, never routable data
; (the f64 silent-miscompile family). `classifyClassicalCallArm` ACCEPTS the
; structural shape (pure, all-classical-args), and the EMITTER then gates on
; `copyControlledFn` NON-NULL — the integer-only guard — declining loudly BEFORE
; any mutation. The gate is on `copyControlledFn`, NOT on `abiWidthFromType`
; non-empty (keying on the latter is the f64 trap). NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @fp_f(double) #0

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp ogt double %q, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %r = call double @fp_f(double 7.000000e+00)   ; PURE but fp result — angle, not data
  br label %merge
merge:
  %y = phi double [ %r, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}

attributes #0 = { nounwind willreturn memory(none) }
