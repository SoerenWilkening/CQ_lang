; lowering_reject_volatile_scalar_array.ll — DECLINE PIN (bd zco4): the volatile
; scalar-local SSA promotion must NOT fire for an ARRAY / aggregate alloca — a
; tainted-index array is the Shadow / MUX-EXCH domain, and a whole-aggregate
; promotion is out of the scalar accumulator's scope (Gate 1: the allocated type
; must be an integer/fp SCALAR). Left untouched, the tainted store into the array
; slot rides the existing loud decline. If the promotion over-fired here, the
; store would vanish and the module would compile — this test would then fail.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %z = alloca [2 x double], align 16
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %g0 = getelementptr inbounds [2 x double], ptr %z, i64 0, i64 0
  store volatile double %q, ptr %g0, align 8
  %v = load volatile double, ptr %g0, align 8
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
