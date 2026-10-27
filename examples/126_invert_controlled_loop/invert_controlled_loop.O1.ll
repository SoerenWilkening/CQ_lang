; ModuleID = 'invert_controlled_loop.c'
source_filename = "invert_controlled_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @invert_controlled_loop(i32 noundef %0, double noundef %1, i32 noundef %2, ptr nocapture noundef readonly %3, i32 noundef %4, i32 noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !6
  %9 = icmp sgt i32 %4, 0
  br i1 %9, label %10, label %15

10:                                               ; preds = %7
  %11 = sext i32 %5 to i64
  %12 = sext i32 %8 to i64
  %13 = zext nneg i32 %4 to i64
  %14 = sub nsw i64 %12, %11
  br label %20

15:                                               ; preds = %28, %7
  %16 = phi i32 [ %2, %7 ], [ %29, %28 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !7
  tail call void @__cq_invert_end() #3
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  %18 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %19 = add nsw i32 %18, %17
  ret i32 %19

20:                                               ; preds = %10, %28
  %21 = phi i64 [ 0, %10 ], [ %30, %28 ]
  %22 = phi i32 [ %2, %10 ], [ %29, %28 ]
  %23 = icmp slt i64 %21, %14
  br i1 %23, label %24, label %28

24:                                               ; preds = %20
  %25 = getelementptr inbounds double, ptr %3, i64 %21
  %26 = load double, ptr %25, align 8, !tbaa !8
  %27 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef %26) #2
  tail call void @cq_phi(double noundef %6) #3
  br label %28

28:                                               ; preds = %20, %24
  %29 = phi i32 [ %27, %24 ], [ %22, %20 ]
  %30 = add nuw nsw i64 %21, 1
  %31 = icmp eq i64 %30, %13
  br i1 %31, label %15, label %20, !llvm.loop !12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @__cq_invert_begin() local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare void @__cq_invert_end() local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!6 = !{i64 2147510113}
!7 = !{i64 2147511187}
!8 = !{!9, !9, i64 0}
!9 = !{!"double", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
