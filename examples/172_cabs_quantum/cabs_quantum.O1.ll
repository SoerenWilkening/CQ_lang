; ModuleID = 'cabs_quantum.c'
source_filename = "cabs_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @cabs_quantum_re(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %5 = tail call double @llvm.fabs.f64(double %4)
  %6 = bitcast double %5 to i64
  %7 = tail call double @llvm.fabs.f64(double %2)
  %8 = bitcast double %7 to i64
  %9 = icmp ult i64 %6, %8
  %10 = select i1 %9, double %5, double %7
  %11 = select i1 %9, double %7, double %5
  %12 = bitcast double %11 to i64
  %13 = lshr i64 %12, 52
  %14 = trunc nuw nsw i64 %13 to i32
  %15 = bitcast double %10 to i64
  %16 = lshr i64 %15, 52
  %17 = trunc nuw nsw i64 %16 to i32
  %18 = icmp eq i64 %16, 2047
  br i1 %18, label %63, label %19

19:                                               ; preds = %3
  %20 = icmp eq i64 %13, 2047
  %21 = icmp eq i64 %15, 0
  %22 = or i1 %21, %20
  br i1 %22, label %63, label %23

23:                                               ; preds = %19
  %24 = sub nsw i32 %14, %17
  %25 = icmp sgt i32 %24, 64
  br i1 %25, label %26, label %28

26:                                               ; preds = %23
  %27 = fadd double %7, %5
  br label %63

28:                                               ; preds = %23
  %29 = icmp ugt i64 %12, 6908521828386340863
  br i1 %29, label %30, label %33

30:                                               ; preds = %28
  %31 = fmul double %11, 0x1430000000000000
  %32 = fmul double %10, 0x1430000000000000
  br label %38

33:                                               ; preds = %28
  %34 = icmp ult i64 %15, 2580562586483294208
  br i1 %34, label %35, label %38

35:                                               ; preds = %33
  %36 = fmul double %11, 0x6BB0000000000000
  %37 = fmul double %10, 0x6BB0000000000000
  br label %38

38:                                               ; preds = %35, %33, %30
  %39 = phi double [ %32, %30 ], [ %37, %35 ], [ %10, %33 ]
  %40 = phi double [ %31, %30 ], [ %36, %35 ], [ %11, %33 ]
  %41 = phi double [ 0x6BB0000000000000, %30 ], [ 0x1430000000000000, %35 ], [ 1.000000e+00, %33 ]
  %42 = fptrunc double %40 to float
  %43 = fpext float %42 to double
  %44 = fsub double %40, %43
  %45 = fmul double %43, %43
  %46 = fadd double %40, %40
  %47 = fsub double %46, %44
  %48 = fmul double %44, %44
  %49 = tail call double @llvm.fmuladd.f64(double %44, double %47, double %48)
  %50 = fptrunc double %39 to float
  %51 = fpext float %50 to double
  %52 = fsub double %39, %51
  %53 = fmul double %51, %51
  %54 = fadd double %39, %39
  %55 = fsub double %54, %52
  %56 = fmul double %52, %52
  %57 = tail call double @llvm.fmuladd.f64(double %52, double %55, double %56)
  %58 = fadd double %57, %49
  %59 = fadd double %53, %58
  %60 = fadd double %45, %59
  %61 = tail call double @llvm.sqrt.f64(double %60)
  %62 = fmul double %41, %61
  br label %63

63:                                               ; preds = %3, %19, %26, %38
  %64 = phi double [ %27, %26 ], [ %62, %38 ], [ %10, %3 ], [ %11, %19 ]
  %65 = tail call double @cq_measure_f64(double noundef %64) #5
  ret double %65
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @cabs_quantum_both(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %6 = tail call double @cq_theta_f64(double noundef %2, double noundef %3) #4
  %7 = tail call double @llvm.fabs.f64(double %5)
  %8 = bitcast double %7 to i64
  %9 = tail call double @llvm.fabs.f64(double %6)
  %10 = bitcast double %9 to i64
  %11 = icmp ult i64 %8, %10
  %12 = select i1 %11, double %7, double %9
  %13 = select i1 %11, double %9, double %7
  %14 = bitcast double %13 to i64
  %15 = lshr i64 %14, 52
  %16 = trunc nuw nsw i64 %15 to i32
  %17 = bitcast double %12 to i64
  %18 = lshr i64 %17, 52
  %19 = trunc nuw nsw i64 %18 to i32
  %20 = icmp eq i64 %18, 2047
  br i1 %20, label %65, label %21

21:                                               ; preds = %4
  %22 = icmp eq i64 %15, 2047
  %23 = icmp eq i64 %17, 0
  %24 = or i1 %23, %22
  br i1 %24, label %65, label %25

25:                                               ; preds = %21
  %26 = sub nsw i32 %16, %19
  %27 = icmp sgt i32 %26, 64
  br i1 %27, label %28, label %30

28:                                               ; preds = %25
  %29 = fadd double %7, %9
  br label %65

30:                                               ; preds = %25
  %31 = icmp ugt i64 %14, 6908521828386340863
  br i1 %31, label %32, label %35

32:                                               ; preds = %30
  %33 = fmul double %13, 0x1430000000000000
  %34 = fmul double %12, 0x1430000000000000
  br label %40

35:                                               ; preds = %30
  %36 = icmp ult i64 %17, 2580562586483294208
  br i1 %36, label %37, label %40

37:                                               ; preds = %35
  %38 = fmul double %13, 0x6BB0000000000000
  %39 = fmul double %12, 0x6BB0000000000000
  br label %40

40:                                               ; preds = %37, %35, %32
  %41 = phi double [ %34, %32 ], [ %39, %37 ], [ %12, %35 ]
  %42 = phi double [ %33, %32 ], [ %38, %37 ], [ %13, %35 ]
  %43 = phi double [ 0x6BB0000000000000, %32 ], [ 0x1430000000000000, %37 ], [ 1.000000e+00, %35 ]
  %44 = fptrunc double %42 to float
  %45 = fpext float %44 to double
  %46 = fsub double %42, %45
  %47 = fmul double %45, %45
  %48 = fadd double %42, %42
  %49 = fsub double %48, %46
  %50 = fmul double %46, %46
  %51 = tail call double @llvm.fmuladd.f64(double %46, double %49, double %50)
  %52 = fptrunc double %41 to float
  %53 = fpext float %52 to double
  %54 = fsub double %41, %53
  %55 = fmul double %53, %53
  %56 = fadd double %41, %41
  %57 = fsub double %56, %54
  %58 = fmul double %54, %54
  %59 = tail call double @llvm.fmuladd.f64(double %54, double %57, double %58)
  %60 = fadd double %59, %51
  %61 = fadd double %55, %60
  %62 = fadd double %47, %61
  %63 = tail call double @llvm.sqrt.f64(double %62)
  %64 = fmul double %43, %63
  br label %65

65:                                               ; preds = %4, %21, %28, %40
  %66 = phi double [ %29, %28 ], [ %64, %40 ], [ %12, %4 ], [ %13, %21 ]
  %67 = tail call double @cq_measure_f64(double noundef %66) #5
  ret double %67
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
