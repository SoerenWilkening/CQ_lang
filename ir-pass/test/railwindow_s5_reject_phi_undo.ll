; railwindow_s5_reject_phi_undo.ll — DECLINE (bd `test_C_libtooling-01po.19`,
; design Q6 (a), owner ruling owner-ruling-01po19-rolled-design-2026-10-15:
; "-O1 header phis carrying a cell value are mapped back to the cell by SCEV
; address identity; loud if the address cannot be rebuilt").
;
; HAND IR: railwindow_ghz_cnot_walk_accept.ll's clang -O1 module with ONE edit,
; the straight-line store of the rotated rail moved from cell 0 to cell 1. The
; header φ `%5` still carries a cell value on both edges (preheader: the value
; parked in cell 1; latch: the value parked in cell i+1), but the cell it reads
; in trip k would be A(k) with A(0) = cell 1 and A(k+1) = cell k+1 — no single
; affine cell (`A_pre != start - step`). RailWindowPhiUndo.cpp must refuse it
; loudly rather than load the wrong cell or leave a loop-carried rail φ.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq rail window: a loop-carried cell value cannot be mapped back to its cell

; ModuleID = 'ghz.c'
source_filename = "ghz.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FF921FB54442D18) #5
  %3 = zext i1 %2 to i8
  %c1 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 1
  store i8 %3, ptr %c1, align 1, !tbaa !6
  br label %4

4:                                                ; preds = %0, %4
  %5 = phi i8 [ %3, %0 ], [ %11, %4 ]
  %6 = phi i64 [ 0, %0 ], [ %7, %4 ]
  %7 = add nuw nsw i64 %6, 1
  %8 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %7
  %9 = load i8, ptr %8, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = icmp ne i8 %9, %5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %8, align 1, !tbaa !6
  %12 = icmp eq i64 %6, 0
  br i1 %12, label %4, label %14, !llvm.loop !12

13:                                               ; preds = %14
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %23

14:                                               ; preds = %4, %14
  %15 = phi i64 [ %24, %14 ], [ 0, %4 ]
  %16 = phi i32 [ %23, %14 ], [ 0, %4 ]
  %17 = shl nsw i32 %16, 1
  %18 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %15
  %19 = load i8, ptr %18, align 1, !tbaa !6, !range !10, !noundef !11
  %20 = trunc nuw i8 %19 to i1
  %21 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %20) #4
  %22 = zext i1 %21 to i32
  %23 = or disjoint i32 %17, %22
  %24 = add nuw nsw i64 %15, 1
  %25 = icmp eq i64 %24, 3
  br i1 %25, label %13, label %14, !llvm.loop !15
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
attributes #5 = { nomerge nounwind }

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
