; ModuleID = 'clone_cell_classical_arms.c'
source_filename = "clone_cell_classical_arms.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @clone_cell_classical_arms(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [2 x double], align 16
  %4 = alloca [2 x double], align 16
  %5 = alloca [2 x double], align 16
  %6 = alloca [2 x double], align 16
  %7 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  %8 = fmul double %7, 3.000000e+00
  store double %8, ptr %3, align 16, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %3, i64 8
  store double 4.000000e+00, ptr %9, align 8, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  store double %7, ptr %4, align 16, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %4, i64 8
  store double 5.000000e+00, ptr %10, align 8, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #5
  store double 6.000000e+00, ptr %5, align 16, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %5, i64 8
  store double %7, ptr %11, align 8, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %6) #5
  %12 = fadd double %7, 7.000000e+00
  store double %12, ptr %6, align 16, !tbaa !6
  %13 = getelementptr inbounds i8, ptr %6, i64 8
  store double %7, ptr %13, align 8, !tbaa !6
  call fastcc void @f(i32 noundef 0, double noundef %7, ptr noundef nonnull %3)
  call fastcc void @f(i32 noundef 1, double noundef %7, ptr noundef nonnull %4)
  call fastcc void @f(i32 noundef 2, double noundef %7, ptr noundef nonnull %5)
  call fastcc void @f(i32 noundef 3, double noundef %7, ptr noundef nonnull %6)
  %14 = load double, ptr %3, align 16, !tbaa !6
  %15 = load double, ptr %9, align 8, !tbaa !6
  %16 = fadd double %14, %15
  %17 = load double, ptr %4, align 16, !tbaa !6
  %18 = fadd double %16, %17
  %19 = load double, ptr %10, align 8, !tbaa !6
  %20 = fadd double %18, %19
  %21 = load double, ptr %5, align 16, !tbaa !6
  %22 = fadd double %20, %21
  %23 = load double, ptr %11, align 8, !tbaa !6
  %24 = fadd double %22, %23
  %25 = load double, ptr %6, align 16, !tbaa !6
  %26 = fadd double %24, %25
  %27 = load double, ptr %13, align 8, !tbaa !6
  %28 = fadd double %26, %27
  %29 = tail call double @cq_measure_f64(double noundef %28) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %6) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret double %29
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @f(i32 noundef %0, double noundef %1, ptr nocapture noundef writeonly %2) unnamed_addr #3 {
  switch i32 %0, label %20 [
    i32 0, label %4
    i32 1, label %10
    i32 2, label %15
  ]

4:                                                ; preds = %3
  %5 = fcmp ogt double %1, 1.000000e+00
  br i1 %5, label %6, label %8

6:                                                ; preds = %4
  %7 = fmul double %1, 2.000000e+00
  store double %7, ptr %2, align 8, !tbaa !6
  br label %20

8:                                                ; preds = %4
  %9 = fneg double %1
  store double %9, ptr %2, align 8, !tbaa !6
  br label %20

10:                                               ; preds = %3
  %11 = fadd double %1, 1.000000e+00
  store double %11, ptr %2, align 8, !tbaa !6
  %12 = fcmp olt double %1, 5.000000e-01
  br i1 %12, label %13, label %20

13:                                               ; preds = %10
  %14 = getelementptr inbounds i8, ptr %2, i64 8
  store double %1, ptr %14, align 8, !tbaa !6
  br label %20

15:                                               ; preds = %3
  %16 = fcmp une double %1, 0.000000e+00
  br i1 %16, label %17, label %20

17:                                               ; preds = %15
  store double %1, ptr %2, align 8, !tbaa !6
  %18 = fmul double %1, %1
  %19 = getelementptr inbounds i8, ptr %2, i64 8
  store double %18, ptr %19, align 8, !tbaa !6
  br label %20

20:                                               ; preds = %3, %15, %17, %10, %13, %6, %8
  ret void
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

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

; CHECK __cq_q_f_010011: switch i32 %0, label
; CHECK __cq_q_f_010011: call i32 @cq_template_select_f64(i32 %{{p}}, i32 %{{v}}, i32 %{{old}})
; CHECK __cq_q_f_010011_unc: call void @cqrt_copy_f64(i32 %old0, i32 %cell)
; USERCHECK clone_cell_classical_arms
