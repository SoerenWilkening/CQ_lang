; ModuleID = 'clone_cell_seq.c'
source_filename = "clone_cell_seq.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: write, inaccessiblemem: readwrite) uwtable
define void @two(double noundef %0, ptr nocapture noundef writeonly %1) local_unnamed_addr #0 {
  %3 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 2.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  store double %3, ptr %1, align 8, !tbaa !6
  %4 = tail call double @llvm.experimental.constrained.fadd.f64(double %3, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  store double %4, ptr %1, align 8, !tbaa !6
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #1

; Function Attrs: nounwind ssp strictfp uwtable
define double @u_two(double noundef %0) local_unnamed_addr #2 {
  %2 = alloca double, align 8
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #7
  call void @two(double noundef %3, ptr noundef nonnull %2) #5
  %4 = load double, ptr %2, align 8, !tbaa !6
  %5 = tail call double @cq_measure_f64(double noundef %4) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #7
  ret double %5
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #4

declare double @cq_measure_f64(double noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: write, inaccessiblemem: readwrite) uwtable
define range(i32 0, 2) i32 @cond(double noundef %0, ptr nocapture noundef writeonly %1) local_unnamed_addr #0 {
  %3 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 2.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  store double %3, ptr %1, align 8, !tbaa !6
  %4 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %3, double 1.000000e+00, metadata !"ogt", metadata !"fpexcept.ignore") #5
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  store double %6, ptr %1, align 8, !tbaa !6
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ 1, %5 ], [ 0, %2 ]
  ret i32 %8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #1

; Function Attrs: nounwind ssp strictfp uwtable
define double @u_cond(double noundef %0) local_unnamed_addr #2 {
  %2 = alloca double, align 8
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #7
  %4 = call i32 @cond(double noundef %3, ptr noundef nonnull %2) #5
  %5 = load double, ptr %2, align 8, !tbaa !6
  %6 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %4, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  %7 = tail call double @llvm.experimental.constrained.fadd.f64(double %5, double %6, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  %8 = tail call double @cq_measure_f64(double noundef %7) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #7
  ret double %8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: write, inaccessiblemem: readwrite) uwtable
define void @pair(double noundef %0, ptr nocapture noundef writeonly %1) local_unnamed_addr #0 {
  %3 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %0, double 5.000000e-01, metadata !"ogt", metadata !"fpexcept.ignore") #5
  br i1 %3, label %4, label %8

4:                                                ; preds = %2
  %5 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  store double %5, ptr %1, align 8, !tbaa !6
  %6 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %5, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  %7 = tail call double @llvm.experimental.constrained.fmul.f64(double %6, double 5.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  br label %9

8:                                                ; preds = %2
  store double %0, ptr %1, align 8, !tbaa !6
  br label %9

9:                                                ; preds = %8, %4
  %10 = phi double [ 2.500000e-01, %8 ], [ %7, %4 ]
  %11 = getelementptr inbounds i8, ptr %1, i64 8
  store double %10, ptr %11, align 8, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp strictfp uwtable
define double @u_pair(double noundef %0) local_unnamed_addr #2 {
  %2 = alloca [2 x double], align 16
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #6
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #7
  call void @pair(double noundef %3, ptr noundef nonnull %2) #5
  %4 = load double, ptr %2, align 16, !tbaa !6
  %5 = getelementptr inbounds i8, ptr %2, i64 8
  %6 = load double, ptr %5, align 8, !tbaa !6
  %7 = tail call double @llvm.experimental.constrained.fadd.f64(double %4, double %6, metadata !"round.dynamic", metadata !"fpexcept.ignore") #5
  %8 = tail call double @cq_measure_f64(double noundef %7) #7
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #7
  ret double %8
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: write, inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #2 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { strictfp }
attributes #6 = { nomerge nounwind strictfp }
attributes #7 = { nounwind strictfp }

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
