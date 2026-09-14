; w1 — the shape bd wx8g NEWLY admits, carrying the cyclic hole: a BARE-RAIL
; in-loop controlled STATE PREP whose loop-header phi %v takes an M-descendant
; on its BACK EDGE.  %v dominates both of F2's slots (the arm theta's arg-0 and
; the merge phi's pred-edge incoming), so it is a genuine collider.
; The shipped tripwire pair uses a COMPARE condition and was therefore never
; behind wx8g's RailCond-guarded carve-out; this module is.
; EXPECT: DECLINE at F2.
define i32 @main() local_unnamed_addr {
entry:
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %join ]
  %v = phi i1 [ false, %entry ], [ %carry, %join ]
  br i1 %b, label %arm, label %join

arm:
  %t = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %join

join:
  %m = phi i1 [ %t, %arm ], [ false, %loop ]
  %s = select i1 %m, i32 1, i32 0
  %carry = icmp sgt i32 %s, 2
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
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
