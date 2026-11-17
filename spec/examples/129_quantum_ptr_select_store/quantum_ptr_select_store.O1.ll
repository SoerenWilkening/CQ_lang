; ModuleID = 'quantum_ptr_select_store.c'
source_filename = "quantum_ptr_select_store.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.pair = type { i32, i32 }

; Function Attrs: nounwind ssp uwtable
define i32 @ptr_select_rmw(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %8) #4
  store i32 %3, ptr %8, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %9) #4
  store i32 %5, ptr %9, align 4, !tbaa !6
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #5
  store i32 %11, ptr %8, align 4, !tbaa !6
  %12 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %6) #5
  store i32 %12, ptr %9, align 4, !tbaa !6
  %13 = icmp sgt i32 %10, %2
  %14 = select i1 %13, ptr %8, ptr %9
  %15 = load i32, ptr %14, align 4, !tbaa !6
  %16 = add nsw i32 %15, 1
  store i32 %16, ptr %14, align 4, !tbaa !6
  call fastcc void @bump(ptr noundef nonnull %14)
  %17 = load i32, ptr %8, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  %19 = load i32, ptr %9, align 4, !tbaa !6
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  %21 = add nsw i32 %20, %18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %9) #4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8) #4
  ret i32 %21
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @bump(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = add nsw i32 %2, 1
  store i32 %3, ptr %0, align 4, !tbaa !6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @guarded_field_store(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, i32 noundef %6) local_unnamed_addr #0 {
  %8 = alloca [2 x %struct.pair], align 16
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %8) #4
  store i32 %5, ptr %8, align 16, !tbaa !10
  %11 = getelementptr inbounds i8, ptr %8, i64 4
  store i32 7, ptr %11, align 4, !tbaa !12
  %12 = getelementptr inbounds i8, ptr %8, i64 8
  %13 = add nsw i32 %5, 1
  store i32 %13, ptr %12, align 8, !tbaa !10
  %14 = getelementptr inbounds i8, ptr %8, i64 12
  store i32 8, ptr %14, align 4, !tbaa !12
  %15 = icmp sgt i32 %9, %2
  br i1 %15, label %16, label %23

16:                                               ; preds = %7
  %17 = icmp sgt i32 %10, %5
  %18 = mul nsw i32 %10, 3
  %19 = sub nsw i32 %10, %5
  %20 = select i1 %17, i32 %18, i32 %19
  %21 = sext i32 %6 to i64
  %22 = getelementptr inbounds [2 x %struct.pair], ptr %8, i64 0, i64 %21
  store i32 %20, ptr %22, align 8, !tbaa !10
  br label %23

23:                                               ; preds = %16, %7
  %24 = load i32, ptr %8, align 16, !tbaa !10
  %25 = load i32, ptr %12, align 8, !tbaa !10
  %26 = add nsw i32 %25, %24
  %27 = sext i32 %6 to i64
  %28 = getelementptr inbounds [2 x %struct.pair], ptr %8, i64 0, i64 %27, i32 1
  %29 = load i32, ptr %28, align 4, !tbaa !12
  %30 = add nsw i32 %26, %29
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30) #4
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %8) #4
  ret i32 %31
}

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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !7, i64 0}
!11 = !{!"pair", !7, i64 0, !7, i64 4}
!12 = !{!11, !7, i64 4}
