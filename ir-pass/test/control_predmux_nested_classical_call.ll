; dm7f.16: clang -O1's actual nested classifier diamond, both in main and a
; noinline lifted body. cls stays a call; main and clones use the same edge muxes.
; On each basis input: x>y selects x-y when y>3, else x+y; x<=y selects y.
; Copies preserve the borrowed source. The clone mirrors its complete gate stream.
; The measured return escapes, so no separate caller-side _unc is needed here.
; RUN: %cq-opt -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define double @direct(
; CHECK: call i32 @cls(double noundef %1)
; CHECK: call i32 @cq_template_fsub_f64_hl
; CHECK: call i32 @cq_template_fadd_f64_hl
; CHECK: call void @cqrt_copy_f64_controlled
; CHECK: call double @cqrt_measure_f64
; CHECK-LABEL: define double @lifted(
; CHECK: call i32 @__cq_q_helper_01
; CHECK-LABEL: define internal i32 @__cq_q_helper_01(
; CHECK: call i32 @cls(double noundef %1)
; CHECK: call void @cqrt_copy_f64_controlled
; CHECK: call void @cqrt_copy_f64(
; CHECK: call void @cq_template_fadd_f64_hl_unc
; CHECK: call void @cq_template_fsub_f64_hl_unc
; CHECK: call void @cqrt_free
; CHECK: ret i32
; ModuleID = '/tmp/dm7f16/shape.c'
source_filename = "/tmp/dm7f16/shape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 0, 2) i32 @cls(double noundef %0) local_unnamed_addr #0 {
  %2 = fcmp ogt double %0, 3.000000e+00
  %3 = zext i1 %2 to i32
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef double @helper(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = fcmp ogt double %0, %1
  br i1 %3, label %4, label %11

4:                                                ; preds = %2
  %5 = tail call i32 @cls(double noundef %1)
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %4
  %8 = fsub double %0, %1
  br label %11

9:                                                ; preds = %4
  %10 = fadd double %0, %1
  br label %11

11:                                               ; preds = %2, %9, %7
  %12 = phi double [ %8, %7 ], [ %10, %9 ], [ %1, %2 ]
  ret double %12
}

; Function Attrs: nounwind ssp uwtable
define double @direct(double noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #3
  %4 = fcmp ogt double %3, %1
  br i1 %4, label %5, label %12

5:                                                ; preds = %2
  %6 = tail call i32 @cls(double noundef %1)
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %10, label %8

8:                                                ; preds = %5
  %9 = fsub double %3, %1
  br label %12

10:                                               ; preds = %5
  %11 = fadd double %3, %1
  br label %12

12:                                               ; preds = %8, %10, %2
  %13 = phi double [ %9, %8 ], [ %11, %10 ], [ %1, %2 ]
  %14 = tail call double @cq_measure_f64(double noundef %13) #4
  ret double %14
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define double @lifted(double noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #3
  %4 = tail call double @helper(double noundef %3, double noundef %1)
  %5 = tail call double @cq_measure_f64(double noundef %4) #4
  ret double %5
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
