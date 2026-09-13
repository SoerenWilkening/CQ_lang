; G1 BOUNDARY — the collider %d is the condition of a SELECT, not of a conditional br.
; "Is a select condition a conditional br's condition?"  R-2 as spelled says NO, so this
; row keeps declining.  Measured so the spelling's boundary is a fact, not a reading.
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
merge:
  %rm = phi i1 [ %rt, %arm ], [ true, %entry ]
  %sel = select i1 %d, i32 3, i32 9
  %ms = call i32 @cq_measure_si32(i32 %sel)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z2 = zext i1 %mr to i32
  %s  = add i32 %ms, %z2
  ret i32 %s
}
