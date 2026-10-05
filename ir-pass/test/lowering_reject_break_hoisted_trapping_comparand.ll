; lowering_reject_break_hoisted_trapping_comparand.ll — DECLINE (bd
; test_C_libtooling-8h7d.15; the decline twin of
; lowering_loop_break_hoisted_comparand.ll). The module below is `clang -O1`'s
; output for this C, unedited apart from the ModuleID / source_filename lines:
;
;     int break_hoisted_div(int x, int pseed, int k, int d, int n) {
;         int p = pseed; cq_theta(&p, 0.5);
;         int q = x; cq_theta(&q, 0.25);
;         for (int i = 0; i < n; i++) { q = q ^ 9; if (q == p + k / d) break; }
;         return cq_measure(q);
;     }
;
; LICM hoists `k / d` and `p + k / d` into the DEDICATED preheader (%9). E17 of
; `emitBreakForward` lowers a dedicated preheader by hoisting its instructions into
; the zero-trip guard (%5), which puts each of them on the zero-trip path. An
; `sdiv` by a runtime divisor fails `isSafeToSpeculativelyExecute`: with n <= 0
; and d == 0 (or k == INT_MIN, d == -1) the source never divides and the hoisted
; program would trap. So E17 refuses, and the emitter's recognized-but-non-
; canonical decline fires; it mirrors `kMsgBreakUnemittable` character for
; character.
;
; This is a compiler gap, not a physics limit (R1): lowering it needs the
; preheader's values made available to the reverse-play without running them on
; the zero-trip path (for instance by emitting the reverse-play on the loop's own
; exit edge). RETIREMENT TRIGGER: when that lands this file becomes an accept;
; re-derive its stream from the hand trace in the twin, do not delete it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @break_hoisted_div(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %8 = icmp sgt i32 %4, 0
  br i1 %8, label %9, label %20

9:                                                ; preds = %5
  %10 = sdiv i32 %2, %3
  %11 = add nsw i32 %10, %6
  br label %12

12:                                               ; preds = %12, %9
  %13 = phi i32 [ 0, %9 ], [ %17, %12 ]
  %14 = phi i32 [ %7, %9 ], [ %15, %12 ]
  %15 = xor i32 %14, 9
  %16 = icmp eq i32 %15, %11
  %17 = add nuw nsw i32 %13, 1
  %18 = icmp eq i32 %17, %4
  %19 = select i1 %16, i1 true, i1 %18
  br i1 %19, label %20, label %12, !llvm.loop !6

20:                                               ; preds = %12, %5
  %21 = phi i32 [ %7, %5 ], [ %15, %12 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #3
  ret i32 %22
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
