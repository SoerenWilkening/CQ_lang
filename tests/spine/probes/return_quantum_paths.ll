; cq-jkq8 (was a stop: a return under a quantum predicate): two returns, each under a quantum predicate. The
; plugin gives a tainted function one return block (unifyReturns, a CFG rewrite before the final taint), so the
; returns merge by rule 9's select at the common return.
; USERCHECK tworet
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @tworet(i32 %0, double %1, i32 %2) {
  %4 = call i32 @cq_theta_si32(i32 %0, double %1)
  %5 = icmp sgt i32 %4, 3
  br i1 %5, label %6, label %9
6:
  %7 = add i32 %4, %2
  %8 = call i32 @cq_measure_si32(i32 %7)
  ret i32 %8
9:
  %10 = mul i32 %4, 3
  %11 = call i32 @cq_theta_si32(i32 %10, double %1)
  %12 = call i32 @cq_measure_si32(i32 %11)
  ret i32 %12
}
