; spec_reject_select_aliased_leaf.ll — DECLINE (bd 7q3s), the PHASE-6 CLONE twin
; of control_swap_reject_select_aliased_leaf.ll. Same aliased-operand compare
; (`fcmp uno double %x, %x`), but inside a classical callee the specializer would
; lift, so it reaches `Specialization.cpp`'s `lowerCloneSelect`/`mintCondNetwork`
; rather than the top-level 4.4 emitter.
;
; This fixture exists because the two paths mint through DIFFERENT code
; (`mintCondNetwork` does not call `compareFlagMintable`) but SHARE
; `collectCondTree` — so one fence covers both, and this pins that it really does.
; Without it a future refactor could fence only the top level and leave the clone
; path minting `cq_template_fcmp_uno_f64(i32 %h, i32 %h)` at exit 0.
;
; Note the diagnostic is the SPECIALIZATION dialect, not the control dialect: the
; callee is declined for lifting rather than the region being declined, which is
; the correct posture — a callee containing an unlowerable condition is simply not
; a liftable callee.
;
;
; SCOPE OF THIS FIXTURE (corrected 2026-07-31 by a Rule-13 finding): it pins the
; SSA-IDENTICAL form only. The claim an earlier draft carried — "no -O1 C program
; reaches this" — is TRUE of this form and FALSE of the hazard in general: a
; cq_phi (Rz) result RAUWs to its argument's rail, so SSA-DISTINCT operands can
; still be ONE RAIL, and that IS reachable from four lines of plain C. The fence
; therefore tests RAIL identity via `operandsAlias`, and the rail form is pinned
; separately by control_swap_reject_select_rail_alias_cond.ll. Do not re-derive
; the zero-blast-radius argument from a corpus scan: a scan for the SSA form
; cannot see the rail form.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cq_template_fcmp_uno_f64
; CHECK-NOT: cqrt_copy_f64_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x = sitofp i32 %n to double
  %c = fcmp uno double %x, %x          ; ALIASED operands — one rail, two slots
  %a = select i1 %c, double 0.000000e+00, double %x
  %r = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
