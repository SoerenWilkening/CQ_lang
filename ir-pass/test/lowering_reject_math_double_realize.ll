; lowering_reject_math_double_realize.ll
;
; The fmul result has both data and angle uses. Sharing that basis value is valid coherent control.
;
; Known lowering gap: coherent quantum-derived angles (NORTHSTAR goal 1; bd 94ad).
; The current gate ABI takes a classical double angle. Passing a quantum handle
; into that slot would miscompile the program, so this test pins the loud fence.
; An angle register and bit-controlled rotation ladder can implement the operation;
; its absence is a compiler gap, not a no-unitary proof. Never insert a measure.
; Retire this negative when that lowering preserves the data and angle semantics
; and has analytic and trace evidence for this consumer.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r   = fmul double %q, %q                       ; TAINTED fp-DATA, realized two ways
  %d   = fadd double %r, %r                        ; (1) genuine DATA use
  call void @cq_phi(double %r)  ; (2) ALSO the arg-1 ANGLE
  %m1  = call double @cq_measure_f64(double %q)
  %m2  = call double @cq_measure_f64(double %d)
  %s   = fadd double %m1, %m2
  ret double %s
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; Declined whole construct, before lowerOps — neither the fmul nor the fadd is lowered:
; CHECK-NOT: cq_template_fmul
; CHECK-NOT: cq_template_fadd
; CHECK-NOT: cqrt_rz
