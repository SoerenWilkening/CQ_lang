; R13 ATTACK: mismatched param/return type with an undef operand. (1a) would RAUW
; to a zero of the RETURN type and never reach the type guard below it.
declare i64 @cq_measure_si32(i32)
define i64 @f() {
  %m = call i64 @cq_measure_si32(i32 undef)
  ret i64 %m
}
