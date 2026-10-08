; lowering_stale_speccall_reject_round2_breakescape_sibling.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 2 R2-2: an L1 window). Hand IR (the
; review's probe p2_brkesc_sibling).
;
; The branch `%c2` reads `%iex`, a 7.4 break-escape value: CLASSICAL at the early
; stale sweep and at round-1 detection, TAINTED only at round 2
; (`repropagateControlMerges`). Arm %a holds the lifted read `g(%p)`, the sibling arm
; %b an in-place Ry on `%p`. At the early sweep the call is not under tainted control,
; so it is asked with the reader policy and granted by path exclusivity; under round-2
; taint both arms run, which the pure-op policy refuses. The re-ask
; (`declineTaintedArmLiftedReads`, called immediately before EVERY
; `detectControlRegions`, here round 2's) asks the pure-op question again and
; declines with the stale-record string. Before it, the same module died one stage
; later at ArmClassify's value-arm call reject (`value-arm swap-route under quantum
; control`): loud by accident, with the stale question never asked. This CHECK
; distinguishes the two.
; RETIREMENT TRIGGER (L7): with lowering_stale_speccall_reject_tainted_sibling_arms.ll,
; the day a control emitter claims a value arm holding a lifted call.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function f i32 (i32, i32, i32): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @g(i32 noundef %x) #4 {
  %m = mul nsw i32 %x, 3
  %r = add nsw i32 %m, 1
  ret i32 %r
}

define i32 @f(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %p = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 7.000000e-01) #2
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
  %c2 = icmp sgt i32 %iex, 2
  br i1 %c2, label %a, label %b

a:
  %d = tail call i32 @g(i32 noundef %p)
  br label %m

b:
  %p2 = tail call i32 @cq_theta_si32(i32 noundef %p, double noundef 3.000000e-01) #2
  br label %m

m:
  %r = phi i32 [ %d, %a ], [ %p2, %b ]
  %ma = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %mb = tail call i32 @cq_measure_si32(i32 noundef %r) #3
  %s = add i32 %ma, %mb
  ret i32 %s
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
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
