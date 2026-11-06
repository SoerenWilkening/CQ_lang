; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv2hostres/vaD.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv2hostres/vaD.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

; Function Attrs: nofree noinline norecurse nosync nounwind ssp uwtable
define i32 @sum2(i32 noundef %0, ...) #0 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #6
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = call fastcc i32 @vs(i32 noundef %0, ptr noundef nonnull %2)
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #6
  ret i32 %3
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, argmem: readwrite, inaccessiblemem: none) uwtable
define internal fastcc i32 @vs(i32 noundef %0, ptr nocapture noundef %1) unnamed_addr #3 {
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %8

4:                                                ; preds = %2
  %5 = getelementptr inbounds i8, ptr %1, i64 8
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load i32, ptr %1, align 8
  br label %10

8:                                                ; preds = %23, %2
  %9 = phi i32 [ 0, %2 ], [ %28, %23 ]
  ret i32 %9

10:                                               ; preds = %4, %23
  %11 = phi i32 [ %7, %4 ], [ %24, %23 ]
  %12 = phi i32 [ 0, %4 ], [ %29, %23 ]
  %13 = phi i32 [ 0, %4 ], [ %28, %23 ]
  %14 = icmp ult i32 %11, 41
  br i1 %14, label %15, label %20

15:                                               ; preds = %10
  %16 = load ptr, ptr %6, align 8
  %17 = zext nneg i32 %11 to i64
  %18 = getelementptr i8, ptr %16, i64 %17
  %19 = add nuw nsw i32 %11, 8
  store i32 %19, ptr %1, align 8
  br label %23

20:                                               ; preds = %10
  %21 = load ptr, ptr %5, align 8
  %22 = getelementptr i8, ptr %21, i64 8
  store ptr %22, ptr %5, align 8
  br label %23

23:                                               ; preds = %20, %15
  %24 = phi i32 [ %19, %15 ], [ %11, %20 ]
  %25 = phi ptr [ %18, %15 ], [ %21, %20 ]
  %26 = load ptr, ptr %25, align 8, !tbaa !6
  %27 = load i32, ptr %26, align 4, !tbaa !10
  %28 = add nsw i32 %27, %13
  %29 = add nuw nsw i32 %12, 1
  %30 = icmp eq i32 %29, %0
  br i1 %30, label %8, label %10, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @vaD(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #4 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #6
  %7 = add nsw i32 %1, 1
  store i32 %7, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  store volatile ptr @sum2, ptr %6, align 8, !tbaa !6
  %8 = load volatile ptr, ptr %6, align 8, !tbaa !6
  %9 = call i32 (i32, ...) %8(i32 noundef 2, ptr noundef nonnull %4, ptr noundef nonnull %5) #6
  %10 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #7
  %11 = add nsw i32 %10, %9
  %12 = call i32 @cq_measure_si32(i32 noundef %11) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #5

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #5

attributes #0 = { nofree noinline norecurse nosync nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(read, argmem: readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
