; control_phase_kickback_reject_qq_compare.ll — DECLINE. A Q+Q CONDITION
; (PRD §6.3 row 4 and §9: PRE-EXISTING, unchanged by this epic).
;
;     if (q == p) cq_phi(θ);        // both operands quantum
;
; `CompareLowering::lowerCompareToFlag` mints `cq_template_icmp_<pred>_<W>_hl(q,
; lit)` — a HANDLE-and-LITERAL template. There is no Q+Q flag mint at any width,
; so the flag this region needs cannot be built.
;
; THE MESSAGE IS THE PRE-EXISTING ONE, AND THAT IS MEASURED, NOT ASSUMED. The
; pre-3qlq oracle emits `no template for opcode 'icmp i1' in tainted context` for
; the SAME shape written in the retired register form
; (`%qa = cq_phi_si32(%q, θ)` in the arm, measured 2026-09-05 on the
; `pre-3qlq` worktree binary), so the surface change churned no message here.
;
; WHERE IT COMES FROM, precisely: `classifyPhaseKickback` deliberately does NOT
; ask whether the compare is Q+Q, so this region is ACCEPTED at detection and
; `lowerCompareToFlag` refuses at the emitter's step 1. That is safe — and only
; safe — because the mint is the FIRST emission, so the module is untouched when
; the emitter returns. `emitRegion`'s flat phase path has the identical structure.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  %c = icmp eq i32 %q, %p
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: no template for opcode 'icmp i1' in tainted context
