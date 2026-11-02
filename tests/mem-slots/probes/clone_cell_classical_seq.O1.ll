; ModuleID = 'clone_cell_classical_seq.c'
source_filename = "clone_cell_classical_seq.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @clone_cell_seq_a(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  store i32 7, ptr %4, align 4, !tbaa !6
  %6 = call fastcc double @sa(double noundef %5, i32 noundef %2, ptr noundef nonnull %4)
  %7 = tail call double @cq_measure_f64(double noundef %6) #6
  %8 = load i32, ptr %4, align 4, !tbaa !6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  %10 = sitofp i32 %9 to double
  %11 = fadd double %7, %10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  ret double %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc double @sa(double noundef %0, i32 noundef %1, ptr nocapture noundef writeonly %2) unnamed_addr #3 {
  store i32 0, ptr %2, align 4, !tbaa !6
  %4 = icmp sgt i32 %1, 2
  br i1 %4, label %5, label %13

5:                                                ; preds = %3
  %6 = fmul double %0, %0
  %7 = fcmp ule double %6, 1.000000e+00
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = add nuw nsw i32 %1, 1
  store i32 %9, ptr %2, align 4, !tbaa !6
  %10 = fsub double %6, %0
  br label %11

11:                                               ; preds = %5, %8
  %12 = phi double [ %10, %8 ], [ undef, %5 ]
  br i1 %7, label %13, label %15

13:                                               ; preds = %11, %3
  %14 = fmul double %0, 2.000000e+00
  br label %15

15:                                               ; preds = %11, %13
  %16 = phi double [ %12, %11 ], [ %14, %13 ]
  ret double %16
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define double @clone_cell_seq_b(double noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca double, align 8
  %6 = alloca double, align 8
  %7 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #6
  store double 5.000000e-01, ptr %5, align 8, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #6
  store double %3, ptr %6, align 8, !tbaa !10
  %8 = call fastcc i32 @sb(double noundef %7, i32 noundef %2, ptr noundef nonnull %5)
  %9 = fmul double %7, 3.000000e+00
  %10 = add nsw i32 %2, 1
  %11 = call fastcc i32 @sb(double noundef %9, i32 noundef %10, ptr noundef nonnull %6)
  %12 = load double, ptr %5, align 8, !tbaa !10
  %13 = tail call double @cq_measure_f64(double noundef %12) #6
  %14 = load double, ptr %6, align 8, !tbaa !10
  %15 = tail call double @cq_measure_f64(double noundef %14) #6
  %16 = fadd double %13, %15
  %17 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  %18 = sitofp i32 %17 to double
  %19 = fadd double %16, %18
  %20 = tail call i32 @cq_measure_si32(i32 noundef %11) #6
  %21 = sitofp i32 %20 to double
  %22 = fadd double %19, %21
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #6
  ret double %22
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc i32 @sb(double noundef %0, i32 noundef %1, ptr nocapture noundef writeonly %2) unnamed_addr #3 {
  %4 = fadd double %0, 1.000000e+00
  store double %4, ptr %2, align 8, !tbaa !10
  %5 = fcmp olt double %4, -2.000000e+00
  br i1 %5, label %22, label %6

6:                                                ; preds = %3
  %7 = and i32 %1, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %6
  %10 = fadd double %0, -3.000000e+00
  br label %18

11:                                               ; preds = %6
  %12 = and i32 %1, 2
  %13 = icmp ne i32 %12, 0
  %14 = fcmp olt double %0, 5.000000e-01
  %15 = and i1 %14, %13
  br i1 %15, label %16, label %22

16:                                               ; preds = %11
  %17 = fmul double %0, %0
  br label %18

18:                                               ; preds = %9, %16
  %19 = phi double [ %17, %16 ], [ %10, %9 ]
  %20 = phi i32 [ 2, %16 ], [ 1, %9 ]
  store double %19, ptr %2, align 8, !tbaa !10
  %21 = add nsw i32 %20, %1
  br label %22

22:                                               ; preds = %18, %11, %3
  %23 = phi i32 [ %1, %3 ], [ %1, %11 ], [ %21, %18 ]
  ret i32 %23
}

