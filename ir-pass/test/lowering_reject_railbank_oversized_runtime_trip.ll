; lowering_reject_railbank_oversized_runtime_trip.ll — DECLINE (bd `test_C_libtooling-01po.19`, review round 1 item 5).
;
; clause C6 (an over-sized bank: `bool b[8]` walked by `for (i < 3)`), kept pinned with a RUNTIME trip on the post-walk READ loop (the walk keeps its constant 3 trips, so C2-prime passes and C6 fires).
;
; WHY THIS FILE EXISTS. `lowering_reject_railbank_oversized.ll` pinned this clause with constant trips. Since bd
; 01po.19 that shape compiles: `unrollQuantumArrayWalks` (RailBankUnroll.h) unrolls the
; constant-trip loops that touch a quantum array the rolled bank does not own and SROA
; scalarizes it. The clause is still reachable whenever a variable cell index sits in a
; loop without a constant trip: the stage's trial fails and the module reaches the
; rail-bank verdict byte-untouched. This is the same module with `%33 = icmp eq i64 %32, 8` compared against
; `%cq.trip`, a classical value read from an external global at entry.
;
; This decline is a gap, not a physics limit (NORTHSTAR goal 1). RETIREMENT TRIGGER:
; the rolled lowering of a runtime-trip walk (01po.19 follow-up) re-derives it.
;
; RUN: env CQ_RAILBANK_UNROLL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='scalarized' --implicit-check-not='tainted value stored to memory'
; CHECK: cq rail bank: array has cells no iteration writes

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cq_trip = external global i64, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %cq.trip = load i64, ptr @cq_trip, align 8
  %1 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %1) #3
  store i64 0, ptr %1, align 8
  br label %4

2:                                                ; preds = %14
  %3 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  br label %23

4:                                                ; preds = %0, %14
  %5 = phi i64 [ 0, %0 ], [ %20, %14 ]
  %6 = phi i32 [ 5, %0 ], [ %19, %14 ]
  %7 = icmp sgt i32 %6, 2
  br i1 %7, label %8, label %14

8:                                                ; preds = %4
  %9 = getelementptr inbounds [8 x i8], ptr %1, i64 0, i64 %5
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 5.000000e-01) #3
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !6
  br label %14

14:                                               ; preds = %8, %4
  %15 = getelementptr inbounds [8 x i8], ptr %1, i64 0, i64 %5
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = add nsw i32 %6, -3
  %19 = select i1 %17, i32 %18, i32 %6
  %20 = add nuw nsw i64 %5, 1
  %21 = icmp eq i64 %20, 3
  br i1 %21, label %2, label %4, !llvm.loop !12

22:                                               ; preds = %23
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %1) #3
  ret i32 %31

23:                                               ; preds = %2, %23
  %24 = phi i64 [ 0, %2 ], [ %32, %23 ]
  %25 = phi i32 [ %3, %2 ], [ %31, %23 ]
  %26 = getelementptr inbounds [8 x i8], ptr %1, i64 0, i64 %24
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #3
  %30 = zext i1 %29 to i32
  %31 = add nsw i32 %25, %30
  %32 = add nuw nsw i64 %24, 1
  %33 = icmp eq i64 %32, %cq.trip
  br i1 %33, label %22, label %23, !llvm.loop !15
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
