; R2 probe: an INTERIOR rail phi (region-internal join), incomings %rail / true.
; convertPhis must take the SELECT-CHAIN path (rail call is off isBooleanCondTree),
; producing `select(%c, %rail, true)`, whose FALSE arm is a NON-ZERO constant —
; so buildNegation skips arm 1 and runs cast<ConstantInt> on %rail.
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %A, label %B
A:
  br label %J
B:
  br label %J
J:
  %rp = phi i1 [ false, %A ], [ %rail, %B ]
  br i1 %rp, label %M, label %C
C:
  br label %M
M:
  %v = phi i32 [ 2, %C ], [ 5, %J ]
  %w = phi i32 [ 3, %C ], [ 6, %J ]
  %m1 = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %w)
  %mb = call i1 @cq_measure_i1(i1 %rail)
  %z = zext i1 %mb to i32
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
