; ModuleID = 'callee_controlled_ry_in_loop.c'
source_filename = "callee_controlled_ry_in_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @callee_controlled_ry_in_loop(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, i32 noundef %6) local_unnamed_addr #0 {
  %8 = alloca i32, align 4
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %2) #4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %8) #5
  store i32 %3, ptr %8, align 4, !tbaa !6
  %11 = icmp sgt i32 %6, 0
  %12 = and i1 %10, %11
  br i1 %12, label %13, label %18

13:                                               ; preds = %7, %13
  %14 = phi i32 [ %16, %13 ], [ 0, %7 ]
  %15 = add nsw i32 %14, %4
  call fastcc void @step(ptr noundef nonnull %8, i32 noundef %9, i32 noundef %15, double noundef %5)
  %16 = add nuw nsw i32 %14, 1
  %17 = icmp eq i32 %16, %6
  br i1 %17, label %18, label %13, !llvm.loop !10

18:                                               ; preds = %13, %7
  %19 = load i32, ptr %8, align 4, !tbaa !6
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #5
  %21 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %22 = add nsw i32 %21, %20
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #5
  %24 = zext i1 %23 to i32
  %25 = add nsw i32 %22, %24
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8) #5
  ret i32 %25
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @step(ptr nocapture noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) unnamed_addr #3 {
  %5 = icmp sgt i32 %1, %2
  br i1 %5, label %6, label %9

6:                                                ; preds = %4
  %7 = load i32, ptr %0, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %3) #4
  store i32 %8, ptr %0, align 4, !tbaa !6
  br label %9

9:                                                ; preds = %6, %4
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
