; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@A = internal constant [3 x x86_fp80] [x86_fp80 0xK3FFF8000000000000000, x86_fp80 0xK40008000000000000000, x86_fp80 0xK4000C000000000000000], align 16
@B = internal constant [4 x x86_fp80] [x86_fp80 0xK40018000000000000000, x86_fp80 0xK4001A000000000000000, x86_fp80 0xK4001C000000000000000, x86_fp80 0xK4001E000000000000000], align 16

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @f_tables(x86_fp80 noundef %0) local_unnamed_addr #0 {
  %2 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef %0, double noundef 3.000000e-01) #4
  %3 = tail call x86_fp80 @pol(x86_fp80 noundef %2, ptr noundef nonnull @A, i32 noundef 2) #5
  %4 = tail call x86_fp80 @pol(x86_fp80 noundef %2, ptr noundef nonnull getelementptr inbounds (i8, ptr @B, i64 16), i32 noundef 2) #5
  %5 = fdiv x86_fp80 %3, %4
  %6 = tail call x86_fp80 @cq_measure_f80(x86_fp80 noundef %5) #5
  ret x86_fp80 %6
}

declare x86_fp80 @cq_theta_f80(x86_fp80 noundef, double noundef) local_unnamed_addr #1

declare x86_fp80 @cq_measure_f80(x86_fp80 noundef) local_unnamed_addr #1

; Function Attrs: nofree norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define x86_fp80 @pol(x86_fp80 noundef %0, ptr nocapture noundef readonly %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = load x86_fp80, ptr %1, align 16, !tbaa !6
  br label %5

5:                                                ; preds = %5, %3
  %6 = phi i32 [ %2, %3 ], [ %12, %5 ]
  %7 = phi ptr [ %1, %3 ], [ %9, %5 ]
  %8 = phi x86_fp80 [ %4, %3 ], [ %11, %5 ]
  %9 = getelementptr inbounds i8, ptr %7, i64 16
  %10 = load x86_fp80, ptr %9, align 16, !tbaa !6
  %11 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %8, x86_fp80 %0, x86_fp80 %10)
  %12 = add nsw i32 %6, -1
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %5, !llvm.loop !10

14:                                               ; preds = %5
  ret x86_fp80 %11
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare x86_fp80 @llvm.fmuladd.f80(x86_fp80, x86_fp80, x86_fp80) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"long double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
