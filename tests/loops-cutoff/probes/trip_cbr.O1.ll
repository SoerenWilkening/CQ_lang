; ModuleID = 'trip_cbr.c'
source_filename = "trip_cbr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@pb_seen = internal unnamed_addr global i32 0, align 4
@pe_tab = internal unnamed_addr constant [4 x i32] [i32 3, i32 5, i32 11, i32 17], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @pa_store(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #8
  store i32 3, ptr %5, align 4, !tbaa !6
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %7 = and i32 %3, 1
  %8 = icmp eq i32 %7, 0
  %9 = select i1 %8, ptr null, ptr %5
  %10 = call fastcc i32 @pa_loop(i32 noundef %6, i32 noundef %2, ptr noundef %9)
  %11 = call i32 @cq_measure_ui32(i32 noundef %10) #8
  %12 = shl nsw i32 %11, 4
  %13 = load i32, ptr %5, align 4, !tbaa !6
  %14 = call i32 @cq_measure_si32(i32 noundef %13) #8
  %15 = add nsw i32 %14, %12
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #8
  ret i32 %15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: write) uwtable
define internal fastcc i32 @pa_loop(i32 noundef %0, i32 noundef %1, ptr noundef writeonly %2) unnamed_addr #3 {
  %4 = icmp ugt i32 %0, %1
  br i1 %4, label %5, label %13

5:                                                ; preds = %3
  %6 = icmp eq ptr %2, null
  br label %7

7:                                                ; preds = %5, %11
  %8 = phi i32 [ %0, %5 ], [ %9, %11 ]
  %9 = lshr i32 %8, 1
  br i1 %6, label %11, label %10

10:                                               ; preds = %7
  store i32 7, ptr %2, align 4, !tbaa !6
  br label %11

11:                                               ; preds = %10, %7
  %12 = icmp ugt i32 %9, %1
  br i1 %12, label %7, label %13, !llvm.loop !10

