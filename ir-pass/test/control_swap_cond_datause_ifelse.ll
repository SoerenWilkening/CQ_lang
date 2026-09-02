; control_swap_cond_datause_ifelse.ll — ACCEPT probe (ziov WI-1, adversarial):
; shared condition flag on a two-arm IF/ELSE (both successors hold a phase gate,
; reconverging at a 2-incoming merge phi).
;
; `if (q>5) rz(q,a); else rz(q,b);` with `%c = q>5` ALSO read as data (`zext →
; add → ret`, escaped). BOTH arms route off the SAME shared flag (the else arm
; ¬flag-bracketed), and the data `zext` consumes that same flag. ONE mint, two
; rails freed, no strip, NO flag free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
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

; ONE flag, shared by the data use (zext) and BOTH arms' controlled gates (drbq
; Inc 2a — each arm is one `cqrt_rz_i32_controlled` on q, the ELSE one bracketed):
; CHECK:         %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:         call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; CHECK:         call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT:    call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:    call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; CHECK-NEXT:    call void @cqrt_x(i32 %[[F]])
; The flag is NEITHER stripped NOR freed, and since drbq Inc 2a there is nothing
; ELSE to free either — the two work rails went with the route:
; bd `8txa` retarget: the flag STRIP is spelled `_unc` now, so asserting
; the absence of `_inv` here would be VACUOUS — nothing emits `_inv`.
; CHECK-NOT:     cq_template_icmp_sgt_i32_hl_unc
; CHECK-NOT:     cqrt_cswap

; CNT-COUNT-1: call i32 @cq_template_icmp_sgt_i32_hl(
; CNT-NOT:     call i32 @cq_template_icmp_sgt_i32_hl(
; ZERO frees anywhere in the module — the shared flag is NEVER freed (its data
; lineage owns it) and there is no work rail left to free. Its OWN prefix, with NO
; positive directive at all, so the window is the WHOLE input rather than the tail
; of the CNT scan (bd memory [filecheck-check-not-window-trap]). Deliberately
; unanchored: `tools/fixture_guard_liveness.py` cannot inject against a
; whole-module guard, and it reports an unanchored one as "not checkable, not
; dead" — which is the honest classification, where a `define` anchor made it
; report "anchor unresolvable" and count as DEAD.
; NOFREE-NOT: call void @cqrt_free(

; THE ROUTE'S ABSENCE, ON ITS OWN PREFIX ANCHORED AT THE FUNCTION HEADER (bd
; drbq Inc 2a round-1 review, L3 F2). The trailing `CHECK-NOT: cqrt_cswap`
; above scans only PAST the last positive of the `CHECK` prefix, so a route
; re-inserted AT the arm gate lands before its window and the assertion cannot
; fire (bd memory filecheck-check-not-window-trap). Anchoring at `define` makes
; the window the whole function. MUTATION-VERIFIED: re-inserting
; `cqrt_alloc_<W>(0) + cqrt_cswap` before the first controlled gate turns this
; prefix RED.
; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
