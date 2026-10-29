; A load through a fat pointer (rule 21 per-object guarded access) is not built in this module: an
; internal error, never a lowering.
; EXPECT-ERROR: cq: unimplemented: fatptr: a load through a fat pointer
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_si32(i32)
@A = internal global [4 x i32] [i32 1, i32 2, i32 3, i32 4]
@B = internal global [4 x i32] [i32 5, i32 6, i32 7, i32 8]

define i32 @load_through_fat(i32 %x0, double %t) {
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %b = and i32 %x, 1
  %c = icmp eq i32 %b, 0
  %p = select i1 %c, ptr @A, ptr @B
  %v = load i32, ptr %p, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
