; loop_acc_reject_inloop_exit_seed_constant.ll — DECLINE (bd 01po.19.18.6, R11 round 1
; rA1A-F1; invariant (4): the zero-trip rename touches the BYPASS edge only).
;
; SOURCE (clang -O1, verbatim below; the reviewer's u1_unprobed_reset_break.c):
;   /* UNPROBED (reviewer probe budget exhausted). Hypothesis F1: an in-loop exit edge whose
;      exit-phi incoming is the same uniqued constant as the seed is renamed to the register
;      by commitSeededAccumulator (DT.dominates(Entry, inLoopBlock) is true), so the break
;      path reads seed+sum instead of 0. Expected C semantics: the k-trip break yields c==0. */
;   #include <stdio.h>
;   #include <stdlib.h>
;   int main(int argc, char **argv) {
;       int n = atoi(argv[1]), k = atoi(argv[2]);
;       int a = 0; cq_theta(&a, 1.0);
;       int c = 0;
;       for (int i = 0; i < n; i++) { c += a; if (i == k) { c = 0; break; } }
;       printf("%d %d\n", cq_measure(c), cq_measure(a));
;       return 0;
;   }
;
; The exit φ `%20 = phi [0, %2], [%16, %15], [0, %11]` merges the SEED on the
; guard's bypass edge (%2, outside the loop) and the uniqued constant `0` of
; `c = 0; break;` on an IN-LOOP exit edge (%11). Only the bypass edge carries the
; register's value (the loop never ran); the in-loop `0` is the program's reset,
; NOT the register, which by then holds the trips' sum. Renaming it read
; seed + Σ on the break path (C says 0). The commit now renames edges from
; OUTSIDE the loop only, so the in-loop `0` stays classical and the φ is a
; classical mux of a register: loud, at the mux guard. (Before the fix the module
; also failed loudly, at the record fence, which saw the renamed edge read past
; the loop's gates; the invariant was broken, the stream was not emitted.)
; RETIREMENT TRIGGER: a reset-on-break lowering (the 7.4 break escape register)
; makes this an accept with a trace check.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #4
  %10 = icmp sgt i32 %5, 0
  br i1 %10, label %11, label %19

11:                                               ; preds = %2, %15
  %12 = phi i32 [ %17, %15 ], [ 0, %2 ]
  %13 = phi i32 [ %16, %15 ], [ 0, %2 ]
  %14 = icmp eq i32 %12, %8
  br i1 %14, label %19, label %15

15:                                               ; preds = %11
  %16 = add nsw i32 %13, %9
  %17 = add nuw nsw i32 %12, 1
  %18 = icmp eq i32 %17, %5
  br i1 %18, label %19, label %11, !llvm.loop !10

19:                                               ; preds = %15, %11, %2
  %20 = phi i32 [ 0, %2 ], [ %16, %15 ], [ 0, %11 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  %22 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %23 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %21, i32 noundef %22)
  ret i32 0
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }


!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
