; lowering_mc_late_fallback_measured_chain.ll — FALLBACK (M-C Increment 7a, bd
; test_C_libtooling-x67f). The site stays OUT OF PLACE; that is the existing
; lowering, not a decline (see the sibling _fallback_reader_after.ll's header).
;
; WHAT IT PINS: NO PLAN ENTRY MEANS NO CONVERSION. The late round trusts a prior
; producer only when the M-B interior partition has PLANNED that producer's rail
; for discharge. Here the derived condition's chain rail is MEASURED after the
; region, so `ChainWalk::isInteriorTerminalHandle` refuses it on (I3) — a
; measure user disqualifies a rail, and rightly: `FreePoint` classifies a
; measured terminal as `Measured` and the spine emits neither an adjoint nor a
; free for it, so the rail stands entangled with the register for the rest of
; the program. Converting the subtraction would then relabel a register that a
; live record still describes.
;
; NOTE WHICH HALF OF THE CHAIN STILL DISCHARGES, because the file would be
; misread otherwise: the `ashr` rail IS interior (its only consumer is the QQ
; `add`), so M-B uncomputes and frees it before the region — visible in the
; CHECK chain below. It is the QQ `add` rail, the one the user measures, that
; has no owner. A partial plan is normal; what the fence asks is whether the
; SPECIFIC prior reader of the site's parent is in it, and the `add` reads the
; parent.
;
; NO RED STATE EXISTS on any earlier plugin (before Increment 7a nothing
; converted late at all). MEASURED MUTATION instead (bd memory
; [rule12-pins-without-a-red-state-2026-08-29]): replacing arm (d2)'s plan
; lookup in `ArithLowering::priorUseIsSettled` with a blanket
;     return true;
; (i.e. "any prior rail-minting producer is settled") converts the sub here and
; reddens ELEVEN fixtures — this file, _fallback_reader_after.ll and
; _fallback_terminal_dag.ll (which cover the three independent steps of that
; arm), PLUS the eight ordinary Q+C arithmetic fixtures whose parent then has a
; "settled" prior template reader and converts at the late round:
; lowering_add_qc_{i1,i8,i16,i32,i64}.ll, lowering_xor_qc_i32.ll,
; lowering_sub_negative.ll and lowering_intrinsic_smin_fanout_skip.ll. Dropping
; only the POSITION test leaves this file green (it reddens
; _fallback_reader_after.ll ALONE), which is what shows this one pins membership
; rather than placement.
;
; THE COUNT WAS WRONG HERE UNTIL THE INCREMENT-7 RULE-13 ROUND (finding F2, and
; the same class as Increment 6's F-A): this header said "this + the other two",
; and the reviewer measured eleven — re-measured independently in the fix round
; (`lit ir-pass/test` under M2: 1245 pass / 1 XFAIL / 11 fail, the list above).
; The direction is harmless — the family discriminates from eight MORE sides
; than claimed — but an off-by-eight measured claim is exactly the kind of
; statement this project's defence rests on being literal (Rule 19).
;
; `%off` is a volatile load so nothing folds it away.
;
; SHAPE (`clang -O1` output of):
;     int a = cq_theta(u, 0.5);
;     int t = (a >> 2) + a;
;     if (t == 5) a = cq_phi(a, PI);
;     int mt = cq_measure(t);
;     a -= off;
;     return cq_measure(a) + mt;
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCONV < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @late_measured_chain(i32 noundef %0, ptr noundef %1) {
  %3 = load volatile i32, ptr %1, align 4
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = ashr i32 %4, 2
  %6 = add nsw i32 %5, %4
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %10
8:
  %9 = call i32 @cq_phi_si32(i32 noundef %4, double noundef 0x400921FB54442D18)
  br label %10
10:
  %11 = phi i32 [ %9, %8 ], [ %4, %2 ]
  %12 = call i32 @cq_measure_si32(i32 noundef %6)
  %13 = sub nsw i32 %11, %3
  %14 = call i32 @cq_measure_si32(i32 noundef %13)
  %15 = add nsw i32 %14, %12
  ret i32 %15
}

; CHECK-LABEL: define i32 @late_measured_chain(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[SH:.*]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[AD:.*]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[SH]])
; the OWNED half of the chain discharges immediately — M-B is working here
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[SH]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SH]])
; the region, then the user's own measurement of the chain rail
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %{{.*}}, i32 %[[AD]], i32 5)
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[AD]])
; THE SITE, out of place: `%[[AD]]` is a prior reader of `%[[H]]` with no plan
; entry, so arm (d2) refuses and a fresh rail carries `a - off`.
; CHECK-NEXT: %[[SUB:.*]] = call i32 @cq_template_sub_i32_hl(i32 %[[H]], i32 %3)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[SUB]])
; and the measured chain rail is never uncomputed and never freed (Rule 6 —
; left allocated, the whole reason it cannot be trusted)
; CHECK-NOT: cq_template_add_i32_unc

; NOCONV-NOT: cqrt_addc_i32
; NOCONV-NOT: cqrt_xorc_i32
; SILENT pins 'no diagnostic of any kind' on the pass's stderr: since owner
; ruling 2026-08-29 (bd lyyf) the M-A guard WARNS and opt exits 0 either way, so
; only stderr can witness silence (Inc-7 fix-round re-review R2/R3).
; SILENT-NOT: warning
; SILENT-NOT: error
