; control_swap_cond_datause_escape.ll — ACCEPT probe (ziov WI-1): the tainted
; condition compare is used in BOTH a control AND a data position, and the data
; lineage ESCAPES via `ret`.
;
; `%c = icmp sgt q, 5` feeds the diamond's `br` (control) AND a `zext` (data) — the
; CSE of a `q>5` reused as a boolean value `f`. The flat 4.1 classifier USED to
; decline this outright ("condition used outside the branch"); ziov re-derives the
; correct lowering (owner 2026-06-15): the control flag IS `q>5`, so the route and
; the data use must read ONE shared physical flag — mint it once, route with it,
; and feed the SAME handle to the data `zext`. The flag's eager strip+free is
; SKIPPED because its data lineage (`zext → add → ret`) escapes to the caller —
; FreePoint already treats that chain as Escaped (left allocated, caller owns it).
; Net: ONE icmp mint, NO `_inv` flag-strip, NO flag free.
;
; ADVERSARIAL POSTCONDITION (the ziov bug it fixes): exactly ONE
; cq_template_icmp_sgt_i32_hl — NOT two distinct flag handles (the route and the
; data use controlled by different physical flags was the verify-clean redundancy).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT mint scan: exactly ONE sgt flag, and never its `_inv` strip.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
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
  %m  = call i32 @cq_measure_si32(i32 %qm)
  %r  = add i32 %m, %d             ; keep %d live — escapes via ret
  ret i32 %r
}

; ONE flag mint, shared by the data use (zext) and the arm's controlled gate —
; the data use is emitted at the compare position, BEFORE the arm stream (drbq
; Inc 2a: the arm is one `cqrt_rz_i32_controlled` on q, not a cswap route):
; CHECK:         %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:         call i32 @cq_template_zext_i1_to_i32(i32 %[[F]])
; CHECK:         call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; The flag is NEITHER stripped NOR freed (its data lineage escapes):
; bd `8txa` retarget: the flag STRIP is spelled `_unc` now, so asserting
; the absence of `_inv` here would be VACUOUS — nothing emits `_inv`.
; CHECK-NOT:     cq_template_icmp_sgt_i32_hl_unc
; …and no rail is allocated or freed at all on this path (there is no work rail
; to free, and the shared flag is the data lineage's to reclaim — Rule 6):
; CHECK-NOT:     call void @cqrt_free(
; CHECK-NOT:     cqrt_cswap

; CNT-COUNT-1: call i32 @cq_template_icmp_sgt_i32_hl(
; CNT-NOT:     call i32 @cq_template_icmp_sgt_i32_hl(

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
