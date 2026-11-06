; ModuleID = 'tail_excl.c'
source_filename = "tail_excl.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [12 x i8] c"12.5e3 Ab,x\00", align 1

; Function Attrs: nounwind ssp uwtable
define i64 @te_len(i8 noundef signext %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [64 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %3) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %3, i8 0, i64 64, i1 false)
  br label %10

4:                                                ; preds = %10
  store i8 %0, ptr %3, align 16, !tbaa !6
  %5 = tail call signext i8 @cq_theta_c(i8 noundef signext %0, double noundef 3.000000e-01) #6
  store i8 %5, ptr %3, align 16, !tbaa !6
  %6 = and i64 %1, 1
  %7 = getelementptr inbounds i8, ptr %3, i64 %6
  %8 = call fastcc i64 @len(ptr noundef nonnull %7) #7
  %9 = call i64 @cq_measure_sl(i64 noundef %8) #8
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %3) #5
  ret i64 %9

10:                                               ; preds = %2, %10
  %11 = phi i64 [ 0, %2 ], [ %14, %10 ]
  %12 = getelementptr inbounds [12 x i8], ptr @.str, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !6
  %14 = add nuw nsw i64 %11, 1
  %15 = getelementptr inbounds [64 x i8], ptr %3, i64 0, i64 %14
  store i8 %13, ptr %15, align 1, !tbaa !6
  %16 = icmp eq i64 %14, 11
  br i1 %16, label %4, label %10, !llvm.loop !9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #3

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #3

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define internal fastcc i64 @len(ptr noundef %0) unnamed_addr #4 {
  %2 = ptrtoint ptr %0 to i64
  %3 = and i64 %2, 7
  %4 = icmp eq i64 %3, 0
  br i1 %4, label %17, label %5

5:                                                ; preds = %1
  %6 = load i8, ptr %0, align 1, !tbaa !6
  %7 = icmp eq i8 %6, 0
  br i1 %7, label %34, label %11

8:                                                ; preds = %11
  %9 = load i8, ptr %13, align 1, !tbaa !6
  %10 = icmp eq i8 %9, 0
  br i1 %10, label %34, label %11, !llvm.loop !12

11:                                               ; preds = %5, %8
  %12 = phi ptr [ %13, %8 ], [ %0, %5 ]
  %13 = getelementptr inbounds i8, ptr %12, i64 1
  %14 = ptrtoint ptr %13 to i64
  %15 = and i64 %14, 7
  %16 = icmp eq i64 %15, 0
  br i1 %16, label %17, label %8, !llvm.loop !12

17:                                               ; preds = %11, %1
  %18 = phi ptr [ %0, %1 ], [ %13, %11 ]
  br label %19

19:                                               ; preds = %17, %19
  %20 = phi ptr [ %26, %19 ], [ %18, %17 ]
  %21 = load i64, ptr %20, align 8, !tbaa !6
  %22 = sub i64 72340172838076672, %21
  %23 = or i64 %22, %21
  %24 = and i64 %23, -9187201950435737472
  %25 = icmp eq i64 %24, -9187201950435737472
  %26 = getelementptr inbounds i8, ptr %20, i64 8
  br i1 %25, label %19, label %27, !llvm.loop !13

27:                                               ; preds = %19, %27
  %28 = phi ptr [ %31, %27 ], [ %20, %19 ]
  %29 = load i8, ptr %28, align 1, !tbaa !6
  %30 = icmp eq i8 %29, 0
  %31 = getelementptr inbounds i8, ptr %28, i64 1
  br i1 %30, label %32, label %27, !llvm.loop !14

32:                                               ; preds = %27
  %33 = ptrtoint ptr %28 to i64
  br label %34

34:                                               ; preds = %8, %5, %32
  %35 = phi i64 [ %33, %32 ], [ %2, %5 ], [ %14, %8 ]
  %36 = ptrtoint ptr %0 to i64
  %37 = sub i64 %35, %36
  ret i64 %37
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
