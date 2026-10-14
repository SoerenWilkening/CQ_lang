; lowering_reject_railbank_two_stores_runtime_trip.ll — DECLINE (bd `test_C_libtooling-01po.19`).
;
; clause C4 (two store sites into one bank), with a RUNTIME walk trip.
;
; WHY THIS FILE EXISTS. `lowering_reject_railbank_two_stores.ll` pinned this clause with a CONSTANT
; trip. Since bd 01po.19 that shape compiles: `unrollQuantumArrayWalks` (RailBankUnroll.h)
; fully unrolls the constant-trip loops that index a quantum array the rolled bank does
; not own and SROA scalarizes it. The clause is still reachable whenever a variable cell
; index sits in a loop without a SCEV-proven constant trip, because the stage's trial on
; a clone then fails and the module reaches the rail-bank verdict BYTE-UNTOUCHED. This is
; the same module with the walk's exit compare `%27 = icmp eq i64 %26, 4` turned into a compare
; against `%cq.trip`, a classical value read from an external global at entry.
;
; This decline is a gap, not a physics limit (NORTHSTAR goal 1): the rolled lowering of
; a runtime-trip multi-site / re-executed walk is the remaining 01po.19 follow-up.
; RETIREMENT TRIGGER: when that lowering lands, re-derive this file as an ACCEPT.
;
; `--implicit-check-not` proves the stage left the module for its owner (its debug
; lever prints `left for its owner`, never `scalarized`). A `DS_Error` writes nothing to
; stdout, so the property is the `not` inversion plus the exact message (one diagnostic:
; `LLVMContext::diagnose` exits on the first error, bd `br4a`).
;
; RUN: env CQ_RAILBANK_UNROLL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='scalarized' --implicit-check-not='tainted value stored to memory'
; CHECK: cq rail bank: array is written from more than one store site

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cq_trip = external global i64, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %cq.trip = load i64, ptr @cq_trip, align 8
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
  icmp eq i64 %26, %cq.trip
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
