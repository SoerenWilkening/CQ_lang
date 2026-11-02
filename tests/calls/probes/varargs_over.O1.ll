; ModuleID = 'varargs_over.c'
source_filename = "varargs_over.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

; Function Attrs: nounwind ssp uwtable
define i32 @vw_over(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = tail call i32 (i32, ...) @sum8(i32 poison, i32 noundef %2, i32 noundef 2, i32 noundef %4, i32 noundef 4, i32 noundef 5, i32 noundef %4, i32 noundef 7, i32 noundef %2)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #6
  ret i32 %6
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp uwtable
define internal range(i32 -2147483647, -2147483648) i32 @sum8(i32 %0, ...) unnamed_addr #3 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #6
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = load i32, ptr %2, align 16
  %4 = getelementptr inbounds i8, ptr %2, i64 8
  %5 = getelementptr inbounds i8, ptr %2, i64 16
  %6 = load ptr, ptr %5, align 16
  %7 = load ptr, ptr %4, align 8
  br label %10

8:                                                ; preds = %23
  call void @llvm.va_end.p0(ptr %2)
  %9 = add nsw i32 %28, 1
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #6
  ret i32 %9

10:                                               ; preds = %1, %23
  %11 = phi ptr [ %7, %1 ], [ %24, %23 ]
  %12 = phi i32 [ 0, %1 ], [ %29, %23 ]
  %13 = phi i32 [ 0, %1 ], [ %28, %23 ]
  %14 = phi i32 [ %3, %1 ], [ %25, %23 ]
  %15 = mul nsw i32 %13, 3
  %16 = icmp ult i32 %14, 41
  br i1 %16, label %17, label %21

17:                                               ; preds = %10
  %18 = zext nneg i32 %14 to i64
  %19 = getelementptr i8, ptr %6, i64 %18
  %20 = add nuw nsw i32 %14, 8
  store i32 %20, ptr %2, align 16
  br label %23

21:                                               ; preds = %10
  %22 = getelementptr i8, ptr %11, i64 8
  store ptr %22, ptr %4, align 8
  br label %23

23:                                               ; preds = %21, %17
  %24 = phi ptr [ %11, %17 ], [ %22, %21 ]
  %25 = phi i32 [ %20, %17 ], [ %14, %21 ]
  %26 = phi ptr [ %19, %17 ], [ %11, %21 ]
  %27 = load i32, ptr %26, align 4, !tbaa !6
  %28 = add nsw i32 %27, %15
  %29 = add nuw nsw i32 %12, 1
  %30 = icmp eq i32 %29, 8
  br i1 %30, label %8, label %10, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
