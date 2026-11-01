; Rule 16 (102 raise_handled): raise(sig) under a quantum predicate runs the handler signal(sig, h) installed in
; the module as h's _ctl clone (rule 19), after the delivery's effect entry; no abort.
; CHECK raise_h: call void @cqrt_tape_effect_controlled(i32 %{{f}}, i32 %{{t}}, ptr @.cq.effect.raise)
; CHECK raise_h: call void @cqrt_tape_write_i32_lit(i32 %{{t}}, i32 30)
; CHECK raise_h: call void @__cq_q_h_0_ctl(i32 %{{f}}, i32 30)
; CHECK-COUNT raise_h: @cqrt_abort_i1 0
; CHECK-COUNT raise_h: @raise( 0
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)
declare i32 @raise(i32)
declare ptr @signal(i32, ptr)

define internal void @h(i32 %s) {
  call void @cq_phi(double 1.0)
  ret void
}

define i32 @raise_h(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %old = call ptr @signal(i32 30, ptr @h)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @raise(i32 30)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
