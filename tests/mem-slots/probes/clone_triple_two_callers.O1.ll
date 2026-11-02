; ModuleID = 'clone_triple_two_callers.c'
source_filename = "clone_triple_two_callers.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @clone_triple_two_callers(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #5
  %3 = tail call fastcc double @fa(double noundef %2)
  %4 = tail call fastcc double @fb(double noundef %2)
  %5 = fadd double %3, %4
  %6 = tail call double @cq_measure_f64(double noundef %5) #6
  ret double %6
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc double @fa(double noundef %0) unnamed_addr #3 {
  %2 = alloca [2 x double], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #6
  %3 = call fastcc i32 @split2(double noundef %0, ptr noundef nonnull %2)
  %4 = icmp eq i32 %3, 0
  %5 = load double, ptr %2, align 16
  %6 = getelementptr inbounds i8, ptr %2, i64 8
  %7 = load double, ptr %6, align 8
  %8 = select i1 %4, double %7, double %5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #6
  ret double %8
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc double @fb(double noundef %0) unnamed_addr #3 {
  %2 = alloca [2 x double], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #6
  %3 = call fastcc i32 @split2(double noundef %0, ptr noundef nonnull %2)
  %4 = icmp eq i32 %3, 0
  %5 = getelementptr inbounds i8, ptr %2, i64 8
  %6 = load double, ptr %5, align 8
  %7 = fadd double %6, 1.000000e+00
  %8 = load double, ptr %2, align 16
  %9 = select i1 %4, double %8, double %7
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #6
  ret double %9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc range(i32 0, 2) i32 @split2(double noundef %0, ptr nocapture noundef writeonly %1) unnamed_addr #4 {
  %3 = fmul double %0, 5.000000e-01
  store double %3, ptr %1, align 8, !tbaa !6
  %4 = fsub double %0, %3
  %5 = getelementptr inbounds i8, ptr %1, i64 8
  store double %4, ptr %5, align 8, !tbaa !6
  %6 = fcmp ogt double %0, 1.000000e+00
  %7 = zext i1 %6 to i32
  ret i32 %7
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
; USERCHECK clone_triple_two_callers
; CHECK __cq_q_split2_10000_unc: getelementptr inbounds i32, ptr %{{a}}, i64 %{{b}}
