; lead 7 — a type where Constant::getNullValue is not the obvious value.
; Three reserved-name thetas with an undef seed at a VECTOR, an i128 and a
; POINTER type.  `declMatchesPrototype` should adjudicate before the rewrite;
; nothing here may be normalized into a `zeroinitializer`/`null` gate operand.
declare <2 x double> @cq_theta_f64(<2 x double>, double)
declare <2 x double> @cq_measure_f64(<2 x double>)
define <2 x double> @example() {
  %q = call <2 x double> @cq_theta_f64(<2 x double> undef, double 5.000000e-01)
  %m = call <2 x double> @cq_measure_f64(<2 x double> %q)
  ret <2 x double> %m
}
