; ModuleID = 'cabs_complex_h.c'
source_filename = "cabs_complex_h.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define double @cabs(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @llvm.fabs.f64(double %0)
  %4 = bitcast double %3 to i64
  %5 = tail call double @llvm.fabs.f64(double %1)
  %6 = bitcast double %5 to i64
  %7 = icmp ult i64 %4, %6
  %8 = select i1 %7, double %3, double %5
  %9 = select i1 %7, double %5, double %3
  %10 = bitcast double %9 to i64
  %11 = lshr i64 %10, 52
  %12 = trunc nuw nsw i64 %11 to i32
  %13 = bitcast double %8 to i64
  %14 = lshr i64 %13, 52
  %15 = trunc nuw nsw i64 %14 to i32
  %16 = icmp eq i64 %14, 2047
  br i1 %16, label %61, label %17

17:                                               ; preds = %2
  %18 = icmp eq i64 %11, 2047
  %19 = icmp eq i64 %13, 0
  %20 = or i1 %19, %18
  br i1 %20, label %61, label %21

21:                                               ; preds = %17
  %22 = sub nsw i32 %12, %15
  %23 = icmp sgt i32 %22, 64
  br i1 %23, label %24, label %26

24:                                               ; preds = %21
  %25 = fadd double %3, %5
  br label %61

26:                                               ; preds = %21
  %27 = icmp ugt i64 %10, 6908521828386340863
  br i1 %27, label %28, label %31

28:                                               ; preds = %26
  %29 = fmul double %9, 0x1430000000000000
  %30 = fmul double %8, 0x1430000000000000
  br label %36

31:                                               ; preds = %26
  %32 = icmp ult i64 %13, 2580562586483294208
  br i1 %32, label %33, label %36

33:                                               ; preds = %31
  %34 = fmul double %9, 0x6BB0000000000000
  %35 = fmul double %8, 0x6BB0000000000000
  br label %36

36:                                               ; preds = %33, %31, %28
  %37 = phi double [ %30, %28 ], [ %35, %33 ], [ %8, %31 ]
  %38 = phi double [ %29, %28 ], [ %34, %33 ], [ %9, %31 ]
  %39 = phi double [ 0x6BB0000000000000, %28 ], [ 0x1430000000000000, %33 ], [ 1.000000e+00, %31 ]
  %40 = fptrunc double %38 to float
  %41 = fpext float %40 to double
  %42 = fsub double %38, %41
  %43 = fmul double %41, %41
  %44 = fadd double %38, %38
  %45 = fsub double %44, %42
  %46 = fmul double %42, %42
  %47 = tail call double @llvm.fmuladd.f64(double %42, double %45, double %46)
  %48 = fptrunc double %37 to float
  %49 = fpext float %48 to double
  %50 = fsub double %37, %49
  %51 = fmul double %49, %49
  %52 = fadd double %37, %37
  %53 = fsub double %52, %50
  %54 = fmul double %50, %50
  %55 = tail call double @llvm.fmuladd.f64(double %50, double %53, double %54)
  %56 = fadd double %55, %47
  %57 = fadd double %51, %56
  %58 = fadd double %43, %57
  %59 = tail call double @llvm.sqrt.f64(double %58)
  %60 = fmul double %39, %59
  br label %61

61:                                               ; preds = %2, %17, %24, %36
  %62 = phi double [ %25, %24 ], [ %60, %36 ], [ %8, %2 ], [ %9, %17 ]
  ret double %62
}

