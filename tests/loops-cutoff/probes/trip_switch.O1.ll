; ModuleID = 'trip_switch.c'
source_filename = "trip_switch.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.sa_wcs.w = private unnamed_addr constant [8 x i32] [i32 65, i32 256, i32 66, i32 67, i32 68, i32 69, i32 0, i32 0], align 16
@__const.sc_wide.cell = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @sa_wcs(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [16 x i8], align 16
  %5 = alloca [8 x i32], align 16
  %6 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #7
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %5) #7
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %5, ptr noundef nonnull align 16 dereferenceable(32) @__const.sa_wcs.w, i64 32, i1 false)
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %0, ptr %7, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #8
  store i32 %8, ptr %7, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #7
  store ptr %5, ptr %6, align 8, !tbaa !10
  %9 = and i32 %2, 7
  %10 = call fastcc i32 @sa_conv(ptr noundef nonnull %4, ptr noundef nonnull %6, i32 noundef %9)
  %11 = call i32 @cq_measure_ui32(i32 noundef %10) #7
  %12 = getelementptr inbounds i8, ptr %4, i64 1
  %13 = load i8, ptr %12, align 1, !tbaa !12
  %14 = call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %13) #7
  %15 = load ptr, ptr %6, align 8, !tbaa !10
  %16 = icmp eq ptr %15, null
  %17 = ptrtoint ptr %15 to i64
  %18 = ptrtoint ptr %5 to i64
  %19 = sub i64 %17, %18
  %20 = lshr exact i64 %19, 2
  %21 = trunc i64 %20 to i32
  %22 = select i1 %16, i32 15, i32 %21
  %23 = shl i32 %11, 12
  %24 = zext i8 %14 to i32
  %25 = shl nuw nsw i32 %24, 4
  %26 = or disjoint i32 %25, %23
  %27 = call i32 @cq_measure_ui32(i32 noundef %22) #7
  %28 = add i32 %26, %27
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #7
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %5) #7
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #7
  ret i32 %28
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #4

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define internal fastcc i32 @sa_conv(ptr nocapture noundef writeonly %0, ptr nocapture noundef %1, i32 noundef %2) unnamed_addr #5 {
  %4 = icmp ugt i32 %2, 3
  br i1 %4, label %9, label %5

5:                                                ; preds = %29, %3
  %6 = phi ptr [ %0, %3 ], [ %30, %29 ]
  %7 = phi i32 [ %2, %3 ], [ %31, %29 ]
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %65, label %35

9:                                                ; preds = %3, %29
  %10 = phi i32 [ %31, %29 ], [ %2, %3 ]
  %11 = phi ptr [ %30, %29 ], [ %0, %3 ]
  %12 = load ptr, ptr %1, align 8, !tbaa !10
  %13 = load i32, ptr %12, align 4, !tbaa !6
  %14 = add i32 %13, -128
  %15 = icmp ult i32 %14, -127
  br i1 %15, label %16, label %25

16:                                               ; preds = %9
  %17 = icmp eq i32 %13, 0
  br i1 %17, label %61, label %18

18:                                               ; preds = %16
  %19 = tail call fastcc i32 @sa_put(ptr noundef %11, i32 noundef %13)
  %20 = icmp eq i32 %19, -1
  br i1 %20, label %65, label %21

21:                                               ; preds = %18
  %22 = zext i32 %19 to i64
  %23 = getelementptr inbounds i8, ptr %11, i64 %22
  %24 = sub i32 %10, %19
  br label %29

25:                                               ; preds = %9
  %26 = trunc nuw i32 %13 to i8
  %27 = getelementptr inbounds i8, ptr %11, i64 1
  store i8 %26, ptr %11, align 1, !tbaa !12
  %28 = add i32 %10, -1
  br label %29

