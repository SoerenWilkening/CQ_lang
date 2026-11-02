; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@atanhi = internal unnamed_addr constant [4 x double] [double 0x3FDDAC670561BB4F, double 0x3FE921FB54442D18, double 0x3FEF730BD281F69B, double 0x3FF921FB54442D18], align 16
@atanlo = internal unnamed_addr constant [4 x double] [double 0x3C7A2B7F222F65E2, double 0x3C81A62633145C07, double 0x3C7007887AF0CBBD, double 0x3C91A62633145C07], align 16

; Function Attrs: nounwind ssp uwtable
define double @f_atan(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #9
  %3 = tail call double @llvm.atan.f64(double %2)
  %4 = tail call double @cq_measure_f64(double noundef %3) #10
  ret double %4
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.atan.f64(double) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp strictfp
define double @atan(double noundef %0) local_unnamed_addr #3 {
  %2 = alloca float, align 4
  %3 = bitcast double %0 to i64
  %4 = lshr i64 %3, 32
  %5 = trunc nuw i64 %4 to i32
  %6 = and i32 %5, 2147483647
  %7 = icmp ugt i32 %6, 1141899263
  br i1 %7, label %8, label %18

8:                                                ; preds = %1
  %9 = tail call double @llvm.fabs.f64(double %0)
  %10 = bitcast double %9 to i64
  %11 = icmp ugt i64 %10, 9218868437227405312
  br i1 %11, label %80, label %12

12:                                               ; preds = %8
  %13 = tail call double @llvm.experimental.constrained.fpext.f64.f32(float 0x3870000000000000, metadata !"fpexcept.ignore") #11
  %14 = tail call double @llvm.experimental.constrained.fadd.f64(double 0x3FF921FB54442D18, double %13, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %15 = fneg double %14
  %16 = icmp slt i64 %3, 0
  %17 = select i1 %16, double %15, double %14
  br label %80

18:                                               ; preds = %1
  %19 = icmp ult i32 %6, 1071382528
  br i1 %19, label %20, label %26

20:                                               ; preds = %18
  %21 = icmp ult i32 %6, 1044381696
  br i1 %21, label %22, label %47

22:                                               ; preds = %20
  %23 = icmp ult i32 %6, 1048576
  br i1 %23, label %24, label %80

24:                                               ; preds = %22
  %25 = tail call float @llvm.experimental.constrained.fptrunc.f32.f64(double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2)
  store volatile float %25, ptr %2, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2)
  br label %80

26:                                               ; preds = %18
  %27 = tail call double @fabs(double noundef %0) #12
  %28 = icmp ult i32 %6, 1072889856
  br i1 %28, label %29, label %39

29:                                               ; preds = %26
  %30 = icmp ult i32 %6, 1072037888
  br i1 %30, label %31, label %35

31:                                               ; preds = %29
  %32 = tail call double @llvm.experimental.constrained.fmuladd.f64(double 2.000000e+00, double %27, double -1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %33 = tail call double @llvm.experimental.constrained.fadd.f64(double 2.000000e+00, double %27, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %34 = tail call double @llvm.experimental.constrained.fdiv.f64(double %32, double %33, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %47

35:                                               ; preds = %29
  %36 = tail call double @llvm.experimental.constrained.fsub.f64(double %27, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %37 = tail call double @llvm.experimental.constrained.fadd.f64(double %27, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %38 = tail call double @llvm.experimental.constrained.fdiv.f64(double %36, double %37, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %47

39:                                               ; preds = %26
  %40 = icmp ult i32 %6, 1073971200
  br i1 %40, label %41, label %45

41:                                               ; preds = %39
  %42 = tail call double @llvm.experimental.constrained.fsub.f64(double %27, double 1.500000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %43 = tail call double @llvm.experimental.constrained.fmuladd.f64(double 1.500000e+00, double %27, double 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %44 = tail call double @llvm.experimental.constrained.fdiv.f64(double %42, double %43, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %47

45:                                               ; preds = %39
  %46 = tail call double @llvm.experimental.constrained.fdiv.f64(double -1.000000e+00, double %27, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %47

47:                                               ; preds = %45, %41, %35, %31, %20
  %48 = phi double [ %34, %31 ], [ %38, %35 ], [ %44, %41 ], [ %46, %45 ], [ %0, %20 ]
  %49 = phi i64 [ 0, %31 ], [ 1, %35 ], [ 2, %41 ], [ 3, %45 ], [ 4294967295, %20 ]
  %50 = tail call double @llvm.experimental.constrained.fmul.f64(double %48, double %48, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %51 = tail call double @llvm.experimental.constrained.fmul.f64(double %50, double %50, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %52 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %51, double 0x3F90AD3AE322DA11, double 0x3FA97B4B24760DEB, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %53 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %51, double %52, double 0x3FB10D66A0D03D51, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %54 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %51, double %53, double 0x3FB745CDC54C206E, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %55 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %51, double %54, double 0x3FC24924920083FF, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %56 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %51, double %55, double 0x3FD555555555550D, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %57 = tail call double @llvm.experimental.constrained.fmul.f64(double %50, double %56, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %58 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %51, double 0xBFA2B4442C6A6C2F, double 0xBFADDE2D52DEFD9A, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %59 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %51, double %58, double 0xBFB3B0F2AF749A6D, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %60 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %51, double %59, double 0xBFBC71C6FE231671, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %61 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %51, double %60, double 0xBFC999999998EBC4, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %62 = tail call double @llvm.experimental.constrained.fmul.f64(double %51, double %61, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br i1 %19, label %63, label %67

63:                                               ; preds = %47
  %64 = tail call double @llvm.experimental.constrained.fadd.f64(double %57, double %62, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %65 = fneg double %48
  %66 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %65, double %64, double %48, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %80

67:                                               ; preds = %47
  %68 = getelementptr inbounds [4 x double], ptr @atanhi, i64 0, i64 %49
  %69 = load double, ptr %68, align 8
  %70 = tail call double @llvm.experimental.constrained.fadd.f64(double %57, double %62, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %71 = getelementptr inbounds [4 x double], ptr @atanlo, i64 0, i64 %49
  %72 = load double, ptr %71, align 8
  %73 = fneg double %72
  %74 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %48, double %70, double %73, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %75 = tail call double @llvm.experimental.constrained.fsub.f64(double %74, double %48, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %76 = tail call double @llvm.experimental.constrained.fsub.f64(double %69, double %75, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %77 = fneg double %76
  %78 = icmp slt i64 %3, 0
  %79 = select i1 %78, double %77, double %76
  br label %80

80:                                               ; preds = %67, %63, %24, %22, %12, %8
  %81 = phi double [ %17, %12 ], [ %66, %63 ], [ %79, %67 ], [ %0, %8 ], [ %0, %24 ], [ %0, %22 ]
  ret double %81
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fpext.f64.f32(float, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fptrunc.f32.f64(double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #5

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #4

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none)
define noundef double @fabs(double noundef %0) local_unnamed_addr #6 {
  %2 = tail call double @llvm.fabs.f64(double %0)
  ret double %2
}

; Function Attrs: nounwind ssp strictfp
define hidden double @__math_oflow(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call double @__math_xflow(i32 noundef %0, double noundef 0x7000000000000000) #12
  ret double %2
}

; Function Attrs: nounwind ssp strictfp
define hidden double @__math_uflow(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call double @__math_xflow(i32 noundef %0, double noundef 0x1000000000000000) #12
  ret double %2
}

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define hidden double @__math_xflow(i32 noundef %0, double noundef %1) local_unnamed_addr #7 {
  %3 = alloca double, align 8
  %4 = icmp eq i32 %0, 0
  %5 = fneg double %1
  %6 = select i1 %4, double %1, double %5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3)
  store volatile double %6, ptr %3, align 8
  %7 = load volatile double, ptr %3, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3)
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double %7, double %1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  ret double %8
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite)
define hidden double @__math_invalid(double noundef %0) local_unnamed_addr #8 {
  %2 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %3 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %4 = tail call double @llvm.experimental.constrained.fdiv.f64(double %2, double %3, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  ret double %4
}

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define hidden double @__math_divzero(i32 noundef %0) local_unnamed_addr #7 {
  %2 = alloca double, align 8
  %3 = icmp eq i32 %0, 0
  %4 = select i1 %3, double 1.000000e+00, double -1.000000e+00
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double %4, ptr %2, align 8
  %5 = load volatile double, ptr %2, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  %6 = tail call double @llvm.experimental.constrained.fdiv.f64(double %5, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  ret double %6
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nounwind ssp strictfp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #5 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #9 = { nomerge nounwind }
attributes #10 = { nounwind }
attributes #11 = { strictfp }
attributes #12 = { nobuiltin nounwind strictfp "no-builtins" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
