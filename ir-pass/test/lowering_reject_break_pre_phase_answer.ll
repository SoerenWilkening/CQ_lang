; lowering_reject_break_pre_phase_answer.ll — DECLINE (bd test_C_libtooling-tinh;
; the decline twin of lowering_loop_break_post_phase_answer.ll). The same program
; with the kickback on the answer register moved BEFORE the loop. The module
; below is `clang -O1`'s output for this C, unedited apart from the ModuleID /
; source_filename lines:
;
;     int break_pre_phase_answer(int x, int pseed, int n) {
;         int p = pseed; cq_theta(&p, 0.5);
;         int q = x; cq_theta(&q, 0.25);
;         if (q == 5) cq_phi(0.3);
;         for (int i = 0; i < n; i++) { q = q ^ 9; if (q == p) break; }
;         return cq_measure(q);
;     }
;
; The phase's block (%7) can reach the loop header (%10), so B3's construct
; filter does not exempt it, and its key `%6 = (%5 == 5)` reads the rail mint %5
; that the escaping answer %19 derives from. B3 declines. This is the policy line
; bd 3by9 kept at the owner's scope (a phase BEFORE the construct whose keys meet
; the answer's lineage), not a proven unitary hazard: see the L5 paragraph of
; `lineageCarriesBranchPhase` in TaintPropagation.h and
; lowering_reject_break_phase_answer_kickback.ll. What it pins here is the
; boundary of the tinh widening: only a phase that cannot reach the construct is
; exempt. Mirrors `kMsgBreakPhase` character for character. (Without B3 the
; module would still decline, at E15, with a different string: the mint is read
; by the pre-loop compare.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break preserves a phase answer

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @break_pre_phase_answer(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %6 = icmp eq i32 %5, 5
  br i1 %6, label %7, label %8

7:                                                ; preds = %3
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %8

8:                                                ; preds = %7, %3
  %9 = icmp sgt i32 %2, 0
  br i1 %9, label %10, label %18

10:                                               ; preds = %8, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %8 ]
  %12 = phi i32 [ %13, %10 ], [ %5, %8 ]
  %13 = xor i32 %12, 9
  %14 = icmp eq i32 %13, %4
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %2
  %17 = select i1 %14, i1 true, i1 %16
  br i1 %17, label %18, label %10, !llvm.loop !6

18:                                               ; preds = %10, %8
  %19 = phi i32 [ %5, %8 ], [ %13, %10 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  ret i32 %20
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
