; ModuleID = 'struct_byvalue_quantum.c'
source_filename = "struct_byvalue_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @struct_byvalue_one(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = zext i32 %2 to i64
  %7 = shl nuw i64 %6, 32
  %8 = zext i32 %5 to i64
  %9 = or disjoint i64 %7, %8
  %10 = tail call fastcc i64 @shift(i64 %9, i32 noundef %3)
  %11 = trunc i64 %10 to i32
  %12 = lshr i64 %10, 32
  %13 = trunc nuw i64 %12 to i32
  %14 = add nsw i32 %13, %11
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc i64 @shift(i64 %0, i32 noundef %1) unnamed_addr #2 {
  %3 = trunc i64 %0 to i32
  %4 = lshr i64 %0, 32
  %5 = trunc nuw i64 %4 to i32
  %6 = add nsw i32 %3, %1
  %7 = mul nsw i32 %5, %1
  %8 = zext i32 %7 to i64
  %9 = shl nuw i64 %8, 32
  %10 = zext i32 %6 to i64
  %11 = or disjoint i64 %9, %10
  ret i64 %11
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @struct_byvalue_both(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %7 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #3
  %8 = zext i32 %7 to i64
  %9 = shl nuw i64 %8, 32
  %10 = zext i32 %6 to i64
  %11 = or disjoint i64 %9, %10
  %12 = tail call fastcc i64 @shift(i64 %11, i32 noundef %4)
  %13 = trunc i64 %12 to i32
  %14 = lshr i64 %12, 32
  %15 = trunc nuw i64 %14 to i32
  %16 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15) #4
  %18 = add nsw i32 %17, %16
  ret i32 %18
}

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
