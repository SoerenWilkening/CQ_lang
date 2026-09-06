; control_phase_kickback_mixed_preheader_addc_after_region_inloop.ll — ACCEPT.
; bd test_C_libtooling-3qlq Inc 1, the FOURTH C-1 round (bd 7yd0). THE THIRD
; POPULATION MEMBER OF THE `hasOneUse` RETIREMENT, and the one with NO MERGE IN IT
; AT ALL — found by sweeping the whole C-1 reproducer corpus, not by the finding.
;
;     int q = cq_theta(u, 0.5); int r = cq_theta(u, 0.3);
;     if (q > 5) cq_phi(0.4);              // a flat kickback REGION on `q`
;     q = q + 7;                           // PREHEADER dtzb op on the SAME register
;     for (int i = 0; i < 3; ++i) {
;         if ((q >> i) & 1) cq_phi(0.2);   // D4's per-bit idiom, ROLLED
;         r = cq_theta(r, 0.1);            // ... and a CARRIED register: MIXED loop
;     }
;     q = cq_theta(q, 0.9);                // the DIFFUSION
;     return cq_measure(q) + cq_measure(r);
;
; `clang -O1` output verbatim (`@main` dropped). Single TU, plain C.
;
; WHY IT IS A THIRD SHAPE. `commitOutOfLoopInPlaceOps`' retired stability conjunct
; `P->hasOneUse()` asked "does the parent have any other user?", and here the other
; user is the REGION'S OWN COMPARE. That is not a merge out-rail and not a later
; read: by the time the commit runs (inside the round-2 `collapseFlattenedLoopRails`)
; `lowerControlRegions` has already turned it into
; `cq_template_icmp_sgt_i32_hl`, whose rail is `_unc`'d AND `cqrt_free`d before the
; `add` — so `priorUseIsSettled` arm (d) settles it and M-C lowers the op in place.
; `hasOneUse` could not see any of that; G6/G7 can, and do.
;
; MEASURED on `main` a3c1513: 3 `cq_template_and_i32_hl` mints / **0** `_hl_unc`
; (36-line trace) against a hand-unrolled twin of the same source at **3/3** (42),
; at `opt` exit 0, verify-clean and STRICT stage 2b `0 violation(s)`. Here it is
; 3/3 and the two traces are BYTE-IDENTICAL, 42 = 42. Three which-path records of
; `q`'s low bits used to live through `cqrt_ry_i32(%h, 0.9)` — a different unitary
; (Rule 8), invisible to 2b.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The preceding region: mint, kickback, strip, free — and it is exactly the
; `_unc` + `cqrt_free` pair that makes the compare a SETTLED prior use.
; CHECK: %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK: %[[C:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[C]], double 4.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[C]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 7)

; The ROLLED body, in order, with the per-iteration discharge that was missing.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %{{.*}}, double 1.000000e-01)

; ⭐ THE ASSERTION. ZERO on `main` a3c1513.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; The preheader op is IN PLACE, exactly once, with no adjoint of it anywhere.
; PCNT-COUNT-1: call void @cqrt_addc_i32(
; PCNT-NOT: call void @cqrt_addc_i32(
; PCNT-NOT: @cqrt_addc_{{[a-z0-9]+}}_inv(
; PCNT-NOT: @cq_template_add_i32_hl(

; Two kickback gates: the flat region's and the body's.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; Three frees: the flat region's flag, then the body's bit rail + flag.
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; Two `cqrt_x`: the body kickback's ¬flag bracket only — the flat region's arm is
; the TRUE successor and needs none.
; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; WHOLE-FILE PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: fneg
; NOROUTE-NOT: call void @cqrt_rz_i1(i32 %{{.*}}, double -

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = icmp sgt i32 %2, 5
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  tail call void @cq_phi(double noundef 4.000000e-01) #2
  br label %6

6:                                                ; preds = %5, %1
  %7 = add nsw i32 %2, 7
  br label %13

8:                                                ; preds = %20
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 9.000000e-01) #2
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2
  %11 = tail call i32 @cq_measure_si32(i32 noundef %21) #2
  %12 = add nsw i32 %11, %10
  ret i32 %12

13:                                               ; preds = %6, %20
  %14 = phi i32 [ 0, %6 ], [ %22, %20 ]
  %15 = phi i32 [ %3, %6 ], [ %21, %20 ]
  %16 = shl nuw nsw i32 1, %14
  %17 = and i32 %16, %7
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %20, label %19

19:                                               ; preds = %13
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %20

20:                                               ; preds = %19, %13
  %21 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 1.000000e-01) #2
  %22 = add nuw nsw i32 %14, 1
  %23 = icmp eq i32 %22, 3
  br i1 %23, label %8, label %13, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
