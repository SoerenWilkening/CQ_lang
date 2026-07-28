; control_swap_cond_datause_negarm.ll — ACCEPT probe (ziov WI-1, adversarial):
; shared condition flag on a NEGATED diamond (the gate arm is the FALSE
; successor, Rule 9 — clang -O1 swaps the branch targets).
;
; `br i1 %c, label %merge, label %arm` routes the gate on ¬flag (the `cqrt_x`
; bracket), AND `%c` is reused as data (`zext → add → ret`, escaped). The flag's
; VALUE is independent of arm polarity, so the shared `q>5` flag feeds the data
; `zext` correctly while the route fires on ¬flag. ONE mint, no strip, no flag
; free — the ¬flag `cqrt_x` brackets must survive on the SHARED flag handle.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %d = zext i1 %c to i32            ; DATA use of the condition compare
  br i1 %c, label %merge, label %arm   ; NEGATED: gate arm is the FALSE successor
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  %r  = add i32 %m, %d             ; keep %d live — escapes via ret
  ret i32 %r
}

; ONE flag, shared by the data use (zext) and the ¬flag-bracketed route:
; CHECK:         %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:         call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; CHECK:         call void @cqrt_x(i32 %[[F]])
; CHECK:         call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:         call void @cqrt_x(i32 %[[F]])
; bd `8txa` retarget: the flag STRIP is spelled `_unc` now, so asserting
; the absence of `_inv` here would be VACUOUS — nothing emits `_inv`.
; CHECK-NOT:     cq_template_icmp_sgt_i32_hl_unc
; CHECK-NOT:     _controlled

; CNT-COUNT-1: call i32 @cq_template_icmp_sgt_i32_hl(
; CNT-NOT:     call i32 @cq_template_icmp_sgt_i32_hl(
