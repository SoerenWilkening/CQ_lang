; ModuleID = 'float_accum_quantum_break.c'
source_filename = "float_accum_quantum_break.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @float_accum_break(double noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3
  %8 = icmp sgt i32 %3, 0
  br i1 %8, label %9, label %21

9:                                                ; preds = %6
  %10 = zext nneg i32 %3 to i64
  br label %11

11:                                               ; preds = %11, %9
  %12 = phi i64 [ 0, %9 ], [ %18, %11 ]
  %13 = phi double [ 0.000000e+00, %9 ], [ %16, %11 ]
  %14 = getelementptr inbounds double, ptr %2, i64 %12
  %15 = load double, ptr %14, align 8, !tbaa !6
  %16 = tail call double @llvm.fmuladd.f64(double %15, double %7, double %13)
  %17 = fcmp ogt double %16, %4
  %18 = add nuw nsw i64 %12, 1
  %19 = icmp eq i64 %18, %10
  %20 = select i1 %17, i1 true, i1 %19
  br i1 %20, label %21, label %11, !llvm.loop !10

21:                                               ; preds = %11, %6
  %22 = phi double [ 0.000000e+00, %6 ], [ %16, %11 ]
  %23 = fmul double %4, 2.000000e+00
  %24 = fcmp ogt double %22, %23
  br i1 %24, label %25, label %27

25:                                               ; preds = %21
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %5) #3
  br label %27

27:                                               ; preds = %25, %21
  %28 = phi i1 [ %26, %25 ], [ false, %21 ]
  %29 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #4
  %30 = zext i1 %29 to i32
  %31 = tail call double @cq_measure_f64(double noundef %22) #4
  %32 = fcmp ogt double %31, 0.000000e+00
  %33 = zext i1 %32 to i32
  %34 = add nuw nsw i32 %33, %30
  ret i32 %34
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
