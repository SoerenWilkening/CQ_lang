; e14 — a RAIL-conditioned select whose ARM is a 6.5 classical-call-arm `%out`.
; The select is TAINTED AT ROUND 1 (its condition is a theta result), so it is
; classified AND EMITTED at round 1, while `%out` only becomes tainted at round
; 2 — `materializeCopySource` keys on round-1 taint.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 4)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %b = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %z = select i1 %b, i32 %y, i32 99
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
