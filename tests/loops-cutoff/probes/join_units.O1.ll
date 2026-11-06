; ModuleID = 'join_units.c'
source_filename = "join_units.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ju_units(i32 noundef %0, i64 noundef %1, i64 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3) #2
  %6 = icmp eq i64 %1, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %4
  %8 = icmp sgt i64 %2, 3
  br i1 %8, label %33, label %29

9:                                                ; preds = %4
  %10 = and i32 %5, 1
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %71, label %12

12:                                               ; preds = %9, %18
  %13 = phi i64 [ %24, %18 ], [ 0, %9 ]
  %14 = phi i32 [ %25, %18 ], [ 0, %9 ]
  %15 = shl i32 65536, %14
  %16 = and i32 %15, %5
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %71

18:                                               ; preds = %12
  %19 = add nuw nsw i32 %14, 8
  %20 = lshr i32 %5, %19
  %21 = and i32 %20, 1
  %22 = add nuw nsw i32 %21, 1
  %23 = zext nneg i32 %22 to i64
  %24 = add nuw nsw i64 %13, %23
  %25 = add nuw nsw i32 %14, 1
  %26 = shl nuw i32 2, %14
  %27 = and i32 %26, %5
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %71, label %12, !llvm.loop !6

29:                                               ; preds = %45, %7
  %30 = phi i64 [ %2, %7 ], [ %51, %45 ]
  %31 = phi i32 [ 0, %7 ], [ %52, %45 ]
  %32 = icmp eq i64 %30, 0
  br i1 %32, label %71, label %54

33:                                               ; preds = %7, %45
  %34 = phi i32 [ %52, %45 ], [ 0, %7 ]
  %35 = phi i64 [ %51, %45 ], [ %2, %7 ]
  %36 = shl nuw i32 1, %34
  %37 = and i32 %36, %5
  %38 = icmp eq i32 %37, 0
  br i1 %38, label %41, label %39

39:                                               ; preds = %33
  %40 = sub nsw i64 %2, %35
  br label %71

41:                                               ; preds = %33
  %42 = shl i32 65536, %34
  %43 = and i32 %42, %5
  %44 = icmp eq i32 %43, 0
  br i1 %44, label %45, label %71

45:                                               ; preds = %41
  %46 = add nuw nsw i32 %34, 8
  %47 = lshr i32 %5, %46
  %48 = and i32 %47, 1
  %49 = add nuw nsw i32 %48, 1
  %50 = zext nneg i32 %49 to i64
  %51 = sub nsw i64 %35, %50
  %52 = add nuw nsw i32 %34, 1
  %53 = icmp sgt i64 %51, 3
  br i1 %53, label %33, label %29, !llvm.loop !9

54:                                               ; preds = %29, %67
  %55 = phi i32 [ %69, %67 ], [ %31, %29 ]
  %56 = phi i64 [ %68, %67 ], [ %30, %29 ]
  %57 = shl nuw i32 1, %55
  %58 = and i32 %57, %5
  %59 = icmp eq i32 %58, 0
  br i1 %59, label %63, label %60

60:                                               ; preds = %54
  %61 = add i64 %2, 100
  %62 = sub i64 %61, %56
  br label %71

63:                                               ; preds = %54
  %64 = shl i32 65536, %55
  %65 = and i32 %64, %5
  %66 = icmp eq i32 %65, 0
  br i1 %66, label %67, label %71

67:                                               ; preds = %63
  %68 = add nsw i64 %56, -1
  %69 = add nuw nsw i32 %55, 1
  %70 = icmp eq i64 %68, 0
  br i1 %70, label %71, label %54, !llvm.loop !10

71:                                               ; preds = %41, %63, %67, %18, %12, %29, %9, %60, %39
  %72 = phi i64 [ %40, %39 ], [ %62, %60 ], [ 0, %9 ], [ %2, %29 ], [ -2, %12 ], [ %24, %18 ], [ %2, %67 ], [ -1, %63 ], [ -3, %41 ]
  %73 = tail call i64 @cq_measure_sl(i64 noundef %72) #3
  %74 = trunc i64 %73 to i32
  ret i32 %74
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

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
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
