; A signed quantum index into memory of unknown extent: t[i] with i < 0 is legal C, and the QROM's
; unsigned index would read 0 there. Not built: an internal error.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @sext_param(i32 %x0, double %t, ptr %p) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %s = sext i32 %x to i64
  %e = getelementptr inbounds i32, ptr %p, i64 %s
  %v = load i32, ptr %e, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; EXPECT-ERROR: cq: unimplemented: mem-qrom: a sign-extended quantum index into memory of unknown extent
