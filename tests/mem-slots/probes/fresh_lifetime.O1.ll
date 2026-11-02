; ModuleID = 'fresh_lifetime.c'
source_filename = "fresh_lifetime.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nofree norecurse nounwind ssp memory(inaccessiblemem: readwrite) uwtable
define double @f_once(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca double, align 8
  %3 = fcmp olt double %0, 1.000000e+00
  br i1 %3, label %4, label %7

4:                                                ; preds = %1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double 0x10000000000000, ptr %2, align 8, !tbaa !6
  %5 = load volatile double, ptr %2, align 8, !tbaa !6
  %6 = fmul double %5, 0x10000000000000
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  br label %7

7:                                                ; preds = %4, %1
  %8 = phi double [ %6, %4 ], [ %0, %1 ]
  ret double %8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nofree norecurse nounwind ssp memory(inaccessiblemem: readwrite) uwtable
define double @f_twice(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca double, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  %3 = fcmp olt double %0, 1.000000e+00
  br i1 %3, label %4, label %5

4:                                                ; preds = %1
  store volatile double 2.000000e+00, ptr %2, align 8, !tbaa !6
  br label %5

5:                                                ; preds = %4, %1
  %6 = fcmp olt double %0, 5.000000e-01
  br i1 %6, label %7, label %10

7:                                                ; preds = %5
  store volatile double 3.000000e+00, ptr %2, align 8, !tbaa !6
  %8 = load volatile double, ptr %2, align 8, !tbaa !6
  %9 = fadd double %8, %0
  br label %10

10:                                               ; preds = %7, %5
  %11 = phi double [ %9, %7 ], [ %0, %5 ]
  br i1 %3, label %12, label %15

12:                                               ; preds = %10
  %13 = load volatile double, ptr %2, align 8, !tbaa !6
  %14 = fadd double %11, %13
  br label %15

15:                                               ; preds = %12, %10
  %16 = phi double [ %14, %12 ], [ %11, %10 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  ret double %16
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 11, 4) i32 @f_atomic(i32 noundef %0) local_unnamed_addr #2 {
  %2 = icmp sgt i32 %0, 3
  %3 = add nuw nsw i32 %0, 7
  %4 = select i1 %2, i32 %3, i32 %0
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define double @e_once(double noundef %0) local_unnamed_addr #3 {
  %2 = alloca double, align 8
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #5
  %4 = fcmp olt double %3, 1.000000e+00
  br i1 %4, label %5, label %8

5:                                                ; preds = %1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double 0x10000000000000, ptr %2, align 8, !tbaa !6
  %6 = load volatile double, ptr %2, align 8, !tbaa !6
  %7 = fmul double %6, 0x10000000000000
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  br label %8

8:                                                ; preds = %1, %5
  %9 = phi double [ %7, %5 ], [ %3, %1 ]
  %10 = tail call double @cq_measure_f64(double noundef %9) #6
  ret double %10
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #4

declare double @cq_measure_f64(double noundef) local_unnamed_addr #4

; Function Attrs: nounwind ssp uwtable
define double @e_twice(double noundef %0) local_unnamed_addr #3 {
  %2 = alloca double, align 8
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  %4 = fcmp olt double %3, 1.000000e+00
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  store volatile double 2.000000e+00, ptr %2, align 8, !tbaa !6
  br label %6

6:                                                ; preds = %5, %1
  %7 = fcmp olt double %3, 5.000000e-01
  br i1 %7, label %8, label %11

8:                                                ; preds = %6
  store volatile double 3.000000e+00, ptr %2, align 8, !tbaa !6
  %9 = load volatile double, ptr %2, align 8, !tbaa !6
  %10 = fadd double %3, %9
  br label %11

11:                                               ; preds = %8, %6
  %12 = phi double [ %10, %8 ], [ %3, %6 ]
  br i1 %4, label %13, label %16

13:                                               ; preds = %11
  %14 = load volatile double, ptr %2, align 8, !tbaa !6
  %15 = fadd double %12, %14
  br label %16

16:                                               ; preds = %11, %13
  %17 = phi double [ %15, %13 ], [ %12, %11 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  %18 = tail call double @cq_measure_f64(double noundef %17) #6
  ret double %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @e_atomic(i32 noundef %0) local_unnamed_addr #3 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #5
  %3 = icmp sgt i32 %2, 3
  %4 = add nuw nsw i32 %2, 7
  %5 = select i1 %3, i32 %4, i32 %2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #6
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

attributes #0 = { nofree norecurse nounwind ssp memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
; USERCHECK e_once
; USERCHECK e_twice
; USERCHECK e_atomic
; CHECK-COUNT e_once: call i32 @cq_template_select_f64_lh( 0
