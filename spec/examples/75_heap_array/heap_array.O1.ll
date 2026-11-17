; ModuleID = 'heap_array.c'
source_filename = "heap_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @heap_array(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %6 = sext i32 %2 to i64    ; C: n  (as a size)
  %7 = shl nsw i64 %6, 2    ; C: n * sizeof *a
  %8 = tail call ptr @malloc(i64 noundef %7) #5    ; C: int *a = malloc(n * sizeof *a);
  %9 = icmp sgt i32 %2, 0    ; C: i < n  (first test)
  br i1 %9, label %10, label %12    ; C: for (int i = 0; i < n; i++)

10:                                               ; preds = %4
  %11 = zext nneg i32 %2 to i64    ; C: n  (as the loop bound)
  br label %21    ; C: for (int i = 0; i < n; i++)

12:                                               ; preds = %21, %4
  %13 = sext i32 %3 to i64    ; C: k  (as an index)
  %14 = getelementptr inbounds i32, ptr %8, i64 %13    ; C: &a[k]
  %15 = load i32, ptr %14, align 4, !tbaa !6    ; C: a[k]
  %16 = getelementptr i32, ptr %8, i64 %6    ; C: &a[n]
  %17 = getelementptr i8, ptr %16, i64 -4    ; C: &a[n - 1]
  %18 = load i32, ptr %17, align 4, !tbaa !6    ; C: a[n - 1]
  %19 = add nsw i32 %18, %15    ; C: int r = a[k] + a[n - 1];
  tail call void @free(ptr noundef %8)    ; C: free(a);
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #6    ; C: cq_measure(r)
  ret i32 %20    ; C: return

21:                                               ; preds = %10, %21
  %22 = phi i64 [ 0, %10 ], [ %26, %21 ]    ; C: i
  %23 = trunc nuw nsw i64 %22 to i32    ; C: i  (as int)
  %24 = add i32 %5, %23    ; C: x + i
  %25 = getelementptr inbounds i32, ptr %8, i64 %22    ; C: &a[i]
  store i32 %24, ptr %25, align 4, !tbaa !6    ; C: a[i] = x + i;
  %26 = add nuw nsw i64 %22, 1    ; C: i++
  %27 = icmp eq i64 %26, %11    ; C: i < n
  br i1 %27, label %12, label %21, !llvm.loop !10    ; C: for (int i = 0; i < n; i++)
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { allocsize(0) }
attributes #6 = { nounwind }

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
