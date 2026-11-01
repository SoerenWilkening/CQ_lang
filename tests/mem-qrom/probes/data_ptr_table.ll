; A data pointer read at a quantum index from a constant table: a fat pointer over the object table
; (rule 21) whose derived (tag, idx) tables are not built: an internal error.
@a = internal constant [2 x i32] [i32 1, i32 2]
@b = internal constant [2 x i32] [i32 3, i32 4]
@t = internal constant [2 x ptr] [ptr @a, ptr @b]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @data_ptr_table(i32 %x0, double %t) {
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %a = and i32 %x, 1
  %z = zext nneg i32 %a to i64
  %e = getelementptr inbounds [2 x ptr], ptr @t, i64 0, i64 %z
  %p = load ptr, ptr %e, align 8
  %v = load i32, ptr %p, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; EXPECT-ERROR: cq: unimplemented: mem-qrom: a QROM load of a data pointer
