; r29 — the TWO-READ-POINT question (`FIX_B1_R2.md` §4 item 4: "one diagnostic
; per RAIL … if a future emitter ever reads one rail at two positions with user
; code BETWEEN them"). TWO 4.4 selects on TWO SIBLING rails of one round-2 wire,
; with the second sibling's Ry between the two control reads.
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
  %a1 = select i1 %b, i32 2, i32 5
  %b2 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %a2 = select i1 %b2, i32 11, i32 13
  %m1 = call i32 @cq_measure_si32(i32 %a1)
  %m2 = call i32 @cq_measure_si32(i32 %a2)
  %t = add i32 %m1, %m2
  %u = add i32 %t, %keep
  ret i32 %u
}
attributes #0 = { nounwind willreturn memory(none) }
