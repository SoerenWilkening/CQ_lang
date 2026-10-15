; railwindow_s5_reject_partial_writeback_loop.ll — DECLINE (bd `test_C_libtooling-01po.19` S5 R11 round 1,
; finding C-F1, in a loop; the one predicate `railWindowWritesBack`, RailWindow.h).
;
; The partial write-back inside a loop body, where the in-place round's G5
; same-trip exemption admitted it on c16aacb6: the CNOT fired every trip while
; the store-back ran only on trips with argc > i. The must-write-back walk is
; per trip (it fails on reaching the update again around the back edge, or a
; read of a cell that may be this one, before a write-back).
;
; SOURCE (clang -O1, verbatim below):
;   int main(int argc, char **argv) {
;     bool q[3] = {0};
;     for (int i = 0; i < 3; i++) cq_theta(&q[i], .5 + .2 * i);
;     int r = 0;
;     for (int i = 0; i < 2; i++) {
;       bool x = q[i + 1] ^ q[i];
;       if (argc > i) q[i + 1] = x;
;       r = 2 * r + cq_measure(x);
;     }
;     for (int i = 0; i < 3; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq rail window: quantum array not lowered yet (bd 01po.19), needs S5 cell update not written back once on every path (bd 01po.19.14){{$}}

; ModuleID = 'railwindow_s5_reject_partial_writeback_loop.c'
source_filename = "railwindow_s5_reject_partial_writeback_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %3) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %3, i8 0, i64 3, i1 false)
  br label %4

4:                                                ; preds = %2, %4
  %5 = phi i64 [ 0, %2 ], [ %14, %4 ]
  %6 = getelementptr inbounds [3 x i8], ptr %3, i64 0, i64 %5
  %7 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  %9 = trunc nuw nsw i64 %5 to i32
  %10 = uitofp nneg i32 %9 to double
  %11 = tail call double @llvm.fmuladd.f64(double %10, double 2.000000e-01, double 5.000000e-01)
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef %11) #6
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %6, align 1, !tbaa !6
  %14 = add nuw nsw i64 %5, 1
  %15 = icmp eq i64 %14, 3
  br i1 %15, label %16, label %4, !llvm.loop !12

16:                                               ; preds = %4
  %17 = sext i32 %0 to i64
  br label %18

18:                                               ; preds = %16, %30
  %19 = phi i64 [ 0, %16 ], [ %21, %30 ]
  %20 = phi i32 [ 0, %16 ], [ %34, %30 ]
  %21 = add nuw nsw i64 %19, 1
  %22 = getelementptr inbounds [3 x i8], ptr %3, i64 0, i64 %21
  %23 = load i8, ptr %22, align 1, !tbaa !6, !range !10, !noundef !11
  %24 = getelementptr inbounds [3 x i8], ptr %3, i64 0, i64 %19
  %25 = load i8, ptr %24, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = icmp ne i8 %23, %25
  %27 = icmp slt i64 %19, %17
  br i1 %27, label %28, label %30

28:                                               ; preds = %18
  %29 = zext i1 %26 to i8
  store i8 %29, ptr %22, align 1, !tbaa !6
  br label %30

30:                                               ; preds = %28, %18
  %31 = shl nsw i32 %20, 1
  %32 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %26) #5
  %33 = zext i1 %32 to i32
  %34 = or disjoint i32 %31, %33
  %35 = icmp eq i64 %19, 0
  br i1 %35, label %18, label %37, !llvm.loop !15

36:                                               ; preds = %37
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %3) #5
  ret i32 %46

37:                                               ; preds = %30, %37
  %38 = phi i64 [ %47, %37 ], [ 0, %30 ]
  %39 = phi i32 [ %46, %37 ], [ %34, %30 ]
  %40 = shl nsw i32 %39, 1
  %41 = getelementptr inbounds [3 x i8], ptr %3, i64 0, i64 %38
  %42 = load i8, ptr %41, align 1, !tbaa !6, !range !10, !noundef !11
  %43 = trunc nuw i8 %42 to i1
  %44 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %43) #5
  %45 = zext i1 %44 to i32
  %46 = or disjoint i32 %40, %45
  %47 = add nuw nsw i64 %38, 1
  %48 = icmp eq i64 %47, 3
  br i1 %48, label %36, label %37, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }

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
!16 = distinct !{!16, !13, !14}
