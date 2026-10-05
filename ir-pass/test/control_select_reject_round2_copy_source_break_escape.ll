; control_select_reject_round2_copy_source_break_escape.ll — DECLINE (bd
; test_C_libtooling-r2j3.14; hand-written, the reviewer's probe rv-C1/p4). The
; r2j3.14 hazard reached through a 7.4 break escape register (bd 8h7d.17): the
; loop's escaping counter `%iex` feeds a 4.4 select arm after the loop,
;
;     %iex = phi i32 [ 0, guard ], [ i.next, latch ]
;     %ip1 = add i32 %iex, 1
;     %x   = select i1 (p > 3), i32 %ip1, i32 7     ; measured
;
; `emitBreakForward` rewires `%iex`'s users to `cq.brk.esc.out` in `lowerLoops`,
; but `%ip1` stays classical until round 2, so the round-1 select loaded it as a
; classical copy source and, without the fence, `cqrt_alloc_i32` read the escape
; register's handle id (measured on 28e85906, exit 0). The re-ask in
; `declineQuantumCopySources` declines it loudly; see
; control_select_reject_round2_copy_source.ll for the fence.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: classical copy source became quantum-derived under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @f(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %9 = icmp sgt i32 %2, 0
  br i1 %9, label %10, label %18

10:
  %11 = phi i32 [ %15, %10 ], [ 0, %3 ]
  %12 = phi i32 [ %13, %10 ], [ %8, %3 ]
  %13 = xor i32 %12, 9
  %14 = icmp eq i32 %13, %4
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %2
  %17 = select i1 %14, i1 true, i1 %16
  br i1 %17, label %18, label %10, !llvm.loop !6

18:
  %19 = phi i32 [ %8, %3 ], [ %13, %10 ]
  %iex = phi i32 [ 0, %3 ], [ %15, %10 ]
  %ip1 = add i32 %iex, 1
  %sc = icmp sgt i32 %4, 3
  %x = select i1 %sc, i32 %ip1, i32 7
  %a = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %b = tail call i32 @cq_measure_si32(i32 noundef %x) #3
  %r = add i32 %a, %b
  ret i32 %r
}

define i32 @main() #0 {
  %a = call i32 @f(i32 3, i32 5, i32 4)
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
