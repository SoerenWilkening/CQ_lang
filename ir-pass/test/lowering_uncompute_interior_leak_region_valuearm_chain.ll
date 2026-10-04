; lowering_uncompute_interior_leak_region_valuearm_chain.ll — LEAK PROBE (M-B
; Increment 6, bd test_C_libtooling-160a Rule-13 round, finding F1b). The
; METHOD-B VALUE ARM half of "clause (c) records the PHASE path and nothing
; else". The Increment-6 header claims this failure mode is pinned by a leak
; fixture; only the 4.4 SELECT one
; (lowering_uncompute_interior_leak_select_cond_chain.ll) existed. This is the
; other one.
;
; PROVENANCE: `clang -O1` output (a 6-op arm — a shorter one folds to a tainted
; select, PRD §8.4 / slice_control_value_diamond.c) of
;
;     int q = u; cq_theta(&q, 0.5);  int p = u; cq_theta(&p, 0.25);
;     if (((q * 5) >> 2) == 5) { p = p+3; p = p*5; p = p^9; p = p+1; p = p*7; p = p^2; }
;     return cq_measure(q) + cq_measure(p);
;
; WHY IT MUST LEAK, and it is NOT a scope decision. `SwapRouteEmit::emitRegion`
; records its flag strip in `TaintSet::DischargedFlagGates` because a PHASE arm
; leaves the base holding the same BASIS LABEL it went in with, so an `_unc` placed
; after the strip reads the wire the forward chain read.
;
; ⚠ IT NO LONGER RECORDS A CSWAP PAIR IN `TaintSet::RestoringRoutes` — since bd drbq
; Inc 2a (2026-09-02) the flat phase path emits NO route at all (one
; `cqrt_rz_<W>_controlled` in place), so that set has no writer and clause (d2) is
; inert. The licence MOVED TO THE GATE and got stronger there
; (`preservesBorrowedParent` clause (1b): a controlled Rz is `diag(1,e^{iθ})` on
; `f=1` and `I` on `f=0`, so the base's label is never moved, not
; moved-and-restored). Corrected in the Inc-2a round-1 review (L3 F3).
;
; ⚠⚠ THE VALUE ARM'S ROUTE IS GONE TOO, SINCE bd test_C_libtooling-3qlq Inc 2
; (2026-09-05). `emitValueRegion` now HOISTS the arm chain into the pred and hands
; the region to the 4.4 `emitSelectRegion` controlled-copy merge — there is no
; `cqrt_cswap`, no work rail and no reverse-play anywhere in this module any more.
; THE VERDICT IS UNCHANGED AND THE REASON IS NOT: the leak used to be attributed to
; the non-label-restoring cswap group, which no longer exists. The live reason is
; the OTHER half of the same sentence — `emitSelectRegion` (like `emitValueRegion`
; before it) records NOTHING in `DischargedFlagGates`, so clause (c) refuses to
; move a discharge past the flag strip and `%h_op2` (the QQ `add` rail the compare
; reads) is LEFT ALLOCATED: never `_unc`'d, never freed, Rule 6's fallback.
; `%h_op` (the `ashr`) DOES discharge, and that discrimination is still the point
; of the fixture: the partition is alive in this module and is refusing exactly one
; rail, for exactly one reason. If a later increment records the select/value
; strip, this fixture must be re-dispositioned deliberately.
;
; NOTHING NON-DIAGONAL FOLLOWS, so the leak dephases nothing here; if it did, the
; late M-A guard owns the loud decline (that is the `a8` spelling — add an
; S-dagger and this program declines at ArmClassify before it ever gets here).
;
; Its discriminator is a MUTATION, MEASURED (on the pre-3qlq tree): replacing
; clause (c)'s `taint.DischargedFlagGates.count(C)` membership test with a NAME
; test (`getName().ends_with("_unc")`) reddens this fixture together with
; lowering_uncompute_interior_leak_unrecorded_strip.ll,
; lowering_uncompute_interior_leak_select_cond_chain.ll AND the COMP prefix of
; lowering_fp80_union_multiblock.ll, while every recorded-strip accept stays
; green. That is exactly the "membership, never a name test" fence the header of
; `TaintSet::DischargedFlagGates` claims.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCHAIN < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @valuearm_derived(i32 noundef %0) {
  %2 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01)
  %4 = ashr i32 %2, 2
  %5 = add nsw i32 %4, %2
  %6 = icmp eq i32 %5, 5
  br i1 %6, label %7, label %14

7:                                                ; preds = %1
  %8 = mul i32 %3, 5
  %9 = add i32 %8, 15
  %10 = xor i32 %9, 9
  %11 = mul i32 %10, 7
  %12 = add i32 %11, 7
  %13 = xor i32 %12, 2
  br label %14

14:                                               ; preds = %7, %1
  %15 = phi i32 [ %13, %7 ], [ %3, %1 ]
  %16 = call i32 @cq_measure_si32(i32 noundef %2)
  %17 = call i32 @cq_measure_si32(i32 noundef %15)
  %18 = add nsw i32 %17, %16
  ret i32 %18
}

; The region LOWERS as a hoisted value arm merged by two controlled copies:
; CHECK-LABEL: define i32 @valuearm_derived(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; The FIRST condition-chain rail discharges normally (all its consumers are to
; its left); the SECOND (%[[ADD]], read by the compare) does not — see NOCHAIN.
; CHECK:      %[[SH:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i32_hl(i32 %[[Q]], i32 2)
; CHECK-NEXT: %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[Q]], i32 %[[SH]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[SH]], i32 %[[Q]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SH]])
; the HOISTED arm chain on the original %p (M-C converts the in-place links on
; the FRESH intermediate rails, never on %p — %p has a later reader)
; CHECK:      %[[C1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[C1]], i32 15)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[C1]], i32 9)
; CHECK-NEXT: %[[ANS:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[C1]], i32 7)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[C1]], i32 9)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[C1]], i32 -15)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[C1]], i32 %[[P]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C1]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[ANS]], i32 7)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[ANS]], i32 2)
; the controlled-copy merge
; CHECK-NEXT: %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[ADD]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[ANS]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAG]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAG]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FLAG]], i32 %[[ADD]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[OUT]])

; …and the compare's operand rail is NEVER reversed and NEVER freed. The window
; opens at the strip (which names the rail) and runs to EOF; the only `_unc`
; and `cqrt_free` allowed after it are the strip's own pair, checked above (bd
; memory [filecheck-check-not-window-trap]):
; NOCHAIN:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FLAG2:[a-zA-Z0-9_.]+]], i32 %[[ADD2:[a-zA-Z0-9_.]+]], i32 5)
; NOCHAIN-NEXT: call void @cqrt_free(i32 %[[FLAG2]])
; NOCHAIN-NOT:  call void @cq_template_add_i32_unc(i32 %[[ADD2]],
; NOCHAIN-NOT:  call void @cqrt_free(i32 %[[ADD2]])

; Whole-file PURE-NEGATIVE: the value-arm route is retired (3qlq Inc 2).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy_i32(
; NOROUTE-NOT: phi i32