29:                                               ; preds = %25, %21
  %30 = phi ptr [ %23, %21 ], [ %27, %25 ]
  %31 = phi i32 [ %24, %21 ], [ %28, %25 ]
  %32 = load ptr, ptr %1, align 8, !tbaa !10
  %33 = getelementptr inbounds i8, ptr %32, i64 4
  store ptr %33, ptr %1, align 8, !tbaa !10
  %34 = icmp ugt i32 %31, 3
  br i1 %34, label %9, label %5, !llvm.loop !13

35:                                               ; preds = %5, %55
  %36 = phi i32 [ %57, %55 ], [ %7, %5 ]
  %37 = phi ptr [ %56, %55 ], [ %6, %5 ]
  %38 = load ptr, ptr %1, align 8, !tbaa !10
  %39 = load i32, ptr %38, align 4, !tbaa !6
  %40 = add i32 %39, -128
  %41 = icmp ult i32 %40, -127
  br i1 %41, label %42, label %51

42:                                               ; preds = %35
  %43 = icmp eq i32 %39, 0
  br i1 %43, label %61, label %44

44:                                               ; preds = %42
  %45 = tail call fastcc i32 @sa_put(ptr noundef %37, i32 noundef %39)
  %46 = icmp eq i32 %45, -1
  br i1 %46, label %65, label %47

47:                                               ; preds = %44
  %48 = zext nneg i32 %45 to i64
  %49 = getelementptr inbounds i8, ptr %37, i64 %48
  %50 = sub i32 %36, %45
  br label %55

51:                                               ; preds = %35
  %52 = trunc nuw i32 %39 to i8
  %53 = getelementptr inbounds i8, ptr %37, i64 1
  store i8 %52, ptr %37, align 1, !tbaa !12
  %54 = add i32 %36, -1
  br label %55

55:                                               ; preds = %51, %47
  %56 = phi ptr [ %49, %47 ], [ %53, %51 ]
  %57 = phi i32 [ %50, %47 ], [ %54, %51 ]
  %58 = load ptr, ptr %1, align 8, !tbaa !10
  %59 = getelementptr inbounds i8, ptr %58, i64 4
  store ptr %59, ptr %1, align 8, !tbaa !10
  %60 = icmp eq i32 %57, 0
  br i1 %60, label %65, label %35, !llvm.loop !16

61:                                               ; preds = %16, %42
  %62 = phi ptr [ %37, %42 ], [ %11, %16 ]
  %63 = phi i32 [ %36, %42 ], [ %10, %16 ]
  store i8 0, ptr %62, align 1, !tbaa !12
  store ptr null, ptr %1, align 8, !tbaa !10
  %64 = sub i32 %2, %63
  br label %65

65:                                               ; preds = %18, %44, %55, %61, %5
  %66 = phi i32 [ %2, %5 ], [ %64, %61 ], [ %2, %55 ], [ -1, %44 ], [ -1, %18 ]
  ret i32 %66
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #4

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @sb_narrow(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i32], align 16
  %6 = alloca ptr, align 8
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #8
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #7
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, ptr noundef nonnull align 16 dereferenceable(16) @__const.sc_wide.cell, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  store volatile ptr %5, ptr %6, align 8, !tbaa !10
  %8 = load volatile ptr, ptr %6, align 8, !tbaa !10
  %9 = icmp ugt i32 %7, %2
  br i1 %9, label %10, label %38

10:                                               ; preds = %4
  %11 = and i32 %3, 1
  %12 = icmp eq i32 %11, 0
  %13 = getelementptr inbounds i8, ptr %8, i64 8
  %14 = getelementptr inbounds i8, ptr %8, i64 4
  %15 = getelementptr inbounds i8, ptr %8, i64 12
  br label %16

16:                                               ; preds = %10, %35
  %17 = phi i32 [ 0, %10 ], [ %36, %35 ]
  %18 = phi i32 [ %7, %10 ], [ %19, %35 ]
  %19 = lshr i32 %18, 1
  br i1 %12, label %35, label %20

