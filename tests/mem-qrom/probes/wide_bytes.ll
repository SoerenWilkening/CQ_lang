; A byte table at an unbounded 64-bit quantum index into memory of unknown extent: 2^64 cells, no i64
; length and no stride to reduce by. Awaiting the owner's ruling (SPEC_ISSUES, cq-k65d).
declare i64 @cq_theta_ull(i64, double)
declare i8 @cq_measure_ui8(i8)

define i8 @wide_bytes(i64 %x0, double %t, ptr %p) {
  %x = call i64 @cq_theta_ull(i64 %x0, double %t)
  %e = getelementptr inbounds i8, ptr %p, i64 %x
  %v = load i8, ptr %e, align 1
  %m = call i8 @cq_measure_ui8(i8 %v)
  ret i8 %m
}
; EXPECT-ERROR: cq: unimplemented: awaiting owner ruling: SPEC_ISSUES QROM of 2^64 cells
