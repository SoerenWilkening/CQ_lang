; cq-hzji: rule 23 calls under a quantum control and with quantum masks (each entry §6-checked with cqcheck user
; against its C program: PASS for clear_in_arm, saveflag_in_arm, env_in_arm, setenv_in_arm, classical_op_in_arm,
; setround_runtime, kloop_flags; clear_qmask is a false leak report, cq-3tmx; vec_op a lane-taint question, cq-d1cd).
; C source (clang-19 -O1, -include CQ.h):
;   #include <fenv.h>
;   #pragma STDC FENV_ACCESS ON
;   int clear_in_arm(double x0, double th, double c, double k) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       double y = x * c;
;       feraiseexcept(FE_INEXACT | FE_INVALID);
;       if (x > k) feclearexcept(FE_INEXACT | FE_INVALID);
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(y);
;   }
;   int clear_qmask(int m0, double th, double a, double c) {
;       int m = m0; cq_theta(&m, th); feclearexcept(FE_ALL_EXCEPT);
;       feraiseexcept(FE_INEXACT | FE_DIVBYZERO);
;       double y = a * c;
;       feclearexcept(m & FE_ALL_EXCEPT);
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)y;
;   }
;   int saveflag_in_arm(double x0, double th, double c, double k) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       fexcept_t s;
;       feraiseexcept(FE_DIVBYZERO);
;       fegetexceptflag(&s, FE_ALL_EXCEPT);
;       double y = x * c;
;       if (x > k) fegetexceptflag(&s, FE_ALL_EXCEPT);
;       feclearexcept(FE_ALL_EXCEPT);
;       if (x < c) fesetexceptflag(&s, FE_INEXACT | FE_DIVBYZERO);
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(y);
;   }
;   int env_in_arm(double x0, double th, double c, double k) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       fenv_t e;
;       fegetenv(&e);
;       double y = x * c;
;       if (x > k) { feholdexcept(&e); fesetround(FE_UPWARD); }
;       double z = y + c;
;       if (x < c) feupdateenv(&e);
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(z) + cq_measure(fegetround());
;   }
;   int setenv_in_arm(double x0, double th, double c, double k) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       fenv_t e;
;       fegetenv(&e);
;       fesetround(FE_DOWNWARD);
;       double y = x * c;
;       if (x > k) fesetenv(&e);
;       double z = y + c;
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(z) + cq_measure(fegetround());
;   }
;   int classical_op_in_arm(double x0, double th, double a, double b, double k) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       double r = 0;
;       if (x > k) r = a / b;
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(r);
;   }
;   int setround_runtime(double x0, double th, int r, double a, double b, double k) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       if (x > k) fesetround(FE_UPWARD);
;       fesetround(r);
;       double s = a + b;
;       if (x < k) fesetround(0x123);
;       double t = a / b;
;       return (int)cq_measure(s) + (int)cq_measure(t) + cq_measure(fegetround());
;   }
;   int kloop_flags(unsigned n0, double th, double c) {
;       unsigned n = n0; cq_theta(&n, th); feclearexcept(FE_ALL_EXCEPT);
;       double y = 1.0;
;       for (unsigned i = 0; i < n; i++) y = y * c;
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(y);
;   }
;   typedef double v2 __attribute__((vector_size(16)));
;   int vec_op(double x0, double th, double c) {
;       double x = x0; cq_theta(&x, th); feclearexcept(FE_ALL_EXCEPT);
;       v2 a = {x, c}; v2 b = {c, 3.0};
;       v2 r = a / b;
;       return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(r[0]) + (int)cq_measure(r[1]);
;   }
; CHECK clear_in_arm: call i32 @cq_template_select_i32(
; CHECK clear_qmask: call i32 @cq_template_xor_i32_hl(
; CHECK saveflag_in_arm: call i32 @fesetexceptflag(ptr %{{p}}, i32 63)
; CHECK env_in_arm: call i32 @fesetenv(ptr %{{t}})
; CHECK classical_op_in_arm: call i32 @feraiseexcept(i32 %{{h}})
; CHECK setround_runtime: call i32 @cq_template_select_i32_lh(
; CHECK kloop_flags: call i32 @cq_template_fmul_f64_hl_rm_exc(
; CHECK vec_op: call i32 @cq_template_fdiv_f64_hl_rm_exc(
; ModuleID = 'pred_env.c'
source_filename = "pred_env.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fenv_t = type { i16, i16, i32, [8 x i8] }

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @clear_in_arm(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %6 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %7 = tail call double @llvm.experimental.constrained.fmul.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %8 = tail call i32 @feraiseexcept(i32 noundef 33) #5
  %9 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %5, double %3, metadata !"ogt", metadata !"fpexcept.strict") #6
  br i1 %9, label %10, label %12

10:                                               ; preds = %4
  %11 = tail call i32 @feclearexcept(i32 noundef 33) #5
  br label %12

12:                                               ; preds = %10, %4
  %13 = tail call i32 @fetestexcept(i32 noundef 63) #5
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  %15 = tail call double @cq_measure_f64(double noundef %7) #5
  %16 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %15, metadata !"fpexcept.strict") #6
  %17 = add nsw i32 %16, %14
  ret i32 %17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #3

declare i32 @feraiseexcept(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @clear_qmask(i32 noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %7 = tail call i32 @feraiseexcept(i32 noundef 36) #5
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double %2, double %3, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %9 = and i32 %5, 63
  %10 = tail call i32 @feclearexcept(i32 noundef %9) #5
  %11 = tail call i32 @fetestexcept(i32 noundef 63) #5
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #5
  %13 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %8, metadata !"fpexcept.strict") #6
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @saveflag_in_arm(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca i16, align 2
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %7 = tail call i32 @feclearexcept(i32 noundef 63) #5
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %5) #5
  %8 = tail call i32 @feraiseexcept(i32 noundef 4) #5
  %9 = call i32 @fegetexceptflag(ptr noundef nonnull %5, i32 noundef 63) #5
  %10 = call double @llvm.experimental.constrained.fmul.f64(double %6, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %11 = call i1 @llvm.experimental.constrained.fcmps.f64(double %6, double %3, metadata !"ogt", metadata !"fpexcept.strict") #6
  br i1 %11, label %12, label %14

12:                                               ; preds = %4
  %13 = call i32 @fegetexceptflag(ptr noundef nonnull %5, i32 noundef 63) #5
  br label %14

14:                                               ; preds = %12, %4
  %15 = call i32 @feclearexcept(i32 noundef 63) #5
  %16 = call i1 @llvm.experimental.constrained.fcmps.f64(double %6, double %2, metadata !"olt", metadata !"fpexcept.strict") #6
  br i1 %16, label %17, label %19

17:                                               ; preds = %14
  %18 = call i32 @fesetexceptflag(ptr noundef nonnull %5, i32 noundef 36) #5
  br label %19

19:                                               ; preds = %17, %14
  %20 = call i32 @fetestexcept(i32 noundef 63) #5
  %21 = call i32 @cq_measure_si32(i32 noundef %20) #5
  %22 = call double @cq_measure_f64(double noundef %10) #5
  %23 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %22, metadata !"fpexcept.strict") #6
  %24 = add nsw i32 %23, %21
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %5) #5
  ret i32 %24
}

declare i32 @fegetexceptflag(ptr noundef, i32 noundef) local_unnamed_addr #2

declare i32 @fesetexceptflag(ptr noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @env_in_arm(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca %struct.fenv_t, align 4
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %7 = tail call i32 @feclearexcept(i32 noundef 63) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #5
  %8 = call i32 @fegetenv(ptr noundef nonnull %5) #5
  %9 = call double @llvm.experimental.constrained.fmul.f64(double %6, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %10 = call i1 @llvm.experimental.constrained.fcmps.f64(double %6, double %3, metadata !"ogt", metadata !"fpexcept.strict") #6
  br i1 %10, label %11, label %14

11:                                               ; preds = %4
  %12 = call i32 @feholdexcept(ptr noundef nonnull %5) #5
  %13 = call i32 @fesetround(i32 noundef 2048) #5
  br label %14

14:                                               ; preds = %11, %4
  %15 = call double @llvm.experimental.constrained.fadd.f64(double %9, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %16 = call i1 @llvm.experimental.constrained.fcmps.f64(double %6, double %2, metadata !"olt", metadata !"fpexcept.strict") #6
  br i1 %16, label %17, label %19

17:                                               ; preds = %14
  %18 = call i32 @feupdateenv(ptr noundef nonnull %5) #5
  br label %19

19:                                               ; preds = %17, %14
  %20 = call i32 @fetestexcept(i32 noundef 63) #5
  %21 = call i32 @cq_measure_si32(i32 noundef %20) #5
  %22 = call double @cq_measure_f64(double noundef %15) #5
  %23 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %22, metadata !"fpexcept.strict") #6
  %24 = add nsw i32 %23, %21
  %25 = call i32 @fegetround() #5
  %26 = call i32 @cq_measure_si32(i32 noundef %25) #5
  %27 = add nsw i32 %24, %26
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #5
  ret i32 %27
}

declare i32 @fegetenv(ptr noundef) local_unnamed_addr #2

declare i32 @feholdexcept(ptr noundef) local_unnamed_addr #2

declare i32 @fesetround(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #3

declare i32 @feupdateenv(ptr noundef) local_unnamed_addr #2

declare i32 @fegetround() local_unnamed_addr #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @setenv_in_arm(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca %struct.fenv_t, align 4
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %7 = tail call i32 @feclearexcept(i32 noundef 63) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #5
  %8 = call i32 @fegetenv(ptr noundef nonnull %5) #5
  %9 = call i32 @fesetround(i32 noundef 1024) #5
  %10 = call double @llvm.experimental.constrained.fmul.f64(double %6, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %11 = call i1 @llvm.experimental.constrained.fcmps.f64(double %6, double %3, metadata !"ogt", metadata !"fpexcept.strict") #6
  br i1 %11, label %12, label %14

12:                                               ; preds = %4
  %13 = call i32 @fesetenv(ptr noundef nonnull %5) #5
  br label %14

14:                                               ; preds = %12, %4
  %15 = call double @llvm.experimental.constrained.fadd.f64(double %10, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %16 = call i32 @fetestexcept(i32 noundef 63) #5
  %17 = call i32 @cq_measure_si32(i32 noundef %16) #5
  %18 = call double @cq_measure_f64(double noundef %15) #5
  %19 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %18, metadata !"fpexcept.strict") #6
  %20 = add nsw i32 %19, %17
  %21 = call i32 @fegetround() #5
  %22 = call i32 @cq_measure_si32(i32 noundef %21) #5
  %23 = add nsw i32 %20, %22
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #5
  ret i32 %23
}

declare i32 @fesetenv(ptr noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @classical_op_in_arm(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %7 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %8 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %9 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %6, double %4, metadata !"ogt", metadata !"fpexcept.strict") #6
  br i1 %9, label %10, label %12

10:                                               ; preds = %5
  %11 = tail call double @llvm.experimental.constrained.fdiv.f64(double %2, double %3, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  br label %12

12:                                               ; preds = %10, %5
  %13 = phi double [ %11, %10 ], [ %8, %5 ]
  %14 = tail call i32 @fetestexcept(i32 noundef 63) #5
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %16 = tail call double @cq_measure_f64(double noundef %13) #5
  %17 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %16, metadata !"fpexcept.strict") #6
  %18 = add nsw i32 %17, %15
  ret i32 %18
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #3

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @setround_runtime(double noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %8 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %9 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %7, double %5, metadata !"ogt", metadata !"fpexcept.strict") #6
  br i1 %9, label %10, label %12

10:                                               ; preds = %6
  %11 = tail call i32 @fesetround(i32 noundef 2048) #5
  br label %12

12:                                               ; preds = %10, %6
  %13 = tail call i32 @fesetround(i32 noundef %2) #5
  %14 = tail call double @llvm.experimental.constrained.fadd.f64(double %3, double %4, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %15 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %7, double %5, metadata !"olt", metadata !"fpexcept.strict") #6
  br i1 %15, label %16, label %18

16:                                               ; preds = %12
  %17 = tail call i32 @fesetround(i32 noundef 291) #5
  br label %18

18:                                               ; preds = %16, %12
  %19 = tail call double @llvm.experimental.constrained.fdiv.f64(double %3, double %4, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %20 = tail call double @cq_measure_f64(double noundef %14) #5
  %21 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %20, metadata !"fpexcept.strict") #6
  %22 = tail call double @cq_measure_f64(double noundef %19) #5
  %23 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %22, metadata !"fpexcept.strict") #6
  %24 = add nsw i32 %23, %21
  %25 = tail call i32 @fegetround() #5
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #5
  %27 = add nsw i32 %24, %26
  ret i32 %27
}

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @kloop_flags(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %5 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %6 = icmp eq i32 %4, 0
  br i1 %6, label %7, label %14

7:                                                ; preds = %14, %3
  %8 = phi double [ 1.000000e+00, %3 ], [ %17, %14 ]
  %9 = tail call i32 @fetestexcept(i32 noundef 63) #5
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %11 = tail call double @cq_measure_f64(double noundef %8) #5
  %12 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %11, metadata !"fpexcept.strict") #6
  %13 = add nsw i32 %12, %10
  ret i32 %13

14:                                               ; preds = %3, %14
  %15 = phi i32 [ %18, %14 ], [ 0, %3 ]
  %16 = phi double [ %17, %14 ], [ 1.000000e+00, %3 ]
  %17 = tail call double @llvm.experimental.constrained.fmul.f64(double %16, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %18 = add nuw i32 %15, 1
  %19 = icmp eq i32 %18, %4
  br i1 %19, label %7, label %14, !llvm.loop !6
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @vec_op(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %5 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %6 = insertelement <2 x double> poison, double %4, i64 0
  %7 = insertelement <2 x double> %6, double %2, i64 1
  %8 = insertelement <2 x double> <double poison, double 3.000000e+00>, double %2, i64 0
  %9 = tail call <2 x double> @llvm.experimental.constrained.fdiv.v2f64(<2 x double> %7, <2 x double> %8, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %10 = tail call i32 @fetestexcept(i32 noundef 63) #5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %12 = extractelement <2 x double> %9, i64 0
  %13 = tail call double @cq_measure_f64(double noundef %12) #5
  %14 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %13, metadata !"fpexcept.strict") #6
  %15 = add nsw i32 %14, %11
  %16 = extractelement <2 x double> %9, i64 1
  %17 = tail call double @cq_measure_f64(double noundef %16) #5
  %18 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %17, metadata !"fpexcept.strict") #6
  %19 = add nsw i32 %15, %18
  ret i32 %19
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare <2 x double> @llvm.experimental.constrained.fdiv.v2f64(<2 x double>, <2 x double>, metadata, metadata) #3

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
