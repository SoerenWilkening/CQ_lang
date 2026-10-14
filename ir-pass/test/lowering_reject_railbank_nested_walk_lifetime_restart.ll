; lowering_reject_railbank_nested_walk_lifetime_restart.ll — DECLINE (bd `test_C_libtooling-01po.19`, review round 1 F2).
;
; Pins the one-store rail bank's clause C2' one level up (a re-executed walk) on a shape the rolled window model
; (RailWindow.h) REFUSES, so the clause is still a reachable decline after S1-S3.
; The module is `lowering_reject_railbank_nested_walk.ll` (main b568a908) with one change: the object's
; `lifetime.start` is RE-EXECUTED at the top of the walk loop (block `2:`) with
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
; CHECK: cq rail bank: the cell walk is re-executed by an enclosing loop

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %2

2:                                                ; preds = %0, %4
  %3 = phi i32 [ 0, %0 ], [ %5, %4 ]
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1)
  br label %7

4:                                                ; preds = %7
  %5 = add nuw nsw i32 %3, 1
  %6 = icmp eq i32 %3, 0
  br i1 %6, label %2, label %17, !llvm.loop !6

7:                                                ; preds = %2, %7
  %8 = phi i64 [ 0, %2 ], [ %14, %7 ]
  %9 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %8
  %10 = load i8, ptr %9, align 1, !tbaa !9, !range !13, !noundef !14
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 5.000000e-01) #4
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !9
  %14 = add nuw nsw i64 %8, 1
  %15 = icmp eq i64 %14, 3
  br i1 %15, label %4, label %7, !llvm.loop !15

16:                                               ; preds = %17
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %25

17:                                               ; preds = %4, %17
  %18 = phi i64 [ %26, %17 ], [ 0, %4 ]
  %19 = phi i32 [ %25, %17 ], [ 0, %4 ]
  %20 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %18
  %21 = load i8, ptr %20, align 1, !tbaa !9, !range !13, !noundef !14
  %22 = trunc nuw i8 %21 to i1
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %22) #4
  %24 = zext i1 %23 to i32
  %25 = add nuw nsw i32 %19, %24
  %26 = add nuw nsw i64 %18, 1
  %27 = icmp eq i64 %26, 3
  br i1 %27, label %16, label %17, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
!9 = !{!10, !10, i64 0}
!10 = !{!"_Bool", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !7, !8}
!16 = distinct !{!16, !7, !8}
