; control_angle_select_reject_cond_register.ll — DECLINE: an in-place Ry on the
; register the CONDITION reads (bd drbq Inc 2b).
;
;     int q = cq_theta(3,.5);
;     q = cq_theta(q, q == 5 ? .9 : .3);
;
; THE STEM SEPARATOR. This is `control_angle_select_rz_cond_register.ll` with
; `cq_phi` changed to `cq_theta` and NOTHING else; that one ACCEPTS and this one
; declines. Read the pair together — it is the whole content of PRD §3c.
;
; An in-place Ry RELABELS the register's computational basis, so after it the
; minted flag is no longer a function of `q`'s basis and the `icmp_..._unc` strip
; cannot return it to |0>. The `cqrt_free` that follows would then be a free of a
; DIRTY, condition-entangled ancilla — a hidden measurement that collapses `q`
; (Rules 6/8). A diagonal Rz moves no basis label, which is why the twin is fine.
;
; WHICH GUARD FIRES, stated because two could: `SelectClassify`'s GATE 2c wins.
; Its prong (a) is position-free — `findNonDiagonalWireGate` over
; `condProvenance(%c)` finds the `cq_theta` on `%q`'s own wire wherever it sits —
; and gate 2c runs BEFORE gate 3's angle hook, so the message is `condition
; predates a non-diagonal gate` rather than S8's `rotation arm on a condition
; wire`. S8 would have refused it too (`%q` is in both the condition closure and
; the base closure); the two fences overlap here on purpose, and the ORDER is what
; picks the message.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %q, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
