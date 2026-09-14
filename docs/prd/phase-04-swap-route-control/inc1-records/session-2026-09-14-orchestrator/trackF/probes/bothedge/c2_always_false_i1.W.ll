; Track F CONTROL C2 — the SCOPE_R2 x_C6 shape: an i1 that is provably `false` on
; BOTH edges (`icmp slt %q, INT_MIN` is never true).  Seed `false`.  BOTH-EDGE.
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  %x = icmp slt i32 %q, -2147483648
  br i1 %c, label %arm, label %merge
arm:
  %rt = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ false, %entry ]
  %mx = call zeroext i1 @cq_measure_i1(i1 zeroext %x)
  %mr = call zeroext i1 @cq_measure_i1(i1 zeroext %rm)
  %z1 = zext i1 %mx to i32
  %z2 = zext i1 %mr to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
