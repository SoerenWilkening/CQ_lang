; ModuleID = 'ptr_exit.c'
source_filename = "ptr_exit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.pe_fwd.s = private unnamed_addr constant [9 x i8] c"ab/cd/ef\00", align 1
@__const.pe_mix.s = private unnamed_addr constant [9 x i8] c"abcdefgh\00", align 1

; Function Attrs: nounwind ssp uwtable
define i64 @pe_start(i8 noundef zeroext %0, i8 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = alloca [9 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 9, ptr nonnull %3) #4
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(9) %3, ptr noundef nonnull align 1 dereferenceable(9) @__const.pe_fwd.s, i64 9, i1 false)
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #5
  %5 = and i8 %4, 1
  %6 = icmp eq i8 %5, 0
  %7 = lshr i8 %4, 5
  %8 = add nuw nsw i8 %7, 97
  %9 = select i1 %6, i8 %8, i8 47
  %10 = and i8 %0, 7
  %11 = zext nneg i8 %10 to i64
  %12 = getelementptr inbounds [9 x i8], ptr %3, i64 0, i64 %11
  store i8 %9, ptr %12, align 1, !tbaa !6
  %13 = urem i8 %1, 9
  %14 = zext nneg i8 %13 to i64
  %15 = getelementptr inbounds i8, ptr %3, i64 %14
  br label %16

16:                                               ; preds = %19, %2
  %17 = phi ptr [ %15, %2 ], [ %20, %19 ]
  %18 = icmp ugt ptr %17, %3
  br i1 %18, label %19, label %23

19:                                               ; preds = %16
  %20 = getelementptr inbounds i8, ptr %17, i64 -1
  %21 = load i8, ptr %20, align 1, !tbaa !6
  %22 = icmp eq i8 %21, 47
  br i1 %22, label %23, label %16, !llvm.loop !9

23:                                               ; preds = %16, %19
  %24 = ptrtoint ptr %17 to i64
  %25 = ptrtoint ptr %3 to i64
  %26 = sub i64 %24, %25
  %27 = call i64 @cq_measure_sl(i64 noundef %26) #4
  call void @llvm.lifetime.end.p0(i64 9, ptr nonnull %3) #4
  ret i64 %27
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #3

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i64 @pe_phi(i8 noundef zeroext %0) local_unnamed_addr #0 {
  %2 = alloca [9 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 9, ptr nonnull %2) #4
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(9) %2, ptr noundef nonnull align 1 dereferenceable(9) @__const.pe_fwd.s, i64 9, i1 false)
  %3 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #5
  %4 = and i8 %3, 1
  %5 = icmp eq i8 %4, 0
  %6 = lshr i8 %3, 5
  %7 = add nuw nsw i8 %6, 97
  %8 = select i1 %5, i8 %7, i8 47
  %9 = and i8 %0, 7
  %10 = zext nneg i8 %9 to i64
  %11 = getelementptr inbounds [9 x i8], ptr %2, i64 0, i64 %10
  store i8 %8, ptr %11, align 1, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %2, i64 8
  br label %13

13:                                               ; preds = %16, %1
  %14 = phi ptr [ %12, %1 ], [ %17, %16 ]
  %15 = icmp ugt ptr %14, %2
  br i1 %15, label %16, label %20

16:                                               ; preds = %13
  %17 = getelementptr inbounds i8, ptr %14, i64 -1
  %18 = load i8, ptr %17, align 1, !tbaa !6
  %19 = icmp eq i8 %18, 47
  br i1 %19, label %20, label %13, !llvm.loop !12

20:                                               ; preds = %13, %16
  %21 = phi ptr [ %2, %13 ], [ %14, %16 ]
  %22 = ptrtoint ptr %21 to i64
  %23 = ptrtoint ptr %2 to i64
  %24 = sub i64 %22, %23
  %25 = call i64 @cq_measure_sl(i64 noundef %24) #4
  call void @llvm.lifetime.end.p0(i64 9, ptr nonnull %2) #4
  ret i64 %25
}

; Function Attrs: nounwind ssp uwtable
define i32 @pe_fwd(i8 noundef zeroext %0, i8 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = alloca [9 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 9, ptr nonnull %3) #4
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(9) %3, ptr noundef nonnull align 1 dereferenceable(9) @__const.pe_fwd.s, i64 9, i1 false)
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #5
  %5 = and i8 %4, 1
  %6 = icmp eq i8 %5, 0
  %7 = lshr i8 %4, 5
  %8 = add nuw nsw i8 %7, 97
  %9 = select i1 %6, i8 %8, i8 47
  %10 = and i8 %0, 7
  %11 = zext nneg i8 %10 to i64
  %12 = getelementptr inbounds [9 x i8], ptr %3, i64 0, i64 %11
  store i8 %9, ptr %12, align 1, !tbaa !6
  %13 = and i8 %1, 7
  %14 = zext nneg i8 %13 to i64
  %15 = getelementptr inbounds i8, ptr %3, i64 8
  br label %19

16:                                               ; preds = %19
  %17 = add nuw nsw i64 %20, 1
  %18 = icmp eq i64 %17, 8
  br i1 %18, label %26, label %19, !llvm.loop !13

19:                                               ; preds = %2, %16
  %20 = phi i64 [ %14, %2 ], [ %17, %16 ]
  %21 = getelementptr inbounds i8, ptr %3, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !6
  %23 = icmp eq i8 %22, 47
  br i1 %23, label %24, label %16

24:                                               ; preds = %19
  %25 = getelementptr inbounds i8, ptr %3, i64 %20
  br label %26

26:                                               ; preds = %16, %24
  %27 = phi ptr [ %25, %24 ], [ %15, %16 ]
  %28 = load i8, ptr %27, align 1, !tbaa !6
  %29 = sext i8 %28 to i32
  %30 = tail call i32 @cq_measure_si32(i32 noundef %29) #4
  call void @llvm.lifetime.end.p0(i64 9, ptr nonnull %3) #4
  ret i32 %30
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @pe_mix(i8 noundef zeroext %0) local_unnamed_addr #0 {
  %2 = alloca [9 x i8], align 1
  %3 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 9, ptr nonnull %2) #4
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(9) %2, ptr noundef nonnull align 1 dereferenceable(9) @__const.pe_mix.s, i64 9, i1 false)
  %4 = getelementptr inbounds i8, ptr %2, i64 1
  %5 = and i8 %0, 7
  %6 = zext nneg i8 %5 to i64
  %7 = getelementptr inbounds i8, ptr %4, i64 %6
  %8 = zext i8 %3 to i32
  br label %9

9:                                                ; preds = %9, %1
  %10 = phi ptr [ %7, %1 ], [ %12, %9 ]
  %11 = phi i32 [ 0, %1 ], [ %13, %9 ]
  %12 = getelementptr inbounds i8, ptr %10, i64 -1
  %13 = add nuw nsw i32 %11, 1
  %14 = icmp ule ptr %12, %2
  %15 = shl i32 2, %11
  %16 = and i32 %15, %8
  %17 = icmp eq i32 %16, 0
  %18 = select i1 %14, i1 true, i1 %17
  br i1 %18, label %19, label %9, !llvm.loop !14

19:                                               ; preds = %9
  %20 = load i8, ptr %12, align 1, !tbaa !6
  %21 = sext i8 %20 to i32
  %22 = call i32 @cq_measure_si32(i32 noundef %21) #4
  call void @llvm.lifetime.end.p0(i64 9, ptr nonnull %2) #4
  ret i32 %22
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !10, !11}
!13 = distinct !{!13, !10, !11}
!14 = distinct !{!14, !10, !11}
