; control_phase_kickback_mixed_preheader_r2derived_commuted_outofplace.ll — ACCEPT.
; bd test_C_libtooling-3qlq Inc 1, the THIRD C-1 review round, finding **F-C1B-1**,
; THE COMMUTED SPELLING — the one where the round-2 binary did not merely put a
; rail in the immediate slot but **MUTATED THE WRONG RAIL**.
;
;     int w = y + 1;    /* instead of `y * 3`; everything else is z23 verbatim */
;
; `rewriteInPlaceValueRail` picks its rail by `TL = taint.Tainted.count(L)` — the
; LEFT operand wins. With `w` a round-2-tainted `add_i32_hl` rail and `-O1`
; canonicalising the operand order, the round-2 binary emitted
;
;     call void @cqrt_addc_i32(i32 %h_op, i32 %h4)     ; trace: cqrt_addc_i32(h6, 7)
;
; i.e. it added `h4`'s HANDLE ID to the `y+1` register and then read the per-bit
; condition off THAT — `cq_template_and_i32_hl(h6, 1)` — instead of off `a`'s rail
; at all. Same root cause as its sibling fixture (a G2 answer taken at round 1 and
; consumed at `lowerOps`); a strictly worse symptom, and the reason the fix is a
; refusal at the COMMIT rather than a repair at the emitter.
;
; `clang -O1`, `llvm-link`ed with `int ext_f(int a){return a+100;}`, `@main`
; dropped. RED on the round-2 binary, GREEN on 542d588, on the round-1 fix and
; here (47 trace lines, byte-identical across the three).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

; The derived rail is `y + 1` this time. The Q+Q add never becomes the classical-
; immediate `cqrt_addc_i32` of the finding; since bd r2j3.33 (dm7f.51 step 1) it
; lowers through the QUANTUM-source ABI on `a`'s own rail (`a`'s old value is dead,
; the sum survives), `cqrt_add_i32(src = w, dst = a)` — the file name's
; `outofplace` is historical.
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %[[W:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[OUT]], i32 1)
; CHECK: %[[A:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_add_i32(i32 %[[W]], i32 %[[A]]), !cq.inplace.qq
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[W]], i32 %[[OUT]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[W]])

; ⭐ AND THE CONDITION IS READ OFF `a`'s RAIL (holding the sum), not off the `y+1`
; register. That is the "wrong rail" half of the finding, asserted positively.
; CHECK: call i32 @cq_template_and_i32_hl(i32 %[[A]], i32 %{{.*}})

; PCNT-NOT: call void @cqrt_addc_i32(
; PCNT-NOT: call void @cqrt_xorc_i32(

; Exactly ONE kickback gate in the module (the rolled body's).
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; `#cqrt_rz_i1 == #!cq.branchphase` — an unmarked kickback gate is one the
; uncompute spine would adjoint, cancelling the user's phase exactly (F-L7-1).
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; The `cqrt_free` census — a dropped or an extra free is a Rule-6 defect the
; positive CHECKs cannot see.
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; The `cqrt_x` census: the kickback's polarity bracket(s) and the arm brackets.
; An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; The Q-R1-1 residual, pinned exactly as in the sibling fixture: the per-trip
; `and` rail is minted once and NEVER discharged (the invariant register is a
; template rail, so clause (ii) refuses it).
; (Since bd r2j3.33 the invariant register is `a`'s own rail holding the sum, not
; a template rail; the residual is MEASURED unchanged — same `and`, same count.)
; UCNT-COUNT-1: call i32 @cq_template_and_i32_hl(
; UCNT-NOT: call i32 @cq_template_and_i32_hl(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-4: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; WHOLE-FILE PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: call void @cqrt_addc_i32(i32 %{{[A-Za-z0-9_.]+}}, i32 %
; NOROUTE-NOT: call void @cqrt_xorc_i32(i32 %{{[A-Za-z0-9_.]+}}, i32 %

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  %4 = icmp sgt i32 %2, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ 5, %1 ]
  %9 = add nsw i32 %8, 1
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 0x3FE6666666666666) #3
  %11 = add nsw i32 %9, %10
  br label %18

12:                                               ; preds = %25
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %26) #3
  %15 = add nsw i32 %14, %13
  %16 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %17 = add nsw i32 %15, %16
  ret i32 %17

18:                                               ; preds = %25, %7
  %19 = phi i32 [ 0, %7 ], [ %27, %25 ]
  %20 = phi i32 [ %3, %7 ], [ %26, %25 ]
  %21 = shl nuw nsw i32 1, %19
  %22 = and i32 %21, %11
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %25, label %24

24:                                               ; preds = %18
  tail call void @cq_phi(double noundef 2.000000e-01) #3
  br label %25

25:                                               ; preds = %24, %18
  %26 = tail call i32 @cq_theta_si32(i32 noundef %20, double noundef 1.000000e-01) #3
  %27 = add nuw nsw i32 %19, 1
  %28 = icmp eq i32 %27, 3
  br i1 %28, label %12, label %18, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
