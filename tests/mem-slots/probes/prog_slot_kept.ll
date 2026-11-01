; 102 (program slot): with no load of the slot after the guarded _ctl clone call, the slot's old seed is held by
; nothing and is freed right after the call; the clone's rail stays the slot's (kept, never uncomputed). @hit is
; a program slot because raise_r reads it after its own clone call.
; CHECK raise_h: %{{old}} = load i32, ptr @hit, align 4
; CHECK raise_h: call void @__cq_q_h_0_ctl(i32 %{{f}}, i32 30)
; CHECK raise_h: call void @cqrt_free(i32 %{{old}})
; CHECK-COUNT raise_h: @cq_template_select_i32_lh_unc( 0
; CHECK-COUNT raise_h: load i32, ptr @hit 1
target triple = "x86_64-apple-macosx16.0.0"
@hit = internal global i32 0, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @raise(i32)
declare ptr @signal(i32, ptr)

define internal void @h(i32 %s) {
  store volatile i32 %s, ptr @hit, align 4
  ret void
}

define i32 @raise_r(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %f = icmp sgt i32 %x, %k
  br i1 %f, label %then, label %done
then:
  %r = call i32 @raise(i32 30)
  br label %done
done:
  %m = call i32 @cq_measure_si32(i32 %x)
  %hv = load volatile i32, ptr @hit, align 4
  %hm = call i32 @cq_measure_si32(i32 %hv)
  %s = add nsw i32 %hm, %m
  ret i32 %s
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
