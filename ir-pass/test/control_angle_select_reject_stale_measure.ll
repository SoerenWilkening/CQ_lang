; control_angle_select_reject_stale_measure.ll — DECLINE (S9): a pre-gate RECORD
; of the rotated rail is MEASURED after the gate (bd drbq Inc 2b).
;
;     int mark = cq_phi(r, .1);
;     r = cq_theta(r, q == 5 ? .9 : .3);
;     ... cq_measure(mark);
;
; `%mark` is a second SSA name for `r`'s physical rail (Rz lowers in place), and
; the source means the record BEFORE the rotation. Post-lowering both names ARE
; the one handle, so the emitted `cqrt_measure` would read the POST-Ry register —
; a different value, `opt` exit 0, verify-clean and stage-2b clean. That is the
; wrong-VALUE class of bd `0njv`; S9 keeps it unreachable through this accept
; rather than fixing `0njv`.
;
; The accept control is `control_angle_select_ry_alias_pre_gate.ll` — the same IR
; with the measurement BEFORE the gate, which lowers.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %mark = call i32 @cq_phi_si32(i32 %r, double 1.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  %mm = call i32 @cq_measure_si32(i32 %mark)
  %s = add i32 %m, %mm
  ret i32 %s
}
