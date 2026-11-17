; ModuleID = 'nested_struct_return.c'
source_filename = "nested_struct_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @nested_struct_return(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = tail call fastcc { i64, double } @mk(i32 noundef %5, i32 noundef %2, double noundef %3)
  %7 = extractvalue { i64, double } %6, 0
  %8 = extractvalue { i64, double } %6, 1
  %9 = trunc i64 %7 to i32
  %10 = lshr i64 %7, 32
  %11 = trunc nuw i64 %10 to i32
  %12 = add nsw i32 %11, %9
  %13 = sitofp i32 %12 to double
  %14 = fadd double %8, %13
  %15 = tail call double @cq_measure_f64(double noundef %14) #4
  ret double %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc { i64, double } @mk(i32 noundef %0, i32 noundef %1, double noundef %2) unnamed_addr #2 {
  %4 = add nsw i32 %1, %0
  %5 = mul nsw i32 %1, %0
  %6 = fmul double %2, 2.000000e+00
  %7 = zext i32 %5 to i64
  %8 = shl nuw i64 %7, 32
  %9 = zext i32 %4 to i64
  %10 = or disjoint i64 %8, %9
  %11 = insertvalue { i64, double } poison, i64 %10, 0
  %12 = insertvalue { i64, double } %11, double %6, 1
  ret { i64, double } %12
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
