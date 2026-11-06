; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/p/2in7d.c'
source_filename = "2in7d.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define i32 @l(i32 noundef %0) #0 {
  %2 = and i32 %0, 63
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %14, label %4

4:                                                ; preds = %1
  %5 = load i32, ptr @g, align 4, !tbaa !6
  br label %6

6:                                                ; preds = %4, %6
  %7 = phi i32 [ %9, %6 ], [ 0, %4 ]
  %8 = phi i32 [ %10, %6 ], [ %5, %4 ]
  %9 = add nuw nsw i32 %7, 1
  %10 = xor i32 %8, %9
  %11 = mul nuw nsw i32 %9, %9
  %12 = icmp ult i32 %11, %2
  br i1 %12, label %6, label %13, !llvm.loop !10

13:                                               ; preds = %6
  store i32 %10, ptr @g, align 4, !tbaa !6
  br label %14

14:                                               ; preds = %13, %1
  %15 = phi i32 [ %9, %13 ], [ 0, %1 ]
  ret i32 %15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = alloca ptr, align 8
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e+00) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3)
  store volatile ptr @l, ptr %3, align 8, !tbaa !13
  %6 = load volatile ptr, ptr %3, align 8, !tbaa !13
  %7 = tail call i32 %6(i32 noundef %4) #5
  %8 = and i32 %5, 2
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %15, label %10

10:                                               ; preds = %2
  %11 = load volatile ptr, ptr %3, align 8, !tbaa !13
  %12 = ashr i32 %4, 1
  %13 = tail call i32 %11(i32 noundef %12) #5
  %14 = add nsw i32 %13, %7
  br label %15

15:                                               ; preds = %10, %2
  %16 = phi i32 [ %14, %10 ], [ %7, %2 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  %18 = load i32, ptr @g, align 4, !tbaa !6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #5
  %20 = shl nsw i32 %19, 6
  %21 = add nsw i32 %20, %17
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3)
  ret i32 %21
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{!14, !14, i64 0}
!14 = !{!"any pointer", !8, i64 0}
