; control_angle_select_reject_irreducible_cycle_rz.ll — DECLINE (S7, the CYCLE
; prong), `cq_phi` STEM. The Ry sibling is
; `control_angle_select_reject_irreducible_cycle.ll`; read its header for the
; round-1 Rule-13 finding (lens L3-1) and the two twins that decline.
;
; THE STEM MATTERS HERE, and it is why this file exists rather than one fixture.
; The Rz stem is exempt from S8 (R4 disjoint wires) and S9 (R6 stale record) on
; the PRD §12.1 diagonal argument, so on the pre-fix binary the Ry form of this
; shape could still be caught by an unrelated clause on some inputs while the Rz
; form had NOTHING left between S7 and the accept. Measured on the round-1
; reproducer (`review2b/L3/l3/x/x2_irreducible_rz.ll`): the Rz form ACCEPTED
; silently and the only diagnostic anywhere in the pipeline came from
; `declineClassicalMuxes`' mislabelled backstop on a DIFFERENT probe.
;
; The base here is a plain `cq_theta` source (not a derived `mul`), so nothing but
; S7 stands between this module and an emitted controlled Rz inside a cycle.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %cls, i32 %cls2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %e0 = icmp eq i32 %cls, 0
  br i1 %e0, label %A, label %B
A:
  br label %B
B:
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_phi_si32(i32 %r, double %ang)
  %e1 = icmp eq i32 %cls2, 0
  br i1 %e1, label %A, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
