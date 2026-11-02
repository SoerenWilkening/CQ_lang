; ModuleID = 'vol_const_pred.c'
source_filename = "vol_const_pred.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tiny = internal constant x86_fp80 0xK18EF8000000000000000, align 16
@small = internal constant double 0x170000000000000, align 8

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @p_vol_const_pred(double noundef %0) local_unnamed_addr #0 {
  %2 = fcmp olt double %0, 1.000000e+00
  br i1 %2, label %3, label %11

3:                                                ; preds = %1
  %4 = load volatile x86_fp80, ptr @tiny, align 16, !tbaa !6
  %5 = load volatile x86_fp80, ptr @tiny, align 16, !tbaa !6
  %6 = fmul x86_fp80 %4, %5
  %7 = fptrunc x86_fp80 %6 to double
  %8 = fadd double %7, %0
  %9 = load volatile double, ptr @small, align 8, !tbaa !10
  %10 = fadd double %9, %8
  br label %11

11:                                               ; preds = %3, %1
  %12 = phi double [ %10, %3 ], [ %0, %1 ]
  ret double %12
}

; Function Attrs: nounwind ssp uwtable
define double @e_vol_const_pred(double noundef %0) local_unnamed_addr #1 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #3
  %3 = tail call double @p_vol_const_pred(double noundef %2)
  %4 = tail call double @cq_measure_f64(double noundef %3) #4
  ret double %4
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"long double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"double", !8, i64 0}
