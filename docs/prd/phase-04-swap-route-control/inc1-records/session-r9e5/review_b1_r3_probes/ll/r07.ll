; r07 — AREA 1: the 4.3 depth-2 NEST with the INNER level's condition the
; round-2 `%out`-derived rail (w5 did the OUTER level). The inner arm's phases
; ride the conjunction ancilla, so the conjunction toffoli is the ONLY read of
; the register. Sibling BEFORE.
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
  %co = icmp sgt i32 %q, 7
  br i1 %co, label %mid, label %join
mid:
  br i1 %b, label %inner, label %join
inner:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %n = call i32 @cq_measure_si32(i32 %q)
  %t = add i32 %zz, %n
  %u = add i32 %t, %keep
  ret i32 %u
}
attributes #0 = { nounwind willreturn memory(none) }
