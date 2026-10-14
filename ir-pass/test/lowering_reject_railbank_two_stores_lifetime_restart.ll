; lowering_reject_railbank_two_stores_lifetime_restart.ll — DECLINE (bd `test_C_libtooling-01po.19`, review round 1 F2).
;
; Pins the one-store rail bank's clause C4 (two store sites) on a shape the rolled window model
; (RailWindow.h) REFUSES, so the clause is still a reachable decline after S1-S3.
; The module is `lowering_reject_railbank_two_stores.ll` (main b568a908) with one change: the object's
; `lifetime.start` is RE-EXECUTED at the top of the walk loop (block `4:`) with
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
; CHECK: cq rail bank: array is written from more than one store site

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %4

2:                                                ; preds = %20
  %3 = tail call i32 @cq_measure_si32(i32 noundef %25) #3
  br label %29

4:                                                ; preds = %0, %20
  %5 = phi i64 [ 0, %0 ], [ %26, %20 ]
  %6 = phi i32 [ 5, %0 ], [ %25, %20 ]
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1)
  %7 = icmp sgt i32 %6, 2
  br i1 %7, label %8, label %20

8:                                                ; preds = %4
  %9 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 5.000000e-01) #3
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !6
  %14 = sub nuw nsw i64 3, %5
  %15 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %14
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef 2.500000e-01) #3
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %15, align 1, !tbaa !6
  br label %20

20:                                               ; preds = %8, %4
  %21 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %22 = load i8, ptr %21, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = trunc nuw i8 %22 to i1
  %24 = add nsw i32 %6, -3
  %25 = select i1 %23, i32 %24, i32 %6
  %26 = add nuw nsw i64 %5, 1
  %27 = icmp eq i64 %26, 4
  br i1 %27, label %2, label %4, !llvm.loop !12

28:                                               ; preds = %29
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %37

29:                                               ; preds = %2, %29
  %30 = phi i64 [ 0, %2 ], [ %38, %29 ]
  %31 = phi i32 [ %3, %2 ], [ %37, %29 ]
  %32 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %30
  %33 = load i8, ptr %32, align 1, !tbaa !6, !range !10, !noundef !11
  %34 = trunc nuw i8 %33 to i1
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34) #3
  %36 = zext i1 %35 to i32
  %37 = add nsw i32 %31, %36
  %38 = add nuw nsw i64 %30, 1
  %39 = icmp eq i64 %38, 4
  br i1 %39, label %28, label %29, !llvm.loop !15
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
!15 = distinct !{!15, !13, !14}
