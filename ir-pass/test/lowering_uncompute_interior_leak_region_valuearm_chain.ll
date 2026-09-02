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
;     int q = cq_theta(u, 0.5);  int p = cq_theta(u, 0.25);
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
; moved-and-restored). Nothing about THIS fixture's verdict changes — the value
; arm's route is what leaks, and it was never recorded either. Corrected in the
; Inc-2a round-1 review (L3 F3).
;
; `emitValueRegion` records NEITHER, and the reason is
; visible three lines apart in the stream below: its second `cqrt_cswap` swaps
; the ARM'S ANSWER (`%h_op5`) onto the base, and the third swaps the rail back —
; the group is not label-restoring, so clause (d2) has nothing true to say about
; it. Its strip is read-only on its own, but admitting the strip WITHOUT the
; route would move the discharge past a swap the scan cannot exempt (that is
; bd test_C_libtooling-6uqc.2's "needs its own argument").
;
; SO: `%h_op8` (the QQ `add` rail the compare reads) is LEFT ALLOCATED — never
; `_unc`'d, never freed, Rule 6's fallback. `%h_op7` (the `ashr`) DOES discharge,
; and that discrimination is the point of the fixture: the partition is alive in
; this module and is refusing exactly one rail, for exactly one reason. If a
; later increment records the value-arm strip, this fixture must be
; re-dispositioned deliberately with the route argument written down.
;
; NOTHING NON-DIAGONAL FOLLOWS, so the leak dephases nothing here; if it did, the
; late M-A guard owns the loud decline (that is the `a8` spelling — add an
; S-dagger and this program declines at ArmClassify before it ever gets here).
;
; NO RED STATE EXISTS on any earlier plugin (it leaks on `439dae3` and `f27c7fd`
; too). Its discriminator is a MUTATION, MEASURED: replacing clause (c)'s
; `taint.DischargedFlagGates.count(C)` membership test with a NAME test
; (`getName().ends_with("_unc")`) reddens this fixture together with
; lowering_uncompute_interior_leak_unrecorded_strip.ll,
; lowering_uncompute_interior_leak_select_cond_chain.ll AND the COMP prefix of
; lowering_fp80_union_multiblock.ll (four fixtures, re-measured by the Inc-6
; fix-round re-review), while every recorded-strip accept stays green. That is exactly the "membership, never a name test"
; fence the header of `TaintSet::DischargedFlagGates` claims.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCHAIN < %t.cqd0.ll
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

; The region LOWERS as a method-B value arm — route in, arm ops verbatim on the
; work rail, route the answer onto the base, copy out, route back, reverse-play,
; route the rail back, free, strip:
; CHECK-LABEL: define i32 @valuearm_derived(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; The FIRST chain rail discharges normally (all its consumers are to its left):
; CHECK:      %[[SH:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i32_hl(i32 %[[Q]], i32 2)
; CHECK-NEXT: %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[Q]], i32 %[[SH]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[SH]], i32 %[[Q]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SH]])
; CHECK-NEXT: %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[ADD]], i32 5)
; CHECK-NEXT: %[[RAIL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[P]], i32 %[[RAIL]])
; This is the swap that is NOT label-restoring — the ARM'S ANSWER goes onto the
; base, the copy-out reads it, and only then is the rail swapped back:
; CHECK:      %[[ANS:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 {{.*}}, i32 2)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[P]], i32 %[[ANS]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[P]], i32 %[[ANS]])
; CHECK:      call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[P]], i32 %[[RAIL]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[RAIL]])
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
