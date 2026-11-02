; ModuleID = 'alias_writes.c'
source_filename = "alias_writes.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @aw_same(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca double, align 8
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #5
  store double 0.000000e+00, ptr %2, align 8, !tbaa !6
  call fastcc void @sc(double noundef %3, ptr noundef nonnull %2, ptr noundef nonnull %2)
  %4 = load double, ptr %2, align 8, !tbaa !6
  %5 = tail call double @cq_measure_f64(double noundef %4) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #5
  ret double %5
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @sc(double noundef %0, ptr nocapture noundef writeonly %1, ptr nocapture noundef writeonly %2) unnamed_addr #3 {
  %4 = fcmp ogt double %0, 5.000000e-01
  br i1 %4, label %5, label %8

5:                                                ; preds = %3
  %6 = fmul double %0, 3.000000e+00
  store double %6, ptr %1, align 8, !tbaa !6
  %7 = fadd double %0, -1.000000e+00
  store double %7, ptr %2, align 8, !tbaa !6
  br label %11

8:                                                ; preds = %3
  %9 = fadd double %0, 2.000000e+00
  store double %9, ptr %2, align 8, !tbaa !6
  %10 = fmul double %0, 2.500000e-01
  store double %10, ptr %1, align 8, !tbaa !6
  br label %11

11:                                               ; preds = %8, %5
  ret void
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define double @aw_rmw(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca double, align 8
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #5
  store double 1.000000e+00, ptr %2, align 8, !tbaa !6
  call fastcc void @sc2(double noundef %3, ptr noundef nonnull %2, ptr noundef nonnull %2)
  %4 = load double, ptr %2, align 8, !tbaa !6
  %5 = tail call double @cq_measure_f64(double noundef %4) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #5
  ret double %5
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @sc2(double noundef %0, ptr nocapture noundef writeonly %1, ptr nocapture noundef writeonly %2) unnamed_addr #3 {
  %4 = fmul double %0, 3.000000e+00
  store double %4, ptr %1, align 8, !tbaa !6
  %5 = fadd double %4, %0
  store double %5, ptr %2, align 8, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @aw_buf(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #4
  ret i32 1
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

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
