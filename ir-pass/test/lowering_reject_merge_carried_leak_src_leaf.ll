; lowering_reject_merge_carried_leak_src_leaf.ll — DECLINE: a leaked loop-carried merge rail composed with a
; later non-diagonal gate on a register it records.
;
; THE HAZARD (bd test_C_libtooling-r2j3.32, routing decision (b) of 2026-10-15).
; `a` is the loop-carried handle variable: each trip's merge rail is the next
; trip's copy source, so no trip's rail can be reversed before the next trip's
; is (LIFO across trips: a post-loop reverse loop, bd 8h7d.20, not emitted
; yet). Two trips' rails therefore stay allocated holding CNOT records of the
; trip's condition and copied sources — an ACCEPTED leak, as long as nothing
; after the loop acts non-diagonally on a register they record. Here something
; does: a later `cq_theta(&x, .3)` on the copied SOURCE register `x` (the original
; r2j3.32 shape rotated the source). Lowered silently, that rotation would interfere branches the
; leaked records still tell apart — a dephased, wrong unitary (the r2j3.32
; miscompile, one loop out). Without the rotation the program is an ACCEPT
; (measured 2026-10-15; the shipped twin is
; `tests/e2e/slice_control_cascade_loop_carried_handle.c`).
;
; TWO WALLS. The composition is declined UPSTREAM today, by the string pinned
; below (character for character), before the merge discharge runs. The
; discharge's own fence — `MergeCarriedFence.h`, diagnostic `cq merge
; discharge: non-diagonal gate on a register a leaked loop-carried merge rail
; records` — is the second wall: no source program reaches it while the
; upstream fence holds, so it is pinned on hand-lowered IR by
; `cq-merge-selftest` (`Inputs/merge_selftest/carried_fence.ll`, case
; `src_leaf_loud`, ctest `ir-pass-merge-discharge-selftest`). If the upstream string
; below ever stops firing, the expected replacement is THAT diagnostic, not an
; accept: re-derive this fixture against it.
;
; Source (clang -O1, the IR below verbatim):
;   int main(int u) {
;       int a = 5;
;       int x = u + 7;
;       cq_theta(&x, 0.2);
;       bool b0[3];
;       for (int i = 0; i < 3; ++i) {
;           cq_theta(&b0[i], 0.5);
;           if (b0[i]) a = x;
;       }
;       cq_theta(&x, 0.3);
;       return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a) + cq_measure(x);
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function main i32 (i32): cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [3 x i8], align 1
  %3 = add nsw i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %2) #4
  br label %27

5:                                                ; preds = %27
  %6 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 3.000000e-01) #3
  %7 = load i8, ptr %2, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8) #4
  %10 = zext i1 %9 to i32
  %11 = getelementptr inbounds i8, ptr %2, i64 1
  %12 = load i8, ptr %11, align 1, !tbaa !6, !range !10, !noundef !11
  %13 = trunc nuw i8 %12 to i1
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13) #4
  %15 = zext i1 %14 to i32
  %16 = add nuw nsw i32 %15, %10
  %17 = getelementptr inbounds i8, ptr %2, i64 2
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = trunc nuw i8 %18 to i1
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %19) #4
  %21 = zext i1 %20 to i32
  %22 = add nuw nsw i32 %16, %21
  %23 = tail call i32 @cq_measure_si32(i32 noundef %35) #4
  %24 = add nsw i32 %22, %23
  %25 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %26 = add nsw i32 %24, %25
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %2) #4
  ret i32 %26

27:                                               ; preds = %1, %27
  %28 = phi i64 [ 0, %1 ], [ %36, %27 ]
  %29 = phi i32 [ 5, %1 ], [ %35, %27 ]
  %30 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %28
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %32, double noundef 5.000000e-01) #3
  %34 = zext i1 %33 to i8
  store i8 %34, ptr %30, align 1, !tbaa !6
  %35 = select i1 %33, i32 %4, i32 %29
  %36 = add nuw nsw i64 %28, 1
  %37 = icmp eq i64 %36, 3
  br i1 %37, label %5, label %27, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
