; ModuleID = 'realloc_pointer_rail.c'
source_filename = "realloc_pointer_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @realloc_pointer_rail(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&k, tk);
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4    ; C: cq_theta(&x, tx);
  %7 = tail call dereferenceable_or_null(8) ptr @malloc(i64 noundef 8) #5    ; C: int *a = malloc(8)
  %8 = tail call dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #5    ; C: *b = malloc(16);
  %9 = getelementptr inbounds i8, ptr %7, i64 4    ; C: &a[1]
  store i32 %6, ptr %9, align 4, !tbaa !6    ; C: a[1] = x;
  %10 = getelementptr inbounds i8, ptr %8, i64 4    ; C: &b[1]
  store i32 5, ptr %10, align 4, !tbaa !6    ; C: b[1] = 5;
  %11 = getelementptr inbounds i8, ptr %8, i64 8    ; C: &b[2]
  store i32 7, ptr %11, align 4, !tbaa !6    ; C: b[2] = 7;
  %12 = and i32 %5, 1    ; C: k & 1
  %13 = icmp eq i32 %12, 0    ; C: (k & 1) ? a : b
  %14 = select i1 %13, ptr %8, ptr %7    ; C: int *p = (k & 1) ? a : b;
  %15 = tail call dereferenceable_or_null(24) ptr @realloc(ptr noundef %14, i64 noundef 24) #6    ; C: int *q = realloc(p, 24);
  %16 = getelementptr inbounds i8, ptr %15, i64 4    ; C: &q[1]
  %17 = load i32, ptr %16, align 4, !tbaa !6    ; C: q[1]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #7    ; C: int r1 = cq_measure(q[1]);
  %19 = getelementptr inbounds i8, ptr %15, i64 8    ; C: &q[2]
  %20 = load i32, ptr %19, align 4, !tbaa !6    ; C: q[2]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #7    ; C: cq_measure(q[2])
  %22 = add nsw i32 %21, %18    ; C: r1 + cq_measure(q[2])
  ret i32 %22    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite)
declare noalias noundef ptr @realloc(ptr allocptr nocapture noundef, i64 noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { allocsize(0) }
attributes #6 = { allocsize(1) }
attributes #7 = { nounwind }

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
