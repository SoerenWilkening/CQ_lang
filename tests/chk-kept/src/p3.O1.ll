; ModuleID = 'p3.c'
source_filename = "p3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@T = internal unnamed_addr constant [4 x i32] [i32 5, i32 7, i32 11, i32 13], align 16
@cell = local_unnamed_addr global i32 0, align 4

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @rd(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 3
  %3 = zext nneg i32 %2 to i64
  %4 = getelementptr inbounds [4 x i32], ptr @T, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !6
  %6 = add nsw i32 %5, %0
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @p3(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #3
  %5 = tail call i32 @rd(i32 noundef %0)
  store i32 %0, ptr @cell, align 4, !tbaa !6
  %6 = tail call i32 @rd(i32 noundef %4)
  %7 = and i32 %6, 6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  %9 = add nsw i32 %8, %5
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
