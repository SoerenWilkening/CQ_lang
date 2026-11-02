; ModuleID = 'fresh_sibling_arms.c'
source_filename = "fresh_sibling_arms.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @fresh_sibling_arms(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %3 = tail call dereferenceable_or_null(8) ptr @malloc(i64 noundef 8) #5
  %4 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 7, ptr %4, align 4, !tbaa !6
  %5 = and i32 %2, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %1
  %8 = mul nsw i32 %2, 3
  store i32 %8, ptr %3, align 4, !tbaa !6
  br label %12

9:                                                ; preds = %1
  %10 = add nsw i32 %2, 5
  store i32 %10, ptr %3, align 4, !tbaa !6
  %11 = xor i32 %2, 6
  store i32 %11, ptr %4, align 4, !tbaa !6
  br label %12

12:                                               ; preds = %9, %7
  %13 = and i32 %0, 1
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds i32, ptr %3, i64 %14
  %16 = load i32, ptr %15, align 4, !tbaa !6
  tail call void @free(ptr noundef %3)
  %17 = ashr i32 %0, 1
  %18 = xor i32 %16, %17
  ret i32 %18
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @fresh_sibling_arms3(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %3 = tail call dereferenceable_or_null(8) ptr @malloc(i64 noundef 8) #5
  %4 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 %0, ptr %4, align 4, !tbaa !6
  %5 = and i32 %2, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %1
  %8 = mul nsw i32 %2, 3
  br label %16

9:                                                ; preds = %1
  %10 = and i32 %2, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %14, label %12

12:                                               ; preds = %9
  %13 = add nsw i32 %2, 5
  br label %16

14:                                               ; preds = %9
  %15 = xor i32 %2, 6
  br label %16

16:                                               ; preds = %12, %14, %7
  %17 = phi i32 [ %13, %12 ], [ %15, %14 ], [ %8, %7 ]
  store i32 %17, ptr %3, align 4, !tbaa !6
  %18 = and i32 %0, 1
  %19 = zext nneg i32 %18 to i64
  %20 = getelementptr inbounds i32, ptr %3, i64 %19
  %21 = load i32, ptr %20, align 4, !tbaa !6
  tail call void @free(ptr noundef %3)
  %22 = ashr i32 %0, 1
  %23 = xor i32 %21, %22
  ret i32 %23
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { allocsize(0) }

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
; USERCHECK fresh_sibling_arms
; USERCHECK fresh_sibling_arms3
