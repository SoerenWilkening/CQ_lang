; ModuleID = '60_qft/qft.c'
source_filename = "60_qft/qft.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define void @qft(ptr nocapture noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0    ; C: n > 0
  br i1 %4, label %5, label %12    ; C: for (i = 0; i < n; i++)

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64    ; C: (bound)
  %7 = zext nneg i32 %1 to i64    ; C: (bound)
  %8 = zext nneg i32 %1 to i64    ; C: (bound)
  br label %13    ; C: enter the outer loop

9:                                                ; preds = %37, %13
  %10 = add nuw nsw i64 %15, 1    ; C: (i + 1)++
  %11 = icmp eq i64 %21, %7    ; C: i < n
  br i1 %11, label %12, label %13, !llvm.loop !6    ; C: outer loop back / exit

12:                                               ; preds = %9, %3
  ret void    ; C: return

13:                                               ; preds = %5, %9
  %14 = phi i64 [ 0, %5 ], [ %21, %9 ]    ; C: i
  %15 = phi i64 [ 1, %5 ], [ %10, %9 ]    ; C: i + 1
  %16 = getelementptr inbounds i8, ptr %0, i64 %14    ; C: &q[i]
  %17 = load i8, ptr %16, align 1, !tbaa !9, !range !13, !noundef !14    ; C: q[i]
  %18 = trunc nuw i8 %17 to i1    ; C: q[i] as bool
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %18, double noundef %2) #2    ; C: cq_theta(&q[i], base);
  %20 = zext i1 %19 to i8    ; C: (store back)
  store i8 %20, ptr %16, align 1, !tbaa !9    ; C: q[i] = ...
  %21 = add nuw nsw i64 %14, 1    ; C: i + 1
  %22 = icmp ult i64 %21, %6    ; C: j = i + 1 < n (inner loop runs?)
  br i1 %22, label %23, label %9    ; C: for (j = i + 1; j < n; j++)

23:                                               ; preds = %13, %37
  %24 = phi i64 [ %38, %37 ], [ %15, %13 ]    ; C: j
  %25 = getelementptr inbounds i8, ptr %0, i64 %24    ; C: &q[j]
  %26 = load i8, ptr %25, align 1, !tbaa !9, !range !13, !noundef !14    ; C: q[j]
  %27 = trunc nuw i8 %26 to i1    ; C: q[j] as bool
  br i1 %27, label %28, label %37    ; C: if (q[j] && ...  (first conjunct)

28:                                               ; preds = %23
  %29 = load i8, ptr %16, align 1, !tbaa !9, !range !13, !noundef !14    ; C: q[i]  (second conjunct)
  %30 = trunc nuw i8 %29 to i1    ; C: q[i] as bool
  br i1 %30, label %31, label %37    ; C: ... && q[i])

31:                                               ; preds = %28
  %32 = sub nuw nsw i64 %24, %14    ; C: j - i
  %33 = trunc nsw i64 %32 to i32    ; C: (int)(j - i)
  %34 = shl nuw i32 1, %33    ; C: 1 << (j - i)
  %35 = sitofp i32 %34 to double    ; C: (double)(1 << (j - i))
  %36 = fdiv double %2, %35    ; C: base / (double)(1 << (j - i))
  tail call void @cq_phi(double noundef %36) #3    ; C: cq_phi(...);
  br label %37    ; C: end of if

37:                                               ; preds = %23, %28, %31
  %38 = add nuw nsw i64 %24, 1    ; C: j++
  %39 = icmp eq i64 %38, %8    ; C: j < n
  br i1 %39, label %9, label %23, !llvm.loop !15    ; C: inner loop back / exit
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{!10, !10, i64 0}
!10 = !{!"_Bool", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !7, !8}
