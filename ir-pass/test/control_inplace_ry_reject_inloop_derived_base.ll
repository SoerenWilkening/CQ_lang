; control_inplace_ry_reject_inloop_derived_base.ll — DECLINE (PRD §13.2 row DB,
; and the increment's MANDATORY probe — §13.2c): a DERIVED OUT-OF-PLACE rotated
; base minted before the loop.
;
;     int p = cq_theta(...); int r = p * 5;
;     for (...) { if (q == 5) r = cq_theta(r, .9); q = cq_phi(q, .1); }
;
; R7-loop CLAUSE (b') OWNS IT, AT DETECTION. The rail phi for `r` has its external
; incoming `%3 = mul nsw i32 %2, 5`, and `peelInPlaceBase` stops at a `mul` (no
; in-place ABI — a `mul` mints a FRESH rail), so `railPhiRootMint` — the round-2
; collapse's own step-(1) body, called here rather than re-spelt — returns null and
; the region is refused with the loop string.
;
; WHY THE CLAUSE EXISTS, MEASURED RATHER THAN READ (§13.2c demanded exactly this
; probe, run FIRST, before anything else in the increment was trusted). With R7's
; loop clause lifted and NOTHING else changed, this module declined
; `stale rail record read past a controlled Ry` on R6's FLAT predicates — it did
; NOT accept, so there was no over-accept and the increment proceeded. With R6 also
; made per-activation and clause (b') absent, it would have been EMITTED and
; FLATTENED and then declined downstream at `declineClassicalMuxes`, whose
; `tainted value muxed by a classical-condition phi` string calls a QUANTUM
; register a classical mux — the "accepted then declined after mutation" shape this
; epic has already had to fix once. Clause (b') turns that into a clean
; pre-mutation decline with an accurate message.
;
; THE PRD PREDICTED THE DOWNSTREAM MUX MESSAGE AS THE MEASURED ONE FOR THE
; R7-LIFTED PROBE AND THAT PREDICTION WAS WRONG (flat R6 fires first); corrected in
; place. The disposition it argued for — decline, at detection, with the loop
; string — is what shipped.
;
; The body below is verbatim `clang -O1` output.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_phi_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %3 = mul nsw i32 %2, 5
  br label %8

4:                                                ; preds = %15
  %5 = tail call i32 @cq_measure_si32(i32 noundef %17) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %16) #2
  %7 = add nsw i32 %6, %5
  ret i32 %7

8:                                                ; preds = %0, %15
  %9 = phi i32 [ 0, %0 ], [ %18, %15 ]
  %10 = phi i32 [ %3, %0 ], [ %16, %15 ]
  %11 = phi i32 [ %1, %0 ], [ %17, %15 ]
  %12 = icmp eq i32 %11, 5
  br i1 %12, label %13, label %15

13:                                               ; preds = %8
  %14 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #2
  br label %15

15:                                               ; preds = %13, %8
  %16 = phi i32 [ %14, %13 ], [ %10, %8 ]
  %17 = tail call i32 @cq_phi_si32(i32 noundef %11, double noundef 1.000000e-01) #2
  %18 = add nuw nsw i32 %9, 1
  %19 = icmp eq i32 %9, 0
  br i1 %19, label %8, label %4, !llvm.loop !6
}

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
