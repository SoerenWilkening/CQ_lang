; ModuleID = 'fenv_ignore_loop.c'
source_filename = "fenv_ignore_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define double @il_loop(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %5 = and i32 %4, 3
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %10, %3
  %8 = phi double [ %2, %3 ], [ %16, %10 ]
  %9 = tail call double @cq_measure_f64(double noundef %8) #5
  ret double %9

10:                                               ; preds = %3, %10
  %11 = phi i32 [ %17, %10 ], [ 0, %3 ]
  %12 = phi double [ %16, %10 ], [ %2, %3 ]
  %13 = tail call double @llvm.experimental.constrained.fmul.f64(double %12, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %14 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %13, metadata !"fpexcept.ignore") #6
  %15 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %14, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %16 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %12, double 5.000000e-01, double %15, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %17 = add nuw nsw i32 %11, 1
  %18 = icmp eq i32 %17, %5
  br i1 %18, label %7, label %10, !llvm.loop !6
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp strictfp uwtable
define double @il_array(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  br label %15

5:                                                ; preds = %15
  %6 = getelementptr inbounds i8, ptr %3, i64 4
  %7 = load i32, ptr %6, align 4, !tbaa !9
  %8 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %7, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %9 = tail call double @llvm.experimental.constrained.fadd.f64(double %23, double %8, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %10 = getelementptr inbounds i8, ptr %3, i64 12
  %11 = load i32, ptr %10, align 4, !tbaa !9
  %12 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %11, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %13 = tail call double @llvm.experimental.constrained.fadd.f64(double %9, double %12, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %14 = tail call double @cq_measure_f64(double noundef %13) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret double %14

15:                                               ; preds = %2, %15
  %16 = phi i64 [ 0, %2 ], [ %24, %15 ]
  %17 = phi double [ %4, %2 ], [ %23, %15 ]
  %18 = tail call double @llvm.experimental.constrained.fmul.f64(double %17, double 2.500000e-01, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %19 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %18, metadata !"fpexcept.ignore") #6
  %20 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %16
  store i32 %19, ptr %20, align 4, !tbaa !9
  %21 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %19, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %22 = fneg double %21
  %23 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %17, double 2.000000e+00, double %22, metadata !"round.dynamic", metadata !"fpexcept.ignore") #6
  %24 = add nuw nsw i64 %16, 1
  %25 = icmp eq i64 %24, 4
  br i1 %25, label %5, label %15, !llvm.loop !13
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #3

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { nomerge nounwind strictfp }
attributes #5 = { nounwind strictfp }
attributes #6 = { strictfp }

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
!13 = distinct !{!13, !7, !8}
