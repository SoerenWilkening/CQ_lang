; Owner ruling 2026-11-11 Q7 (cq-edr1f), CR rule 16 noreturn: exit(5) with classical arguments and no quantum
; predicate, where an abort event can precede it, is the effect entry `exit` under an alloc_i1(true) seed, then
; abort_i1 of that seed; never the call made as it stands. (if (a & 1) abort(); if (c & 1) exit(5);)
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort() noreturn nounwind
declare void @exit(i32) noreturn

define i32 @after_abort(i32 %a0, double %t, i32 %c) {
entry:
  %a = call i32 @cq_theta_si32(i32 %a0, double %t)
  %ab = and i32 %a, 1
  %qa = icmp eq i32 %ab, 0
  br i1 %qa, label %next, label %die
die:
  call void @abort()
  unreachable
next:
  %cb = and i32 %c, 1
  %cc = icmp eq i32 %cb, 0
  br i1 %cc, label %ok, label %quit
quit:
  call void @exit(i32 5)
  unreachable
ok:
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
; CHECK after_abort: %{{s}} = call i32 @cqrt_alloc_i1(i1 true)
; CHECK after_abort: call void @cqrt_tape_write_i32_lit(i32 %{{t}}, i32 5)
; CHECK after_abort: call void @cqrt_tape_effect_controlled(i32 %{{s}}, i32 %{{t}}, ptr @.cq.effect.exit, i32 1)
; CHECK-COUNT after_abort: call void @cqrt_abort_i1( 2
; CHECK-COUNT after_abort: call void @exit( 0
; Owner ruling 2026-11-14 Q1 (cq-9tang): abort_i1 of the true seed does not return; the `unreachable` after it stays.
; CHECK-COUNT after_abort: unreachable 1
