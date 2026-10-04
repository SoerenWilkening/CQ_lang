; loop_carried_handle_reject_postloop_rotation.ll — bd `test_C_libtooling-zujr`,
; THE RULE-8 TRIPWIRE, and the fixture the increment's own PROTOCOL F-10 obligation
; produced: *"an accept-direction widening of a CONDITION fence owes one
; rolled-vs-unrolled probe with a trailing non-diagonal gate on every register the
; condition reads."*
;
; THE PROGRAM is the owner's rolled cascade with an S-dagger after the loop:
;   int a = 5; bool b0[3];
;   for (int i = 0; i < 3; ++i) { if (a >= 3) cq_theta(&b0[i], .5);
;                                 if (b0[i]) a -= 3; }
;   cq_theta(&a, -0.5);
;   return cq_measure(b0[0]) + cq_measure(a);
;
; ⚠ THE DECLINE STRING MOVED AND THE MOVE IS NOT A FENCE WEAKENING — READ THIS
; BEFORE "FIXING" IT.  On the ORACLE (`cq-opt` 07d93784…) this module declined
; `cq controlled lowering: condition predates a non-diagonal gate`, anchored at
; the region CONDITION.  That string was NOT the 2c wire fence speaking: the
; post-loop `cq_theta(&a,-.5)` is PROVABLY POST-REGION, so `condWireDisposition`
; returned `ProvenPostRegion`, which sets `DeferredWireGate` — and
; `DeferredWireGate` RE-SPELLS EVERY LATER DECLINE IN `classifyArms` AS THE WIRE
; MESSAGE.  What actually declined was the R7-loop clause (c3).  So the oracle's
; string was already a mislabel (CLAUDE.md L6), and removing the (c3)
; over-decline (bd `8h7d.11`) simply stopped producing it.  BISECTED, not
; inferred: of the nine toggles in `$SES/probes/` only `no_c3` restores the old
; string.
;
; ⚠ WHAT DECLINES NOW, AND WHY THIS FILE EXISTS: the region is ACCEPTED (a
; controlled state prep is a ROTATION arm, so the P1 clause
; `SawValueArm || !(SawPhaseArm || SawRotationArm)` does not fire on the deferred
; gate) and the module dies at the 4.4 DATA SELECT instead, generically.  THE
; SELECT IS THE ONLY THING STANDING BETWEEN THIS PROGRAM AND A RULE-8 WRONG
; UNITARY: the per-trip `a - 3` chain rails and the superseded registers are left
; ALIVE and ENTANGLED, and `cqrt_ry_i32` then runs on the register they record
; before it is measured.  The FLAT twin already compiles that circuit, with the
; ruled WARNING `cq rotation lowering: non-diagonal gate over a live derived
; record` (bd `lyyf`) — measured, exit 0, on BOTH binaries — so the class is
; PRE-EXISTING (bd `s82e` / bd `tu9q`) and this increment does not widen it: the
; rolled form is strictly MORE conservative here than the flat one.
;
; ⚠⚠ L8 RETIREMENT TRIGGER, and it is the reason this file must not be deleted:
; THE DAY THE SELECT WALL MOVES — bd `r903` (the `i8` `_Bool` wire) or bd `fg9k`,
; either of which gives the 4.4 data select the leaf this condition needs — THIS
; MODULE ACCEPTS, AND WHAT IT ACCEPTS IS THE RULE-8 HAZARD ABOVE.  It is then
; bd `s82e`'s fence that owes it, not this predicate (Rule 14: a second spelling
; of another track's fence is the drbq Inc-3 (b') defect).  Re-derive this file
; then, as an ACCEPT with that fence's decline, or as a quarantined divergence
; with the argument written out.  Do NOT delete it, and do NOT close it by
; narrowing `loopCarriedHandlePhi`: the predicate is not what admits the gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #3
  br label %10

2:                                                ; preds = %20
  %3 = tail call i32 @cq_theta_si32(i32 noundef %25, double noundef -5.000000e-01) #3
  %4 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #3
  %7 = zext i1 %6 to i32
  %8 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %9 = add nsw i32 %8, %7
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #3
  ret i32 %9

10:                                               ; preds = %0, %20
  %11 = phi i64 [ 0, %0 ], [ %26, %20 ]
  %12 = phi i32 [ 5, %0 ], [ %25, %20 ]
  %13 = icmp sgt i32 %12, 2
  br i1 %13, label %14, label %20

14:                                               ; preds = %10
  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %11
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef 5.000000e-01) #3
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %15, align 1, !tbaa !6
  br label %20

20:                                               ; preds = %14, %10
  %21 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %11
  %22 = load i8, ptr %21, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = trunc nuw i8 %22 to i1
  %24 = add nsw i32 %12, -3
  %25 = select i1 %23, i32 %24, i32 %12
  %26 = add nuw nsw i64 %11, 1
  %27 = icmp eq i64 %26, 3
  br i1 %27, label %2, label %10, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
