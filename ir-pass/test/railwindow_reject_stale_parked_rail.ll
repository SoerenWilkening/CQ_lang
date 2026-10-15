; railwindow_reject_stale_parked_rail.ll — DECLINE + ADVERSARIAL (bd 01po.19
; S4): a fresh rail parked in a cell, then rotated again through its own name.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; `q[i&3] = x; cq_theta(&x, .2)` would rotate the cell's rail too (the cell
; holds x's HANDLE), where C leaves the cell holding x's old value; the cells
; are read after. Loud (`railWindowStaleUse`, the parked-rail rule).
;
; ⚠ L7 RETIREMENT TRIGGER: loud until the copy-on-read lowering (bd 01po.19.2)
; exists; a live cell temporary across a window gate is bd 01po.19.5. This
; decline is an interim one, not a physics refusal.
;
; SOURCE (clang -O1, verbatim below):
;   /* adversarial: a fresh rail parked in a cell, then the parked rail's own name
;      rotated again. C semantics: q[i] keeps the value x held at the store. */
;   int f(int n) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3);
;     for (int i = 0; i < n; i++) {
;       bool x = 0;
;       cq_theta(&x, .7);
;       q[i & 3] = x;
;       cq_theta(&x, .2);
;       if (cq_measure(x)) break;
;     }
;     int r = 0;
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return f(2); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function f i32 (i32): cq rail window: quantum-array cell rail read past a non-diagonal gate on that array

; ModuleID = 'stale2.c'
source_filename = "stale2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #3
  store i32 0, ptr %2, align 4
  br label %6

3:                                                ; preds = %6
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %15, label %5

5:                                                ; preds = %15, %3
  br label %28

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

15:                                               ; preds = %3, %15
  %16 = phi i32 [ %24, %15 ], [ 0, %3 ]
  %17 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FE6666666666666) #4
  %18 = zext i1 %17 to i8
  %19 = and i32 %16, 3
  %20 = zext nneg i32 %19 to i64
  %21 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %20
  store i8 %18, ptr %21, align 1, !tbaa !6
  %22 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %17, double noundef 2.000000e-01) #4
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %22) #3
  %24 = add nuw nsw i32 %16, 1
  %25 = icmp eq i32 %24, %0
  %26 = select i1 %23, i1 true, i1 %25
  br i1 %26, label %5, label %15, !llvm.loop !15

27:                                               ; preds = %28
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #3
  ret i32 %37

28:                                               ; preds = %5, %28
  %29 = phi i64 [ %38, %28 ], [ 0, %5 ]
  %30 = phi i32 [ %37, %28 ], [ 0, %5 ]
  %31 = shl nsw i32 %30, 1
  %32 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %29
  %33 = load i8, ptr %32, align 1, !tbaa !6, !range !10, !noundef !11
  %34 = trunc nuw i8 %33 to i1
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34) #3
  %36 = zext i1 %35 to i32
  %37 = or disjoint i32 %31, %36
  %38 = add nuw nsw i64 %29, 1
  %39 = icmp eq i64 %38, 4
  br i1 %39, label %27, label %28, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @f(i32 noundef 2)
  ret i32 %1
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
!16 = distinct !{!16, !13, !14}
