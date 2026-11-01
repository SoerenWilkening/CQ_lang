; ModuleID = 'qram_loop_columns.c'
source_filename = "qram_loop_columns.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.cell = type { i8, double, %struct.in }
%struct.in = type { i16, i32 }

; Function Attrs: nounwind ssp uwtable
define i32 @t2(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x %struct.cell], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 96, ptr nonnull %4) #4
  br label %37

6:                                                ; preds = %37
  %7 = and i32 %5, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %8, i32 2
  %10 = getelementptr inbounds i8, ptr %9, i64 4
  store i32 %2, ptr %10, align 4, !tbaa !6
  %11 = trunc i32 %2 to i16
  %12 = add i32 %5, 1
  %13 = and i32 %12, 3
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %14
  %16 = getelementptr inbounds i8, ptr %15, i64 16
  store i16 %11, ptr %16, align 8, !tbaa !14
  %17 = xor i32 %7, 2
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %18
  store i8 9, ptr %19, align 8, !tbaa !15
  %20 = load i16, ptr %9, align 8, !tbaa !14
  %21 = sext i16 %20 to i32
  %22 = add i32 %5, 3
  %23 = and i32 %22, 3
  %24 = zext nneg i32 %23 to i64
  %25 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %24, i32 2, i32 1
  %26 = load i32, ptr %25, align 4, !tbaa !6
  %27 = getelementptr inbounds i8, ptr %15, i64 8
  %28 = load double, ptr %27, align 8, !tbaa !16
  %29 = fptosi double %28 to i32
  %30 = getelementptr inbounds i8, ptr %4, i64 44
  %31 = load i32, ptr %30, align 4, !tbaa !6
  %32 = add nsw i32 %21, 9
  %33 = add i32 %32, %26
  %34 = add nsw i32 %33, %29
  %35 = add nsw i32 %34, %31
  %36 = tail call i32 @cq_measure_si32(i32 noundef %35) #4
  call void @llvm.lifetime.end.p0(i64 96, ptr nonnull %4) #4
  ret i32 %36

37:                                               ; preds = %3, %37
  %38 = phi i64 [ 0, %3 ], [ %51, %37 ]
  %39 = trunc i64 %38 to i8
  %40 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %38
  store i8 %39, ptr %40, align 8, !tbaa !15
  %41 = trunc nuw nsw i64 %38 to i32
  %42 = uitofp nneg i32 %41 to double
  %43 = fmul double %42, 1.500000e+00
  %44 = getelementptr inbounds i8, ptr %40, i64 8
  store double %43, ptr %44, align 8, !tbaa !16
  %45 = trunc i64 %38 to i16
  %46 = add nuw nsw i16 %45, 10
  %47 = getelementptr inbounds i8, ptr %40, i64 16
  store i16 %46, ptr %47, align 8, !tbaa !14
  %48 = getelementptr inbounds i8, ptr %40, i64 20
  %49 = trunc i64 %38 to i32
  %50 = or i32 %49, 100
  store i32 %50, ptr %48, align 4, !tbaa !6
  %51 = add nuw nsw i64 %38, 1
  %52 = icmp eq i64 %51, 4
  br i1 %52, label %6, label %37, !llvm.loop !17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !13, i64 20}
!7 = !{!"cell", !8, i64 0, !10, i64 8, !11, i64 16}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!"double", !8, i64 0}
!11 = !{!"in", !12, i64 0, !13, i64 4}
!12 = !{!"short", !8, i64 0}
!13 = !{!"int", !8, i64 0}
!14 = !{!7, !12, i64 16}
!15 = !{!7, !8, i64 0}
!16 = !{!7, !10, i64 8}
!17 = distinct !{!17, !18, !19}
!18 = !{!"llvm.loop.mustprogress"}
!19 = !{!"llvm.loop.unroll.disable"}
