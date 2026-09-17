; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/15feda8c-ff76-4035-8aec-acbfe9c14725/scratchpad/rz/m_rz_eq_rz.rolled.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/15feda8c-ff76-4035-8aec-acbfe9c14725/scratchpad/rz/m_rz_eq_rz.rolled.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@off = local_unnamed_addr global i32 3, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = icmp eq i32 %1, 5
  br label %5

3:                                                ; preds = %8
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  ret i32 %4

5:                                                ; preds = %0, %8
  %6 = phi i32 [ 0, %0 ], [ %9, %8 ]
  tail call void @cq_phi(double noundef 1.250000e-01) #2
  br i1 %2, label %7, label %8

7:                                                ; preds = %5
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %8

8:                                                ; preds = %7, %5
  tail call void @cq_phi(double noundef -1.250000e-01) #2
  %9 = add nuw nsw i32 %6, 1
  %10 = icmp eq i32 %6, 0
  br i1 %10, label %5, label %3, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = icmp eq i32 %1, 5
  br label %3

3:                                                ; preds = %6, %0
  %4 = phi i32 [ 0, %0 ], [ %7, %6 ]
  tail call void @cq_phi(double noundef 1.250000e-01) #2
  br i1 %2, label %5, label %6

5:                                                ; preds = %3
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %6

6:                                                ; preds = %5, %3
  tail call void @cq_phi(double noundef -1.250000e-01) #2
  %7 = add nuw nsw i32 %4, 1
  %8 = icmp eq i32 %4, 0
  br i1 %8, label %3, label %9, !llvm.loop !6

9:                                                ; preds = %6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  ret i32 0
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

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
