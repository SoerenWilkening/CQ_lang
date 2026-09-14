; E2 obligation (b): does a bitcast ConstantExpr of a whole-value undef SURVIVE
; parsing, or does the folder collapse it to `float undef` (making it a member of
; the RETIRED whole-value clause rather than of the residual)?
declare float @cq_measure_f32(float)
define float @bc() {
entry:
  %m = call float @cq_measure_f32(float bitcast (i32 undef to float))
  ret float %m
}
