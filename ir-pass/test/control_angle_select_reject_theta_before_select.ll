; control_angle_select_reject_theta_before_select.ll — DECLINE: an in-place `Ry`
; sits between the compare and the SELECT, i.e. in the window `[Cond, Sel)`.
;
; THE OTHER HALF OF S6's ADVERTISED WINDOW, AND IT HAS A DIFFERENT OWNER. S6 says
; its window runs from the compare to the CONSUMER, which is longer than gate 2c
; prong (c)'s compare-to-select window — but `classifyAngleSelect` never sees this
; module: `SelectClassify`'s GATE 2c runs BEFORE gate 3, so a theta in `[Cond, Sel)`
; is refused there with `condition predates a non-diagonal gate`, and a
; `DS_Error` diagnostic exits the process, so S6 is never asked.
;
; The sibling `control_angle_select_reject_theta_between.ll` pins the `(Sel, T)`
; half, which IS S6's and which fires the `rotation angle` string. Recorded by the
; round-1 Rule-13 review (lens L1-4 sub): before this file, only one of the two
; halves of the window S6's comment advertises had a fixture, so a reader could
; not tell from the suite which guard actually owns which half — and the two
; strings differ, which is exactly the kind of thing that silently changes when a
; gate is reordered.
;
; `%zz` rotates a THIRD register, disjoint from the condition and the base, so
; like its sibling this is a deliberate OVER-decline: both scans are wire-blind.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %z = call i32 @cq_theta_si32(i32 %u2, double 2.000000e-01)
  %c = icmp eq i32 %q, 5
  %zz = call i32 @cq_theta_si32(i32 %z, double 4.000000e-01)
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %mz = call i32 @cq_measure_si32(i32 %zz)
  %s = add i32 %mt, %mz
  ret i32 %s
}
