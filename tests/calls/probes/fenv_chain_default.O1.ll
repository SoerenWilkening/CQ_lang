; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @ch_split(double noundef %0) local_unnamed_addr #0 {
  %2 = alloca [2 x double], align 16
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #7
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #8
  call void @split(double noundef %3, ptr noundef nonnull %2) #8
  %4 = load double, ptr %2, align 16, !tbaa !6
  %5 = getelementptr inbounds i8, ptr %2, i64 8
  %6 = load double, ptr %5, align 8, !tbaa !6
  %7 = fadd double %4, %6
  %8 = call double @cq_measure_f64(double noundef %7) #8
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #8
  ret double %8
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @third(double noundef %0) local_unnamed_addr #3 {
  %2 = tail call double @llvm.experimental.constrained.fdiv.f64(double %0, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %3 = tail call double @llvm.experimental.constrained.fadd.f64(double %2, double 1.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  ret double %3
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #4

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: write, inaccessiblemem: readwrite) uwtable
define void @split(double noundef %0, ptr nocapture noundef writeonly %1) local_unnamed_addr #5 {
  %3 = tail call double @third(double noundef %0) #9
  store double %3, ptr %1, align 8, !tbaa !6
  %4 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 5.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.ignore") #9
  %5 = getelementptr inbounds i8, ptr %1, i64 8
  store double %4, ptr %5, align 8, !tbaa !6
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #4

; Function Attrs: nounwind ssp strictfp uwtable
define double @other(double noundef %0) local_unnamed_addr #6 {
  %2 = tail call i32 @fesetround(i32 noundef 2048) #10
  %3 = tail call double @third(double noundef %0) #10
  %4 = tail call i32 @fesetround(i32 noundef 0) #10
  ret double %3
}

declare i32 @fesetround(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(argmem: write, inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nomerge nounwind }
attributes #8 = { nounwind }
attributes #9 = { strictfp }
attributes #10 = { nounwind strictfp }

!llvm.ident = !{!0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
