; ModuleID = 'src/L2arr.c'
source_filename = "src/L2arr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  br label %4

3:                                                ; preds = %16
  ret i32 %19

4:                                                ; preds = %2, %16
  %5 = phi i64 [ 0, %2 ], [ %20, %16 ]
  %6 = phi i32 [ 0, %2 ], [ %19, %16 ]
  %7 = trunc i64 %5 to i32
  %8 = add i32 %7, %0
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #5
  %10 = getelementptr inbounds i32, ptr %1, i64 %5
  %11 = load i32, ptr %10, align 4, !tbaa !6
  %12 = sext i32 %9 to i64
  %13 = icmp slt i64 %5, %12
  br i1 %13, label %14, label %16

14:                                               ; preds = %4
  %15 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 2.000000e-01) #5
  br label %16

16:                                               ; preds = %14, %4
  %17 = phi i32 [ %15, %14 ], [ 6, %4 ]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  %19 = add nsw i32 %18, %6
  %20 = add nuw nsw i64 %5, 1
  %21 = icmp eq i64 %20, 3
  br i1 %21, label %3, label %4, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #3 {
  %3 = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %3) #5
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  %5 = load ptr, ptr %4, align 8, !tbaa !13
  %6 = tail call i32 @atoi(ptr nocapture noundef %5)
  store i32 %6, ptr %3, align 4, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 4
  %8 = getelementptr inbounds i8, ptr %1, i64 16
  %9 = load ptr, ptr %8, align 8, !tbaa !13
  %10 = tail call i32 @atoi(ptr nocapture noundef %9)
  store i32 %10, ptr %7, align 4, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %3, i64 8
  %12 = getelementptr inbounds i8, ptr %1, i64 24
  %13 = load ptr, ptr %12, align 8, !tbaa !13
  %14 = tail call i32 @atoi(ptr nocapture noundef %13)
  store i32 %14, ptr %11, align 4, !tbaa !6
  %15 = add nsw i32 %0, 3
  %16 = call i32 @slice(i32 noundef %15, ptr noundef nonnull %3)
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %3) #5
  ret i32 %16
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #4

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{!14, !14, i64 0}
!14 = !{!"any pointer", !8, i64 0}
