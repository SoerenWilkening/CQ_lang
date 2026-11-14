; cq-edr1f contrast (CR rule 16): no tape or abort event in the module, so exit(5) with classical arguments and no
; quantum predicate is the ordinary host call, made as it stands.
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @exit(i32) noreturn

define i32 @no_event(i32 %a0, double %t, i32 %c) {
entry:
  %a = call i32 @cq_theta_si32(i32 %a0, double %t)
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
; CHECK no_event: call void @exit(i32 5)
; CHECK-COUNT no_event: cqrt_tape_ 0
; CHECK-COUNT no_event: cqrt_abort_i1( 0
