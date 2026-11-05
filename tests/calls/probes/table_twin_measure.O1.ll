; ModuleID = 'table_twin_measure.c'
source_filename = "table_twin_measure.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = internal unnamed_addr constant [2 x ptr] [ptr @g, ptr @h], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @e_cl(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #4
  %8 = and i32 %4, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [2 x ptr], ptr @tab, i64 0, i64 %9
  %11 = load ptr, ptr %10, align 8, !tbaa !6
  %12 = tail call i32 %11(i32 noundef %6, i32 noundef %7) #5
  %13 = mul nsw i32 %12, %12
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @e_rail(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #4
  %8 = fadd double %2, %3
  %9 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %8) #4
  %10 = and i32 %9, 1
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [2 x ptr], ptr @tab, i64 0, i64 %11
  %13 = load ptr, ptr %12, align 8, !tbaa !6
  %14 = tail call i32 %13(i32 noundef %6, i32 noundef %7) #5
  %15 = mul nsw i32 %14, %14
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #5
  ret i32 %16
}

; Function Attrs: noinline nounwind ssp uwtable
define internal i32 @g(i32 noundef %0, i32 noundef %1) #2 {
  %3 = tail call i32 @cq_measure_si32(i32 noundef %0) #5
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal i32 @h(i32 noundef %0, i32 noundef %1) #3 {
  %3 = sub nsw i32 %0, %1
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
