; control_phase_kickback_reject_rail_sibling_theta.ll — DECLINE (bd 3qlq.4,
; Rule-13 round-1 finding F-1b-1, a CONFIRMED silent miscompile on the first
; build of Inc 1b; its plain-C source is p80 in the session-3qlq4 record):
;
;     int q = cq_theta(0,.3); bool t = (bool)(q & 1);
;     bool b = cq_theta(t,.5); bool c = cq_theta(t,.9);   // TWO in-place Ry on t's rail
;     if (b) cq_phi(.7); return cq_measure(c);
;
; `b` and `c` are SIBLING in-place rotations on ONE physical rail (both chained
; on the template result `t`, so `lowerRotations` RAUWs both to `t`'s handle), and
; the branch reads `b` — a STALE name: at the branch the register is `Ry(.9)Ry(.5)|t>`,
; which is `c`. The first build accepted and emitted `ry(h,.5); ry(h,.9); rz(h,.7)`
; — byte-identical to the stream for `if (c)` and for the well-formed chain
; `c0 = cq_theta(t,.5); c = cq_theta(c0,.9); if (c)` — at opt exit 0, verify-clean,
; stage-2b clean. `main` declined it (`branch phase on a bare i1 condition`).
;
; ROOT CAUSE, and it is PRE-EXISTING for the compare path: `WireWalk::
; findNonDiagonalWireGate`'s backward ancestry crossed a chained theta's arg-0
; edge only when the parent was spelled `cq_theta_`/`cq_phi_`, so a TEMPLATE
; parent stopped the closure at `b` and the sibling `c` — a user of the PARENT,
; never of the seed — was invisible to every fence that asks the walker. The
; walker now crosses the edge whenever the parent is TAINTED (the relation
; `lowerRotations` builds the rail from; `Taint` threaded to every caller), so
; `c` is on `b`'s wire and the DT prong refuses it (not provably post-branch).
; The compare twin (`..._reject_sibling_theta_template_parent_cmp.ll`) accepted
; on `main` too and now declines. The discriminating ACCEPT is
; `control_phase_kickback_rail_post_ry.ll` (a chained Ry AFTER the region).

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %t = trunc i32 %q to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 %t, double 9.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %c)
  %z = zext i1 %m to i32
  ret i32 %z
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
