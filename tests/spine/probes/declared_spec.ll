; cq-049b: a rule 27 declared specialization (a callee with no body called with a quantum argument)
; has nothing to construct; calls emits the declared clone at the call site. Taint publishes it after
; its caller, so it is the last specialization and the module epilogue (finishEntries,
; dropDeadSurface) must still run: the entry is lowered in place and the surface declarations go.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ext_q(i32, i32)

define i32 @declared_spec(i32 %x0, double %t, i32 %c) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %r = call i32 @ext_q(i32 %x, i32 %c)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
; CHECK declared_spec: call i32 @__cq_q_ext_q_10(i32 %{{a}}, i32 %{{c}}, i32 4)
; CHECK declared_spec: call i32 @cqrt_measure_i32(
; CHECK-COUNT declared_spec: cq_theta_si32 0
; CHECK-COUNT declared_spec: call i32 @ext_q( 0
