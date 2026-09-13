; C5 RIVAL, the CLEAN both-slots-folded rival: C2 with the post-region measure of %x
; removed (that measure was a confound — it declined at R6 `stale rail record read
; past a controlled Ry`).  %x's only post-region use is the CONDITIONAL BR.  This is
; the sharpest HOLE candidate for R-2: if it lowers, R-2 strikes F2 on C1 while the
; rival that folds into C1 has a lowering.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = icmp slt i32 %q, -2147483648
  %c = icmp sgt i32 %q, 100
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ %x, %entry ]
  br i1 %x, label %arm2, label %merge2
arm2:
  call void @cq_phi(double 7.000000e-01)
  br label %merge2
merge2:
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z2 = zext i1 %mr to i32
  ret i32 %z2
}
