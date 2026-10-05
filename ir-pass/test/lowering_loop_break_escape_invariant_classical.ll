; lowering_loop_break_escape_invariant_classical.ll — ACCEPT (bd
; test_C_libtooling-923w). The discriminating twin of
; lowering_loop_break_escape_classical_counter.ll (a decline until bd 8h7d.17,
; then named lowering_reject_break_escape_classical_counter.ll; it now lowers the
; escaping counter through a capture register): the SAME module with ONE
; operand changed, the exit φ's in-loop incoming `%15` (i.next, loop-VARIANT) ->
; `%2` (the bound n, loop-INVARIANT):
;
;     %iex = phi i32 [ 0, %7 ], [ %2, %10 ]
;     %c2  = icmp eq i32 %iex, 2
;     br i1 %c2, label %ph, label %end
;     ph:  call void @cq_phi(double 7.0e-01)
;
; WHY IT IS CORRECT. No value defined inside the loop escapes except through the
; escape φ, so the full-trip virtualization changes nothing the program can read
; after the loop: `%iex` is `n > 0 ? n : 0` in the source and in the lowering,
; a classical value. The phase under it is under CLASSICAL control only, hence
; global, and `deleteGlobalPhases` deletes it (owner decision D2). The break
; construct and the `p == 3` kickback before it lower exactly as in
; lowering_loop_break_qq_phase.ll. Without this twin, E16 could be a wall ("any
; exit φ beside the answer declines") rather than a test of loop variance; since
; bd 8h7d.17 it also pins that a loop-INVARIANT carrier gets no capture register
; (no `cq.brk.esc.*` mint): only a value computed inside the loop is lowered as
; a control-merge register.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PHASE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ESC < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @break_escape_invariant(
; CHECK: call void @cqrt_rz_i1(i32 {{%[a-z0-9_.]+}}, double 3.000000e-01), !cq.branchphase
; CHECK: %cq.brk.out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %iex = phi i32 [ 0, %{{[0-9]+}} ], [ %2, %{{[0-9]+}} ]
; CHECK: call void @cqrt_copy_i32(i32 %cq.brk.R, i32 %cq.brk.out)
; CHECK: cq.brk.rev:
; CHECK: cq.brk.tail:
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.R)
; CHECK-NEXT: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK-NEXT: %c2 = icmp eq i32 %iex, 2
; CHECK: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
;
; --- one phase gate (the kickback); the classically controlled phase is deleted.
; PHASE-COUNT-1: call void @cqrt_rz_
; PHASE-NOT: call void @cqrt_rz_
; PHASE-NOT: call void @cq_phi(
;
; --- bd 8h7d.17: a loop-invariant carrier is not an escape; no capture register.
; ESC: %cq.brk.out = call i32 @cqrt_alloc_i32(i32 0)
; ESC-NOT: cq.brk.esc


target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @break_escape_invariant(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
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
  %iex = phi i32 [ 0, %7 ], [ %2, %10 ]
  %c2 = icmp eq i32 %iex, 2
  br i1 %c2, label %ph, label %end

ph:
  tail call void @cq_phi(double noundef 7.000000e-01) #3
  br label %end

end:
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
