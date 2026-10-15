; railwindow_reject_store_width.ll — DECLINE (bd 01po.19 S4, addendum note 1):
; a post-Q `memset(q, 2, 4)` on a `_Bool` array — fill byte 2 is not a `_Bool`
; value, so the per-cell rebind cannot be exact (kMsgWindowStoreWidth).
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
;
; SOURCE (clang -O1, verbatim below):
;   #include <string.h>
;   /* decline: a post-Q fill whose byte is not a _Bool value */
;   int f(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3);
;     memset(q, 2, sizeof q);
;     int r = 0;
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return f(); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function f i32 (): cq rail window: stored value does not fit the cell's rail

; ModuleID = 'badfill.c'
source_filename = "badfill.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %3

2:                                                ; preds = %3
  store i32 33686018, ptr %1, align 4
  br label %13

3:                                                ; preds = %0, %3
  %4 = phi i64 [ 0, %0 ], [ %10, %3 ]
  %5 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %4
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = trunc nuw i8 %6 to i1
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef 3.000000e-01) #4
  %9 = zext i1 %8 to i8
  store i8 %9, ptr %5, align 1, !tbaa !6
  %10 = add nuw nsw i64 %4, 1
  %11 = icmp eq i64 %10, 4
  br i1 %11, label %2, label %3, !llvm.loop !12

12:                                               ; preds = %13
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %22

13:                                               ; preds = %2, %13
  %14 = phi i64 [ 0, %2 ], [ %23, %13 ]
  %15 = phi i32 [ 0, %2 ], [ %22, %13 ]
  %16 = shl nsw i32 %15, 1
  %17 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %14
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = trunc nuw i8 %18 to i1
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %19) #3
  %21 = zext i1 %20 to i32
  %22 = or disjoint i32 %16, %21
  %23 = add nuw nsw i64 %14, 1
  %24 = icmp eq i64 %23, 4
  br i1 %24, label %12, label %13, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %3

2:                                                ; preds = %3
  store i32 33686018, ptr %1, align 4
  br label %12

3:                                                ; preds = %3, %0
  %4 = phi i64 [ 0, %0 ], [ %10, %3 ]
  %5 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %4
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = trunc nuw i8 %6 to i1
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef 3.000000e-01) #4
  %9 = zext i1 %8 to i8
  store i8 %9, ptr %5, align 1, !tbaa !6
  %10 = add nuw nsw i64 %4, 1
  %11 = icmp eq i64 %10, 4
  br i1 %11, label %2, label %3, !llvm.loop !12

12:                                               ; preds = %12, %2
  %13 = phi i64 [ 0, %2 ], [ %22, %12 ]
  %14 = phi i32 [ 0, %2 ], [ %21, %12 ]
  %15 = shl nsw i32 %14, 1
  %16 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %13
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = trunc nuw i8 %17 to i1
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %18) #3
  %20 = zext i1 %19 to i32
  %21 = or disjoint i32 %15, %20
  %22 = add nuw nsw i64 %13, 1
  %23 = icmp eq i64 %22, 4
  br i1 %23, label %24, label %12, !llvm.loop !15

24:                                               ; preds = %12
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %21
}

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
