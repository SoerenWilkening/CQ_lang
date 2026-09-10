; r32 — AREA 2 (survival of the read point): the round-1 rail select sits INSIDE
; a block that a ROUND-2 region's `RegionFlatten` then folds away, so the
; recorded `cqrt_cnot` is MOVED (and its block erased) between the emission and
; the re-verification stage. The `WeakTrackingVH` must still name it (a move is
; not an erase) and the decline must still fire. Sibling BEFORE.
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
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %a1 = select i1 %b, i32 2, i32 5
  %c1 = icmp sgt i32 %y, 2
  br i1 %c1, label %inner, label %join
inner:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %m = call i32 @cq_measure_si32(i32 %a1)
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %t = add i32 %m, %zz
  %u = add i32 %t, %keep
  ret i32 %u
}
attributes #0 = { nounwind willreturn memory(none) }
