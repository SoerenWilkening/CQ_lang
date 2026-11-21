; ModuleID = 'nest.c'
source_filename = "nest.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483648, 2147483647) i32 @g1(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 7
  %3 = add nsw i32 %2, -1
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -1073741815, 1073741833) i32 @g2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = ashr i32 %0, 1
  %3 = add nsw i32 %2, 9
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @nest(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 0x3FE6666666666666) #4
  %6 = and i32 %2, 1
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %20, label %8

8:                                                ; preds = %4
  %9 = tail call i32 @g1(i32 noundef %5)
  %10 = and i32 %2, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %16, label %12

12:                                               ; preds = %8
  %13 = add nsw i32 %5, %1
  %14 = tail call i32 @g2(i32 noundef %13)
  %15 = add nsw i32 %14, %9
  br label %20

16:                                               ; preds = %8
  %17 = xor i32 %5, %1
  %18 = tail call i32 @g1(i32 noundef %17)
  %19 = sub nsw i32 %9, %18
  br label %20

20:                                               ; preds = %12, %16, %4
  %21 = phi i32 [ %15, %12 ], [ %19, %16 ], [ 1, %4 ]
  %22 = icmp slt i32 %1, 0
  br i1 %22, label %55, label %23

23:                                               ; preds = %20
  %24 = icmp sgt i32 %3, 0
  br i1 %24, label %25, label %49

25:                                               ; preds = %23
  %26 = add nsw i32 %3, -1
  %27 = tail call i32 @llvm.umin.i32(i32 %1, i32 %26)
  br label %28

28:                                               ; preds = %25, %45
  %29 = phi i1 [ %47, %45 ], [ %24, %25 ]
  %30 = phi i32 [ %46, %45 ], [ 0, %25 ]
  %31 = phi i32 [ %40, %45 ], [ %21, %25 ]
  %32 = ashr i32 %2, %30
  %33 = and i32 %32, 4
  %34 = icmp eq i32 %33, 0
  br i1 %34, label %39, label %35

35:                                               ; preds = %28
  %36 = add nsw i32 %30, %5
  %37 = tail call i32 @g2(i32 noundef %36)
  %38 = xor i32 %37, %31
  br label %39

39:                                               ; preds = %35, %28
  %40 = phi i32 [ %38, %35 ], [ %31, %28 ]
  %41 = icmp eq i32 %30, %1
  br i1 %41, label %42, label %45

42:                                               ; preds = %39
  %43 = sub nsw i32 %40, %27
  %44 = tail call i32 @cq_measure_si32(i32 noundef %43) #5
  br label %49

45:                                               ; preds = %39
  %46 = add nuw nsw i32 %30, 1
  %47 = icmp slt i32 %46, %3
  %48 = icmp eq i32 %46, %3
  br i1 %48, label %49, label %28, !llvm.loop !6

49:                                               ; preds = %45, %23, %42
  %50 = phi i1 [ %29, %42 ], [ %24, %23 ], [ %47, %45 ]
  %51 = phi i32 [ %44, %42 ], [ undef, %23 ], [ undef, %45 ]
  %52 = phi i32 [ %40, %42 ], [ %21, %23 ], [ %40, %45 ]
  br i1 %50, label %58, label %53

53:                                               ; preds = %49
  %54 = add nsw i32 %52, 3
  br label %55

55:                                               ; preds = %20, %53
  %56 = phi i32 [ %54, %53 ], [ %21, %20 ]
  %57 = tail call i32 @cq_measure_si32(i32 noundef %56) #5
  br label %58

58:                                               ; preds = %55, %49
  %59 = phi i32 [ %51, %49 ], [ %57, %55 ]
  ret i32 %59
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #3

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
