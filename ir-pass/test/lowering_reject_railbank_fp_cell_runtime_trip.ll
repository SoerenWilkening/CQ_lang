; lowering_reject_railbank_fp_cell_runtime_trip.ll — DECLINE (bd `test_C_libtooling-01po.19`).
;
; clause C3: an `f64` cell (`abiWidthFromType` gives "f64", which `widthHasReversibleCopy` refuses), with a RUNTIME walk trip.
;
; WHY THIS FILE EXISTS. Runtime trips are in the 01po.19 scope (owner ruling
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`), so the clause must keep
; firing for them, not only for `lowering_reject_railbank_fp_cell.ll`'s constant trip. The rolled window model
; (RailWindow.h) REFUSES this array (its cells have no reversible integer copy, or
; one access is a byte view of a wider cell), so it never claims it and the
; rail-bank clause below still owns the decline. `CQ_RAILWINDOW_DBG` must print no
; claim. Same module as `lowering_reject_railbank_fp_cell.ll`, with the walk's exit compare `%8 = icmp eq i64 %7, 3`
; compared against `%cq.trip`, a classical value read from an external global.
;
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='CQ_RAILWINDOW_DBG' --implicit-check-not='tainted value stored to memory'
; CHECK: cq rail bank: array element is not a reversible rail cell

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cq_trip = external global i64, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %cq.trip = load i64, ptr @cq_trip, align 8
  %1 = alloca [3 x double], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %1, i8 0, i64 24, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = getelementptr inbounds [3 x double], ptr %1, i64 0, i64 %3
  %5 = load double, ptr %4, align 8, !tbaa !6
  %6 = tail call double @cq_theta_f64(double noundef %5, double noundef 5.000000e-01) #4
  store double %6, ptr %4, align 8, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, %cq.trip
  br i1 %8, label %10, label %2, !llvm.loop !10

9:                                                ; preds = %10
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %1) #4
  ret i32 %17

10:                                               ; preds = %2, %10
  %11 = phi i64 [ %18, %10 ], [ 0, %2 ]
  %12 = phi i32 [ %17, %10 ], [ 0, %2 ]
  %13 = getelementptr inbounds [3 x double], ptr %1, i64 0, i64 %11
  %14 = load double, ptr %13, align 8, !tbaa !6
  %15 = tail call double @cq_measure_f64(double noundef %14) #4
  %16 = fptosi double %15 to i32
  %17 = add nsw i32 %12, %16
  %18 = add nuw nsw i64 %11, 1
  %19 = icmp eq i64 %18, 3
  br i1 %19, label %9, label %10, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #3

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
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
