; p8 — THE BACK-EDGE HOLE in the availability argument.
; %v is a LOOP-HEADER phi that takes %carry (a transitive USER of the region's
; merge phi %m) on the BACK EDGE.  So %v is in PhiDesc -- and yet %v DOMINATES
; the arm and the pred-edge, i.e. it IS available at both of F2's two slots.
; %v is pinned to the seed (false) on the true edge, so it is a genuine collider.
define i32 @main() local_unnamed_addr {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %join ]
  %v = phi i1 [ false, %entry ], [ %carryX, %join ]
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %k = add nsw i32 %q, -5
  %c = icmp eq i32 %q, 7
  br i1 %c, label %arm, label %join

arm:
  %t = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %join

join:
  %m = phi i1 [ %t, %arm ], [ false, %loop ]
  %s = select i1 %m, i32 1, i32 %k
  %carry = icmp sgt i32 %s, 2
  %carryX = icmp sgt i32 %k, 2
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %loop

exit:
  %r = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %m)
  %rv = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %v)
  %z = zext i1 %r to i32
  %zv = zext i1 %rv to i32
  %a = add nsw i32 %z, %zv
  ret i32 %a
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
