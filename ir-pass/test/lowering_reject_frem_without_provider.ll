; LLVM frem has no approved hardware route or Bennett.jl implementation.
; A tainted remainder is a compiler gap until exact source lifting works;
; it must fail loudly rather than minting a trace-only cq_template_frem call.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @fmod_quantum_quantum(double %x, double %y) {
entry:
  %qx = call double @cq_theta_f64(double %x, double 5.000000e-01)
  %qy = call double @cq_theta_f64(double %y, double 5.000000e-01)
  %r = frem double %qx, %qy
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}no template for opcode 'frem double' in tainted context
; CHECK-NOT: cq_template_frem
