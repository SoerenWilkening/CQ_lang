declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @__cq_invert_begin() #9
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @__cq_invert_begin()
  %v1 = add i32 %p, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
attributes #9 = { nounwind willreturn speculatable memory(none) }
