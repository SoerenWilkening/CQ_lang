; ModuleID = 'fatal_armguard.c'
source_filename = "fatal_armguard.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f_armguard(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [8 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #4
  %4 = and i32 %0, 3
  %5 = add nuw nsw i32 %4, 2
  %6 = zext nneg i32 %5 to i64
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(1) %3, i8 0, i64 %6, i1 false), !tbaa !6
  %7 = and i32 %0, 3
  %8 = add nuw nsw i32 %7, 2
  %9 = zext nneg i32 %8 to i64
  br label %10

10:                                               ; preds = %2, %29
  %11 = phi i64 [ 0, %2 ], [ %30, %29 ]
  %12 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !10, !noundef !11
  %14 = trunc nuw i8 %13 to i1
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %14, double noundef %1) #5
  %16 = zext i1 %15 to i8
  store i8 %16, ptr %12, align 1, !tbaa !6
  %17 = icmp ne i64 %11, 0
  %18 = select i1 %17, i1 %15, i1 false
  br i1 %18, label %19, label %29

19:                                               ; preds = %10
  %20 = add nsw i64 %11, -1
  %21 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = trunc nuw i8 %22 to i1
  br i1 %23, label %24, label %29

24:                                               ; preds = %19
  %25 = trunc i64 %11 to i32
  %26 = add i32 %25, 1
  %27 = uitofp nneg i32 %26 to double
  %28 = fdiv double %1, %27
  tail call void @cq_phi(double noundef %28) #4
  br label %29

29:                                               ; preds = %10, %19, %24
  %30 = add nuw nsw i64 %11, 1
  %31 = icmp eq i64 %30, %9
  br i1 %31, label %32, label %10, !llvm.loop !12

32:                                               ; preds = %29
  %33 = zext nneg i32 %8 to i64
  br label %35

34:                                               ; preds = %35
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #4
  ret i32 %45

35:                                               ; preds = %32, %35
  %36 = phi i64 [ 0, %32 ], [ %46, %35 ]
  %37 = phi i32 [ 0, %32 ], [ %45, %35 ]
  %38 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %36
  %39 = load i8, ptr %38, align 1, !tbaa !6, !range !10, !noundef !11
  %40 = trunc nuw i8 %39 to i1
  %41 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %40) #4
  %42 = zext i1 %41 to i32
  %43 = trunc nuw nsw i64 %36 to i32
  %44 = shl nuw nsw i32 %42, %43
  %45 = add nuw nsw i32 %44, %37
  %46 = add nuw nsw i64 %36, 1
  %47 = icmp eq i64 %46, %33
  br i1 %47, label %34, label %35, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }
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
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
