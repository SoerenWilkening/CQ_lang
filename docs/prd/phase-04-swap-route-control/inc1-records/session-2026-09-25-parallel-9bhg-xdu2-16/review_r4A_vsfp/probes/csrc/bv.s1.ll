; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.Big = type { [8 x i32] }

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = alloca %struct.Big, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  %5 = load ptr, ptr %4, align 8, !tbaa !6
  %6 = tail call i32 @atoi(ptr nocapture noundef %5)
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #5
  store i32 %6, ptr %3, align 8, !tbaa !10
  %7 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 1, ptr %7, align 4, !tbaa !10
  %8 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 2, ptr %8, align 8, !tbaa !10
  %9 = getelementptr inbounds i8, ptr %3, i64 12
  store i32 3, ptr %9, align 4, !tbaa !10
  %10 = getelementptr inbounds i8, ptr %3, i64 16
  store i32 4, ptr %10, align 8, !tbaa !10
  %11 = getelementptr inbounds i8, ptr %3, i64 20
  store i32 5, ptr %11, align 4, !tbaa !10
  %12 = getelementptr inbounds i8, ptr %3, i64 24
  store i32 6, ptr %12, align 8, !tbaa !10
  %13 = getelementptr inbounds i8, ptr %3, i64 28
  store i32 7, ptr %13, align 4, !tbaa !10
  %14 = and i32 %6, 7
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-01) #5
  %16 = tail call i32 @h(i32 noundef %15, ptr noundef nonnull byval(%struct.Big) align 8 %3) #5
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  %18 = load i32, ptr %3, align 8, !tbaa !10
  %19 = add nsw i32 %18, %17
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #5
  ret i32 %19
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, ptr nocapture noundef readnone byval(%struct.Big) align 8 %1) local_unnamed_addr #4 {
  %3 = mul nsw i32 %0, 3
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
