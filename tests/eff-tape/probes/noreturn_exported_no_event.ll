; Owner ruling 2026-11-14 (scope of Q7, CR rule 16 noreturn, NORTHSTAR principle 1): a classical noreturn call is an
; effect entry only where an event can precede it on a path inside the lowered code. The module holds an abort event
; (f), but check, fail and trapper are externally visible, purely classical and never called after an event in the
; module (f calls check before its event): their own symbols are lowered as in a module with no event, host exit, trap,
; `noreturn` and `unreachable` included. Only what lowered callers reach after an event (their table clones) carries the entry form.
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort() noreturn nounwind
declare void @exit(i32) noreturn
declare void @llvm.trap() cold noreturn nounwind

define void @check(i32 %c) {
entry:
  %b = and i32 %c, 4
  %z = icmp eq i32 %b, 0
  br i1 %z, label %ok, label %die
die:
  call void @exit(i32 2)
  unreachable
ok:
  ret void
}

define void @fail(i32 %c) noreturn {
entry:
  call void @exit(i32 %c)
  unreachable
}

define i32 @trapper(i32 %c) {
entry:
  %z = icmp eq i32 %c, 7
  br i1 %z, label %die, label %ok
die:
  call void @llvm.trap()
  unreachable
ok:
  %r = add i32 %c, 1
  ret i32 %r
}

define i32 @f(i32 %a0, double %t, i32 %c) {
entry:
  call void @check(i32 %c)
  %a = call i32 @cq_theta_si32(i32 %a0, double %t)
  %ab = and i32 %a, 1
  %qa = icmp eq i32 %ab, 0
  br i1 %qa, label %next, label %die
die:
  call void @abort()
  unreachable
next:
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
; trapper has no call: the pass's identity. check and fail make a call, so the pass lowers them (rule 19: a body is its
; own lowering only with no call): exactly as in the control module, which holds no event.
; IDENTITY trapper
; SAME check noreturn_exported_no_event.control.ll
; SAME fail noreturn_exported_no_event.control.ll
; SAME trapper noreturn_exported_no_event.control.ll
; CHECK-COUNT check: @cqrt_ 0
; CHECK-COUNT fail: @cqrt_ 0
; CHECK fail: call void @exit(i32 %c)
; CHECK fail: unreachable
; CHECK-COUNT f: call void @cqrt_abort_i1( 1
; CHECK __cq_q_fail_1_t: call void @cqrt_tape_effect_controlled(i32 %{{s}}, i32 %{{t}}, ptr @.cq.effect.exit, i32 1)
; CHECK __cq_q_fail_1_t: call void @cqrt_abort_i1(