; Function Attrs: nounwind ssp uwtable
define double @cabs_complex_h_re(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %5 = fmul double %2, 0.000000e+00
  %6 = fadd double %5, %4
  %7 = tail call double @llvm.fabs.f64(double %6)
  %8 = bitcast double %7 to i64
  %9 = tail call double @llvm.fabs.f64(double %2)
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

21:                                               ; preds = %3
  %22 = icmp eq i64 %15, 2047
  %23 = icmp eq i64 %17, 0
  %24 = or i1 %23, %22
  br i1 %24, label %65, label %25

25:                                               ; preds = %21
  %26 = sub nsw i32 %16, %19
  %27 = icmp sgt i32 %26, 64
  br i1 %27, label %28, label %30

28:                                               ; preds = %25
  %29 = fadd double %9, %7
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

65:                                               ; preds = %3, %21, %28, %40
  %66 = phi double [ %29, %28 ], [ %64, %40 ], [ %12, %3 ], [ %13, %21 ]
  %67 = tail call double @cq_measure_f64(double noundef %66) #6
  ret double %67
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define double @cabs_complex_h_both(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #1 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %6 = tail call double @cq_theta_f64(double noundef %2, double noundef %3) #5
  %7 = fmul double %6, 0.000000e+00
  %8 = fadd double %5, %7
  %9 = tail call double @llvm.fabs.f64(double %8)
  %10 = bitcast double %9 to i64
  %11 = tail call double @llvm.fabs.f64(double %6)
  %12 = bitcast double %11 to i64
  %13 = icmp ult i64 %10, %12
  %14 = select i1 %13, double %9, double %11
  %15 = select i1 %13, double %11, double %9
  %16 = bitcast double %15 to i64
  %17 = lshr i64 %16, 52
  %18 = trunc nuw nsw i64 %17 to i32
  %19 = bitcast double %14 to i64
  %20 = lshr i64 %19, 52
  %21 = trunc nuw nsw i64 %20 to i32
  %22 = icmp eq i64 %20, 2047
  br i1 %22, label %67, label %23

23:                                               ; preds = %4
  %24 = icmp eq i64 %17, 2047
  %25 = icmp eq i64 %19, 0
  %26 = or i1 %25, %24
  br i1 %26, label %67, label %27

27:                                               ; preds = %23
  %28 = sub nsw i32 %18, %21
  %29 = icmp sgt i32 %28, 64
  br i1 %29, label %30, label %32

30:                                               ; preds = %27
  %31 = fadd double %11, %9
  br label %67

32:                                               ; preds = %27
  %33 = icmp ugt i64 %16, 6908521828386340863
  br i1 %33, label %34, label %37

34:                                               ; preds = %32
  %35 = fmul double %15, 0x1430000000000000
  %36 = fmul double %14, 0x1430000000000000
  br label %42

37:                                               ; preds = %32
  %38 = icmp ult i64 %19, 2580562586483294208
  br i1 %38, label %39, label %42

39:                                               ; preds = %37
  %40 = fmul double %15, 0x6BB0000000000000
  %41 = fmul double %14, 0x6BB0000000000000
  br label %42

42:                                               ; preds = %39, %37, %34
  %43 = phi double [ %36, %34 ], [ %41, %39 ], [ %14, %37 ]
  %44 = phi double [ %35, %34 ], [ %40, %39 ], [ %15, %37 ]
  %45 = phi double [ 0x6BB0000000000000, %34 ], [ 0x1430000000000000, %39 ], [ 1.000000e+00, %37 ]
  %46 = fptrunc double %44 to float
  %47 = fpext float %46 to double
  %48 = fsub double %44, %47
  %49 = fmul double %47, %47
  %50 = fadd double %44, %44
  %51 = fsub double %50, %48
  %52 = fmul double %48, %48
  %53 = tail call double @llvm.fmuladd.f64(double %48, double %51, double %52)
  %54 = fptrunc double %43 to float
  %55 = fpext float %54 to double
  %56 = fsub double %43, %55
  %57 = fmul double %55, %55
  %58 = fadd double %43, %43
  %59 = fsub double %58, %56
  %60 = fmul double %56, %56
  %61 = tail call double @llvm.fmuladd.f64(double %56, double %59, double %60)
  %62 = fadd double %61, %53
  %63 = fadd double %57, %62
  %64 = fadd double %49, %63
  %65 = tail call double @llvm.sqrt.f64(double %64)
  %66 = fmul double %45, %65
  br label %67

67:                                               ; preds = %4, %23, %30, %42
  %68 = phi double [ %31, %30 ], [ %66, %42 ], [ %14, %4 ], [ %15, %23 ]
  %69 = tail call double @cq_measure_f64(double noundef %68) #6
  ret double %69
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #4

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