; Function Attrs: nounwind ssp uwtable
define double @clone_cell_seq_c(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca double, align 8
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #6
  store double -1.000000e+00, ptr %4, align 8, !tbaa !10
  %6 = call fastcc double @sc(double noundef %5, i32 noundef %2, ptr noundef nonnull %4)
  %7 = load double, ptr %4, align 8, !tbaa !10
  %8 = tail call double @cq_measure_f64(double noundef %7) #6
  %9 = tail call double @cq_measure_f64(double noundef %6) #6
  %10 = fadd double %8, %9
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #6
  ret double %10
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc double @sc(double noundef %0, i32 noundef %1, ptr nocapture noundef %2) unnamed_addr #4 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %11

5:                                                ; preds = %3
  store double %0, ptr %2, align 8, !tbaa !10
  %6 = fmul double %0, %0
  %7 = fcmp ogt double %6, 5.000000e-01
  br i1 %7, label %8, label %13

8:                                                ; preds = %5
  %9 = fsub double %6, %0
  store double %9, ptr %2, align 8, !tbaa !10
  %10 = icmp sgt i32 %1, 9
  br i1 %10, label %19, label %13

11:                                               ; preds = %3
  %12 = fmul double %0, 2.000000e+00
  store double %12, ptr %2, align 8, !tbaa !10
  br label %13

13:                                               ; preds = %5, %8, %11
  %14 = load double, ptr %2, align 8, !tbaa !10
  %15 = fadd double %14, 1.000000e+00
  %16 = icmp sgt i32 %1, 5
  br i1 %16, label %17, label %19

17:                                               ; preds = %13
  %18 = fmul double %15, 3.000000e+00
  store double %18, ptr %2, align 8, !tbaa !10
  br label %19

19:                                               ; preds = %8, %13, %17
  %20 = phi double [ %15, %17 ], [ %15, %13 ], [ %6, %8 ]
  ret double %20
}

; Function Attrs: nounwind ssp uwtable
define double @clone_cell_seq_d(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca double, align 8
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #6
  store double 4.000000e+00, ptr %4, align 8, !tbaa !10
  %6 = call fastcc i32 @sd(double noundef %5, i32 noundef %2, ptr noundef nonnull %4)
  %7 = load double, ptr %4, align 8, !tbaa !10
  %8 = tail call double @cq_measure_f64(double noundef %7) #6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #6
  %10 = sitofp i32 %9 to double
  %11 = fadd double %8, %10
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #6
  ret double %11
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc range(i32 0, 2) i32 @sd(double noundef %0, i32 noundef %1, ptr nocapture noundef writeonly %2) unnamed_addr #3 {
  %4 = icmp sgt i32 %1, 3
  br i1 %4, label %5, label %10

5:                                                ; preds = %3
  %6 = fmul double %0, 3.000000e+00
  %7 = fcmp ogt double %6, 1.000000e+00
  br i1 %7, label %8, label %10

8:                                                ; preds = %5
  store double %6, ptr %2, align 8, !tbaa !10
  %9 = icmp sgt i32 %1, 9
  br i1 %9, label %15, label %10

10:                                               ; preds = %5, %8, %3
  %11 = icmp sgt i32 %1, 6
  br i1 %11, label %12, label %15

12:                                               ; preds = %10
  %13 = uitofp nneg i32 %1 to double
  %14 = fadd double %13, %0
  store double %14, ptr %2, align 8, !tbaa !10
  br label %15

15:                                               ; preds = %8, %10, %12
  %16 = phi i32 [ 0, %12 ], [ 0, %10 ], [ 1, %8 ]
  ret i32 %16
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"double", !8, i64 0}
