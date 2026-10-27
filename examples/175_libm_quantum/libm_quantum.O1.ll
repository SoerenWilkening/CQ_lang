; ModuleID = 'libm_quantum.c'
source_filename = "libm_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @libm_cbrt_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %4 = bitcast double %3 to i64
  %5 = lshr i64 %4, 32
  %6 = trunc nuw i64 %5 to i32
  %7 = and i32 %6, 2147483647
  %8 = icmp ugt i32 %7, 2146435071
  br i1 %8, label %9, label %11

9:                                                ; preds = %2
  %10 = fadd double %3, %3
  br label %53

11:                                               ; preds = %2
  %12 = icmp ult i32 %7, 1048576
  br i1 %12, label %13, label %20

13:                                               ; preds = %11
  %14 = fmul double %3, 0x4350000000000000
  %15 = bitcast double %14 to i64
  %16 = lshr i64 %15, 32
  %17 = trunc nuw i64 %16 to i32
  %18 = and i32 %17, 2147483647
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %53, label %20

20:                                               ; preds = %11, %13
  %21 = phi i32 [ %18, %13 ], [ %7, %11 ]
  %22 = phi i32 [ 696219795, %13 ], [ 715094163, %11 ]
  %23 = phi double [ %14, %13 ], [ %3, %11 ]
  %24 = udiv i32 %21, 3
  %25 = add nuw nsw i32 %24, %22
  %26 = bitcast double %23 to i64
  %27 = and i64 %26, -9223372036854775808
  %28 = zext nneg i32 %25 to i64
  %29 = shl nuw nsw i64 %28, 32
  %30 = or disjoint i64 %29, %27
  %31 = bitcast i64 %30 to double
  %32 = fmul double %31, %31
  %33 = fdiv double %31, %3
  %34 = fmul double %32, %33
  %35 = tail call double @llvm.fmuladd.f64(double %34, double 0x3FF9F1604A49D6C2, double 0xBFFE28E092F02420)
  %36 = tail call double @llvm.fmuladd.f64(double %34, double %35, double 0x3FFE03E60F61E692)
  %37 = fmul double %34, %34
  %38 = fmul double %34, %37
  %39 = tail call double @llvm.fmuladd.f64(double %34, double 0x3FC2B000D4E4EDD7, double 0xBFE844CBBEE751D9)
  %40 = tail call double @llvm.fmuladd.f64(double %38, double %39, double %36)
  %41 = fmul double %40, %31
  %42 = bitcast double %41 to i64
  %43 = and i64 %42, -1073741824
  %44 = add i64 %43, 2147483648
  %45 = bitcast i64 %44 to double
  %46 = fmul double %45, %45
  %47 = fdiv double %3, %46
  %48 = fadd double %45, %45
  %49 = fsub double %47, %45
  %50 = fadd double %48, %47
  %51 = fdiv double %49, %50
  %52 = tail call double @llvm.fmuladd.f64(double %45, double %51, double %45)
  br label %53

53:                                               ; preds = %9, %13, %20
  %54 = phi double [ %10, %9 ], [ %52, %20 ], [ %3, %13 ]
  %55 = tail call double @cq_measure_f64(double noundef %54) #6
  ret double %55
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @libm_scalbn_qq(double noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #5
  %7 = icmp sgt i32 %6, 1023
  br i1 %7, label %8, label %16

8:                                                ; preds = %4
  %9 = fmul double %5, 0x7FE0000000000000
  %10 = add nsw i32 %6, -1023
  %11 = icmp sgt i32 %6, 2046
  br i1 %11, label %12, label %26

12:                                               ; preds = %8
  %13 = fmul double %9, 0x7FE0000000000000
  %14 = tail call i32 @llvm.smin.i32(i32 %6, i32 3069)
  %15 = add nsw i32 %14, -2046
  br label %26

16:                                               ; preds = %4
  %17 = icmp slt i32 %6, -1022
  br i1 %17, label %18, label %26

18:                                               ; preds = %16
  %19 = fmul double %5, 0x360000000000000
  %20 = add nuw nsw i32 %6, 969
  %21 = icmp slt i32 %6, -1991
  br i1 %21, label %22, label %26

22:                                               ; preds = %18
  %23 = fmul double %19, 0x360000000000000
  %24 = tail call i32 @llvm.smax.i32(i32 %6, i32 -2960)
  %25 = add nsw i32 %24, 1938
  br label %26

26:                                               ; preds = %8, %12, %16, %18, %22
  %27 = phi i32 [ %15, %12 ], [ %10, %8 ], [ %25, %22 ], [ %20, %18 ], [ %6, %16 ]
  %28 = phi double [ %13, %12 ], [ %9, %8 ], [ %23, %22 ], [ %19, %18 ], [ %5, %16 ]
  %29 = add nsw i32 %27, 1023
  %30 = zext i32 %29 to i64
  %31 = shl i64 %30, 52
  %32 = bitcast i64 %31 to double
  %33 = fmul double %28, %32
  %34 = tail call double @cq_measure_f64(double noundef %33) #6
  ret double %34
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @libm_exp_atan2_q(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %5 = tail call double @llvm.exp.f64(double %4)
  %6 = tail call double @atan2(double noundef %4, double noundef %2) #7
  %7 = fadd double %5, %6
  %8 = tail call double @cq_measure_f64(double noundef %7) #6
  ret double %8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.exp.f64(double) #2

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare double @atan2(double noundef, double noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define double @libm_sin_log_pow_q(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %5 = tail call double @llvm.sin.f64(double %4)
  %6 = tail call double @llvm.log.f64(double %4)
  %7 = fadd double %5, %6
  %8 = tail call double @llvm.pow.f64(double %4, double %2)
  %9 = fadd double %8, %7
  %10 = tail call double @cq_measure_f64(double noundef %9) #6
  ret double %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sin.f64(double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.log.f64(double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.pow.f64(double, double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { mustprogress nofree nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
attributes #7 = { nounwind willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
