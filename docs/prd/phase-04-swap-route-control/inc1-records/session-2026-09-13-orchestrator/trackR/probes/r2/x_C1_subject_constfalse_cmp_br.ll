; C1 SUBJECT — %x = icmp slt %q, INT_MIN: a tainted compare whose result is provably
; FALSE on both edges (a distinct rail, NOT a constant in the IR), pinned == the seed
; , and used as the condition of a conditional br.  R-2 would ACCEPT this.
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
  %rt = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ false, %entry ]
  br i1 %x, label %arm2, label %merge2
arm2:
  call void @cq_phi(double 7.000000e-01)
  br label %merge2
merge2:
  %mx = call i1 @cq_measure_i1(i1 %x)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z1 = zext i1 %mx to i32
  %z2 = zext i1 %mr to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
