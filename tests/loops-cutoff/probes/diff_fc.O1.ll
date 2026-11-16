; ModuleID = 'diff_fc.c'
source_filename = "diff_fc.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !6
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = lshr i32 %5, 1
  br i1 %7, label %9, label %4, !llvm.loop !7

9:                                                ; preds = %4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !10
  tail call void @__cq_invert_end() #5
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %5) #6
  ret i32 %10
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #2

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_do(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !11
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %9, %4 ]
  %6 = phi i32 [ 3, %2 ], [ %8, %4 ]
  %7 = mul i32 %6, 5
  %8 = add i32 %7, %5
  %9 = lshr i32 %5, 1
  %10 = and i32 %5, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !12

12:                                               ; preds = %4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !13
  tail call void @__cq_invert_end() #5
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %8) #6
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_call(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !14
  %4 = tail call fastcc i32 @fc_g(i32 noundef %3)
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !15
  tail call void @__cq_invert_end() #5
  %5 = tail call i32 @cq_measure_ui32(i32 noundef %4) #6
  ret i32 %5
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @fc_g(i32 noundef %0) unnamed_addr #3 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %12, label %4

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %8, %4 ], [ 1, %1 ]
  %6 = phi i32 [ %9, %4 ], [ %0, %1 ]
  %7 = mul i32 %5, 3
  %8 = add i32 %7, %6
  %9 = lshr i32 %6, 1
  %10 = and i32 %6, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !16

12:                                               ; preds = %4, %1
  %13 = phi i32 [ 1, %1 ], [ %8, %4 ]
  ret i32 %13
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { noduplicate nounwind }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{i64 2147511708}
!7 = distinct !{!7, !8, !9}
!8 = !{!"llvm.loop.mustprogress"}
!9 = !{!"llvm.loop.unroll.disable"}
!10 = !{i64 2147511764}
!11 = !{i64 2147513633}
!12 = distinct !{!12, !8, !9}
!13 = !{i64 2147513689}
!14 = !{i64 2147515558}
!15 = !{i64 2147515614}
!16 = distinct !{!16, !8, !9}
