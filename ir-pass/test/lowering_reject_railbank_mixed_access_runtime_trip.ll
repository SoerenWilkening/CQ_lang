; lowering_reject_railbank_mixed_access_runtime_trip.ll — DECLINE (bd `test_C_libtooling-01po.19`).
;
; clause C1: a byte view of an int-cell bank, with a RUNTIME walk trip.
;
; WHY THIS FILE EXISTS. Runtime trips are in the 01po.19 scope (owner ruling
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`), so the clause must keep
; firing for them, not only for `lowering_reject_railbank_mixed_access.ll`'s constant trip. The rolled window model
; (RailWindow.h) REFUSES this array (its cells have no reversible integer copy, or
; one access is a byte view of a wider cell), so it never claims it and the
; rail-bank clause below still owns the decline. `CQ_RAILWINDOW_DBG` must print no
; claim. Same module as `lowering_reject_railbank_mixed_access.ll`, with the walk's exit compare `%22 = icmp eq i64 %21, 3`
; compared against `%cq.trip`, a classical value read from an external global.
;
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='CQ_RAILWINDOW_DBG' --implicit-check-not='tainted value stored to memory'
; CHECK: cq rail bank: array mixes a rail cell access with an unrecognized one

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cq_trip = external global i64, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %cq.trip = load i64, ptr @cq_trip, align 8
  %1 = alloca [3 x i32], align 4
  %2 = alloca i8, align 1
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(12) %1, i8 0, i64 12, i1 false)
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %2)
  br label %7

3:                                                ; preds = %15
  %4 = getelementptr inbounds i8, ptr %1, i64 1
  %5 = load i8, ptr %4, align 1, !tbaa !6
  store volatile i8 %5, ptr %2, align 1, !tbaa !6
  %6 = tail call i32 @cq_measure_si32(i32 noundef %20) #4
  br label %27

7:                                                ; preds = %0, %15
  %8 = phi i64 [ 0, %0 ], [ %21, %15 ]
  %9 = phi i32 [ 5, %0 ], [ %20, %15 ]
  %10 = icmp sgt i32 %9, 2
  br i1 %10, label %11, label %15

11:                                               ; preds = %7
  %12 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %8
  %13 = load i32, ptr %12, align 4, !tbaa !9
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 5.000000e-01) #4
  store i32 %14, ptr %12, align 4, !tbaa !9
  br label %15

15:                                               ; preds = %11, %7
  %16 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %8
  %17 = load i32, ptr %16, align 4, !tbaa !9
  %18 = icmp eq i32 %17, 0
  %19 = add nsw i32 %9, -3
  %20 = select i1 %18, i32 %9, i32 %19
  %21 = add nuw nsw i64 %8, 1
  %22 = icmp eq i64 %21, %cq.trip
  br i1 %22, label %3, label %7, !llvm.loop !11

23:                                               ; preds = %27
  %24 = load volatile i8, ptr %2, align 1, !tbaa !6
  %25 = sext i8 %24 to i32
  %26 = add nsw i32 %33, %25
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %2)
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %1) #4
  ret i32 %26

27:                                               ; preds = %3, %27
  %28 = phi i64 [ 0, %3 ], [ %34, %27 ]
  %29 = phi i32 [ %6, %3 ], [ %33, %27 ]
  %30 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %28
  %31 = load i32, ptr %30, align 4, !tbaa !9
  %32 = tail call i32 @cq_measure_si32(i32 noundef %31) #4
  %33 = add nsw i32 %32, %29
  %34 = add nuw nsw i64 %28, 1
  %35 = icmp eq i64 %34, 3
  br i1 %35, label %23, label %27, !llvm.loop !14
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

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
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"int", !7, i64 0}
!11 = distinct !{!11, !12, !13}
!12 = !{!"llvm.loop.mustprogress"}
!13 = !{!"llvm.loop.unroll.disable"}
!14 = distinct !{!14, !12, !13}
