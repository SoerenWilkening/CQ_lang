; ModuleID = 'b_bound_i32.c'
source_filename = "b_bound_i32.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @bb_i32(i8 noundef zeroext %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 1.000000e+00) #3
  %3 = zext i8 %2 to i32
  %4 = and i32 %3, 3
  %5 = tail call fastcc i32 @f(i32 noundef %4, i32 noundef %3)
  %6 = lshr i32 %3, 2
  %7 = and i32 %6, 7
  %8 = zext i8 %0 to i32
  %9 = add nuw nsw i32 %3, %8
  %10 = tail call fastcc i32 @f(i32 noundef %7, i32 noundef %9)
  %11 = add nsw i32 %10, %5
  ret i32 %11
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @f(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %6, %2
  %5 = phi i32 [ 1, %2 ], [ %12, %6 ]
  ret i32 %5

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %13, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %12, %6 ], [ 1, %2 ]
  %9 = mul nsw i32 %8, 3
  %10 = and i32 %8, 7
  %11 = lshr i32 %1, %10
  %12 = xor i32 %11, %9
  %13 = add nuw nsw i32 %7, 1
  %14 = icmp eq i32 %13, %0
  br i1 %14, label %4, label %6, !llvm.loop !6
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }

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
