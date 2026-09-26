; ModuleID = 'call_for.k3m.s1.ll'
source_filename = "call_for.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @slice()
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice() unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #4
  %3 = tail call i32 @cq_theta_si32(i32 noundef 2, double noundef 4.000000e-01) #4
  %4 = icmp sgt i32 %1, 1
  %5 = icmp slt i32 %2, 5
  %6 = and i1 %4, %5
  br label %7

7:                                                ; preds = %0
  %8 = select i1 %6, i32 0, i32 55
  br i1 true, label %11, label %9

9:                                                ; preds = %7
  %10 = tail call fastcc i32 @g(i32 noundef 0)
  br label %11

11:                                               ; preds = %9, %7
  %12 = phi i32 [ %10, %9 ], [ 0, %7 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  %14 = add nsw i32 %13, %12
  %15 = select i1 %6, i32 1, i32 55
  br i1 false, label %19, label %16

16:                                               ; preds = %11
  %17 = tail call fastcc i32 @g(i32 noundef 1)
  %18 = add nsw i32 %17, %14
  br label %19

19:                                               ; preds = %16, %11
  %20 = phi i32 [ %18, %16 ], [ %14, %11 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %15) #4
  %22 = add nsw i32 %21, %20
  %23 = select i1 %6, i32 2, i32 55
  br i1 true, label %27, label %24

24:                                               ; preds = %19
  %25 = tail call fastcc i32 @g(i32 noundef 2)
  %26 = add nsw i32 %25, %22
  br label %27

27:                                               ; preds = %24, %19
  %28 = phi i32 [ %26, %24 ], [ %22, %19 ]
  %29 = tail call i32 @cq_measure_si32(i32 noundef %23) #4
  %30 = add nsw i32 %29, %28
  %31 = tail call i32 @cq_measure_si32(i32 noundef %1) #4
  %32 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %33 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %34 = add i32 %31, %30
  %35 = add i32 %34, %32
  %36 = add i32 %35, %33
  ret i32 %36
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) unnamed_addr #3 {
  %2 = mul nsw i32 %0, %0
  %3 = add nuw nsw i32 %2, 1
  ret i32 %3
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
