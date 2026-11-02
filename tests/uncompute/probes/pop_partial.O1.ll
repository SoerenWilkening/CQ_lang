; ModuleID = 'tests/uncompute/probes/pop_partial.c'
source_filename = "tests/uncompute/probes/pop_partial.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @pp(i32 noundef %0, i8 noundef zeroext %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef 1.000000e+00) #3
  %6 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %1, double noundef 1.000000e+00) #3
  %7 = tail call dereferenceable_or_null(4) ptr @malloc(i64 noundef 4) #4
  store i8 7, ptr %7, align 1, !tbaa !6
  %8 = and i32 %5, 3
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds i8, ptr %7, i64 %9
  store i8 %6, ptr %10, align 1, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %7, i64 1
  %12 = load i8, ptr %11, align 1, !tbaa !6
  %13 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %12) #5
  %14 = icmp eq i32 %2, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %4
  %16 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %6, double noundef %3) #3
  br label %17

17:                                               ; preds = %15, %4
  %18 = zext i8 %13 to i32
  %19 = getelementptr inbounds i8, ptr %7, i64 2
  %20 = load i8, ptr %19, align 1, !tbaa !6
  %21 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %20) #5
  %22 = zext i8 %21 to i32
  %23 = add nuw nsw i32 %22, %18
  %24 = tail call i32 @cq_measure_ui32(i32 noundef %5) #5
  %25 = add i32 %23, %24
  ret i32 %25
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { allocsize(0) }
attributes #5 = { nounwind }

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
