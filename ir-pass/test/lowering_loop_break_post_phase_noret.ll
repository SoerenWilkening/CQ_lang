; lowering_loop_break_post_phase_noret.ll — POSITIVE emission (bd
; test_C_libtooling-tinh, the "function with no ret" clause). The program of
; lowering_loop_break_post_phase_answer.ll in a function that ends in a noreturn
; `exit` instead of a `ret`. The module below is `clang -O1`'s output for this C,
; unedited apart from the ModuleID / source_filename lines:
;
;     void exit(int);
;     void break_post_phase_noret(int x, int pseed, int n) {
;         int p = pseed; cq_theta(&p, 0.5);
;         int q = x; cq_theta(&q, 0.25);
;         for (int i = 0; i < n; i++) { q = q ^ 9; if (q == p) break; }
;         if (q == 5) cq_phi(0.3);
;         exit(cq_measure(q));
;     }
;
; `lineageCarriesBranchPhase` keeps a COARSE answer for a function with no `ret`
; (its control-dependence walk reads post-dominance over returning paths, which
; is vacuous here), so before the fix any branch phase in the function declined
; B3. The construct filter is asked first: a phase whose block cannot reach the
; loop header is a later gate whatever the function's exits, so it is skipped
; before the coarse fallback is consulted. The stream and its trace argument are
; lowering_loop_break_post_phase_answer.ll's, ending in `exit` instead of `ret`.
; STILL COARSE (reported, not changed): a branch phase that CAN reach the header
; in a no-`ret` function, e.g. a pre-loop kickback on a comparand, which a
; returning function lowers (lowering_loop_break_qq_phase.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define void @break_post_phase_noret(
; CHECK: cq.brk.tail:
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.R)
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK-NEXT: [[F:%[a-z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.out, i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[F]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[F]], i32 %cq.brk.out, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 [[F]])
; CHECK-NEXT: [[M:%[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %cq.brk.out)
; CHECK-NEXT: call void @exit(i32 noundef [[M]])
; CHECK-NEXT: unreachable

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noreturn nounwind ssp uwtable
define void @break_post_phase_noret(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #3
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #3
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %15

7:                                                ; preds = %3, %7
  %8 = phi i32 [ %12, %7 ], [ 0, %3 ]
  %9 = phi i32 [ %10, %7 ], [ %5, %3 ]
  %10 = xor i32 %9, 9
  %11 = icmp eq i32 %10, %4
  %12 = add nuw nsw i32 %8, 1
  %13 = icmp eq i32 %12, %2
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %7, !llvm.loop !6

15:                                               ; preds = %7, %3
  %16 = phi i32 [ %5, %3 ], [ %10, %7 ]
  %17 = icmp eq i32 %16, 5
  br i1 %17, label %18, label %19

18:                                               ; preds = %15
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  br label %19

19:                                               ; preds = %18, %15
  %20 = tail call i32 @cq_measure_si32(i32 noundef %16) #4
  tail call void @exit(i32 noundef %20) #5
  unreachable
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
attributes #5 = { noreturn nounwind }

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
