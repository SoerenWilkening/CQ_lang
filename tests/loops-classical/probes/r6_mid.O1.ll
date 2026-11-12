; ModuleID = 'r6_mid.c'
source_filename = "r6_mid.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @r6_mid_join(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca [8 x i8], align 8
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #5
  store i32 0, ptr %6, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  store volatile ptr %6, ptr %7, align 8, !tbaa !10
  %10 = load volatile ptr, ptr %7, align 8, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8) #5
  store i64 0, ptr %8, align 8
  %11 = and i32 %3, 3
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %18, label %13

13:                                               ; preds = %5
  %14 = and i32 %2, 1
  %15 = icmp eq i32 %14, 0
  %16 = and i32 %4, 7
  %17 = zext nneg i32 %16 to i64
  br label %31

18:                                               ; preds = %38, %5
  %19 = phi i32 [ 0, %5 ], [ %40, %38 ]
  %20 = call i32 @cq_measure_ui32(i32 noundef %19) #5
  %21 = shl i32 %20, 8
  %22 = load i32, ptr %10, align 4, !tbaa !6
  %23 = call i32 @cq_measure_ui32(i32 noundef %22) #5
  %24 = add i32 %23, %21
  %25 = getelementptr inbounds i8, ptr %8, i64 1
  %26 = load i8, ptr %25, align 1, !tbaa !12
  %27 = call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %26) #5
  %28 = zext i8 %27 to i32
  %29 = shl nuw nsw i32 %28, 16
  %30 = add i32 %24, %29
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #5
  ret i32 %30

31:                                               ; preds = %13, %38
  %32 = phi i32 [ 0, %13 ], [ %43, %38 ]
  %33 = phi i32 [ 0, %13 ], [ %40, %38 ]
  %34 = add i32 %32, %9
  br i1 %15, label %38, label %35

35:                                               ; preds = %31
  %36 = load i32, ptr %10, align 4, !tbaa !6
  %37 = xor i32 %36, %34
  store i32 %37, ptr %10, align 4, !tbaa !6
  br label %38

38:                                               ; preds = %35, %31
  %39 = mul i32 %33, 3
  %40 = add i32 %34, %39
  %41 = and i32 %34, 255
  %42 = call ptr @__memset_chk(ptr noundef nonnull %8, i32 noundef %41, i64 noundef %17, i64 noundef 8) #5
  %43 = add nuw nsw i32 %32, 1
  %44 = icmp eq i32 %43, %11
  br i1 %44, label %18, label %31, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind memory(argmem: readwrite)
declare ptr @__memset_chk(ptr noundef writeonly, i32 noundef, i64 noundef, i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @r6_mid_head(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [8 x i8], align 8
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #5
  store i64 0, ptr %5, align 8
  %7 = and i32 %2, 3
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %12, label %9

9:                                                ; preds = %4
  %10 = and i32 %3, 7
  %11 = zext nneg i32 %10 to i64
  br label %21

12:                                               ; preds = %21, %4
  %13 = phi i32 [ 0, %4 ], [ %26, %21 ]
  %14 = call i32 @cq_measure_ui32(i32 noundef %13) #5
  %15 = getelementptr inbounds i8, ptr %5, i64 1
  %16 = load i8, ptr %15, align 1, !tbaa !12
  %17 = call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %16) #5
  %18 = zext i8 %17 to i32
  %19 = shl nuw nsw i32 %18, 16
  %20 = add i32 %19, %14
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #5
  ret i32 %20

21:                                               ; preds = %9, %21
  %22 = phi i32 [ 0, %9 ], [ %29, %21 ]
  %23 = phi i32 [ 0, %9 ], [ %26, %21 ]
  %24 = add i32 %22, %6
  %25 = mul i32 %23, 3
  %26 = add i32 %24, %25
  %27 = and i32 %24, 255
  %28 = call ptr @__memset_chk(ptr noundef nonnull %5, i32 noundef %27, i64 noundef %11, i64 noundef 8) #5
  %29 = add nuw nsw i32 %22, 1
  %30 = icmp eq i32 %29, %7
  br i1 %30, label %12, label %21, !llvm.loop !16
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind memory(argmem: readwrite) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !8, i64 0}
!12 = !{!8, !8, i64 0}
!13 = distinct !{!13, !14, !15}
!14 = !{!"llvm.loop.mustprogress"}
!15 = !{!"llvm.loop.unroll.disable"}
!16 = distinct !{!16, !14, !15}