13:                                               ; preds = %11, %3
  %14 = phi i32 [ %0, %3 ], [ %9, %11 ]
  ret i32 %14
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @pa_update(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #8
  store i32 3, ptr %5, align 4, !tbaa !6
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %7 = and i32 %3, 1
  %8 = icmp eq i32 %7, 0
  %9 = select i1 %8, ptr null, ptr %5
  %10 = call fastcc i32 @pa_loop2(i32 noundef %6, i32 noundef %2, ptr noundef %9)
  %11 = call i32 @cq_measure_ui32(i32 noundef %10) #8
  %12 = shl i32 %11, 6
  %13 = load i32, ptr %5, align 4, !tbaa !6
  %14 = call i32 @cq_measure_ui32(i32 noundef %13) #8
  %15 = add i32 %14, %12
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #8
  ret i32 %15
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define internal fastcc i32 @pa_loop2(i32 noundef %0, i32 noundef %1, ptr noundef %2) unnamed_addr #4 {
  %4 = icmp ugt i32 %0, %1
  br i1 %4, label %5, label %15

5:                                                ; preds = %3
  %6 = icmp eq ptr %2, null
  br label %7

7:                                                ; preds = %5, %13
  %8 = phi i32 [ %0, %5 ], [ %9, %13 ]
  %9 = lshr i32 %8, 1
  br i1 %6, label %13, label %10

10:                                               ; preds = %7
  %11 = load i32, ptr %2, align 4, !tbaa !6
  %12 = add i32 %11, %9
  store i32 %12, ptr %2, align 4, !tbaa !6
  br label %13

13:                                               ; preds = %10, %7
  %14 = icmp ugt i32 %9, %1
  br i1 %14, label %7, label %15, !llvm.loop !13

15:                                               ; preds = %13, %3
  %16 = phi i32 [ %0, %3 ], [ %9, %13 ]
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @pb_call(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  store i32 0, ptr @pb_seen, align 4, !tbaa !6
  %6 = icmp ugt i32 %5, %2
  br i1 %6, label %7, label %21

7:                                                ; preds = %4
  %8 = and i32 %3, 1
  %9 = icmp eq i32 %8, 0
  br label %10

10:                                               ; preds = %7, %18
  %11 = phi i32 [ 1, %7 ], [ %19, %18 ]
  %12 = phi i32 [ %5, %7 ], [ %13, %18 ]
  %13 = lshr i32 %12, 1
  br i1 %9, label %16, label %14

14:                                               ; preds = %10
  %15 = tail call fastcc i32 @pb_note(i32 noundef %11, i32 noundef %13)
  br label %18

16:                                               ; preds = %10
  %17 = xor i32 %11, 9
  br label %18

18:                                               ; preds = %16, %14
  %19 = phi i32 [ %15, %14 ], [ %17, %16 ]
  %20 = icmp ugt i32 %13, %2
  br i1 %20, label %10, label %21, !llvm.loop !14

21:                                               ; preds = %18, %4
  %22 = phi i32 [ 1, %4 ], [ %19, %18 ]
  %23 = tail call i32 @cq_measure_ui32(i32 noundef %22) #8
  %24 = shl i32 %23, 8
  %25 = load i32, ptr @pb_seen, align 4, !tbaa !6
  %26 = tail call i32 @cq_measure_ui32(i32 noundef %25) #8
  %27 = add i32 %26, %24
  ret i32 %27
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc noundef i32 @pb_note(i32 noundef %0, i32 noundef %1) unnamed_addr #5 {
  %3 = add i32 %1, %0
  %4 = load i32, ptr @pb_seen, align 4, !tbaa !6
  %5 = add i32 %3, %4
  store i32 %5, ptr @pb_seen, align 4, !tbaa !6
  %6 = mul i32 %0, 5
  %7 = add i32 %6, %1
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @pc_ctl(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #8
  store i32 1, ptr %6, align 4, !tbaa !6
  %9 = and i32 %8, 1
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %13, label %11

11:                                               ; preds = %5
  %12 = call fastcc i32 @pc_inner(i32 noundef %7, i32 noundef %2, i32 noundef %3, ptr noundef nonnull %6)
  br label %13

13:                                               ; preds = %11, %5
  %14 = phi i32 [ %12, %11 ], [ 9, %5 ]
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #8
  %16 = shl i32 %15, 8
  %17 = load i32, ptr %6, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %17) #8
  %19 = add i32 %18, %16
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #8
  ret i32 %19
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define internal fastcc i32 @pc_inner(i32 noundef %0, i32 noundef %1, i32 noundef %2, ptr nocapture noundef %3) unnamed_addr #4 {
  %5 = icmp ugt i32 %0, %1
  br i1 %5, label %6, label %20

6:                                                ; preds = %4
  %7 = and i32 %2, 2
  %8 = icmp eq i32 %7, 0
  br label %9

9:                                                ; preds = %6, %17
  %10 = phi i32 [ 0, %6 ], [ %18, %17 ]
  %11 = phi i32 [ %0, %6 ], [ %12, %17 ]
  %12 = lshr i32 %11, 1
  br i1 %8, label %17, label %13

13:                                               ; preds = %9
  %14 = add nuw i32 %12, 1
  %15 = load i32, ptr %3, align 4, !tbaa !6
  %16 = add i32 %14, %15
  store i32 %16, ptr %3, align 4, !tbaa !6
  br label %17

17:                                               ; preds = %13, %9
  %18 = add i32 %10, 1
  %19 = icmp ugt i32 %12, %1
  br i1 %19, label %9, label %20, !llvm.loop !15

20:                                               ; preds = %17, %4
  %21 = phi i32 [ 0, %4 ], [ %18, %17 ]
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @pd_trip(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [2 x i32], align 8
  %6 = alloca ptr, align 8
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #8
  store i64 8589934593, ptr %5, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  store volatile ptr %5, ptr %6, align 8, !tbaa !16
  %8 = load volatile ptr, ptr %6, align 8, !tbaa !16
  %9 = icmp ugt i32 %7, %2
  br i1 %9, label %10, label %28

10:                                               ; preds = %4, %25
  %11 = phi i32 [ %13, %25 ], [ %7, %4 ]
  %12 = phi i32 [ %26, %25 ], [ 0, %4 ]
  %13 = lshr i32 %11, 1
  %14 = mul i32 %12, 3
  %15 = add i32 %14, %3
  %16 = and i32 %15, 3
  %17 = icmp eq i32 %16, 1
  br i1 %17, label %18, label %25

18:                                               ; preds = %10
  %19 = add i32 %13, %12
  %20 = and i32 %12, 1
  %21 = zext nneg i32 %20 to i64
  %22 = getelementptr inbounds i32, ptr %8, i64 %21
  %23 = load i32, ptr %22, align 4, !tbaa !6
  %24 = xor i32 %23, %19
  store i32 %24, ptr %22, align 4, !tbaa !6
  br label %25

25:                                               ; preds = %18, %10
  %26 = add i32 %12, 1
  %27 = icmp ugt i32 %13, %2
  br i1 %27, label %10, label %28, !llvm.loop !18

28:                                               ; preds = %25, %4
  %29 = load i32, ptr %8, align 4, !tbaa !6
  %30 = call i32 @cq_measure_ui32(i32 noundef %29) #8
  %31 = shl i32 %30, 6
  %32 = getelementptr inbounds i8, ptr %8, i64 4
  %33 = load i32, ptr %32, align 4, !tbaa !6
  %34 = call i32 @cq_measure_ui32(i32 noundef %33) #8
  %35 = add i32 %34, %31
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #8
  ret i32 %35
}

; Function Attrs: nounwind ssp uwtable
define i32 @pe_twin(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #9
  %8 = tail call fastcc i32 @pe_f(i32 noundef %6, i32 noundef %2, i32 noundef %3)
  %9 = and i32 %8, 1
  %10 = icmp eq i32 %9, 0
  %11 = add i32 %7, 3
  %12 = select i1 %10, i32 %7, i32 %11
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %12) #8
  ret i32 %13
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @pe_f(i32 noundef %0, i32 noundef %1, i32 noundef %2) unnamed_addr #6 {
  %4 = icmp ugt i32 %0, %1
  br i1 %4, label %5, label %26

5:                                                ; preds = %3, %22
  %6 = phi i32 [ %24, %22 ], [ 0, %3 ]
  %7 = phi i32 [ %23, %22 ], [ 0, %3 ]
  %8 = phi i32 [ %9, %22 ], [ %0, %3 ]
  %9 = lshr i32 %8, 1
  %10 = shl nuw i32 1, %6
  %11 = and i32 %10, %2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %20, label %13

13:                                               ; preds = %5
  %14 = and i32 %6, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr @pe_tab, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = xor i32 %17, %9
  %19 = add i32 %18, %7
  br label %22

20:                                               ; preds = %5
  %21 = xor i32 %6, %7
  br label %22

22:                                               ; preds = %20, %13
  %23 = phi i32 [ %19, %13 ], [ %21, %20 ]
  %24 = add i32 %6, 1
  %25 = icmp ugt i32 %9, %1
  br i1 %25, label %5, label %26, !llvm.loop !19

26:                                               ; preds = %22, %3
  %27 = phi i32 [ 0, %3 ], [ %23, %22 ]
  ret i32 %27
}

; Function Attrs: nounwind ssp uwtable
define i32 @pf_nested(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #8
  store i32 0, ptr %6, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  store volatile ptr %6, ptr %7, align 8, !tbaa !16
  %10 = load volatile ptr, ptr %7, align 8, !tbaa !16
  %11 = icmp ugt i32 %8, %2
  br i1 %11, label %12, label %39

12:                                               ; preds = %5
  %13 = and i32 %3, 1
  %14 = icmp eq i32 %13, 0
  %15 = and i32 %3, 2
  %16 = icmp eq i32 %15, 0
  br label %17

17:                                               ; preds = %12, %37
  %18 = phi i32 [ %8, %12 ], [ %20, %37 ]
  %19 = phi i32 [ 0, %12 ], [ %32, %37 ]
  %20 = lshr i32 %18, 1
  br i1 %14, label %31, label %21

21:                                               ; preds = %17
  %22 = load i32, ptr %10, align 4, !tbaa !6
  %23 = xor i32 %22, 5
  store i32 %23, ptr %10, align 4, !tbaa !6
  %24 = icmp ugt i32 %9, %20
  br i1 %24, label %25, label %31

25:                                               ; preds = %21, %25
  %26 = phi i32 [ %28, %25 ], [ %9, %21 ]
  %27 = phi i32 [ %29, %25 ], [ %19, %21 ]
  %28 = lshr i32 %26, 1
  %29 = add i32 %27, 2
  %30 = icmp ugt i32 %28, %20
  br i1 %30, label %25, label %31, !llvm.loop !20

31:                                               ; preds = %25, %21, %17
  %32 = phi i32 [ %19, %17 ], [ %19, %21 ], [ %29, %25 ]
  br i1 %16, label %37, label %33

33:                                               ; preds = %31
  %34 = add i32 %32, 1
  %35 = load i32, ptr %10, align 4, !tbaa !6
  %36 = add i32 %34, %35
  store i32 %36, ptr %10, align 4, !tbaa !6
  br label %37

37:                                               ; preds = %33, %31
  %38 = icmp ugt i32 %20, %2
  br i1 %38, label %17, label %39, !llvm.loop !21

39:                                               ; preds = %37, %5
  %40 = phi i32 [ 0, %5 ], [ %32, %37 ]
  %41 = call i32 @cq_measure_ui32(i32 noundef %40) #8
  %42 = shl i32 %41, 8
  %43 = load i32, ptr %10, align 4, !tbaa !6
  %44 = call i32 @cq_measure_ui32(i32 noundef %43) #8
  %45 = add i32 %44, %42
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #8
  ret i32 %45
}

; Function Attrs: nounwind ssp uwtable
define i32 @pg_abort(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %6 = icmp ugt i32 %5, %2
  br i1 %6, label %7, label %19

7:                                                ; preds = %4
  %8 = icmp eq i32 %3, 77
  br label %9

9:                                                ; preds = %7, %15
  %10 = phi i32 [ 0, %7 ], [ %17, %15 ]
  %11 = phi i32 [ %5, %7 ], [ %16, %15 ]
  %12 = icmp eq i32 %10, 2
  %13 = select i1 %8, i1 %12, i1 false
  br i1 %13, label %14, label %15

14:                                               ; preds = %9
  tail call void @abort() #10
  unreachable

15:                                               ; preds = %9
  %16 = lshr i32 %11, 1
  %17 = add i32 %10, 1
  %18 = icmp ugt i32 %16, %2
  br i1 %18, label %9, label %19, !llvm.loop !22

19:                                               ; preds = %15, %4
  %20 = phi i32 [ 0, %4 ], [ %17, %15 ]
  %21 = tail call i32 @cq_measure_ui32(i32 noundef %20) #8
  ret i32 %21
}

; Function Attrs: noreturn nounwind
declare void @abort() local_unnamed_addr #7

; Function Attrs: nounwind ssp uwtable
define i32 @ph_measure(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #9
  %8 = icmp ugt i32 %6, %2
  br i1 %8, label %9, label %29

9:                                                ; preds = %5
  %10 = and i32 %3, 1
  %11 = icmp eq i32 %10, 0
  %12 = and i32 %7, 3
  %13 = and i32 %3, 4
  %14 = icmp eq i32 %13, 0
  br label %15

15:                                               ; preds = %9, %25
  %16 = phi i32 [ 0, %9 ], [ %23, %25 ]
  %17 = phi i32 [ %6, %9 ], [ %18, %25 ]
  %18 = lshr i32 %17, 1
  br i1 %11, label %22, label %19

19:                                               ; preds = %15
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %12) #8
  %21 = add i32 %20, %16
  br label %22

22:                                               ; preds = %19, %15
  %23 = phi i32 [ %21, %19 ], [ %16, %15 ]
  br i1 %14, label %25, label %24

24:                                               ; preds = %22
  tail call void @cq_phi(double noundef 5.000000e-01) #8
  br label %25

25:                                               ; preds = %24, %22
  %26 = icmp ugt i32 %18, %2
  br i1 %26, label %15, label %27, !llvm.loop !23

27:                                               ; preds = %25
  %28 = shl i32 %23, 4
  br label %29

29:                                               ; preds = %27, %5
  %30 = phi i32 [ 0, %5 ], [ %28, %27 ]
  %31 = tail call i32 @cq_measure_ui32(i32 noundef %7) #8
  %32 = add i32 %31, %30
  ret i32 %32
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { nounwind }
attributes #9 = { nomerge nounwind }
attributes #10 = { noreturn nounwind }

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
!14 = distinct !{!14, !11, !12}
!15 = distinct !{!15, !11, !12}
!16 = !{!17, !17, i64 0}
!17 = !{!"any pointer", !8, i64 0}
!18 = distinct !{!18, !11, !12}
!19 = distinct !{!19, !11, !12}
!20 = distinct !{!20, !11, !12}
!21 = distinct !{!21, !11, !12}
!22 = distinct !{!22, !11, !12}
!23 = distinct !{!23, !11, !12}
