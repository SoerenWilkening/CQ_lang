; control_swap_cond_datause_measured.ll — ACCEPT probe (ziov WI-1): the tainted
; condition compare is used in BOTH a control AND a data position, and the data
; lineage is MEASURED.
;
; Same `%c = icmp sgt q, 5` reused as control (`br`) AND data (`zext → add →
; measure`). Like the escape twin, the shared flag is minted ONCE and fed to both
; the route and the `zext`; its eager strip+free is SKIPPED because the data
; lineage is consumed by a measurement — the measurement owns the handle
; (FreePoint → Measured, no adjoint/free). Net: ONE icmp mint, NO `_inv`, NO flag
; free. (This is the shape the flat 4.1 path declined as "condition used outside
; the branch"; ziov upgrades that decline to a correct shared-flag accept.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %d = zext i1 %c to i32            ; DATA use of the condition compare
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %sum = add i32 %qm, %d           ; the data flag feeds the measured value
  %m  = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}

; ONE flag mint, shared by the data use (zext) and the route (cswap) — the data
; use is emitted at the compare position, BEFORE the routed stream:
; CHECK:         %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:         call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; CHECK:         call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %{{[a-zA-Z0-9_.]+}})
; The flag is NEITHER stripped NOR freed (its data lineage is measured):
; bd `8txa` retarget: the flag STRIP is spelled `_unc` now, so asserting
; the absence of `_inv` here would be VACUOUS — nothing emits `_inv`.
; CHECK-NOT:     cq_template_icmp_sgt_i32_hl_unc
; CHECK-NOT:     _controlled

; CNT-COUNT-1: call i32 @cq_template_icmp_sgt_i32_hl(
; CNT-NOT:     call i32 @cq_template_icmp_sgt_i32_hl(
