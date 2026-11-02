; ModuleID = '/tmp/babj/libm_musl_coshf.full.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.exp2f_data = type { [32 x i64], double, [3 x double], double, double, [3 x double] }

@__exp2f_data = hidden local_unnamed_addr constant %struct.exp2f_data { [32 x i64] [i64 4607182418800017408, i64 4607140297302181236, i64 4607100335213349135, i64 4607062579818421073, i64 4607027079437701499, i64 4606993883449571754, i64 4606963042313658936, i64 4606934607594512097, i64 4606908631985796885, i64 4606885169335019979, i64 4606864274668794914, i64 4606846004218661165, i64 4606830415447468583, i64 4606817567076339586, i64 4606807519112221737, i64 4606800332876043653, i64 4606796071031487437, i64 4606794797614391156, i64 4606796578062795143, i64 4606801479247646227, i64 4606809569504174299, i64 4606820918663955941, i64 4606835598087680144, i64 4606853680698631517, i64 4606875241016906669, i64 4606900355194379847, i64 4606929101050434204, i64 4606961558108475497, i64 4606997807633245319, i64 4607037932668951391, i64 4607082018078232794, i64 4607130150581978432], double 0x42E8000000000000, [3 x double] [double 0x3FAC6AF84B912394, double 0x3FCEBFCE50FAC4F3, double 0x3FE62E42FF0C52D6], double 0x4338000000000000, double 0x40471547652B82FE, [3 x double] [double 0x3EBC6AF84B912394, double 0x3F2EBFCE50FAC4F3, double 0x3F962E42FF0C52D6] }, align 8

