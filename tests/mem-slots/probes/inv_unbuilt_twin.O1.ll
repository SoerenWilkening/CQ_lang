; ModuleID = 'inv_unbuilt_twin.c'
source_filename = "inv_unbuilt_twin.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.pr = type { i32, i32 }

; Function Attrs: nounwind ssp uwtable
define i32 @inv_unbuilt_twin(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca %struct.pr, align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #4
  store i32 %0, ptr %6, align 4, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %6, i64 4
  store i32 %2, ptr %7, align 4, !tbaa !11
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  store i32 %8, ptr %6, align 4, !tbaa !6
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #5
  store i32 %9, ptr %7, align 4, !tbaa !11
  call fastcc void @dbl(ptr noundef nonnull %6, i32 noundef %4)
  %10 = load i32, ptr %6, align 4, !tbaa !6
  %11 = load i32, ptr %7, align 4, !tbaa !11
  %12 = add nsw i32 %11, %10
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #4
  ret i32 %13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @dbl(ptr nocapture noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = load i32, ptr %0, align 4, !tbaa !6
  %4 = mul nsw i32 %3, 3
  %5 = add nsw i32 %4, %1
  store i32 %5, ptr %0, align 4, !tbaa !6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !8, i64 0}
!7 = !{!"pr", !8, i64 0, !8, i64 4}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 4}
; CHECK inv_unbuilt_twin: call void @__cq_q_dbl_10_unc(
; CHECK-COUNT inv_unbuilt_twin: _inv0( 0
; USERCHECK inv_unbuilt_twin
