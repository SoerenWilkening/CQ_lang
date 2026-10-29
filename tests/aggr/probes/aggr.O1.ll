; ModuleID = 'aggr.c'
source_filename = "aggr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define float @p_vlanes(float noundef %0, double noundef %1, float noundef %2, float noundef %3) local_unnamed_addr #0 {
  %5 = tail call float @cq_theta_f32(float noundef %0, double noundef %1) #3
  %6 = insertelement <2 x float> poison, float %5, i64 0
  %7 = insertelement <2 x float> %6, float %2, i64 1
  %8 = insertelement <2 x float> poison, float %3, i64 0
  %9 = shufflevector <2 x float> %8, <2 x float> poison, <2 x i32> zeroinitializer
  %10 = fadd <2 x float> %9, %7
  %11 = shufflevector <2 x float> %10, <2 x float> poison, <2 x i32> <i32 1, i32 0>
  %12 = fmul <2 x float> %10, %11
  %13 = shufflevector <2 x float> %12, <2 x float> poison, <2 x i32> <i32 1, i32 poison>
  %14 = fadd <2 x float> %12, %13
  %15 = extractelement <2 x float> %14, i64 0
  %16 = tail call float @cq_measure_f32(float noundef %15) #4
  ret float %16
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_vint(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %7 = insertelement <4 x i32> poison, i32 %6, i64 0
  %8 = insertelement <4 x i32> %7, i32 %2, i64 1
  %9 = mul i32 %6, %3
  %10 = insertelement <4 x i32> %8, i32 %9, i64 2
  %11 = insertelement <4 x i32> %10, i32 %3, i64 3
  %12 = shufflevector <4 x i32> %11, <4 x i32> poison, <4 x i32> <i32 3, i32 2, i32 1, i32 0>
  %13 = add <4 x i32> %12, %11
  %14 = insertelement <4 x i32> poison, i32 %2, i64 0
  %15 = insertelement <4 x i32> %14, i32 %3, i64 1
  %16 = insertelement <4 x i32> %15, i32 %4, i64 2
  %17 = insertelement <4 x i32> %16, i32 %2, i64 3
  %18 = mul <4 x i32> %13, %17
  %19 = and i32 %4, 7
  %20 = insertelement <4 x i32> poison, i32 %19, i64 0
  %21 = and i32 %4, 3
  %22 = add nuw nsw i32 %21, 2
  %23 = insertelement <4 x i32> %20, i32 %22, i64 1
  %24 = and i32 %4, 15
  %25 = insertelement <4 x i32> %23, i32 %24, i64 2
  %26 = and i32 %4, 1
  %27 = insertelement <4 x i32> %25, i32 %26, i64 3
  %28 = lshr <4 x i32> %18, %27
  %29 = shufflevector <4 x i32> %28, <4 x i32> poison, <4 x i32> <i32 1, i32 poison, i32 poison, i32 poison>
  %30 = shufflevector <4 x i32> %28, <4 x i32> poison, <4 x i32> <i32 2, i32 poison, i32 poison, i32 poison>
  %31 = xor <4 x i32> %29, %30
  %32 = shufflevector <4 x i32> %28, <4 x i32> poison, <4 x i32> <i32 3, i32 poison, i32 poison, i32 poison>
  %33 = xor <4 x i32> %31, %32
  %34 = xor <4 x i32> %33, %28
  %35 = extractelement <4 x i32> %34, i64 0
  %36 = tail call i32 @cq_measure_ui32(i32 noundef %35) #4
  ret i32 %36
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_ovf(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = tail call { i32, i1 } @llvm.umul.with.overflow.i32(i32 %4, i32 %2)
  %6 = extractvalue { i32, i1 } %5, 1
  %7 = extractvalue { i32, i1 } %5, 0
  %8 = zext i1 %6 to i32
  %9 = add i32 %7, %8
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #4
  ret i32 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
