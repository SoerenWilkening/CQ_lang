; ModuleID = 'invert_loop.c'
source_filename = "invert_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p_cloop(i32 noundef %0, double noundef %1, i32 noundef %2, ptr nocapture noundef readonly %3, i32 noundef %4, i32 noundef %5, double noundef %6) local_unnamed_addr #0 {
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

15:                                               ; preds = %41, %7
  %16 = phi i32 [ %2, %7 ], [ %33, %41 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !7
  tail call void @__cq_invert_end() #3
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  %18 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %19 = add nsw i32 %18, %17
  ret i32 %19

20:                                               ; preds = %10, %41
  %21 = phi i64 [ 0, %10 ], [ %42, %41 ]
  %22 = phi i32 [ %2, %10 ], [ %33, %41 ]
  %23 = shl nuw nsw i64 %21, 1
  %24 = icmp slt i64 %23, %14
  br i1 %24, label %25, label %32

25:                                               ; preds = %20
  %26 = getelementptr inbounds double, ptr %3, i64 %21
  %27 = load double, ptr %26, align 8, !tbaa !8
  %28 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef %27) #2
  %29 = trunc nuw nsw i64 %21 to i32
  %30 = uitofp nneg i32 %29 to double
  %31 = fmul double %30, %6
  tail call void @cq_phi(double noundef %31) #3
  br label %32

32:                                               ; preds = %25, %20
  %33 = phi i32 [ %28, %25 ], [ %22, %20 ]
  %34 = trunc nuw nsw i64 %21 to i32
  %35 = xor i32 %8, %34
  %36 = and i32 %35, 1
  %37 = icmp eq i32 %36, 0
  br i1 %37, label %41, label %38

38:                                               ; preds = %32
  %39 = getelementptr inbounds double, ptr %3, i64 %21
  %40 = load double, ptr %39, align 8, !tbaa !8
  tail call void @cq_phi(double noundef %40) #3
  br label %41

41:                                               ; preds = %32, %38
  %42 = add nuw nsw i64 %21, 1
  %43 = icmp eq i64 %42, %13
  br i1 %43, label %15, label %20, !llvm.loop !12
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
!6 = !{i64 2147510374}
!7 = !{i64 2147511448}
!8 = !{!9, !9, i64 0}
!9 = !{!"double", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
