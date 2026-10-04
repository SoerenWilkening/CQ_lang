; control_phase_kickback_reject_crossblock_shared_cond_flag.ll — DECLINE. bd
; `test_C_libtooling-drbq.12` (2026-09-17): the fixture for the ONE conjunct that
; keeps the widening off the ziov SHARED-FLAG path.
;
;     int a = 0; cq_theta(&a, 0.5);
;     int f = (a == 5);                      // the compare is ALSO read as DATA
;     if (a == 5) cq_phi(0.7);               // region 1 — compare IS in its Pred
;     if (a == 5) cq_phi(0.7);               // region 2 — Pred is region 1's merge
;     return cq_measure(f) + cq_measure(a);
;
; `clang -O1` CSEs the two compares into one in the entry block, exactly as in
; `control_inplace_ry_crossblock_cse_cond.ll`, so region 2's condition is CROSS-BLOCK
; and would now be admitted by `crossBlockCompareMintable` — except that the compare
; also feeds a data use, which makes `condDataUseDisposition` return `ShareOk` and
; sets `Region.ShareCondFlag`. `condWireDisposition`'s cross-block prong refuses that
; combination explicitly.
;
; ⚠ WHY, AND IT IS AN EMISSION-CONTRACT REASON RATHER THAN A POSITION ONE. On the
; share path `SwapRouteEmit` mints the flag at `Cond->getNextNode()` instead of at
; `BI` — *"`Instruction *FlagAt = R.ShareCondFlag ? Cond->getNextNode() : BI;"* — and
; it SKIPS the eager strip+free, because the data lineage owns the flag downstream.
; With a cross-block condition those two facts collide: the mint lands in the
; COMPARE's block while the rest of the region's stream lands in `Pred`, and (in a
; loop) it would be minted ONCE for a stream that fires per trip.
;
; ⚠ MEASURED, NOT ARGUED. With the `R.ShareCondFlag ||` conjunct deleted from the
; prong and nothing else changed, this module ACCEPTS at exit 0 and emits TWO
; separate flag rails from ONE source compare:
;     %h_cmp1 = cq_template_icmp_eq_i32_hl(%h, 5)
;     %h_cmp  = cq_template_icmp_eq_i32_hl(%h, 5)
;     %h_cast = cq_template_zext_i1_to_i32(%h_cmp1)
;     cqrt_rz_i1(%h_cmp1, …)   cqrt_rz_i1(%h_cmp, …)
; — and NEITHER is stripped or freed, because the share path skips that. `%h_cmp` is
; then a second entangled rail on `%h`'s wire with no owner: the exact "one physical
; flag" invariant the ziov path exists to hold, broken. That is what this file pins.
;
; ⚠ THE Ry-ARM SPELLING OF THIS PROGRAM CANNOT PIN IT, and that is why the fixture is
; a PHASE arm. Measured: the same module with `cq_theta(&r, 0.9)` arms declines
; earlier and elsewhere, `cq controlled lowering: rotation arm shares the condition
; flag under quantum control` — a dedicated rotation-arm refusal that fires before
; `condWireDisposition` is reached, so the conjunct would have no subject there.
;
; ⚠ RETIREMENT TRIGGERS (L8), and the FIRST is the one that matters because it would
; make this file's accept-direction mutant measurement stale rather than merely
; out-of-date:
;   (a) `SwapRouteEmit` stops minting the shared flag at `Cond->getNextNode()` — the
;       whole ground for excluding `ShareCondFlag` from the cross-block admission is
;       that mint POSITION, not anything about the wire. If the share path ever mints
;       at `BI` like every other path, re-derive the conjunct from scratch; it may
;       become an over-decline.
;   (b) `condDataUseDisposition` stops returning `ShareOk` for a `zext`-then-measure
;       lineage — this module would then decline for a different reason and pin
;       nothing. Check the string, not just the exit code.
;   (c) the cross-block prong is narrowed back — this file returns to declining for
;       the ORACLE's reason and its mutant measurement stops isolating anything.
; Re-derive, never delete.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so IR-text negatives here would be
; VACUOUS (Rule 12(b)). The property is pinned by the `not` inversion on the RUN line
; and by the string above; no `CHECK-NOT` is written, deliberately.

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  %z = zext i1 %3 to i32
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  tail call void @cq_phi(double noundef 7.000000e-01) #2
  br label %6

6:                                                ; preds = %4, %0
  br i1 %3, label %8, label %10

8:                                                ; preds = %6
  tail call void @cq_phi(double noundef 7.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %z) #2
  %13 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }
