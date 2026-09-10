; r25 — RUNG (ii) in the round-2 window through the KICKBACK consumer (the fix
; ships `e06` for the SELECT only). The `%out`-derived parent `%x` is MEASURED
; before the branch; at FINAL taint the rail rides `%x`'s wire, so the kickback
; would fire a gate on a COLLAPSED register.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 3
  br i1 %c0, label %arm, label %merge
arm:
  %r = call i32 @f(i32 4)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  br label %second
second:
  %x = trunc i32 %y to i1
  %mx = call i1 @cq_measure_i1(i1 %x)
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  br i1 %b, label %then, label %join
then:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %zx = zext i1 %mx to i32
  %t = add i32 %zx, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
