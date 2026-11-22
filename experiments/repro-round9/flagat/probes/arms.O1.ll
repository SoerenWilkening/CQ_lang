; ModuleID = 'arms.c'
source_filename = "arms.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h1(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483648, 2147483646) i32 @h2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  %3 = add nsw i32 %2, -2
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @arms(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #1 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %7 = and i32 %1, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %5
  %10 = tail call i32 @h1(i32 noundef %6)
  br label %11

11:                                               ; preds = %9, %5
  %12 = phi i32 [ %10, %9 ], [ 0, %5 ]
  %13 = and i32 %2, 1
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %19, label %15

15:                                               ; preds = %11
  %16 = add nsw i32 %6, 7
  %17 = tail call i32 @h2(i32 noundef %16)
  %18 = xor i32 %17, %12
  br label %19

19:                                               ; preds = %15, %11
  %20 = phi i32 [ %18, %15 ], [ %12, %11 ]
  %21 = and i32 %3, 1
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %27, label %23

23:                                               ; preds = %19
  %24 = mul nsw i32 %6, %6
  %25 = tail call i32 @h1(i32 noundef %24)
  %26 = add nsw i32 %25, %20
  br label %27

27:                                               ; preds = %23, %19
  %28 = phi i32 [ %26, %23 ], [ %20, %19 ]
  %29 = and i32 %1, 2
  %30 = icmp eq i32 %29, 0
  br i1 %30, label %35, label %31

31:                                               ; preds = %27
  %32 = shl i32 %6, 2
  %33 = tail call i32 @h2(i32 noundef %32)
  %34 = sub nsw i32 %28, %33
  br label %35

35:                                               ; preds = %31, %27
  %36 = phi i32 [ %34, %31 ], [ %28, %27 ]
  %37 = icmp sgt i32 %4, 0
  br i1 %37, label %42, label %38

38:                                               ; preds = %52, %35
  %39 = phi i32 [ %36, %35 ], [ %53, %52 ]
  %40 = and i32 %1, 4
  %41 = icmp eq i32 %40, 0
  br i1 %41, label %58, label %56

42:                                               ; preds = %35, %52
  %43 = phi i32 [ %54, %52 ], [ 0, %35 ]
  %44 = phi i32 [ %53, %52 ], [ %36, %35 ]
  %45 = shl i32 2, %43
  %46 = and i32 %45, %3
  %47 = icmp eq i32 %46, 0
  br i1 %47, label %52, label %48

48:                                               ; preds = %42
  %49 = add nsw i32 %43, %6
  %50 = tail call i32 @h1(i32 noundef %49)
  %51 = add nsw i32 %50, %44
  br label %52

52:                                               ; preds = %42, %48
  %53 = phi i32 [ %51, %48 ], [ %44, %42 ]
  %54 = add nuw nsw i32 %43, 1
  %55 = icmp eq i32 %54, %4
  br i1 %55, label %38, label %42, !llvm.loop !6

56:                                               ; preds = %38
  %57 = add nsw i32 %39, 1
  br label %65

58:                                               ; preds = %38
  %59 = and i32 %2, 2
  %60 = icmp eq i32 %59, 0
  br i1 %60, label %65, label %61

61:                                               ; preds = %58
  %62 = mul nsw i32 %6, 5
  %63 = tail call i32 @h2(i32 noundef %62)
  %64 = sub nsw i32 %39, %63
  br label %65

65:                                               ; preds = %58, %61, %56
  %66 = phi i32 [ %57, %56 ], [ %64, %61 ], [ %39, %58 ]
  %67 = tail call i32 @cq_measure_si32(i32 noundef %66) #4
  ret i32 %67
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
