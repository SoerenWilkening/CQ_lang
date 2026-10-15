; railwindow_reject_cell_copy_whole_object.ll — DECLINE (bd 01po.19 S4 review
; C-F1, ruling Q2): the plain copy `r[i] = q[i]` that -O1 turns into ONE wide
; `load i32, ptr %q` + `store i32` into the second array. The wide read used
; to make the claim fail and the array declined at the bank ("array mixes a
; rail cell access with an unrecognized one"); the claim now records it, and a
; multi-cell read after Q gets the same window-scoped copy decline.
; ⚠ L7 RETIREMENT TRIGGER: retires with bd 01po.19.2 (copy-on-read).
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; ruling
; `ruling-01po19-s4-r1-qs-2026-10-15`).
;
; SOURCE (clang -O1, verbatim below):
;   int f(int n) {
;     bool q[4] = {0};
;     bool r[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3);
;     for (int i = 0; i < 4; i++) r[i] = q[i];
;     for (int i = 0; i < n; i++) cq_theta(&q[i & 3], .5);
;     int s = 0;
;     for (int i = 0; i < 4; i++) s += cq_measure(r[i]) << i;
;     return s;
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function f i32 (i32): cq rail window: quantum array not lowered yet (bd 01po.19), needs cell copy into another array (bd 01po.19.2 copy-on-read)

; ModuleID = 'copy_plain.c'
source_filename = "copy_plain.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #3
  store i32 0, ptr %2, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #3
  store i32 0, ptr %3, align 4
  br label %4

4:                                                ; preds = %1, %4
  %5 = phi i64 [ 0, %1 ], [ %11, %4 ]
  %6 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %5
  %7 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 3.000000e-01) #4
  %10 = zext i1 %9 to i8
  store i8 %10, ptr %6, align 1, !tbaa !6
  %11 = add nuw nsw i64 %5, 1
  %12 = icmp eq i64 %11, 4
  br i1 %12, label %13, label %4, !llvm.loop !12

13:                                               ; preds = %4
  %14 = load i32, ptr %2, align 4, !tbaa !6
  store i32 %14, ptr %3, align 4, !tbaa !6
  %15 = icmp sgt i32 %0, 0
  br i1 %15, label %17, label %16

16:                                               ; preds = %17, %13
  br label %29

17:                                               ; preds = %13, %17
  %18 = phi i32 [ %26, %17 ], [ 0, %13 ]
  %19 = and i32 %18, 3
  %20 = zext nneg i32 %19 to i64
  %21 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = trunc nuw i8 %22 to i1
  %24 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %23, double noundef 5.000000e-01) #4
  %25 = zext i1 %24 to i8
  store i8 %25, ptr %21, align 1, !tbaa !6
  %26 = add nuw nsw i32 %18, 1
  %27 = icmp eq i32 %26, %0
  br i1 %27, label %16, label %17, !llvm.loop !15

28:                                               ; preds = %29
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #3
  ret i32 %39

29:                                               ; preds = %16, %29
  %30 = phi i64 [ %40, %29 ], [ 0, %16 ]
  %31 = phi i32 [ %39, %29 ], [ 0, %16 ]
  %32 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %30
  %33 = load i8, ptr %32, align 1, !tbaa !6, !range !10, !noundef !11
  %34 = trunc nuw i8 %33 to i1
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34) #3
  %36 = zext i1 %35 to i32
  %37 = trunc nuw nsw i64 %30 to i32
  %38 = shl nuw nsw i32 %36, %37
  %39 = add nuw nsw i32 %38, %31
  %40 = add nuw nsw i64 %30, 1
  %41 = icmp eq i64 %40, 4
  br i1 %41, label %28, label %29, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

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
