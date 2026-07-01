; ModuleID = 'scratchpad_g387/modf_remquo.c'
source_filename = "scratchpad_g387/modf_remquo.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @demo_modf() local_unnamed_addr #0 {
  %1 = alloca double, align 8
  %2 = tail call double @cq_theta_f64(double noundef 0.000000e+00, double noundef 5.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %1) #5
  %3 = call double @modf(double noundef %2, ptr noundef nonnull %1) #5
  %4 = fptosi double %3 to i32
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %6 = load double, ptr %1, align 8, !tbaa !6
  %7 = fptosi double %6 to i32
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %9 = add nsw i32 %8, %5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %1) #5
  ret i32 %9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree nounwind willreturn memory(argmem: write)
declare double @modf(double noundef, ptr nocapture noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @demo_remquo() local_unnamed_addr #0 {
  %1 = alloca i32, align 4
  %2 = tail call double @cq_theta_f64(double noundef 0.000000e+00, double noundef 5.000000e-01) #5
  %3 = tail call double @cq_theta_f64(double noundef 0.000000e+00, double noundef 3.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #5
  %4 = call double @remquo(double noundef %2, double noundef %3, ptr noundef nonnull %1) #5
  %5 = fptosi double %4 to i32
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  %7 = load i32, ptr %1, align 4, !tbaa !10
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %9 = add nsw i32 %8, %6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #5
  ret i32 %9
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(write)
declare double @remquo(double noundef, double noundef, ptr nocapture noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(argmem: write) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree nounwind willreturn memory(write) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
