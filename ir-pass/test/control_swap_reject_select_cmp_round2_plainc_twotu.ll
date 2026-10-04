; control_swap_reject_select_cmp_round2_plainc_twotu.ll — DECLINE (Track A.1, bd
; test_C_libtooling-9pum): THE COMMITTED STAGE-1 MODULE OF THE PLAIN-C
; REPRODUCER, so the round-2 window is pinned as a PROGRAM and not only as hand
; IR. Produced by the shipped 6.5 two-TU recipe (`tests/e2e/run_slice_multi.sh`:
; per-TU `clang -O1` IR, then `llvm-link`, then ONE `cq-lowering`) from
; `session-9pum/probes/9pum_{caller,lib}.c`, which is the reviewer's
; `session-r9e5/review_b1_r2_probes/multi/e13_{caller,lib}.c` verbatim:
;
;     /* caller */  int ext_f(int a);
;                   int q = 3; cq_theta(&q, 0.5);
;                   int y = 5; if (q > 5) y = ext_f(7);
;                   int b  = y; cq_theta(&b, 0.25);
;                   int b3 = y; cq_theta(&b3, 0.9);
;                   int a  = (b == 1) ? 2 : 5;
;                   return cq_measure(a) + cq_measure(b3);
;     /* lib    */  int ext_f(int a) { return a + 100; }
;
; MEASURED on `main` 0c7380c: exit 0, verify-clean, STRICT stage 2b clean, a
; 26-line trace whose lines 13/14/15 are `ry(h2,.25); ry(h2,.9); icmp_eq(h2,1)`.
; The callee must be un-inlinable across TUs — that is what makes
; `if (q > 5) y = ext_f(7)` a 6.5 CLASSICAL-CALL ARM and its merge an `%out` rail
; only ROUND 2 taints. Inline it and the window closes.
;
; The hand-IR spelling is `..._reject_select_cmp_round2_sibling_theta.ll`; the
; accept twin, with the sibling AFTER the select, is
; `control_swap_select_cmp_round2_window_accept.ll`.

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
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01) #3
  %8 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 9.000000e-01) #3
  %9 = icmp eq i32 %7, 1
  %10 = select i1 %9, i32 2, i32 5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %13 = add nsw i32 %12, %11
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ]
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01) #3
  %8 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 9.000000e-01) #3
  %9 = icmp eq i32 %7, 1
  %10 = select i1 %9, i32 2, i32 5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  ret i32 0
}

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

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
