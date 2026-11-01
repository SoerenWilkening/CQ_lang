; ModuleID = 'conc.c'
source_filename = "conc.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@obs_counter = global i32 7, align 4
@tiny = internal global double 1.000000e-300, align 8
@acell = internal unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define double @p_vol_internal(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3
  %5 = fcmp olt double %4, %2
  %6 = load volatile double, ptr @tiny, align 8, !tbaa !6
  %7 = fmul double %4, %6
  %8 = fsub double %4, %6
  %9 = select i1 %5, double %7, double %8
  %10 = tail call double @cq_measure_f64(double noundef %9) #4
  ret double %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_vol_observable(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %5 = load volatile i32, ptr @obs_counter, align 4, !tbaa !10
  store volatile i32 %2, ptr @obs_counter, align 4, !tbaa !10
  %6 = add nsw i32 %5, %4
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @p_atomic_classical(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  store atomic i32 %2, ptr @acell seq_cst, align 4
  %5 = load atomic i32, ptr @acell seq_cst, align 4
  %6 = add nsw i32 %5, %4
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_vol_local(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4)
  %6 = add nsw i32 %5, %2
  store volatile i32 %6, ptr %4, align 4, !tbaa !10
  %7 = load volatile i32, ptr %4, align 4, !tbaa !10
  %8 = shl nsw i32 %7, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4)
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_atomic_rmw(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #4
  store i32 %5, ptr %4, align 4, !tbaa !10
  %6 = atomicrmw add ptr %4, i32 %2 seq_cst, align 4
  %7 = load i32, ptr %4, align 4, !tbaa !10
  %8 = call i32 @cq_measure_si32(i32 noundef %7) #4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #4
  ret i32 %8
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
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
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
