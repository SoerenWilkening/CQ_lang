; Rule 16, a noreturn arm with nothing modified in place afterwards: abort_i1 of the flag, no snapshot,
; the flag kept (never uncomputed, never freed).
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort() noreturn nounwind

define i32 @abort_no_snapshot(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %f = icmp eq i32 %x, %k
  br i1 %f, label %die, label %ok
die:
  call void @abort()
  unreachable
ok:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
; CHECK abort_no_snapshot: %{{f}} = call i32 @cq_template_icmp_eq_i32_hl(i32 %{{x}}, i32 %{{k}})
; CHECK abort_no_snapshot: call void @cqrt_abort_i1(i32 %{{f}})
; CHECK-COUNT abort_no_snapshot: cqrt_copy 0
; CHECK-COUNT abort_no_snapshot: _unc 0
; CHECK-COUNT abort_no_snapshot: cqrt_free 0
; CHECK-COUNT abort_no_snapshot: @abort( 0
