; libm_bind_restore_local_name.ll — bd 3c6m.72, review rounds 2-3: when a call
; bound to a public bundle body ends classical, the restore declares the external
; libm symbol. If a TU's private function already holds that name, the restore
; is skipped: renaming the private function would re-target the module's OTHER
; classical libcalls it captures (bd 3c6m.76, round 3 measured sin(2) changing
; from 3.0 to 0.909297), and a declaration cannot share the name. The call stays
; on the injected body, internalized; the private function is untouched. No C
; program reaches this edge today (round 3).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:     @lib_fp = global ptr @cbrt
; CHECK:     define internal double @cbrt(double %x)
; CHECK:     define internal double @__cq_libm_cbrt(double %x)
; CHECK:     define double @example(double %u0, double %c)
; CHECK:     call double @__cq_libm_cbrt(double %c)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define internal double @cbrt(double %x) {
  %y = fadd double %x, 1.000000e+00
  ret double %y
}
@lib_fp = global ptr @cbrt
define double @__cq_libm_cbrt(double %x) {
  %y = fadd double %x, 2.000000e+00
  ret double %y
}

define double @example(double %u0, double %c) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  %k = call double @__cq_libm_cbrt(double %c)
  %z = fadd double %m, %k
  ret double %z
}
