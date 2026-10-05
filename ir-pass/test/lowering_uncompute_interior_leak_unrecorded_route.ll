; lowering_uncompute_interior_leak_unrecorded_route.ll — LEAK PROBE (M-B
; Increment 6, clause (d2)). THE ROUTE HALF OF THE SAME FENCE: a `cqrt_cswap`
; pair on the borrowed parent, strictly inside the interval, that NO emitter
; recorded as a restoring route.
;
; Clause (d2) admits a route only as a MEMBER OF A RECORDED GROUP
; (`TaintSet::RestoringRoutes`).
;
; ⚠ THAT SET HAS HAD **NO WRITER** SINCE bd drbq Inc 2a (2026-09-02). Its only
; writer WAS `SwapRouteEmit`'s flat PHASE path, which emits no route (Inc 2a made
; its arm gate one `cqrt_rz_<W>_controlled`; since bd 3qlq it is the kickback
; `cqrt_rz_i1` on the flag). So this fixture's discrimination ("hand-written
; cswaps are in no group") is now true BY CONSTRUCTION rather than by test design:
; with the set permanently empty, `routeGroupFullyInside` has exactly one
; reachable return value and no fixture can pin its `true` branch. The VERDICT
; below is unchanged and still correct, and the clause-(d2) machinery is
; deliberately KEPT and annotated (`Uncomputation.cpp` `routeGroupFullyInside`)
; because the 7.2 abort park (`AbortParkEmit`) still emits a route and could start
; recording (the 4.3 nest, 4.5 switch and method-B value arm routes Inc 2a also
; named are retired by bd 3qlq). Recorded in the Inc-2a round-1 review (L3 F3/N1).
;
; Pairing, bracket closure, and "the join is the
; adjoint of the split" are the EMITTER's invariants; re-deriving them here by
; scanning the IR for two cswaps would be a second, weaker spelling of a property
; that already has an owner (Rule 14) — and it would silently claim a route whose
; route-back swaps in an ANSWER (the pre-3qlq method-B VALUE arm's), so the base's
; label genuinely changes.
;
; The two `cqrt_cswap` calls below are hand-written and therefore in no group.
; `preservesBorrowedParent` refuses them (a route is not one of the
; proven-read-only shapes), LEFT fails (they are after the interval opens), RIGHT
; fails (they are before the discharge would go), and clause (d2) finds no group
; — so the component leaks and `%a` is left allocated.
;
; DISCRIMINATION: `%b`, an interior chain on a wire the cswaps never touch, IS
; discharged in the same function.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEA < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_cswap(i32, i32, i32)

define i32 @leak_unrecorded_route(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %fl = call i32 @cqrt_alloc_i32(i32 0)
  %rl = call i32 @cqrt_alloc_i32(i32 0)
  ; the REFUSED component: its borrowed parent %q is cswapped mid-interval
  %a  = mul i32 %q, 3
  call void @cqrt_cswap(i32 %fl, i32 %q, i32 %rl)
  call void @cqrt_cswap(i32 %fl, i32 %q, i32 %rl)
  %ak = and i32 %a, 12
  ; the DISCRIMINATING component, on the other wire
  %b  = mul i32 %p, 7
  %bk = and i32 %b, 20
  %m1 = call i32 @cq_measure_si32(i32 %ak)
  %m2 = call i32 @cq_measure_si32(i32 %bk)
  %s  = add i32 %m1, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @leak_unrecorded_route(
; CHECK:      %[[A:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 3)
; CHECK-NEXT: call void @cqrt_cswap(
; CHECK-NEXT: call void @cqrt_cswap(
; CHECK-NEXT: %[[AK:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[A]], i32 12)
; the discrimination — the untouched wire's chain rail IS discharged:
; CHECK-NEXT: %[[B:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 7)
; CHECK-NEXT: %[[BK:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[B]], i32 20)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[B]], i32 %{{.*}}, i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])

; …and the cswapped component's rail is never adjointed and never freed:
; NOFREEA:     %[[A2:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 3)
; NOFREEA-NOT: @cq_template_mul_i32_hl_unc(i32 %[[A2]],
; NOFREEA-NOT: call void @cqrt_free(i32 %[[A2]])
