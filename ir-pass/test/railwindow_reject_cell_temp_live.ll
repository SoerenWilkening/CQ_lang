; railwindow_reject_cell_temp_live.ll — DECLINE (bd 01po.19 S4, owner ruling Q4
; (a): "loud if no placement exists").
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; `s = q[0] + q[1]` is consumed only after a walk that rotates the array; its
; records cannot be reversed before the walk (their consumer has not run) nor
; after it (the `_unc`s would read rotated rails). The spine leaves them (Rule
; 6) and `declineLiveWindowRecords` refuses the module at the walk's Ry: a
; temporary of a cell is live at a non-diagonal gate on the array.
;
; SOURCE (clang -O1, verbatim below):
;   /* adversarial (Q4): a temporary of two cells whose consumer runs only after a
;      walk rotates the array. Its records must be reversed before the walk, which
;      needs the consumer first: no placement exists -> loud. */
;   int f(int n) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3);
;     int s = q[0] + q[1];
;     for (int i = 0; i < n; i++) cq_theta(&q[i & 3], .5);
;     return cq_measure(s * 3) + cq_measure(q[2]);
;   }
;   int main(void) { return f(2); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function f i32 (i32): cq rail window: temporary read from a quantum-array cell is live at a non-diagonal gate on that array

; ModuleID = 'q4live.c'
source_filename = "q4live.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #3
  store i32 0, ptr %2, align 4
  br label %8

3:                                                ; preds = %8
  %4 = load i8, ptr %2, align 4, !tbaa !6, !range !10, !noundef !11
  %5 = getelementptr inbounds i8, ptr %2, i64 1
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = icmp sgt i32 %0, 0
  br i1 %7, label %28, label %17

8:                                                ; preds = %1, %8
  %9 = phi i64 [ 0, %1 ], [ %15, %8 ]
  %10 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %9
  %11 = load i8, ptr %10, align 1, !tbaa !6, !range !10, !noundef !11
  %12 = trunc nuw i8 %11 to i1
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %12, double noundef 3.000000e-01) #4
  %14 = zext i1 %13 to i8
  store i8 %14, ptr %10, align 1, !tbaa !6
  %15 = add nuw nsw i64 %9, 1
  %16 = icmp eq i64 %15, 4
  br i1 %16, label %3, label %8, !llvm.loop !12

17:                                               ; preds = %28, %3
  %18 = add nuw nsw i8 %6, %4
  %19 = mul nuw nsw i8 %18, 3
  %20 = zext nneg i8 %19 to i32
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %22 = getelementptr inbounds i8, ptr %2, i64 2
  %23 = load i8, ptr %22, align 2, !tbaa !6, !range !10, !noundef !11
  %24 = trunc nuw i8 %23 to i1
  %25 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %24) #3
  %26 = zext i1 %25 to i32
  %27 = add nsw i32 %21, %26
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #3
  ret i32 %27

28:                                               ; preds = %3, %28
  %29 = phi i32 [ %37, %28 ], [ 0, %3 ]
  %30 = and i32 %29, 3
  %31 = zext nneg i32 %30 to i64
  %32 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %31
  %33 = load i8, ptr %32, align 1, !tbaa !6, !range !10, !noundef !11
  %34 = trunc nuw i8 %33 to i1
  %35 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %34, double noundef 5.000000e-01) #4
  %36 = zext i1 %35 to i8
  store i8 %36, ptr %32, align 1, !tbaa !6
  %37 = add nuw nsw i32 %29, 1
  %38 = icmp eq i32 %37, %0
  br i1 %38, label %17, label %28, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
