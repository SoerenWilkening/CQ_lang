; ModuleID = 'byval.c'
source_filename = "byval.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.B = type { i64, i64, i64 }

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define i64 @f(ptr nocapture noundef byval(%struct.B) align 8 %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %0, i64 8
  %4 = load i64, ptr %3, align 8, !tbaa !6
  %5 = add nsw i64 %4, 5
  store i64 %5, ptr %3, align 8, !tbaa !6
  %6 = mul nsw i64 %5, %1
  %7 = getelementptr inbounds i8, ptr %0, i64 16
  %8 = load i64, ptr %7, align 8, !tbaa !11
  %9 = add nsw i64 %6, %8
  ret i64 %9
}

; Function Attrs: nounwind ssp uwtable
define i64 @b3(i64 noundef %0, i64 noundef %1) local_unnamed_addr #1 {
  %3 = alloca %struct.B, align 8
  %4 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef 1.000000e+00) #4
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %3) #5
  store i64 %1, ptr %3, align 8, !tbaa !12
  %5 = getelementptr inbounds i8, ptr %3, i64 8
  %6 = add nsw i64 %1, 1
  store i64 %6, ptr %5, align 8, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 16
  store i64 7, ptr %7, align 8, !tbaa !11
  %8 = tail call i64 @f(ptr noundef nonnull byval(%struct.B) align 8 %3, i64 noundef %4)
  %9 = tail call i64 @cq_measure_sl(i64 noundef %8) #5
  %10 = load i64, ptr %5, align 8, !tbaa !6
  %11 = add nsw i64 %10, %9
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %3) #5
  ret i64 %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr #3

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nounwind ssp uwtable
define i64 @b_twin(i64 noundef %0, i64 noundef %1) local_unnamed_addr #1 {
  %3 = alloca %struct.B, align 8
  %4 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef 1.000000e+00) #4
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %3) #5
  store i64 %1, ptr %3, align 8, !tbaa !12
  %5 = getelementptr inbounds i8, ptr %3, i64 8
  %6 = add nsw i64 %1, 1
  store i64 %6, ptr %5, align 8, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 16
  store i64 7, ptr %7, align 8, !tbaa !11
  %8 = tail call i64 @f(ptr noundef nonnull byval(%struct.B) align 8 %3, i64 noundef %4)
  %9 = mul nsw i64 %1, 3
  store i64 %9, ptr %5, align 8, !tbaa !6
  %10 = add nsw i64 %4, 1
  %11 = tail call i64 @f(ptr noundef nonnull byval(%struct.B) align 8 %3, i64 noundef %10)
  %12 = xor i64 %11, %8
  %13 = tail call i64 @cq_measure_sl(i64 noundef %12) #5
  %14 = load i64, ptr %5, align 8, !tbaa !6
  %15 = add nsw i64 %14, %13
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %3) #5
  ret i64 %15
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !8, i64 8}
!7 = !{!"B", !8, i64 0, !8, i64 8, !8, i64 16}
!8 = !{!"long", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 16}
!12 = !{!7, !8, i64 0}
