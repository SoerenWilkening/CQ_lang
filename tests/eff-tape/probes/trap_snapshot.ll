; Rule 16, llvm.trap in a quantum arm (108) followed by a rotation of a rail live at the trap: the rail
; is snapshotted under the flag before abort_i1; a rail defined after the trap is not.
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.trap() cold noreturn nounwind

define i32 @trap_snapshot(i32 %x0, i32 %y0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %y = call i32 @cq_theta_si32(i32 %y0, double %t)
  %f = icmp ult i32 %x, %k
  br i1 %f, label %die, label %ok
die:
  call void @llvm.trap()
  unreachable
ok:
  %x2 = call i32 @cq_theta_si32(i32 %x, double %t)
  %s = add i32 %x2, %y
  %s2 = call i32 @cq_theta_si32(i32 %s, double %t)
  %m = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m
}
; CHECK trap_snapshot: %{{s}} = call i32 @cqrt_alloc_i32(i32 0)
; CHECK trap_snapshot: call void @cqrt_copy_i32_controlled(i32 %{{f}}, i32 %{{x}}, i32 %{{s}})
; CHECK trap_snapshot: call void @cqrt_abort_i1(i32 %{{f}})
; CHECK-COUNT trap_snapshot: cqrt_copy_i32_controlled 1
; CHECK-COUNT trap_snapshot: @llvm.trap 0
