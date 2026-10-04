; control_phase_kickback_reject_cmp_round2_sibling_theta_sdagger.ll — DECLINE
; (Track A.1, Rule-13 ROUND-1 finding F-A1-1: a CONFIRMED SILENT MISCOMPILE in
; the increment's own first spelling, bd test_C_libtooling-9pum returning
; verbatim). THE COMMITTED STAGE-1 MODULE OF THE PLAIN-C REPRODUCER — two TUs
; through the shipped 6.5 recipe (per-TU `clang -O1`, `llvm-link`, ONE
; `cq-lowering`), from `session-9pum/probes/k7_{caller,lib3}.c`, which is the
; reviewer's `review_a1_r1_probes/k7_caller.c` + `lib3.c` verbatim:
;
;     int q = 3; cq_theta(&q, 0.5);
;     int y = 5; if (q > 5) y = ext_f(7);      /* 6.5 classical-call arm -> %out */
;     int z = 0; if (opaque()) z = ext(1);     /* a classical diamond, to split  */
;     int b  = y; cq_theta(&b, 0.25);
;     int b3 = y; cq_theta(&b3, 0.9);          /* the ROUND-2 sibling: ONE rail  */
;     if (b > 1) cq_phi(0.3);                  /* the control read               */
;     int b2 = b; cq_theta(&b2, -0.25);        /* the S-DAGGER, post-region      */
;     return cq_measure(b3) + cq_measure(b2) + z;
;
; It is `control_phase_kickback_reject_cmp_round2_sibling_theta.ll` PLUS ONE
; LINE, the post-region S-dagger — and that one line used to buy the whole
; program back. MEASURED on `main` 0c7380c AND on the first Track-A.1 build:
; ACCEPT, exit 0, verify-clean, STRICT stage-2b `0 violation(s)`, emitting
;   cqrt_ry_i32(%out, 0.25) ; cqrt_ry_i32(%out, 0.9)
;   cq_template_icmp_sgt_i32_hl(%out, 1) ; cqrt_rz_i1(%h_cmp, 0.3)
; — the flag minted from `Ry(.9)Ry(.25)|y>` while the source compares
; `Ry(.25)|y>`, so the kicked-back P(0.3) marks a different subspace. A
; different unitary, at exit 0.
;
; WHY THE FIRST SPELLING MISSED IT, and it is the whole lesson: rung (iii)'s
; round-2 re-ask was suppressed by a BOOLEAN — "is SOME gate visible taint-blind?"
; — and `findNonDiagonalWireGate` returns ONE gate. The S-dagger `%18` IS visible
; taint-blind (and `condWireDisposition`'s DT prong legitimately proves it
; post-region, so the classifier ACCEPTED it), and its visibility suppressed the
; re-ask about a DIFFERENT gate, `%14`, which only round-2 taint reveals. The
; fence was defeated by making the condition wire DIRTIER — the inverse of a
; safety property. It is now a SET DIFFERENCE: the taint-blind gates are
; ENUMERATED (`collectNonDiagonalWireGates`) and passed back as the `Covered`
; exempt set, so the exemption names gates instead of suppressing entries.
;
; THE THREE DISCRIMINATORS, all committed: `..._round2_sibling_theta.ll` (this
; program without the S-dagger — declined before the fix too),
; `control_phase_kickback_cmp_sdagger_post_region.ll` (this program without the
; ROUND-2 SIBLING — the S-dagger alone is a shipped ACCEPT and must stay one),
; and `session-9pum/probes/k9_caller.c` (the extra line on ANOTHER register —
; declined before the fix, which is what made the defect visible).

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ]
  %7 = tail call i32 @opaque() #3
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %5
  %10 = tail call i32 @ext(i32 noundef 1) #3
  br label %11

11:                                               ; preds = %9, %5
  %12 = phi i32 [ %10, %9 ], [ 0, %5 ]
  %13 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01) #3
  %14 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 9.000000e-01) #3
  %15 = icmp sgt i32 %13, 1
  br i1 %15, label %16, label %17

16:                                               ; preds = %11
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %17

17:                                               ; preds = %16, %11
  %18 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef -2.500000e-01) #3
  %19 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %20 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %21 = add i32 %19, %12
  %22 = add i32 %21, %20
  ret i32 %22
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @opaque() local_unnamed_addr #2 {
  ret i32 1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @ext(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 1
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

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
