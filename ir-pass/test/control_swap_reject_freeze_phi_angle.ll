; control_swap_reject_freeze_phi_angle.ll — DECLINE: a PHI-routed FP-angle leak
; carried through a `freeze` (Phase-7.1 Increment B, the carrier-extension probe).
; Proves `selReachesRotationArg1` crosses BOTH a `phi` and a `freeze` on the way
; to a rotation arg-1.
;
; `%sel = select i1 %c, float a, float b` has a TAINTED condition (`%c` reads the
; quantum `%qd`). Its float result flows into a CLASSICAL-condition (`%cc`) merge
; `phi`, then through a `freeze`, then `fpext`, into a `cq_phi` arg-1 (the angle
; slot). The angle leak ORIGINATES at the tainted-condition select; the
; surrounding `phi` join is classical, so ControlDetect does not claim the merge —
; the select ladder's GATE-3 carrier walk must cross `select -> phi -> freeze ->
; fpext` and land on the arg-1 reach.
;
; Increment B SKIPS an FP-typed tainted `freeze` at the escape guard (value-
; preserving carrier), so the angle no longer hits the blunt `kMsgOther` backstop
; — the GATE-3 fence is the ONLY catch. If the carrier walk did NOT cross
; `freeze`, the walk would stop at the freeze and the quantum-derived angle would
; route into the rotation SILENTLY (the f64/angle miscompile family — Rule 3).
; The `phi` carrier alone already reaches GATE-3; this fixture pins that the
; INTERPOSED `freeze` does not break the reach.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: cq taint escape
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %cc) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd  = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c   = icmp sgt i32 %qd, 5
  %sel = select i1 %c, float 2.500000e-01, float 7.500000e-01   ; tainted-cond select
  br i1 %cc, label %a, label %merge                             ; CLASSICAL join cond
a:
  br label %merge
merge:
  %p   = phi float [ %sel, %a ], [ 0x3FB99999A0000000, %entry ]  ; phi carrier
  %f   = freeze float %p                                         ; freeze carrier
  %w   = fpext float %f to double
  %q2  = call i32 @cq_phi_si32(i32 %qd, double %w)               ; %w in arg-1 (angle)
  %m   = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}