; Function Attrs: nounwind ssp uwtable
define float @f_coshf(float noundef %0) local_unnamed_addr #0 {
  %2 = tail call float @cq_theta_f32(float noundef %0, double noundef 3.000000e-01) #7
  %3 = tail call float @llvm.cosh.f32(float %2)
  %4 = tail call float @cq_measure_f32(float noundef %3) #8
  ret float %4
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.cosh.f32(float) #2

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fptrunc.f32.f64(double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fpext.f64.f32(float, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nounwind ssp strictfp
define hidden float @__expo2f(float noundef %0, float noundef %1) local_unnamed_addr #5 {
  %3 = tail call float @llvm.experimental.constrained.fsub.f32(float %0, float 0x40645C7780000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %4 = tail call float @expf(float noundef %3) #10
  %5 = tail call float @llvm.experimental.constrained.fmul.f32(float %1, float 0x4740000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %6 = tail call float @llvm.experimental.constrained.fmul.f32(float %4, float %5, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %7 = tail call float @llvm.experimental.constrained.fmul.f32(float %6, float 0x4740000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  ret float %7
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fsub.f32(float, float, metadata, metadata) #3

; Function Attrs: nounwind ssp strictfp
define float @expf(float noundef %0) local_unnamed_addr #5 {
  %2 = tail call double @llvm.experimental.constrained.fpext.f64.f32(float %0, metadata !"fpexcept.ignore") #9
  %3 = bitcast float %0 to i32
  %4 = lshr i32 %3, 20
  %5 = and i32 %4, 2047
  %6 = icmp ult i32 %5, 1067
  br i1 %6, label %21, label %7, !prof !7

7:                                                ; preds = %1
  %8 = tail call i1 @llvm.is.fpclass.f32(float %0, i32 4)
  br i1 %8, label %45, label %9

9:                                                ; preds = %7
  %10 = icmp ult i32 %5, 2040
  br i1 %10, label %13, label %11

11:                                               ; preds = %9
  %12 = tail call float @llvm.experimental.constrained.fadd.f32(float %0, float %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %45

13:                                               ; preds = %9
  %14 = tail call i1 @llvm.experimental.constrained.fcmps.f32(float %0, float 0x40562E42E0000000, metadata !"ogt", metadata !"fpexcept.ignore") #9
  br i1 %14, label %15, label %17

15:                                               ; preds = %13
  %16 = tail call float @__math_oflowf(i32 noundef 0) #10
  br label %45

17:                                               ; preds = %13
  %18 = tail call i1 @llvm.experimental.constrained.fcmps.f32(float %0, float 0xC059FE3680000000, metadata !"olt", metadata !"fpexcept.ignore") #9
  br i1 %18, label %19, label %21

19:                                               ; preds = %17
  %20 = tail call float @__math_uflowf(i32 noundef 0) #10
  br label %45

21:                                               ; preds = %17, %1
  %22 = load double, ptr getelementptr inbounds (i8, ptr @__exp2f_data, i64 296), align 8
  %23 = tail call double @llvm.experimental.constrained.fmul.f64(double %22, double %2, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %24 = load double, ptr getelementptr inbounds (i8, ptr @__exp2f_data, i64 288), align 8
  %25 = tail call double @llvm.experimental.constrained.fadd.f64(double %23, double %24, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %26 = bitcast double %25 to i64
  %27 = tail call double @llvm.experimental.constrained.fsub.f64(double %25, double %24, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %28 = tail call double @llvm.experimental.constrained.fsub.f64(double %23, double %27, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %29 = and i64 %26, 31
  %30 = getelementptr inbounds [32 x i64], ptr @__exp2f_data, i64 0, i64 %29
  %31 = load i64, ptr %30, align 8
  %32 = shl i64 %26, 47
  %33 = add i64 %31, %32
  %34 = bitcast i64 %33 to double
  %35 = load double, ptr getelementptr inbounds (i8, ptr @__exp2f_data, i64 304), align 8
  %36 = load double, ptr getelementptr inbounds (i8, ptr @__exp2f_data, i64 312), align 8
  %37 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %35, double %28, double %36, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %38 = tail call double @llvm.experimental.constrained.fmul.f64(double %28, double %28, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %39 = load double, ptr getelementptr inbounds (i8, ptr @__exp2f_data, i64 320), align 8
  %40 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %41 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %39, double %28, double %40, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %42 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %37, double %38, double %41, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %43 = tail call double @llvm.experimental.constrained.fmul.f64(double %42, double %34, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %44 = tail call float @llvm.experimental.constrained.fptrunc.f32.f64(double %43, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %45

45:                                               ; preds = %21, %19, %15, %11, %7
  %46 = phi float [ %12, %11 ], [ %16, %15 ], [ %20, %19 ], [ %44, %21 ], [ 0.000000e+00, %7 ]
  ret float %46
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fmul.f32(float, float, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i1 @llvm.is.fpclass.f32(float, i32 immarg) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f32(float, float, metadata, metadata) #3

; Function Attrs: nounwind ssp strictfp
define hidden float @__math_oflowf(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call float @__math_xflowf(i32 noundef %0, float noundef 0x4600000000000000) #10
  ret float %2
}

; Function Attrs: nounwind ssp strictfp
define hidden float @__math_uflowf(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call float @__math_xflowf(i32 noundef %0, float noundef 0x3A00000000000000) #10
  ret float %2
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #3

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define hidden float @__math_xflowf(i32 noundef %0, float noundef %1) local_unnamed_addr #6 {
  %3 = alloca float, align 4
  %4 = icmp eq i32 %0, 0
  %5 = fneg float %1
  %6 = select i1 %4, float %1, float %5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3)
  store volatile float %6, ptr %3, align 4
  %7 = load volatile float, ptr %3, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3)
  %8 = tail call float @llvm.experimental.constrained.fmul.f32(float %7, float %1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  ret float %8
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fdiv.f32(float, float, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fabs.f32(float) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.sitofp.f32.i32(i32, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fmuladd.f32(float, float, float, metadata, metadata) #3

; Function Attrs: nounwind ssp strictfp
define float @coshf(float noundef %0) local_unnamed_addr #5 {
  %2 = alloca float, align 4
  %3 = tail call float @llvm.fabs.f32(float %0)
  %4 = bitcast float %3 to i32
  %5 = icmp ult i32 %4, 1060205079
  br i1 %5, label %6, label %21

6:                                                ; preds = %1
  %7 = icmp ult i32 %4, 964689920
  br i1 %7, label %8, label %11

8:                                                ; preds = %6
  %9 = tail call float @llvm.experimental.constrained.fadd.f32(float %3, float 0x4770000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2)
  store volatile float %9, ptr %2, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2)
  %10 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %31

11:                                               ; preds = %6
  %12 = tail call float @expm1f(float noundef %3) #10
  %13 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %14 = tail call float @llvm.experimental.constrained.fmul.f32(float %12, float %12, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %15 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 2, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %16 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %17 = tail call float @llvm.experimental.constrained.fadd.f32(float %16, float %12, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %18 = tail call float @llvm.experimental.constrained.fmul.f32(float %15, float %17, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %19 = tail call float @llvm.experimental.constrained.fdiv.f32(float %14, float %18, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %20 = tail call float @llvm.experimental.constrained.fadd.f32(float %13, float %19, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %31

21:                                               ; preds = %1
  %22 = icmp ult i32 %4, 1118925335
  br i1 %22, label %23, label %29

23:                                               ; preds = %21
  %24 = tail call float @expf(float noundef %3) #10
  %25 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %26 = tail call float @llvm.experimental.constrained.fdiv.f32(float %25, float %24, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %27 = tail call float @llvm.experimental.constrained.fadd.f32(float %24, float %26, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %28 = tail call float @llvm.experimental.constrained.fmul.f32(float 5.000000e-01, float %27, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %31

29:                                               ; preds = %21
  %30 = tail call float @__expo2f(float noundef %3, float noundef 1.000000e+00) #10
  br label %31

31:                                               ; preds = %29, %23, %11, %8
  %32 = phi float [ %10, %8 ], [ %20, %11 ], [ %28, %23 ], [ %30, %29 ]
  ret float %32
}

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define float @expm1f(float noundef %0) local_unnamed_addr #6 {
  %2 = alloca float, align 4
  %3 = bitcast float %0 to i32
  %4 = tail call float @llvm.fabs.f32(float %0)
  %5 = bitcast float %4 to i32
  %6 = icmp ugt i32 %5, 1100331075
  br i1 %6, label %7, label %17

7:                                                ; preds = %1
  %8 = icmp ugt i32 %5, 2139095040
  br i1 %8, label %118, label %9

9:                                                ; preds = %7
  %10 = icmp sgt i32 %3, -1
  br i1 %10, label %13, label %11

11:                                               ; preds = %9
  %12 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 -1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %118

13:                                               ; preds = %9
  %14 = icmp ugt i32 %5, 1118925335
  br i1 %14, label %15, label %17

15:                                               ; preds = %13
  %16 = tail call float @llvm.experimental.constrained.fmul.f32(float %0, float 0x47E0000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %118

17:                                               ; preds = %13, %1
  %18 = icmp ugt i32 %5, 1051816472
  br i1 %18, label %19, label %42

19:                                               ; preds = %17
  %20 = icmp ult i32 %5, 1065686418
  br i1 %20, label %21, label %27

21:                                               ; preds = %19
  %22 = icmp sgt i32 %3, -1
  br i1 %22, label %23, label %25

23:                                               ; preds = %21
  %24 = tail call float @llvm.experimental.constrained.fsub.f32(float %0, float 0x3FE62E3000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %35

25:                                               ; preds = %21
  %26 = tail call float @llvm.experimental.constrained.fadd.f32(float %0, float 0x3FE62E3000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %35

27:                                               ; preds = %19
  %28 = tail call float @llvm.copysign.f32(float 5.000000e-01, float %0)
  %29 = tail call float @llvm.experimental.constrained.fmuladd.f32(float 0x3FF7154760000000, float %0, float %28, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %30 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f32(float %29, metadata !"fpexcept.ignore") #9
  %31 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 %30, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %32 = fneg float %31
  %33 = tail call float @llvm.experimental.constrained.fmuladd.f32(float %32, float 0x3FE62E3000000000, float %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %34 = tail call float @llvm.experimental.constrained.fmul.f32(float %31, float 0x3EE2FEFA20000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %35

35:                                               ; preds = %27, %25, %23
  %36 = phi float [ 0xBEE2FEFA20000000, %25 ], [ 0x3EE2FEFA20000000, %23 ], [ %34, %27 ]
  %37 = phi float [ %26, %25 ], [ %24, %23 ], [ %33, %27 ]
  %38 = phi i32 [ -1, %25 ], [ 1, %23 ], [ %30, %27 ]
  %39 = tail call float @llvm.experimental.constrained.fsub.f32(float %37, float %36, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %40 = tail call float @llvm.experimental.constrained.fsub.f32(float %37, float %39, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %41 = tail call float @llvm.experimental.constrained.fsub.f32(float %40, float %36, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %48

42:                                               ; preds = %17
  %43 = icmp ult i32 %5, 855638016
  br i1 %43, label %44, label %48

44:                                               ; preds = %42
  %45 = icmp ult i32 %5, 8388608
  br i1 %45, label %46, label %118

46:                                               ; preds = %44
  %47 = tail call float @llvm.experimental.constrained.fmul.f32(float %0, float %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2)
  store volatile float %47, ptr %2, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2)
  br label %118

48:                                               ; preds = %42, %35
  %49 = phi float [ %41, %35 ], [ undef, %42 ]
  %50 = phi float [ %39, %35 ], [ %0, %42 ]
  %51 = phi i32 [ %38, %35 ], [ 0, %42 ]
  %52 = tail call float @llvm.experimental.constrained.fmul.f32(float 5.000000e-01, float %50, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %53 = tail call float @llvm.experimental.constrained.fmul.f32(float %50, float %52, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %54 = tail call float @llvm.experimental.constrained.fmuladd.f32(float %53, float 0x3F59E60200000000, float 0xBFA1110D00000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %55 = tail call float @llvm.experimental.constrained.fmuladd.f32(float %53, float %54, float 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %56 = fneg float %55
  %57 = tail call float @llvm.experimental.constrained.fmuladd.f32(float %56, float %52, float 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %58 = tail call float @llvm.experimental.constrained.fsub.f32(float %55, float %57, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %59 = fneg float %50
  %60 = tail call float @llvm.experimental.constrained.fmuladd.f32(float %59, float %57, float 6.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %61 = tail call float @llvm.experimental.constrained.fdiv.f32(float %58, float %60, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %62 = tail call float @llvm.experimental.constrained.fmul.f32(float %53, float %61, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %63 = icmp eq i32 %51, 0
  br i1 %63, label %64, label %68

64:                                               ; preds = %48
  %65 = fneg float %53
  %66 = tail call float @llvm.experimental.constrained.fmuladd.f32(float %50, float %62, float %65, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %67 = tail call float @llvm.experimental.constrained.fsub.f32(float %50, float %66, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %118

68:                                               ; preds = %48
  %69 = tail call float @llvm.experimental.constrained.fsub.f32(float %62, float %49, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %70 = fneg float %49
  %71 = tail call float @llvm.experimental.constrained.fmuladd.f32(float %50, float %69, float %70, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %72 = tail call float @llvm.experimental.constrained.fsub.f32(float %71, float %53, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  switch i32 %51, label %85 [
    i32 -1, label %73
    i32 1, label %76
  ]

73:                                               ; preds = %68
  %74 = tail call float @llvm.experimental.constrained.fsub.f32(float %50, float %72, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %75 = tail call float @llvm.experimental.constrained.fmuladd.f32(float 5.000000e-01, float %74, float -5.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %118

76:                                               ; preds = %68
  %77 = tail call i1 @llvm.experimental.constrained.fcmps.f32(float %50, float -2.500000e-01, metadata !"olt", metadata !"fpexcept.ignore") #9
  br i1 %77, label %78, label %82

78:                                               ; preds = %76
  %79 = tail call float @llvm.experimental.constrained.fadd.f32(float %50, float 5.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %80 = tail call float @llvm.experimental.constrained.fsub.f32(float %72, float %79, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %81 = tail call float @llvm.experimental.constrained.fmul.f32(float -2.000000e+00, float %80, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %118

82:                                               ; preds = %76
  %83 = tail call float @llvm.experimental.constrained.fsub.f32(float %50, float %72, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %84 = tail call float @llvm.experimental.constrained.fmuladd.f32(float 2.000000e+00, float %83, float 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %118

85:                                               ; preds = %68
  %86 = shl i32 %51, 23
  %87 = add i32 %86, 1065353216
  %88 = bitcast i32 %87 to float
  %89 = icmp ugt i32 %51, 56
  br i1 %89, label %90, label %102

90:                                               ; preds = %85
  %91 = tail call float @llvm.experimental.constrained.fsub.f32(float %50, float %72, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %92 = tail call float @llvm.experimental.constrained.fadd.f32(float %91, float 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %93 = icmp eq i32 %51, 128
  br i1 %93, label %94, label %97

94:                                               ; preds = %90
  %95 = tail call float @llvm.experimental.constrained.fmul.f32(float %92, float 2.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %96 = tail call float @llvm.experimental.constrained.fmul.f32(float %95, float 0x47E0000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %99

97:                                               ; preds = %90
  %98 = tail call float @llvm.experimental.constrained.fmul.f32(float %92, float %88, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %99

99:                                               ; preds = %97, %94
  %100 = phi float [ %96, %94 ], [ %98, %97 ]
  %101 = tail call float @llvm.experimental.constrained.fsub.f32(float %100, float 1.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %118

102:                                              ; preds = %85
  %103 = sub nuw nsw i32 1065353216, %86
  %104 = bitcast i32 %103 to float
  %105 = icmp slt i32 %51, 23
  br i1 %105, label %106, label %112

106:                                              ; preds = %102
  %107 = tail call float @llvm.experimental.constrained.fsub.f32(float %50, float %72, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %108 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %109 = tail call float @llvm.experimental.constrained.fsub.f32(float %108, float %104, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %110 = tail call float @llvm.experimental.constrained.fadd.f32(float %107, float %109, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %111 = tail call float @llvm.experimental.constrained.fmul.f32(float %110, float %88, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %118

112:                                              ; preds = %102
  %113 = tail call float @llvm.experimental.constrained.fadd.f32(float %72, float %104, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %114 = tail call float @llvm.experimental.constrained.fsub.f32(float %50, float %113, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %115 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %116 = tail call float @llvm.experimental.constrained.fadd.f32(float %114, float %115, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %117 = tail call float @llvm.experimental.constrained.fmul.f32(float %116, float %88, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  br label %118

118:                                              ; preds = %112, %106, %99, %82, %78, %73, %64, %46, %44, %15, %11, %7
  %119 = phi float [ %12, %11 ], [ %16, %15 ], [ %67, %64 ], [ %75, %73 ], [ %81, %78 ], [ %84, %82 ], [ %101, %99 ], [ %0, %7 ], [ %0, %46 ], [ %0, %44 ], [ %111, %106 ], [ %117, %112 ]
  ret float %119
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.copysign.f32(float, float) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f32(float, metadata) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nounwind ssp strictfp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nomerge nounwind }
attributes #8 = { nounwind }
attributes #9 = { strictfp }
attributes #10 = { nobuiltin nounwind strictfp "no-builtins" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5, !6}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{!"branch_weights", !"expected", i32 2000, i32 1}
