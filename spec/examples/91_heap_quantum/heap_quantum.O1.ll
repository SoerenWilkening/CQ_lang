; ModuleID = 'heap_quantum.c'
source_filename = "heap_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 256) i32 @heap_quantum_size(i8 noundef zeroext %0, double noundef %1, i32 noundef %2, double noundef %3, i8 noundef zeroext %4) local_unnamed_addr #0 {
  %6 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #5    ; C: cq_theta(&n, tn);
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef %3) #5    ; C: cq_theta(&k, tk);
  %8 = and i8 %6, 3    ; C: n & 3
  %9 = zext nneg i8 %8 to i64    ; C: (the size)
  %10 = tail call ptr @malloc(i64 noundef %9) #6    ; C: unsigned char *a = malloc(n & 3);
  %11 = and i32 %7, 3    ; C: k & 3
  %12 = zext nneg i32 %11 to i64    ; C: (the index)
  %13 = getelementptr inbounds i8, ptr %10, i64 %12    ; C: &a[k & 3]
  store i8 %4, ptr %13, align 1, !tbaa !6    ; C: a[k & 3] = v;
  %14 = tail call dereferenceable_or_null(6) ptr @realloc(ptr noundef %10, i64 noundef 6) #7    ; C: a = realloc(a, 6);
  %15 = getelementptr inbounds i8, ptr %14, i64 5    ; C: &a[5]
  store i8 1, ptr %15, align 1, !tbaa !6    ; C: a[5] = 1;
  %16 = getelementptr inbounds i8, ptr %14, i64 1    ; C: &a[1]
  %17 = load i8, ptr %16, align 1, !tbaa !6    ; C: a[1]
  %18 = icmp ugt i32 %7, 100    ; C: if (k > 100)
  br i1 %18, label %19, label %20    ; C: if (k > 100)

19:                                               ; preds = %5
  tail call void @free(ptr noundef %14)    ; C: free(a);
  br label %20    ; C: end of if

20:                                               ; preds = %19, %5
  %21 = add i8 %17, 1    ; C: a[1] + a[5]  (a[5] folded to 1)
  %22 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %21) #8    ; C: cq_measure(r)
  %23 = zext i8 %22 to i32    ; C: (int)
  ret i32 %23    ; C: return
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite)
declare noalias noundef ptr @realloc(ptr allocptr nocapture noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #4

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @heap_in_loop(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5    ; C: cq_theta(&x, th);
  %4 = and i32 %3, 3    ; C: x & 3
  %5 = icmp eq i32 %4, 0    ; C: i < (x & 3)  (first test)
  br i1 %5, label %6, label %9    ; C: for (...; i < (x & 3); ...)

6:                                                ; preds = %9, %2
  %7 = phi ptr [ null, %2 ], [ %11, %9 ]    ; C: last (NULL if no trip, else the last p)
  %8 = icmp eq ptr %7, null    ; C: last ? ... : ...
  br i1 %8, label %19, label %16    ; C: last ? last[0] : 7

9:                                                ; preds = %2, %9
  %10 = phi i32 [ %14, %9 ], [ 0, %2 ]    ; C: i
  %11 = tail call dereferenceable_or_null(1) ptr @malloc(i64 noundef 1) #6    ; C: unsigned char *p = malloc(1);
  %12 = add i32 %10, %3    ; C: x + i
  %13 = trunc i32 %12 to i8    ; C: (unsigned char)(x + i)
  store i8 %13, ptr %11, align 1, !tbaa !6    ; C: p[0] = (unsigned char)(x + i);
  %14 = add nuw nsw i32 %10, 1    ; C: i++
  %15 = icmp eq i32 %14, %4    ; C: i < (x & 3)
  br i1 %15, label %6, label %9, !llvm.loop !9    ; C: for (...; i < (x & 3); ...)

16:                                               ; preds = %6
  %17 = load i8, ptr %7, align 1, !tbaa !6    ; C: last[0]
  %18 = zext i8 %17 to i32    ; C: (int)last[0]
  br label %19    ; C: (join)

19:                                               ; preds = %6, %16
  %20 = phi i32 [ %18, %16 ], [ 7, %6 ]    ; C: last ? last[0] : 7
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #8    ; C: cq_measure(last ? last[0] : 7)
  ret i32 %21    ; C: return
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { allocsize(0) }
attributes #7 = { allocsize(1) }
attributes #8 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
