; A 2-D table read with two quantum indices (120's flattened form): not built, an internal error.
@G = internal constant [2 x [2 x i32]] [[2 x i32] [i32 1, i32 2], [2 x i32] [i32 3, i32 4]]
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @two_indices(i32 %x0, i32 %y0, double %t) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %y = call i32 @cq_theta_ui32(i32 %y0, double %t)
  %a = and i32 %x, 1
  %b = and i32 %y, 1
  %za = zext nneg i32 %a to i64
  %zb = zext nneg i32 %b to i64
  %e = getelementptr inbounds [2 x [2 x i32]], ptr @G, i64 0, i64 %za, i64 %zb
  %v = load i32, ptr %e, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; EXPECT-ERROR: cq: unimplemented: mem-qrom: a QROM address with two quantum indices
