; Rule 16: a rotation after a noreturn arm whose target is a phi that may name a rail live at the abort:
; the snapshot set cannot be decided, unimplemented (never a guess).
; EXPECT-ERROR: cq: unimplemented: eff-tape: a rotation after a noreturn arm whose target may alias
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort() noreturn nounwind

define i32 @abort_alias(i32 %x0, double %t, i32 %k, i1 %c) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %f = icmp eq i32 %x, %k
  br i1 %f, label %die, label %ok
die:
  call void @abort()
  unreachable
ok:
  br i1 %c, label %a, label %j
a:
  %y = add i32 %x, 1
  br label %j
j:
  %p = phi i32 [ %x, %ok ], [ %y, %a ]
  %p2 = call i32 @cq_theta_si32(i32 %p, double %t)
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
