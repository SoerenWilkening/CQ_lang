; control_angle_select_reject_phase_rail_round2_sibling_theta.ll — DECLINE (bd
; test_C_libtooling-r9e5, Rule-13 round-3 probe `r09`; the two-TU plain-C twin is
; the round's `multi/m10`): the ROUND-2 TAINT WINDOW (F-B1R2-1) reached through the
; Rz-stem ANGLE SELECT on a rail. `%b` is a theta on `%x = trunc %y` with `%y` a 6.5
; `%out` (classical at round 1, tainted at final taint) and `%b3` its sibling; the
; angle select's kickback pair `rz(b, −B); rz(b, A)` is the rail's read, recorded by
; `AngleSelectEmit`. On f8d29e8 this ACCEPTED with `ry(h,.5); ry(h,.9); rz(h, …)`.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 3
  br i1 %c0, label %arm, label %merge
arm:
  %r = call i32 @f(i32 4)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  br label %second
second:
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %ang = select i1 %b, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
