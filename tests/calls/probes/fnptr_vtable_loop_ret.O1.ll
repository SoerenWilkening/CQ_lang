; ModuleID = 'fnptr_vtable_loop_ret.c'
source_filename = "fnptr_vtable_loop_ret.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.VT = type { ptr }
%struct.Shape = type { ptr, i32, i32 }

@VS = internal constant %struct.VT { ptr @sq }, align 8
@VR = internal constant %struct.VT { ptr @rect }, align 8

; Function Attrs: noinline nounwind ssp uwtable
define i32 @total(ptr nocapture noundef readonly %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  br label %9

7:                                                ; preds = %9, %3
  %8 = phi i32 [ 0, %3 ], [ %17, %9 ]
  ret i32 %8

9:                                                ; preds = %5, %9
  %10 = phi i64 [ 0, %5 ], [ %18, %9 ]
  %11 = phi i32 [ 0, %5 ], [ %17, %9 ]
  %12 = getelementptr inbounds ptr, ptr %0, i64 %10
  %13 = load ptr, ptr %12, align 8, !tbaa !6
  %14 = load ptr, ptr %13, align 8, !tbaa !10
  %15 = load ptr, ptr %14, align 8, !tbaa !13
  %16 = tail call i32 %15(ptr noundef nonnull %13, i32 noundef %2) #5
  %17 = add nsw i32 %16, %11
  %18 = add nuw nsw i64 %10, 1
  %19 = icmp eq i64 %18, %6
  br i1 %19, label %7, label %9, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @vt(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = alloca %struct.Shape, align 8
  %4 = alloca %struct.Shape, align 8
  %5 = alloca [2 x ptr], align 16
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #6
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #6
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  store ptr @VS, ptr %3, align 8, !tbaa !10
  %8 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 %6, ptr %8, align 8, !tbaa !18
  %9 = getelementptr inbounds i8, ptr %3, i64 12
  store i32 0, ptr %9, align 4, !tbaa !19
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  store ptr @VR, ptr %4, align 8, !tbaa !10
  %10 = getelementptr inbounds i8, ptr %4, i64 8
  store i32 %0, ptr %10, align 8, !tbaa !18
  %11 = getelementptr inbounds i8, ptr %4, i64 12
  store i32 %1, ptr %11, align 4, !tbaa !19
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #5
  store ptr %3, ptr %5, align 16, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %5, i64 8
  store ptr %4, ptr %12, align 8, !tbaa !6
  %13 = call i32 @total(ptr noundef nonnull %5, i32 noundef 2, i32 noundef %7)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal i32 @sq(ptr nocapture noundef readonly %0, i32 noundef %1) #4 {
  %3 = getelementptr inbounds i8, ptr %0, i64 8
  %4 = load i32, ptr %3, align 8, !tbaa !18
  %5 = mul nsw i32 %4, %4
  %6 = add nsw i32 %5, %1
  ret i32 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal i32 @rect(ptr nocapture noundef readonly %0, i32 noundef %1) #4 {
  %3 = getelementptr inbounds i8, ptr %0, i64 8
  %4 = load i32, ptr %3, align 8, !tbaa !18
  %5 = getelementptr inbounds i8, ptr %0, i64 12
  %6 = load i32, ptr %5, align 4, !tbaa !19
  %7 = mul nsw i32 %6, %4
  %8 = sub nsw i32 %7, %1
  ret i32 %8
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }

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
!10 = !{!11, !7, i64 0}
!11 = !{!"Shape", !7, i64 0, !12, i64 8, !12, i64 12}
!12 = !{!"int", !8, i64 0}
!13 = !{!14, !7, i64 0}
!14 = !{!"VT", !7, i64 0}
!15 = distinct !{!15, !16, !17}
!16 = !{!"llvm.loop.mustprogress"}
!17 = !{!"llvm.loop.unroll.disable"}
!18 = !{!11, !12, i64 8}
!19 = !{!11, !12, i64 12}
