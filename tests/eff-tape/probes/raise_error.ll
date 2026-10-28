; Rule 16: raise under a quantum predicate depends on the module's signal table (102): unimplemented here.
; EXPECT-ERROR: cq: unimplemented: eff-tape: a signal-family host call
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @raise(i32)

define i32 @raise_q(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @raise(i32 30)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
