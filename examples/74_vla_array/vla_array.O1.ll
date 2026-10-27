; ModuleID = 'vla_array.c'
source_filename = "vla_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @vla_array(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = zext i32 %2 to i64    ; C: n  (as an element count)
  %7 = alloca i32, i64 %6, align 16    ; C: int a[n];
  %8 = icmp sgt i32 %2, 0    ; C: i < n  (first test)
  br i1 %8, label %9, label %11    ; C: for (int i = 0; i < n; i++)

9:                                                ; preds = %4
  %10 = zext nneg i32 %2 to i64    ; C: n  (as the loop bound)
  br label %17    ; C: for (int i = 0; i < n; i++)

11:                                               ; preds = %17, %4
  %12 = urem i32 %5, %2    ; C: x % n
  %13 = zext i32 %12 to i64    ; C: x % n  (as an index)
  %14 = getelementptr inbounds i32, ptr %7, i64 %13    ; C: &a[x % n]
  %15 = load i32, ptr %14, align 4, !tbaa !6    ; C: a[x % n]
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #3    ; C: cq_measure(a[x % n])
  ret i32 %16    ; C: return

17:                                               ; preds = %9, %17
  %18 = phi i64 [ 0, %9 ], [ %22, %17 ]    ; C: i
  %19 = getelementptr inbounds i32, ptr %7, i64 %18    ; C: &a[i]
  %20 = trunc i64 %18 to i32    ; C: i  (as int)
  %21 = mul i32 %20, %3    ; C: i * c
  store i32 %21, ptr %19, align 4, !tbaa !6    ; C: a[i] = i * c;
  %22 = add nuw nsw i64 %18, 1    ; C: i++
  %23 = icmp eq i64 %22, %10    ; C: i < n
  br i1 %23, label %11, label %17, !llvm.loop !10    ; C: for (int i = 0; i < n; i++)
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
