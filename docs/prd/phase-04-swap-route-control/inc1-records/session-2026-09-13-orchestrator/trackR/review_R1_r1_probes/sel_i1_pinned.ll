; sel_i1_pinned.ll — ITEM 1's sub-question: a peeled i1 SELECT that is itself the
; deciding F2 collider.  The mux's only tainted arm is the region's OWN condition
; %c (so it is in CondWire and excluded); the other arm is a constant (never
; visited).  On the FALSE edge both arms are `false`, so `f2Model`'s select arm
; unions them to the singleton {0} = the prep's seed.  The SELECT is NOT a clone
; and MUST NOT be excluded: expected DECLINE on BOTH binaries.
define i32 @main() local_unnamed_addr {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %c = icmp eq i32 %q, 1
  br i1 %c, label %arm, label %m
arm:
  %t = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %m
m:
  %p  = phi i1 [ %t, %arm ], [ false, %entry ]
  %mx = phi i1 [ %c, %arm ], [ false, %entry ]
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %q)
  %m1 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %p)
  %m2 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %mx)
  %z1 = zext i1 %m1 to i32
  %z2 = zext i1 %m2 to i32
  %s1 = add nsw i32 %m0, %z1
  %s2 = add nsw i32 %s1, %z2
  ret i32 %s2
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
