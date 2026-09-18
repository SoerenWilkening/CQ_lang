; The USER writes the NOT: `br i1 (xor %rail, true)`.  canonicalizePred returns it
; unchanged, so the fold's operand test sees a rail that arrived by a DIFFERENT
; producer than buildNegation.  Semantics: arm on the TRUE successor of ¬rail,
; i.e. the arm runs when rail == 0.  a4 must be (rail ? 5 : 2).
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @probe() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %n = xor i1 %b, true
  br i1 %n, label %arm, label %merge
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s1 = add i32 %m1, %m2
  %s2 = add i32 %s1, %z
  ret i32 %s2
}
