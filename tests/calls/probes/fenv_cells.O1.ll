; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fe_cells(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca [2 x double], align 16
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #6
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #7
  call void @sc(double noundef %3, ptr noundef nonnull %2) #7
  %4 = load double, ptr %2, align 16, !tbaa !6
  %5 = getelementptr inbounds i8, ptr %2, i64 8
  %6 = load double, ptr %5, align 8, !tbaa !6
  %7 = fadd double %4, %6
  %8 = call double @cq_measure_f64(double noundef %7) #7
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #7
  ret double %8
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nounwind ssp uwtable
define double @fe_reread(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca double, align 8
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #7
  %4 = call i32 @sc2(double noundef %3, ptr noundef nonnull %2) #7
  %5 = load double, ptr %2, align 8, !tbaa !6
  %6 = sitofp i32 %4 to double
  %7 = fadd double %5, %6
  %8 = call double @cq_measure_f64(double noundef %7) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #7
  ret double %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @fe_qram(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [2 x i32], align 4
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #7
  store i32 %2, ptr %5, align 4, !tbaa !10
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %3, ptr %7, align 4, !tbaa !10
  %8 = and i32 %6, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds i32, ptr %5, i64 %9
  %11 = uitofp i32 %6 to double
  %12 = fadd double %11, -3.000000e+00
  call void @addto(ptr noundef nonnull %5, ptr noundef nonnull %10, double noundef %12) #7
  %13 = load i32, ptr %5, align 4, !tbaa !10
  %14 = call i32 @cq_measure_si32(i32 noundef %13) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #7
  ret i32 %14
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: write, inaccessiblemem: readwrite) uwtable
define void @sc(double noundef %0, ptr nocapture noundef writeonly %1) local_unnamed_addr #3 {
  %3 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #8
  store double %3, ptr %1, align 8, !tbaa !6
  %4 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #8
  %5 = getelementptr inbounds i8, ptr %1, i64 8
  store double %4, ptr %5, align 8, !tbaa !6
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #4

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: write, inaccessiblemem: readwrite) uwtable
define range(i32 0, 2) i32 @sc2(double noundef %0, ptr nocapture noundef writeonly %1) local_unnamed_addr #3 {
  %3 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 2.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #8
  store double %3, ptr %1, align 8, !tbaa !6
  %4 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %3, double 1.000000e+00, metadata !"ogt", metadata !"fpexcept.strict") #8
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #8
  store double %6, ptr %1, align 8, !tbaa !6
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ 1, %5 ], [ 0, %2 ]
  ret i32 %8
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #4

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: readwrite, inaccessiblemem: readwrite) uwtable
define void @addto(ptr nocapture noundef %0, ptr nocapture noundef readonly %1, double noundef %2) local_unnamed_addr #5 {
  %4 = load i32, ptr %1, align 4, !tbaa !10
  %5 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %2, double 0.000000e+00, metadata !"ogt", metadata !"fpexcept.strict") #8
  %6 = zext i1 %5 to i32
  %7 = add nsw i32 %4, %6
  %8 = load i32, ptr %0, align 4, !tbaa !10
  %9 = add nsw i32 %7, %8
  store i32 %9, ptr %0, align 4, !tbaa !10
  ret void
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: write, inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: readwrite, inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }
attributes #8 = { strictfp }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
