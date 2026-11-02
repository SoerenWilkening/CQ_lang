; Rule 16: raise of a stop signal (SIGSTOP) with no handler: the process is suspended and continues after
; SIGCONT, so the raise is its delivery entry alone (as ignore; orchestrator decision cq-a63l), no abort arm.
; CHECK raise_s: call void @cqrt_tape_effect_controlled(i32 %{{f}}, i32 %{{t}}, ptr @.cq.effect.raise)
; CHECK raise_s: call void @cqrt_tape_write_i32_lit(i32 %{{t}}, i32 17)
; CHECK-COUNT raise_s: cqrt_abort_i1 0
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @raise(i32)
declare ptr @signal(i32, ptr)

define i32 @raise_s(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @raise(i32 17)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
