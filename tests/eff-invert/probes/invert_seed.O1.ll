; ModuleID = 'invert_seed.c'
source_filename = "invert_seed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p_seedin(i32 noundef %0, double noundef %1, i32 noundef %2, ptr nocapture noundef readonly %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !6
  %7 = mul nsw i32 %2, 3
  %8 = add nsw i32 %7, 1
  %9 = tail call i32 @llvm.smax.i32(i32 %4, i32 1)
  %10 = zext nneg i32 %9 to i64
  br label %11

11:                                               ; preds = %11, %5
  %12 = phi i64 [ %17, %11 ], [ 0, %5 ]
  %13 = phi i32 [ %16, %11 ], [ %8, %5 ]
  %14 = getelementptr inbounds double, ptr %3, i64 %12
  %15 = load double, ptr %14, align 8, !tbaa !7
  %16 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef %15) #3
  %17 = add nuw nsw i64 %12, 1
  %18 = icmp eq i64 %17, %10
  br i1 %18, label %19, label %11, !llvm.loop !11

19:                                               ; preds = %11
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !14
  tail call void @__cq_invert_end() #4
  %20 = tail call i32 @cq_measure_si32(i32 noundef %16) #4
  %21 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %22 = add nsw i32 %21, %20
  ret i32 %22
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @__cq_invert_begin() local_unnamed_addr #1

declare void @__cq_invert_end() local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_seedtrip(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !15
  %7 = icmp sgt i32 %3, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %5
  %9 = zext nneg i32 %3 to i64
  br label %12

10:                                               ; preds = %12, %5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !16
  tail call void @__cq_invert_end() #4
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  ret i32 %11

12:                                               ; preds = %8, %12
  %13 = phi i64 [ 0, %8 ], [ %19, %12 ]
  %14 = getelementptr inbounds double, ptr %2, i64 %13
  %15 = load double, ptr %14, align 8, !tbaa !7
  %16 = trunc i64 %13 to i32
  %17 = add i32 %16, %4
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef %15) #3
  %19 = add nuw nsw i64 %13, 1
  %20 = icmp eq i64 %19, %9
  br i1 %20, label %10, label %12, !llvm.loop !17
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_seedarm(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !18
  %7 = icmp sgt i32 %2, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #3
  br label %10

10:                                               ; preds = %8, %5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %4) #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !19
  tail call void @__cq_invert_end() #4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  ret i32 %12
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!6 = !{i64 2147511040}
!7 = !{!8, !8, i64 0}
!8 = !{!"double", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = distinct !{!11, !12, !13}
!12 = !{!"llvm.loop.mustprogress"}
!13 = !{!"llvm.loop.unroll.disable"}
!14 = !{i64 2147512114}
!15 = !{i64 2147514741}
!16 = !{i64 2147515815}
!17 = distinct !{!17, !12, !13}
!18 = !{i64 2147517684}
!19 = !{i64 2147519768}
