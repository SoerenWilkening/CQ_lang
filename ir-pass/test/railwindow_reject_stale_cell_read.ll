; railwindow_reject_stale_cell_read.ll — DECLINE + ADVERSARIAL (bd 01po.19 S4):
; THE STALE-CELL SILENT MISCOMPILE, now loud.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; `bool a = q[0]` keeps the CELL'S RAIL NAME across a walk that rotates q[i]
; through other loads. C says `a` is the value from before the walk. MEASURED
; on the first S4 build (before RailWindowFence.cpp): exit 0, verify-clean,
; `cqrt_measure_i1(h0)` AFTER `cqrt_ry_i1(h0, .5)` — the rotated rail measured
; as `a`. The scalar twin declines (`rail record read past an in-place gate on
; the same rail`); this is that refusal across the memory hop
; (`railWindowStaleUse`, array-granular), until a copy-on-read lowering exists.
;
; ⚠ L7 RETIREMENT TRIGGER: loud until the copy-on-read lowering (bd 01po.19.2)
; exists; a live cell temporary across a window gate is bd 01po.19.5. This
; decline is an interim one, not a physics refusal.
;
; SOURCE (clang -O1, verbatim below):
;   /* adversarial: a cell read kept in a local across a gate on the array.
;      C semantics: a is the value q[0] held BEFORE the walk rotated it. */
;   int f(int n) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3);
;     bool a = q[0];
;     for (int i = 0; i < n; i++) cq_theta(&q[i & 3], .5);
;     return cq_measure(a) + 2 * cq_measure(q[0]);
;   }
;   int main(void) { return f(2); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function f i32 (i32): cq rail window: quantum-array cell rail read past a non-diagonal gate on that array

; ModuleID = 'stale1.c'
source_filename = "stale1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #3
  store i32 0, ptr %2, align 4
  br label %6

3:                                                ; preds = %6
  %4 = load i8, ptr %2, align 4, !tbaa !6, !range !10, !noundef !11
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %24, label %15

6:                                                ; preds = %1, %6
  %7 = phi i64 [ 0, %1 ], [ %13, %6 ]
  %8 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %7
  %9 = load i8, ptr %8, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = trunc nuw i8 %9 to i1
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef 3.000000e-01) #4
  %12 = zext i1 %11 to i8
  store i8 %12, ptr %8, align 1, !tbaa !6
  %13 = add nuw nsw i64 %7, 1
  %14 = icmp eq i64 %13, 4
  br i1 %14, label %3, label %6, !llvm.loop !12

15:                                               ; preds = %24, %3
  %16 = trunc nuw i8 %4 to i1
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %16) #3
  %18 = zext i1 %17 to i32
  %19 = load i8, ptr %2, align 4, !tbaa !6, !range !10, !noundef !11
  %20 = trunc nuw i8 %19 to i1
  %21 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %20) #3
  %22 = select i1 %21, i32 2, i32 0
  %23 = or disjoint i32 %22, %18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #3
  ret i32 %23

24:                                               ; preds = %3, %24
  %25 = phi i32 [ %33, %24 ], [ 0, %3 ]
  %26 = and i32 %25, 3
  %27 = zext nneg i32 %26 to i64
  %28 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %27
  %29 = load i8, ptr %28, align 1, !tbaa !6, !range !10, !noundef !11
  %30 = trunc nuw i8 %29 to i1
  %31 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %30, double noundef 5.000000e-01) #4
  %32 = zext i1 %31 to i8
  store i8 %32, ptr %28, align 1, !tbaa !6
  %33 = add nuw nsw i32 %25, 1
  %34 = icmp eq i32 %33, %0
  br i1 %34, label %15, label %24, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %4

2:                                                ; preds = %4
  %3 = load i8, ptr %1, align 4, !tbaa !6, !range !10, !noundef !11
  br label %13

4:                                                ; preds = %4, %0
  %5 = phi i64 [ 0, %0 ], [ %11, %4 ]
  %6 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %7 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 3.000000e-01) #4
  %10 = zext i1 %9 to i8
  store i8 %10, ptr %6, align 1, !tbaa !6
  %11 = add nuw nsw i64 %5, 1
  %12 = icmp eq i64 %11, 4
  br i1 %12, label %2, label %4, !llvm.loop !12

13:                                               ; preds = %13, %2
  %14 = phi i64 [ %20, %13 ], [ 0, %2 ]
  %15 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %14
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef 5.000000e-01) #4
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %15, align 1, !tbaa !6
  %20 = add nuw nsw i64 %14, 1
  %21 = icmp eq i64 %20, 2
  br i1 %21, label %22, label %13, !llvm.loop !15

22:                                               ; preds = %13
  %23 = trunc nuw i8 %3 to i1
  %24 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %23) #3
  %25 = zext i1 %24 to i32
  %26 = load i8, ptr %1, align 4, !tbaa !6, !range !10, !noundef !11
  %27 = trunc nuw i8 %26 to i1
  %28 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %27) #3
  %29 = select i1 %28, i32 2, i32 0
  %30 = or disjoint i32 %29, %25
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %30
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
