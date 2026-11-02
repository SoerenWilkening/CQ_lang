; ModuleID = 'fresh_lifetime_value.c'
source_filename = "fresh_lifetime_value.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) uwtable
define double @f_value(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca double, align 8
  %3 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %0, double 1.000000e+00, metadata !"olt", metadata !"fpexcept.strict") #5
  br i1 %3, label %4, label %8

4:                                                ; preds = %1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  %5 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  store volatile double %5, ptr %2, align 8, !tbaa !6
  %6 = load volatile double, ptr %2, align 8, !tbaa !6
  %7 = tail call double @llvm.experimental.constrained.fmul.f64(double %6, double 5.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  br label %8

8:                                                ; preds = %4, %1
  %9 = phi double [ %7, %4 ], [ %0, %1 ]
  ret double %9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) uwtable
define double @f_sink(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca double, align 8
  %3 = alloca double, align 8
  %4 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %0, double 1.000000e+00, metadata !"olt", metadata !"fpexcept.strict") #5
  br i1 %4, label %5, label %9

5:                                                ; preds = %1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double 0x10000000000000, ptr %2, align 8, !tbaa !6
  %6 = load volatile double, ptr %2, align 8, !tbaa !6
  %7 = tail call double @llvm.experimental.constrained.fmul.f64(double %6, double 0x10000000000000, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3)
  store volatile double %7, ptr %3, align 8, !tbaa !6
  %8 = tail call double @llvm.experimental.constrained.fadd.f64(double %0, double %7, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  br label %9

9:                                                ; preds = %5, %1
  %10 = phi double [ %8, %5 ], [ %0, %1 ]
  ret double %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #2

; Function Attrs: nounwind ssp strictfp uwtable
define double @e_value(double noundef %0) local_unnamed_addr #3 {
  %2 = alloca double, align 8
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #6
  %4 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %3, double 1.000000e+00, metadata !"olt", metadata !"fpexcept.strict") #5
  br i1 %4, label %5, label %9

5:                                                ; preds = %1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  %6 = tail call double @llvm.experimental.constrained.fmul.f64(double %3, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  store volatile double %6, ptr %2, align 8, !tbaa !6
  %7 = load volatile double, ptr %2, align 8, !tbaa !6
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double %7, double 5.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  br label %9

9:                                                ; preds = %1, %5
  %10 = phi double [ %8, %5 ], [ %3, %1 ]
  %11 = tail call double @cq_measure_f64(double noundef %10) #7
  ret double %11
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #4

declare double @cq_measure_f64(double noundef) local_unnamed_addr #4

; Function Attrs: nounwind ssp strictfp uwtable
define double @e_sink(double noundef %0) local_unnamed_addr #3 {
  %2 = alloca double, align 8
  %3 = alloca double, align 8
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #6
  %5 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %4, double 1.000000e+00, metadata !"olt", metadata !"fpexcept.strict") #5
  br i1 %5, label %6, label %10

6:                                                ; preds = %1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double 0x10000000000000, ptr %2, align 8, !tbaa !6
  %7 = load volatile double, ptr %2, align 8, !tbaa !6
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double %7, double 0x10000000000000, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3)
  store volatile double %8, ptr %3, align 8, !tbaa !6
  %9 = tail call double @llvm.experimental.constrained.fadd.f64(double %4, double %8, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  br label %10

10:                                               ; preds = %1, %6
  %11 = phi double [ %9, %6 ], [ %4, %1 ]
  %12 = tail call double @cq_measure_f64(double noundef %11) #7
  ret double %12
}

attributes #0 = { nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
; USERCHECK e_value
; USERCHECK e_sink
; CHECK-COUNT e_value: load i32, ptr 0
; CHECK-COUNT e_sink: load i32, ptr 0
