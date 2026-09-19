; R3 probe x3 — NO block reordering. Outer region B contains A (the rail-phi
; region) as an INTERIOR block, so M4 refuses B at E6. A then claims (its phi is
; at A's OWN entry, which M4 admits) and flattens; A's terminator becomes
; UNCONDITIONAL, so B's E6 no longer sees the rail phi and B may now claim --
; and B's flatten calls convertPhis(A), converting the very phi A's already-
; emitted predicate tree was built from.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)

define i32 @probe(i32 %u) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 9
  br i1 %c, label %Bt, label %Bm
Bt:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %Bt2, label %A
Bt2:
  br label %A
A:
  %rp = phi i1 [ true, %Bt2 ], [ false, %Bt ]
  br i1 %rp, label %Aarm, label %Am
Aarm:
  br label %Am
Am:
  %v  = phi i32 [ 2, %Aarm ], [ 5, %A ]
  %v2 = phi i32 [ 3, %Aarm ], [ 6, %A ]
  br label %Bm
Bm:
  %o  = phi i32 [ 7, %entry ], [ %v, %Am ]
  %o2 = phi i32 [ 8, %entry ], [ %v2, %Am ]
  %m1 = call i32 @cq_measure_si32(i32 %o)
  %m2 = call i32 @cq_measure_si32(i32 %o2)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
