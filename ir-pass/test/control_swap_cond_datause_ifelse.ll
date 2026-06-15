; control_swap_cond_datause_ifelse.ll — ACCEPT probe (ziov WI-1, adversarial):
; shared condition flag on a two-arm IF/ELSE (both successors hold a phase gate,
; reconverging at a 2-incoming merge phi).
;
; `if (q>5) rz(q,a); else rz(q,b);` with `%c = q>5` ALSO read as data (`zext →
; add → ret`, escaped). BOTH arms route off the SAME shared flag (the else arm
; ¬flag-bracketed), and the data `zext` consumes that same flag. ONE mint, two
; rails freed, no strip, NO flag free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %d = zext i1 %c to i32            ; DATA use of the condition compare
  br i1 %c, label %then, label %else
then:
  %t = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
else:
  %e = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %t, %then ], [ %e, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  %r  = add i32 %m, %d             ; keep %d live — escapes via ret
  ret i32 %r
}

; ONE flag, shared by the data use (zext) and BOTH arms' routes:
; CHECK:         %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:         call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; CHECK:         call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %{{[a-zA-Z0-9_.]+}})
; The flag is NEITHER stripped NOR freed; only the two work rails are freed:
; CHECK-NOT:     cq_template_icmp_sgt_i32_hl_inv
; CHECK-NOT:     _controlled

; CNT-COUNT-1: call i32 @cq_template_icmp_sgt_i32_hl(
; CNT-NOT:     call i32 @cq_template_icmp_sgt_i32_hl(
; Exactly two frees (the two rails) — the shared flag is NEVER freed:
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
