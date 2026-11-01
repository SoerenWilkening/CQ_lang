; Rule 16 (102 raise_default): raise(SIGUSR1) under a quantum predicate with no handler in the module: the
; delivery is an effect entry and SIGUSR1's default action terminates, so it is the abort arm (45).
; CHECK raise_q: call void @cqrt_tape_effect_controlled(i32 %{{f}}, i32 %{{t}}, ptr @.cq.effect.raise)
; CHECK raise_q: call void @cqrt_tape_write_i32_lit(i32 %{{t}}, i32 30)
; CHECK raise_q: call void @cqrt_abort_i1(i32 %{{f}})
; CHECK-COUNT raise_q: @raise( 0
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
