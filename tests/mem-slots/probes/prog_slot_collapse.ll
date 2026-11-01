; 102 (CR rules 16, 19, 20, 2, 7): a program slot. @hit is an internal global a signal handler writes and an
; entry reads with no store of its own before the read: a module constructor seeds it with its initializer
; (7, rule 7); the handler's _ctl clone stores hit = ctl ? s : hit (the guarded store); the entry loads the
; old handle before the clone call and, at its load after x's measurement, collapses the slot (rule 2):
; select_unc against a seed of the classical predicate, a fresh seed of (m > k ? 30 : 7) stored back, the old
; seed freed; the load is classical. The classical original h stores a seed.
; CHECK raise_h: %{{old}} = load i32, ptr @hit, align 4
; CHECK raise_h: call void @__cq_q_h_0_ctl(i32 %{{f}}, i32 30)
; CHECK raise_h: %{{m}} = call i32 @cqrt_measure_i32(i32 %{{x}})
; CHECK raise_h: %{{c}} = icmp sgt i32 %{{m}}, %{{k}}
; CHECK raise_h: %{{r}} = load i32, ptr @hit, align 4
; CHECK raise_h: %{{p}} = call i32 @cqrt_alloc_i1(i1 %{{c}})
; CHECK raise_h: call void @cq_template_select_i32_lh_unc(i32 %{{r}}, i32 %{{p}}, i32 30, i32 %{{old}})
; CHECK raise_h: %{{v}} = select i1 %{{c}}, i32 30, i32 7
; CHECK raise_h: %{{n}} = call i32 @cqrt_alloc_i32(i32 %{{v}})
; CHECK raise_h: store i32 %{{n}}, ptr @hit, align 4
; CHECK-COUNT raise_h: @cqrt_free( 4
; CHECK-COUNT raise_h: @cqrt_measure_i32( 1
; CHECK __cq_q_h_0_ctl: %{{o}} = load i32, ptr @hit, align 4
; CHECK __cq_q_h_0_ctl: %{{s}} = call i32 @cq_template_select_i32_lh(i32 %{{c}}, i32 %{{v}}, i32 %{{o}})
; CHECK __cq_q_h_0_ctl: store i32 %{{s}}, ptr @hit, align 4
; CHECK-COUNT __cq_q_h_0_ctl: @cqrt_free( 0
; CHECK __cq_slot_init_hit: %{{z}} = call i32 @cqrt_alloc_i32(i32 7)
; CHECK __cq_slot_init_hit: store i32 %{{z}}, ptr @hit, align 4
; CHECK h: %{{z}} = call i32 @cqrt_alloc_i32(i32 %{{s}})
; CHECK-COUNT h: @cqrt_free( 0
target triple = "x86_64-apple-macosx16.0.0"
@hit = internal global i32 7, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @raise(i32)
declare ptr @signal(i32, ptr)

define internal void @h(i32 %s) {
  store volatile i32 %s, ptr @hit, align 4
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
  %hv = load volatile i32, ptr @hit, align 4
  %hm = call i32 @cq_measure_si32(i32 %hv)
  %s = add nsw i32 %hm, %m
  ret i32 %s
}
