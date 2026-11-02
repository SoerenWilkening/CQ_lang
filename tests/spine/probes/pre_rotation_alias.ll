; cq-29ej (cq-s32y, CR rule 2): another value bound to the rail a cq_theta rotates in place (a freeze of
; the operand, rule 3) read after the rotation reads the copy taken just before the Ry, like the operand
; itself (was a stop).
; CHECK alias: call void @cqrt_copy_i32(i32 %{{h}}, i32 %{{c}})
; USERCHECK alias
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @alias(i32 %x0, double %t, double %u) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %y = freeze i32 %x
  %z = call i32 @cq_theta_si32(i32 %x, double %u)
  %my = call i32 @cq_measure_si32(i32 %y)
  %mz = call i32 @cq_measure_si32(i32 %z)
  %r = add i32 %my, %mz
  ret i32 %r
}
