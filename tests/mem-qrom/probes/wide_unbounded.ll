; A 64-bit quantum index into memory of unknown extent with no range fact: 2^64 entries do not fit the
; i64 length operand. Not built: an internal error.
declare i64 @cq_theta_ull(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @wide_unbounded(i64 %x0, double %t, ptr %p) {
  %x = call i64 @cq_theta_ull(i64 %x0, double %t)
  %e = getelementptr inbounds i32, ptr %p, i64 %x
  %v = load i32, ptr %e, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; EXPECT-ERROR: cq: unimplemented: mem-qrom: a QROM of 2^64 or more entries
