; ModuleID = 'tail_skip.c'
source_filename = "tail_skip.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [12 x i8] c"12.5e3 Ab,x\00", align 1

; Function Attrs: nounwind ssp uwtable
define range(i32 -128, 128) i32 @ts_copy(i8 noundef signext %0, i8 noundef signext %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [64 x i8], align 16
  %5 = alloca [64 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %4) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %4, i8 0, i64 64, i1 false)
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %5) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %5, i8 0, i64 64, i1 false)
  br label %11

6:                                                ; preds = %11
  store i8 %0, ptr %4, align 16, !tbaa !6
  store i8 %1, ptr %5, align 16, !tbaa !6
  %7 = tail call signext i8 @cq_theta_c(i8 noundef signext %0, double noundef 3.000000e-01) #6
  store i8 %7, ptr %4, align 16, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %4, i64 1
  %9 = load i8, ptr %8, align 1, !tbaa !6
  %10 = icmp eq i8 %9, 0
  br i1 %10, label %18, label %19

11:                                               ; preds = %3, %11
  %12 = phi i64 [ 0, %3 ], [ %15, %11 ]
  %13 = getelementptr inbounds [12 x i8], ptr @.str, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6
  %15 = add nuw nsw i64 %12, 1
  %16 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 %15
  store i8 %14, ptr %16, align 1, !tbaa !6
  %17 = icmp eq i64 %15, 11
  br i1 %17, label %6, label %11, !llvm.loop !9

18:                                               ; preds = %6
  call fastcc void @cp(ptr noundef nonnull %4, ptr noundef nonnull %5) #7
  br label %19

19:                                               ; preds = %18, %6
  %20 = load i8, ptr %4, align 16, !tbaa !6
  %21 = call signext i8 @cq_measure_c(i8 noundef signext %20) #8
  %22 = sext i8 %21 to i32
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %5) #5
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %4) #5
  ret i32 %22
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #3

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define internal fastcc void @cp(ptr noalias noundef %0, ptr noalias noundef %1) unnamed_addr #4 {
  %3 = ptrtoint ptr %1 to i64
  %4 = ptrtoint ptr %0 to i64
  %5 = xor i64 %3, %4
  %6 = and i64 %5, 7
  %7 = icmp eq i64 %6, 0
  br i1 %7, label %8, label %42

8:                                                ; preds = %2
  %9 = ptrtoint ptr %1 to i64
  %10 = and i64 %9, 7
  %11 = icmp eq i64 %10, 0
  br i1 %11, label %12, label %20

12:                                               ; preds = %25, %8
  %13 = phi ptr [ %0, %8 ], [ %27, %25 ]
  %14 = phi ptr [ %1, %8 ], [ %26, %25 ]
  %15 = load i64, ptr %14, align 8, !tbaa !6
  %16 = sub i64 72340172838076672, %15
  %17 = or i64 %16, %15
  %18 = and i64 %17, -9187201950435737472
  %19 = icmp eq i64 %18, -9187201950435737472
  br i1 %19, label %31, label %42

20:                                               ; preds = %8, %25
  %21 = phi ptr [ %26, %25 ], [ %1, %8 ]
  %22 = phi ptr [ %27, %25 ], [ %0, %8 ]
  %23 = load i8, ptr %21, align 1, !tbaa !6
  store i8 %23, ptr %22, align 1, !tbaa !6
  %24 = icmp eq i8 %23, 0
  br i1 %24, label %54, label %25

25:                                               ; preds = %20
  %26 = getelementptr inbounds i8, ptr %21, i64 1
  %27 = getelementptr inbounds i8, ptr %22, i64 1
  %28 = ptrtoint ptr %26 to i64
  %29 = and i64 %28, 7
  %30 = icmp eq i64 %29, 0
  br i1 %30, label %12, label %20, !llvm.loop !12

31:                                               ; preds = %12, %31
  %32 = phi i64 [ %37, %31 ], [ %15, %12 ]
  %33 = phi ptr [ %35, %31 ], [ %14, %12 ]
  %34 = phi ptr [ %36, %31 ], [ %13, %12 ]
  %35 = getelementptr inbounds i8, ptr %33, i64 8
  %36 = getelementptr inbounds i8, ptr %34, i64 8
  store i64 %32, ptr %34, align 8, !tbaa !6
  %37 = load i64, ptr %35, align 8, !tbaa !6
  %38 = sub i64 72340172838076672, %37
  %39 = or i64 %38, %37
  %40 = and i64 %39, -9187201950435737472
  %41 = icmp eq i64 %40, -9187201950435737472
  br i1 %41, label %31, label %42, !llvm.loop !13

42:                                               ; preds = %31, %12, %2
  %43 = phi ptr [ %0, %2 ], [ %13, %12 ], [ %36, %31 ]
  %44 = phi ptr [ %1, %2 ], [ %14, %12 ], [ %35, %31 ]
  %45 = load i8, ptr %44, align 1, !tbaa !6
  store i8 %45, ptr %43, align 1, !tbaa !6
  %46 = icmp eq i8 %45, 0
  br i1 %46, label %54, label %47

47:                                               ; preds = %42, %47
  %48 = phi ptr [ %50, %47 ], [ %44, %42 ]
  %49 = phi ptr [ %51, %47 ], [ %43, %42 ]
  %50 = getelementptr inbounds i8, ptr %48, i64 1
  %51 = getelementptr inbounds i8, ptr %49, i64 1
  %52 = load i8, ptr %50, align 1, !tbaa !6
  store i8 %52, ptr %51, align 1, !tbaa !6
  %53 = icmp eq i8 %52, 0
  br i1 %53, label %54, label %47, !llvm.loop !14

54:                                               ; preds = %20, %47, %42
  ret void
}

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nobuiltin nomerge nounwind "no-builtins" }
attributes #7 = { nobuiltin "no-builtins" }
attributes #8 = { nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !10, !11}
!13 = distinct !{!13, !10, !11}
!14 = distinct !{!14, !10, !11}
