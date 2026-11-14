; Control module of noreturn_exported_no_event.ll: the same functions, f without its abort and without its call of check,
; so no code of the module but a table clone holds an event (CR rule 16).
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
  %a = call i32 @cq_theta_si32(i32 %a0, double %t)
  %ab = and i32 %a, 1
  %qa = icmp eq i32 %ab, 0
  br i1 %qa, label %next, label %die
die:
  br label %next
next:
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
