; ModuleID = 'byval_large.c'
source_filename = "byval_large.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.big = type { i64, i64, i64 }

; Function Attrs: nounwind ssp uwtable
define i64 @byval_large_one(i64 noundef %0, double noundef %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #0 {
  %5 = alloca %struct.big, align 8
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #4
  store i64 %0, ptr %5, align 8, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %5, i64 8
  store i64 %2, ptr %6, align 8, !tbaa !11
  %7 = getelementptr inbounds i8, ptr %5, i64 16
  store i64 %3, ptr %7, align 8, !tbaa !12
  %8 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef %1) #5
  store i64 %8, ptr %5, align 8, !tbaa !6
  %9 = tail call fastcc i64 @sum3(ptr noundef nonnull byval(%struct.big) align 8 %5, i64 noundef %3)
  %10 = tail call i64 @cq_measure_sl(i64 noundef %9) #4
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #4
  ret i64 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr #2

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc i64 @sum3(ptr nocapture noundef readonly byval(%struct.big) align 8 %0, i64 noundef %1) unnamed_addr #3 {
  %3 = load i64, ptr %0, align 8, !tbaa !6
  %4 = getelementptr inbounds i8, ptr %0, i64 8
  %5 = load i64, ptr %4, align 8, !tbaa !11
  %6 = mul nsw i64 %5, %1
  %7 = add nsw i64 %6, %3
  %8 = getelementptr inbounds i8, ptr %0, i64 16
  %9 = load i64, ptr %8, align 8, !tbaa !12
  %10 = add nsw i64 %7, %9
  ret i64 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i64 @byval_large_two(i64 noundef %0, double noundef %1, i64 noundef %2, double noundef %3, i64 noundef %4) local_unnamed_addr #0 {
  %6 = alloca %struct.big, align 8
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %6) #4
  store i64 %0, ptr %6, align 8, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %6, i64 8
  store i64 %2, ptr %7, align 8, !tbaa !11
  %8 = getelementptr inbounds i8, ptr %6, i64 16
  store i64 %4, ptr %8, align 8, !tbaa !12
  %9 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef %1) #5
  store i64 %9, ptr %6, align 8, !tbaa !6
  %10 = tail call i64 @cq_theta_sl(i64 noundef %2, double noundef %3) #5
  store i64 %10, ptr %7, align 8, !tbaa !11
  %11 = tail call fastcc i64 @sum3(ptr noundef nonnull byval(%struct.big) align 8 %6, i64 noundef %4)
  %12 = tail call i64 @cq_measure_sl(i64 noundef %11) #4
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %6) #4
  ret i64 %12
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"big", !8, i64 0, !8, i64 8, !8, i64 16}
!8 = !{!"long", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 8}
!12 = !{!7, !8, i64 16}
