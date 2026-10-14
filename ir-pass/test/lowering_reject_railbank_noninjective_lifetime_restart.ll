; lowering_reject_railbank_noninjective_lifetime_restart.ll — DECLINE (bd `test_C_libtooling-01po.19`, review round 1 F2).
;
; Pins the one-store rail bank's clause C2' (a non-injective index) on a shape the rolled window model
; (RailWindow.h) REFUSES, so the clause is still a reachable decline after S1-S3.
; The module is `lowering_reject_railbank_noninjective.ll` (main b568a908) with one change: the object's
; `lifetime.start` is RE-EXECUTED at the top of the walk loop (block `15:`) with
; no `lifetime.end` between iterations, so a later trip restarts contents an earlier
; trip's access left live. The window model refuses that object (storage not live
; at every access; a per-iteration object needs an end between iterations, F3 (a)),
; and the rail-bank verdict declines it on the clause below.
; `CQ_RAILWINDOW_DBG` must print no claim. Hand IR: `-O1` C always pairs the
; markers, so the plain-C route to these clauses (an array declared inside the
; outer loop) is CLAIMED by the window model since F3 (a).
;
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='CQ_RAILWINDOW_DBG' --implicit-check-not='tainted value stored to memory'
; CHECK: cq rail bank: cell index is not an injective per-iteration index

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [2 x i8], align 2
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %1) #3
  store i16 0, ptr %1, align 2
  br label %15

2:                                                ; preds = %27
  %3 = tail call i32 @cq_measure_si32(i32 noundef %34) #3
  %4 = load i8, ptr %1, align 2, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #3
  %7 = zext i1 %6 to i32
  %8 = add nsw i32 %3, %7
  %9 = getelementptr inbounds i8, ptr %1, i64 1
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #3
  %13 = zext i1 %12 to i32
  %14 = add nsw i32 %8, %13
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %1) #3
  ret i32 %14

15:                                               ; preds = %0, %27
  %16 = phi i32 [ 0, %0 ], [ %35, %27 ]
  %17 = phi i32 [ 5, %0 ], [ %34, %27 ]
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %1)
  %18 = icmp sgt i32 %17, 2
  br i1 %18, label %19, label %27

19:                                               ; preds = %15
  %20 = lshr i32 %16, 1
  %21 = zext nneg i32 %20 to i64
  %22 = getelementptr inbounds [2 x i8], ptr %1, i64 0, i64 %21
  %23 = load i8, ptr %22, align 1, !tbaa !6, !range !10, !noundef !11
  %24 = trunc nuw i8 %23 to i1
  %25 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %24, double noundef 5.000000e-01) #3
  %26 = zext i1 %25 to i8
  store i8 %26, ptr %22, align 1, !tbaa !6
  br label %27

27:                                               ; preds = %19, %15
  %28 = lshr i32 %16, 1
  %29 = zext nneg i32 %28 to i64
  %30 = getelementptr inbounds [2 x i8], ptr %1, i64 0, i64 %29
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = add nsw i32 %17, -3
  %34 = select i1 %32, i32 %33, i32 %17
  %35 = add nuw nsw i32 %16, 1
  %36 = icmp eq i32 %35, 4
  br i1 %36, label %2, label %15, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

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
