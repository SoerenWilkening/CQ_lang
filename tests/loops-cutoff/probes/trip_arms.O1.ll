; ModuleID = 'trip_arms.c'
source_filename = "trip_arms.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@ta_g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @ta_scan(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 15
  br label %5

5:                                                ; preds = %2, %24
  %6 = phi i64 [ 0, %2 ], [ %26, %24 ]
  %7 = phi i32 [ %4, %2 ], [ %25, %24 ]
  %8 = trunc nuw i64 %6 to i32
  %9 = mul nuw nsw i32 %8, 3
  %10 = and i32 %7, -33
  %11 = icmp eq i32 %10, %9
  br i1 %11, label %12, label %28

12:                                               ; preds = %5
  %13 = icmp eq i64 %6, 3
  br i1 %13, label %24, label %14

14:                                               ; preds = %12
  %15 = shl nuw nsw i32 256, %8
  %16 = and i32 %15, %3
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %20, label %18

18:                                               ; preds = %14
  %19 = tail call fastcc i32 @more(i32 noundef %7)
  br label %24

20:                                               ; preds = %14
  %21 = or disjoint i32 %8, 12
  %22 = ashr i32 %3, %21
  %23 = and i32 %22, 15
  br label %24

24:                                               ; preds = %12, %20, %18
  %25 = phi i32 [ %19, %18 ], [ %23, %20 ], [ %7, %12 ]
  %26 = add nuw nsw i64 %6, 1
  %27 = icmp eq i64 %26, 4
  br i1 %27, label %28, label %5, !llvm.loop !6

28:                                               ; preds = %5, %24
  %29 = phi i32 [ %7, %5 ], [ %25, %24 ]
  %30 = phi i64 [ %6, %5 ], [ 4, %24 ]
  %31 = trunc i64 %30 to i32
  %32 = add nsw i32 %29, %31
  %33 = tail call i32 @cq_measure_si32(i32 noundef %32) #4
  ret i32 %33
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @more(i32 noundef %0) unnamed_addr #2 {
  %2 = load i32, ptr @ta_g, align 4, !tbaa !9
  %3 = add nsw i32 %2, %0
  store i32 %3, ptr @ta_g, align 4, !tbaa !9
  %4 = add nsw i32 %0, 1
  ret i32 %4
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!9 = !{!10, !10, i64 0}
!10 = !{!"int", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
