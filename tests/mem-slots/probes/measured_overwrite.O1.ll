; ModuleID = 'tests/mem-slots/probes/measured_overwrite.c'
source_filename = "tests/mem-slots/probes/measured_overwrite.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @measured_overwrite(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [2 x i32], align 4
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #4
  %4 = add nsw i32 %3, 1
  store i32 %4, ptr %2, align 4, !tbaa !6
  %5 = add nsw i32 %3, 2
  %6 = getelementptr inbounds i8, ptr %2, i64 4
  store i32 %5, ptr %6, align 4, !tbaa !6
  %7 = xor i32 %3, 5
  store i32 %7, ptr %2, align 4, !tbaa !6
  %8 = and i32 %0, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [2 x i32], ptr %2, i64 0, i64 %9
  %11 = load i32, ptr %10, align 4, !tbaa !6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #4
  ret i32 %12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
; CHECK measured_overwrite: call void @cq_template_add_i32_hl_unc(i32 %{{a}}, i32 %{{x}}, i32 1)
; CHECK-COUNT measured_overwrite: call void @cq_template_add_i32_hl_unc( 1
