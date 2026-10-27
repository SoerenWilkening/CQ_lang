; ModuleID = 'fpclass.c'
source_filename = "fpclass.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @fpclass_d(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = fmul double %4, %2    ; C: double y = x * c;
  %6 = fcmp uno double %5, 0.000000e+00    ; C: __builtin_isnan(y)
  %7 = zext i1 %6 to i32    ; C: __builtin_isnan(y)  (as int)
  %8 = tail call double @llvm.fabs.f64(double %5)    ; C: |y|  (for isinf / isfinite)
  %9 = fcmp oeq double %8, 0x7FF0000000000000    ; C: __builtin_isinf(y)
  %10 = select i1 %9, i32 2, i32 0    ; C: 2 * __builtin_isinf(y)
  %11 = fcmp one double %8, 0x7FF0000000000000    ; C: __builtin_isfinite(y)
  %12 = select i1 %11, i32 4, i32 0    ; C: 4 * __builtin_isfinite(y)
  %13 = tail call i1 @llvm.is.fpclass.f64(double %5, i32 264)    ; C: __builtin_isnormal(y)
  %14 = select i1 %13, i32 8, i32 0    ; C: 8 * __builtin_isnormal(y)
  %15 = or disjoint i32 %14, %7    ; C: isnan + 8 * isnormal
  %16 = or disjoint i32 %15, %10    ; C: + 2 * isinf
  %17 = or disjoint i32 %16, %12    ; C: + 4 * isfinite
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5    ; C: cq_measure(...)
  ret i32 %18    ; C: return
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i1 @llvm.is.fpclass.f64(double, i32 immarg) #2

; Function Attrs: nounwind ssp uwtable
define i32 @fpclass_f(float noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call float @cq_theta_f32(float noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %4 = fcmp oeq float %3, 0.000000e+00    ; C: __builtin_fpclassify: x == 0 ?
  br i1 %4, label %5, label %8    ; C: x == 0 -> FP_ZERO

5:                                                ; preds = %13, %10, %8, %2
  %6 = phi i32 [ 3, %2 ], [ 1, %8 ], [ 2, %10 ], [ %15, %13 ]    ; C: the classification
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #5    ; C: cq_measure(...)
  ret i32 %7    ; C: return

8:                                                ; preds = %2
  %9 = fcmp uno float %3, 0.000000e+00    ; C: isnan(x) ?
  br i1 %9, label %5, label %10    ; C: nan -> FP_NAN

10:                                               ; preds = %8
  %11 = tail call float @llvm.fabs.f32(float %3) #6    ; C: |x|
  %12 = fcmp oeq float %11, 0x7FF0000000000000    ; C: isinf(x) ?
  br i1 %12, label %5, label %13    ; C: inf -> FP_INFINITE

13:                                               ; preds = %10
  %14 = fcmp uge float %11, 0x3810000000000000    ; C: |x| >= FLT_MIN ?
  %15 = select i1 %14, i32 4, i32 5    ; C: FP_NORMAL : FP_SUBNORMAL
  br label %5    ; C: (join)
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fabs.f32(float) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
attributes #6 = { memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
