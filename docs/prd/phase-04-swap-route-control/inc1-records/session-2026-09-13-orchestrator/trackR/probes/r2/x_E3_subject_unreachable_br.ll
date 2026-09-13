; E3 SUBJECT (v2 — the first spelling put the dead block into the merge's phi and both
; halves declined `control flow` on a 4-predecessor merge, an unrelated shape wall).
; Here the unreachable block is self-contained.  The conditional br on the ONE-EDGE
; pinned collider %d sits in a block NOT reachable from entry, so no region is ever
; detected on it — yet R-2's syntactic predicate ("used as the condition of a
; conditional br in this function") fires.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = icmp sgt i32 %q, 7
  %c = icmp sgt i32 %q, 100
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 true, double 9.000000e-01)
  br label %merge
dead:
  br i1 %d, label %d1, label %d2
d1:
  call void @cq_phi(double 7.000000e-01)
  br label %d2
d2:
  unreachable
merge:
  %rm = phi i1 [ %rt, %arm ], [ true, %entry ]
  %md = call i1 @cq_measure_i1(i1 %d)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z1 = zext i1 %md to i32
  %z2 = zext i1 %mr to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
