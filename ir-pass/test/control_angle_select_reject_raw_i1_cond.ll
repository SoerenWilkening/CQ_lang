; control_angle_select_reject_raw_i1_cond.ll — DECLINE: a RAW i1 quantum
; condition, with no compare to mint from (bd drbq Inc 2b; PRD §8 / owner Q6,
; deferred).
;
;     _Bool c = cq_theta(0, 1.1); ... cq_theta(r, c ? .9 : .3);
;
; The whole control mechanism mints its flag AT A COMPARE
; (`cq_template_icmp_<pred>_<W>_hl`), and a `trunc i32 %b to i1` on a quantum
; register is not one. Controlling on the register itself — no flag ancilla — is
; a real 3-gate saving and its own PRD; it is deferred for the `br` form (S4 in
; the PRD's table) and is deferred here for the same reason.
;
; `collectCondTree` refuses the `trunc` as off-grammar, so this declines at
; SelectClassify's GATE 2 with the generic `control flow` string, BEFORE gate 3's
; angle hook is ever reached — which is why the message is not `rotation angle`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %b = call i32 @cq_theta_si32(i32 1, double 1.100000e+00)
  %c = trunc i32 %b to i1
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
