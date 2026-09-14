; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_loop_derived_unrolled.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_loop_derived_unrolled.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = sitofp i32 %1 to double
  %3 = fadd double %2, 3.000000e+00
  %4 = tail call double @llvm.sqrt.f64(double %3)
  %5 = fcmp ugt double %4, 3.500000e+00
  br i1 %5, label %7, label %6

6:                                                ; preds = %0
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3
  br label %7

7:                                                ; preds = %6, %0
  %8 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef -5.000000e-01) #3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %11

10:                                               ; preds = %7
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3
  br label %11

11:                                               ; preds = %10, %7
  %12 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #3
  %13 = sitofp i32 %12 to double
  %14 = fadd double %13, 3.000000e+00
  %15 = tail call double @llvm.sqrt.f64(double %14)
  %16 = fcmp ugt double %15, 3.500000e+00
  br i1 %16, label %18, label %17

17:                                               ; preds = %11
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3
  br label %18

18:                                               ; preds = %17, %11
  %19 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef -5.000000e-01) #3
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %21, label %22

21:                                               ; preds = %18
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3
  br label %22

22:                                               ; preds = %21, %18
  %23 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 5.000000e-01) #3
  %24 = tail call i32 @cq_measure_si32(i32 noundef %23) #3
  ret i32 %24
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #2

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 0
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
