; td2_pad.ll — the §3b two-diamond composition with a PADDING block between the
; regions, so `A.Pred != B.MergeBB` and the hcrg precedence graph never asks
; `reorderable()`.  Region A = the i1 state prep (cond %c).  Region B = a
; peelable 2-phi diamond whose condition %g is an operand ANCESTOR of %c, so %g
; is in A's CondWire while the peel's CLONE of %g is not.
define i32 @main() local_unnamed_addr {
entry:
  %q  = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %g  = icmp sgt i32 %q, 5
  %gz = zext i1 %g to i32
  %c  = icmp eq i32 %gz, 1
  br i1 %c, label %armA, label %mA
armA:
  %t  = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %mA
mA:
  %p  = phi i1 [ %t, %armA ], [ false, %entry ]
  br label %pad
pad:
  br i1 %g, label %armB, label %mB
armB:
  %tb = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %mB
mB:
  %pb = phi i32 [ %tb, %armB ], [ 0, %pad ]
  %mx = phi i32 [ 2, %armB ], [ 5, %pad ]
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %q)
  %m1 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %p)
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %pb)
  %m3 = tail call i32 @cq_measure_si32(i32 noundef %mx)
  %z1 = zext i1 %m1 to i32
  %s1 = add nsw i32 %m0, %z1
  %s2 = add nsw i32 %s1, %m2
  %s3 = add nsw i32 %s2, %m3
  ret i32 %s3
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
