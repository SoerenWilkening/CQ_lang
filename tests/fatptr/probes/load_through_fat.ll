; A load through a fat pointer over host objects at a classical idx (rule 21: a host load checking the
; idx against the object's cell count) is not built: an internal error, never a lowering. (Over QRAM
; objects, and over host objects at a rail idx as a QROM, it is: 84, 88, 167.)
; EXPECT-ERROR: cq: unimplemented: fatptr: a load through a fat pointer from a slot object, a host object at a classical idx
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
