; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @f_floorfn(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #5
  %3 = tail call double @floor(double noundef %2) #6
  %4 = tail call double @cq_measure_f64(double noundef %3) #6
  ret double %4
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define double @floor(double noundef %0) local_unnamed_addr #2 {
  %2 = alloca double, align 8
  %3 = bitcast double %0 to i64
  %4 = lshr i64 %3, 52
  %5 = trunc nuw nsw i64 %4 to i32
  %6 = and i32 %5, 2047
  %7 = icmp ugt i32 %6, 1074
  br i1 %7, label %34, label %8

8:                                                ; preds = %1
  %9 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  %10 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %0, double %9, metadata !"oeq", metadata !"fpexcept.ignore") #7
  br i1 %10, label %34, label %11

11:                                               ; preds = %8
  %12 = icmp slt i64 %3, 0
  br i1 %12, label %13, label %16

13:                                               ; preds = %11
  %14 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  %15 = tail call double @llvm.experimental.constrained.fadd.f64(double %14, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  br label %19

16:                                               ; preds = %11
  %17 = tail call double @llvm.experimental.constrained.fadd.f64(double %0, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  %18 = tail call double @llvm.experimental.constrained.fsub.f64(double %17, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  br label %19

19:                                               ; preds = %16, %13
  %20 = phi double [ %18, %16 ], [ %15, %13 ]
  %21 = tail call double @llvm.experimental.constrained.fsub.f64(double %20, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  %22 = icmp ult i32 %6, 1023
  br i1 %22, label %23, label %27

23:                                               ; preds = %19
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double %21, ptr %2, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  %24 = ashr i64 %3, 63
  %25 = trunc nsw i64 %24 to i32
  %26 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %25, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  br label %34

27:                                               ; preds = %19
  %28 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  %29 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %21, double %28, metadata !"ogt", metadata !"fpexcept.ignore") #7
  %30 = tail call double @llvm.experimental.constrained.fadd.f64(double %0, double %21, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  br i1 %29, label %31, label %34

31:                                               ; preds = %27
  %32 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  %33 = tail call double @llvm.experimental.constrained.fsub.f64(double %30, double %32, metadata !"round.dynamic", metadata !"fpexcept.ignore") #7
  br label %34

34:                                               ; preds = %31, %27, %23, %8, %1
  %35 = phi double [ %26, %23 ], [ %33, %31 ], [ %0, %8 ], [ %0, %1 ], [ %30, %27 ]
  ret double %35
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nobuiltin nomerge nounwind "no-builtins" }
attributes #6 = { nobuiltin nounwind "no-builtins" }
attributes #7 = { strictfp }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
