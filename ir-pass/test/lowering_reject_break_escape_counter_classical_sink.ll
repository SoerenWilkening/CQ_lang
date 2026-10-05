; lowering_reject_break_escape_counter_classical_sink.ll — DECLINE (bd
; test_C_libtooling-8h7d.17; the decline twin of
; lowering_loop_break_escape_classical_counter.ll). The same module with the
; phase under `%iex` replaced by a call that hands `%iex` to an OPAQUE external:
;
;     %iex = phi i32 [ 0, %7 ], [ %15, %10 ]     ; %15 = i.next
;     call void @sink(i32 %iex)
;
; `%iex` depends on when the quantum break fired, so after 8h7d.17 it is a
; quantum register (a control-merge value, `cq.brk.esc.out`), and `sink` has no
; body to lift. Quantum data reaching classical code with no `cq_measure` is
; physics-forbidden (NORTHSTAR goal 1), so the round-2 re-propagation from the
; control-merge rail taints the call and the re-run escape guard declines.
; Before 8h7d.17 the same module declined at E16 with `cq loop lowering: early
; break body is not a provable rolled single-rail loop`; this file pins that the
; widening moved the refusal to the physics boundary rather than dropping it.
; Mirrors the escape guard's message character for character.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @break_escape_counter_sink(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %5 = icmp eq i32 %4, 3
  br i1 %5, label %6, label %7

6:                                                ; preds = %3
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %7

7:                                                ; preds = %6, %3
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %9 = icmp sgt i32 %2, 0
  br i1 %9, label %10, label %18

10:                                               ; preds = %7, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %7 ]
  %12 = phi i32 [ %13, %10 ], [ %8, %7 ]
  %13 = xor i32 %12, 9
  %14 = icmp eq i32 %13, %4
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %2
  %17 = select i1 %14, i1 true, i1 %16
  br i1 %17, label %18, label %10, !llvm.loop !6

18:                                               ; preds = %10, %7
  %19 = phi i32 [ %8, %7 ], [ %13, %10 ]
  %iex = phi i32 [ 0, %7 ], [ %15, %10 ]
  call void @sink(i32 noundef %iex) #3
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  ret i32 %20
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @sink(i32 noundef) local_unnamed_addr #1

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
