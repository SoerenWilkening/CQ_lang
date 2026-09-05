; control_angle_select_reject_runtime_arms_rz.ll — DECLINE (S1, the ARM-VALUE
; fence), the **Rz / `cq_phi` STEM** of `control_angle_select_reject_runtime_arms.ll`.
;
; THE STEM SEPARATOR IS THE POINT. Rz is exempt from S8 (R4 disjoint wires) and
; from S9 (R6 stale record) by the §12.1 diagonal argument — a diagonal gate moves
; no computational-basis label — so a reader could reasonably expect the run-time
; residual to be an Ry-only concern too. IT IS NOT: the residual is ARITHMETIC on
; the ANGLE, not a statement about basis labels, so it rides on both stems
; identically. The clearance measured it directly
; (`clearance2b/p3/r04_rt_rz_pi_sel.c`, the `cq_phi` spelling of the pi/1e16
; reproducer): ACCEPT with a realized true-arm angle of 4.0 rad on the build under
; test, `rotation angle under quantum control` on the pre-2b ORACLE.
;
; The full argument, the five reproducers, the twin fact (the manual
; by-difference twin with run-time arms declines `control flow` on BOTH binaries,
; so this class was reachable ONLY through 2b) and the owner's one-line widening
; option (1) are in `control_angle_select_reject_runtime_arms.ll`'s header; they
; are not duplicated here.
;
; NO NEW DIAGNOSTIC STRING: S1 returns `NotApplicable` and gate 3's pre-existing
; `rotation angle` decline fires.
;
; ORACLE DISPOSITION: the pre-2b binary declines with the SAME string; the
; red-green for this file is against the previous state of THIS tree, where the
; run-time branch of `angleSelectArmsAdmissible` returned `true` and this module
; lowered to `rz(h,%y); mint; rz_controlled(f,h,fsub %x,%y); strip; free`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (angle select -> void call on the select (PRD P2))

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, double %x, double %y) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %x, double %y
  call void @cq_phi(double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; CHECK-NOT: fsub double
; CHECK-NOT: cqrt_rz_i32_controlled