20:                                               ; preds = %16
  %21 = add i32 %19, %17
  %22 = trunc i32 %21 to i8
  switch i8 %22, label %32 [
    i8 1, label %23
    i8 5, label %23
    i8 2, label %26
    i8 -56, label %29
  ]

23:                                               ; preds = %20, %20
  %24 = load i32, ptr %8, align 4, !tbaa !6
  %25 = add i32 %24, %19
  store i32 %25, ptr %8, align 4, !tbaa !6
  br label %35

26:                                               ; preds = %20
  %27 = load i32, ptr %14, align 4, !tbaa !6
  %28 = xor i32 %27, %17
  store i32 %28, ptr %14, align 4, !tbaa !6
  br label %35

29:                                               ; preds = %20
  %30 = load i32, ptr %13, align 4, !tbaa !6
  %31 = add i32 %30, 7
  store i32 %31, ptr %13, align 4, !tbaa !6
  br label %35

32:                                               ; preds = %20
  %33 = load i32, ptr %15, align 4, !tbaa !6
  %34 = add i32 %33, 1
  store i32 %34, ptr %15, align 4, !tbaa !6
  br label %35

35:                                               ; preds = %23, %26, %29, %32, %16
  %36 = add i32 %17, 1
  %37 = icmp ugt i32 %19, %2
  br i1 %37, label %16, label %38, !llvm.loop !17

38:                                               ; preds = %35, %4
  %39 = phi i32 [ 0, %4 ], [ %36, %35 ]
  %40 = call i32 @cq_measure_ui32(i32 noundef %39) #7
  %41 = shl i32 %40, 12
  %42 = load i32, ptr %8, align 4, !tbaa !6
  %43 = getelementptr inbounds i8, ptr %8, i64 4
  %44 = load i32, ptr %43, align 4, !tbaa !6
  %45 = mul i32 %44, 3
  %46 = add i32 %45, %42
  %47 = getelementptr inbounds i8, ptr %8, i64 8
  %48 = load i32, ptr %47, align 4, !tbaa !6
  %49 = mul i32 %48, 5
  %50 = add i32 %46, %49
  %51 = getelementptr inbounds i8, ptr %8, i64 12
  %52 = load i32, ptr %51, align 4, !tbaa !6
  %53 = mul i32 %52, 7
  %54 = add i32 %50, %53
  %55 = call i32 @cq_measure_ui32(i32 noundef %54) #7
  %56 = add i32 %55, %41
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #7
  ret i32 %56
}

; Function Attrs: nounwind ssp uwtable
define i32 @sc_wide(i16 noundef zeroext %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i32], align 16
  %6 = alloca ptr, align 8
  %7 = tail call zeroext i16 @cq_theta_ui16(i16 noundef zeroext %0, double noundef %1) #8
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #7
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, ptr noundef nonnull align 16 dereferenceable(16) @__const.sc_wide.cell, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  store volatile ptr %5, ptr %6, align 8, !tbaa !10
  %8 = load volatile ptr, ptr %6, align 8, !tbaa !10
  %9 = zext i16 %7 to i32
  %10 = icmp ugt i32 %9, %2
  br i1 %10, label %11, label %43

11:                                               ; preds = %4
  %12 = and i32 %3, 2
  %13 = icmp eq i32 %12, 0
  %14 = getelementptr inbounds i8, ptr %8, i64 12
  %15 = getelementptr inbounds i8, ptr %8, i64 8
  %16 = getelementptr inbounds i8, ptr %8, i64 4
  %17 = trunc i32 %2 to i16
  br label %18

18:                                               ; preds = %11, %40
  %19 = phi i32 [ 0, %11 ], [ %41, %40 ]
  %20 = phi i16 [ %7, %11 ], [ %21, %40 ]
  %21 = lshr i16 %20, 1
  br i1 %13, label %25, label %22

22:                                               ; preds = %18
  %23 = load i32, ptr %14, align 4, !tbaa !6
  %24 = xor i32 %23, 9
  store i32 %24, ptr %14, align 4, !tbaa !6
  br label %25

