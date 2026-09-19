; R3 probe x2 (NATURAL block order: top before A) — a rail phi at region A's ENTRY (M4 ADMITS it there) that a
; LATER region's flatten (@top, whose MERGE is A) then CONVERTS to a select
; chain, invalidating A's already-emitted predicate tree.
; Block order puts A textually before top so the driver claims A first.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)

define i32 @probe(i32 %u) {
F0:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %top

top:
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 3
  br i1 %c0, label %p, label %A

p:
  br label %A

A:
  %rp = phi i1  [ %b, %p ], [ false, %top ]
  %dv = phi i32 [ 7, %p ],  [ 8, %top ]
  br i1 %rp, label %arm, label %Am

arm:
  br label %Am

Am:
  %v  = phi i32 [ 2, %arm ], [ %dv, %A ]
  %v2 = phi i32 [ 3, %arm ], [ 6, %A ]
  br label %done

done:
  %m1 = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %v2)
  %mb = call i1 @cq_measure_i1(i1 %rp)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
