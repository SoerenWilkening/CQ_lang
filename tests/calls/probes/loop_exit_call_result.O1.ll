; ModuleID = 'loop_exit_call_result.c'
source_filename = "loop_exit_call_result.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

@sink = local_unnamed_addr global i32 0, align 4

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define noundef i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  store i32 %0, ptr @sink, align 4, !tbaa !6
  ret i32 -1
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn uwtable
define noundef i32 @ve(i32 noundef %0, ...) local_unnamed_addr #1 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #6
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = load i32, ptr %2, align 16
  %4 = icmp ult i32 %3, 41
  br i1 %4, label %5, label %11

5:                                                ; preds = %1
  %6 = getelementptr inbounds i8, ptr %2, i64 16
  %7 = load ptr, ptr %6, align 16
  %8 = zext nneg i32 %3 to i64
  %9 = getelementptr i8, ptr %7, i64 %8
  %10 = add nuw nsw i32 %3, 8
  store i32 %10, ptr %2, align 16
  br label %15

11:                                               ; preds = %1
  %12 = getelementptr inbounds i8, ptr %2, i64 8
  %13 = load ptr, ptr %12, align 8
  %14 = getelementptr i8, ptr %13, i64 8
  store ptr %14, ptr %12, align 8
  br label %15

15:                                               ; preds = %11, %5
  %16 = phi ptr [ %9, %5 ], [ %13, %11 ]
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = add nsw i32 %17, %0
  store i32 %18, ptr @sink, align 4, !tbaa !6
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #6
  ret i32 -1
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nounwind ssp uwtable
define i32 @e() local_unnamed_addr #4 {
  %1 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #7
  %2 = zext i8 %1 to i32
  br label %3

3:                                                ; preds = %3, %0
  %4 = phi i32 [ %2, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %8, %3 ]
  %6 = mul i32 %4, 5
  %7 = add i32 %6, 1
  %8 = add nuw nsw i32 %5, 1
  %9 = and i32 %7, 7
  %10 = icmp ne i32 %9, 3
  %11 = icmp ult i32 %5, 39
  %12 = select i1 %10, i1 %11, i1 false
  br i1 %12, label %3, label %13, !llvm.loop !10

13:                                               ; preds = %3
  %14 = tail call i32 @f(i32 noundef %8)
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %8) #6
  ret i32 %15
}

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #5

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #5

; Function Attrs: nounwind ssp uwtable
define i32 @ev() local_unnamed_addr #4 {
  %1 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #7
  %2 = zext i8 %1 to i32
  br label %3

3:                                                ; preds = %3, %0
  %4 = phi i32 [ %2, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %8, %3 ]
  %6 = mul i32 %4, 5
  %7 = add i32 %6, 1
  %8 = add nuw nsw i32 %5, 1
  %9 = and i32 %7, 7
  %10 = icmp ne i32 %9, 3
  %11 = icmp ult i32 %5, 39
  %12 = select i1 %10, i1 %11, i1 false
  br i1 %12, label %3, label %13, !llvm.loop !13

13:                                               ; preds = %3
  %14 = tail call i32 (i32, ...) @ve(i32 noundef 1, i32 noundef %8)
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %8) #6
  ret i32 %15
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