25:                                               ; preds = %22, %18
  %26 = zext nneg i16 %21 to i64
  %27 = mul nuw nsw i64 %26, 3
  %28 = zext i32 %19 to i64
  %29 = sub nsw i64 %27, %28
  switch i64 %29, label %40 [
    i64 0, label %30
    i64 3, label %30
    i64 6, label %33
    i64 -1, label %37
  ]

30:                                               ; preds = %25, %25
  %31 = load i32, ptr %8, align 4, !tbaa !6
  %32 = add i32 %31, 2
  store i32 %32, ptr %8, align 4, !tbaa !6
  br label %40

33:                                               ; preds = %25
  %34 = zext nneg i16 %21 to i32
  %35 = load i32, ptr %16, align 4, !tbaa !6
  %36 = add i32 %35, %34
  store i32 %36, ptr %16, align 4, !tbaa !6
  br label %40

37:                                               ; preds = %25
  %38 = load i32, ptr %15, align 4, !tbaa !6
  %39 = xor i32 %38, 5
  store i32 %39, ptr %15, align 4, !tbaa !6
  br label %40

40:                                               ; preds = %25, %37, %33, %30
  %41 = add i32 %19, 1
  %42 = icmp ugt i16 %21, %17
  br i1 %42, label %18, label %43, !llvm.loop !18

43:                                               ; preds = %40, %4
  %44 = phi i32 [ 0, %4 ], [ %41, %40 ]
  %45 = call i32 @cq_measure_ui32(i32 noundef %44) #7
  %46 = shl i32 %45, 12
  %47 = load i32, ptr %8, align 4, !tbaa !6
  %48 = getelementptr inbounds i8, ptr %8, i64 4
  %49 = load i32, ptr %48, align 4, !tbaa !6
  %50 = mul i32 %49, 3
  %51 = add i32 %50, %47
  %52 = getelementptr inbounds i8, ptr %8, i64 8
  %53 = load i32, ptr %52, align 4, !tbaa !6
  %54 = mul i32 %53, 5
  %55 = add i32 %51, %54
  %56 = getelementptr inbounds i8, ptr %8, i64 12
  %57 = load i32, ptr %56, align 4, !tbaa !6
  %58 = mul i32 %57, 7
  %59 = add i32 %55, %58
  %60 = call i32 @cq_measure_ui32(i32 noundef %59) #7
  %61 = add i32 %60, %46
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #7
  ret i32 %61
}

declare zeroext i16 @cq_theta_ui16(i16 noundef zeroext, double noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc range(i32 -1, 3) i32 @sa_put(ptr nocapture noundef writeonly %0, i32 noundef %1) unnamed_addr #6 {
  %3 = icmp ult i32 %1, 128
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = trunc nuw nsw i32 %1 to i8
  store i8 %5, ptr %0, align 1, !tbaa !12
  br label %16

6:                                                ; preds = %2
  %7 = icmp ult i32 %1, 2048
  br i1 %7, label %8, label %16

8:                                                ; preds = %6
  %9 = lshr i32 %1, 6
  %10 = trunc nuw i32 %9 to i8
  %11 = or disjoint i8 %10, -64
  store i8 %11, ptr %0, align 1, !tbaa !12
  %12 = trunc i32 %1 to i8
  %13 = and i8 %12, 63
  %14 = or disjoint i8 %13, -128
  %15 = getelementptr inbounds i8, ptr %0, i64 1
  store i8 %14, ptr %15, align 1, !tbaa !12
  br label %16

16:                                               ; preds = %6, %8, %4
  %17 = phi i32 [ 1, %4 ], [ 2, %8 ], [ -1, %6 ]
  ret i32 %17
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nounwind }
attributes #8 = { nomerge nounwind }

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
!17 = distinct !{!17, !14, !15}
!18 = distinct !{!18, !14, !15}
