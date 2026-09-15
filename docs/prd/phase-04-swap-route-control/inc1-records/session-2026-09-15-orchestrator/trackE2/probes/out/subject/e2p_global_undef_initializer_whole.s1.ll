; E2 obligation (b): the global's initializer is itself a WHOLE undef.
@u = global i32 undef
declare i32 @cq_measure_si32(i32)
define i32 @whole() {
entry:
  %m = call i32 @cq_measure_si32(i32 ptrtoint (ptr @u to i32))
  ret i32 %m
}
