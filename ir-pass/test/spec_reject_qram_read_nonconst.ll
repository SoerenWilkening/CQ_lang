; spec_reject_qram_read_nonconst.ll — bd 20xt.4 Inc 1 (over-accept probe): a
; tainted-index read of a NON-const global inside a spec-clone body is NOT a QROM
; table — its contents may differ between the analysed module and the linked/run
; program, so the read is not a reproducible immutable lookup. `qromReadShapeInScope`
; requires `isConstant()` (the SAME gate `matchQramAccess` applies at the emitter),
; so the read's address gep is NOT admitted and `scanBody` keeps the loud
; non-reversibilizable decline (`@G` differs from `spec_accept_qram_read.ll`'s
; `constant @T` ONLY in the `global` vs `constant` keyword). `opt` exits non-zero.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

@G = internal unnamed_addr global [4 x double] [double 1.500000e+00, double 2.500000e+00, double 3.500000e+00, double 4.500000e+00], align 16

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define internal double @lookup(double %x) {
  %i = fptosi double %x to i32
  %m = and i32 %i, 3
  %idx = zext i32 %m to i64
  %p = getelementptr inbounds [4 x double], ptr @G, i64 0, i64 %idx
  %v = load double, ptr %p, align 8
  %r = fadd double %v, %x
  ret double %r
}

define double @example(double %u) {
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @lookup(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction)
