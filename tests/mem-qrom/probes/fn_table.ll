; A function pointer read at a quantum index from a constant table (97): mem-qrom lowers the load as a
; QROM of callee tags over the derived table @fps.cqtag ([2 x i32] [1, 2]) and binds it to the tag rail;
; the call through it is rule 19's dispatch (calls), not built yet: the expected stop is there, past the load.
@fps = internal unnamed_addr constant [2 x ptr] [ptr @dbl, ptr @sq], align 16
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @dbl(i32 %v) {
  %r = shl nsw i32 %v, 1
  ret i32 %r
}
define internal i32 @sq(i32 %v) {
  %r = mul nsw i32 %v, %v
  ret i32 %r
}
define i32 @fn_table(i32 %x0, double %t, i32 %c) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %a = and i32 %x, 1
  %z = zext nneg i32 %a to i64
  %e = getelementptr inbounds [2 x ptr], ptr @fps, i64 0, i64 %z
  %f = load ptr, ptr %e, align 8
  %s = add nsw i32 %x, %c
  %r = call i32 %f(i32 %s)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
; EXPECT-ERROR: cq: unimplemented: calls: a function pointer loaded at a quantum index
