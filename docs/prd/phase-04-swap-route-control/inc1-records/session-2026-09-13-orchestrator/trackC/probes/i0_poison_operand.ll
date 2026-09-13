declare i32 @cq_measure_si32(i32)
define i32 @p() {
  %m = call i32 @cq_measure_si32(i32 poison)
  ret i32 %m
}
