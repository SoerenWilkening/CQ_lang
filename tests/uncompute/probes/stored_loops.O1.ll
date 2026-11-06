; ModuleID = 'stored_loops.c'
source_filename = "stored_loops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = global [8 x i32] zeroinitializer, align 16

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define void @put(ptr nocapture noundef writeonly %0, i32 noundef %1) local_unnamed_addr #0 {
  store i32 %1, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_each(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = load i32, ptr @g, align 16, !tbaa !6
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %15

10:                                               ; preds = %15, %3
  %11 = phi i32 [ %7, %3 ], [ %18, %15 ]
  %12 = load i32, ptr @g, align 16, !tbaa !6
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  ret i32 %14

15:                                               ; preds = %3, %15
  %16 = phi i32 [ %22, %15 ], [ 0, %3 ]
  %17 = phi i32 [ %18, %15 ], [ %7, %3 ]
  %18 = add nsw i32 %17, %4
  %19 = and i32 %16, 1
  %20 = zext nneg i32 %19 to i64
  %21 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %20
  store i32 %18, ptr %21, align 4, !tbaa !6
  %22 = add nuw nsw i32 %16, 1
  %23 = icmp eq i32 %22, %8
  br i1 %23, label %10, label %15, !llvm.loop !10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @sl_each_rot(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %5)
  %6 = add nsw i32 %5, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %6)
  %7 = xor i32 %5, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %7)
  %8 = load i32, ptr @g, align 16, !tbaa !6
  %9 = and i32 %1, 3
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %17

11:                                               ; preds = %17, %4
  %12 = phi i32 [ %8, %4 ], [ %20, %17 ]
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef %3) #3
  %14 = load i32, ptr @g, align 16, !tbaa !6
  %15 = add nsw i32 %14, %13
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #4
  ret i32 %16

17:                                               ; preds = %4, %17
  %18 = phi i32 [ %20, %17 ], [ %8, %4 ]
  %19 = phi i32 [ %24, %17 ], [ 0, %4 ]
  %20 = add nsw i32 %18, %5
  %21 = and i32 %19, 1
  %22 = zext nneg i32 %21 to i64
  %23 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %22
  store i32 %20, ptr %23, align 4, !tbaa !6
  %24 = add nuw nsw i32 %19, 1
  %25 = icmp eq i32 %24, %9
  br i1 %25, label %11, label %17, !llvm.loop !13
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_each_meas(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = load i32, ptr @g, align 16, !tbaa !6
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %13

10:                                               ; preds = %13, %3
  %11 = phi i32 [ %7, %3 ], [ %16, %13 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  ret i32 %12

13:                                               ; preds = %3, %13
  %14 = phi i32 [ %20, %13 ], [ 0, %3 ]
  %15 = phi i32 [ %16, %13 ], [ %7, %3 ]
  %16 = mul nsw i32 %15, %4
  %17 = and i32 %14, 1
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %18
  store i32 %16, ptr %19, align 4, !tbaa !6
  %20 = add nuw nsw i32 %14, 1
  %21 = icmp eq i32 %20, %8
  br i1 %21, label %10, label %13, !llvm.loop !14
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_phi(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = mul nsw i32 %4, 3
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %15

10:                                               ; preds = %15, %3
  %11 = phi i32 [ %7, %3 ], [ %21, %15 ]
  %12 = load i32, ptr @g, align 16, !tbaa !6
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  ret i32 %14

15:                                               ; preds = %3, %15
  %16 = phi i32 [ %22, %15 ], [ 0, %3 ]
  %17 = phi i32 [ %21, %15 ], [ %7, %3 ]
  %18 = and i32 %16, 1
  %19 = zext nneg i32 %18 to i64
  %20 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %19
  store i32 %17, ptr %20, align 4, !tbaa !6
  %21 = mul nsw i32 %17, %4
  %22 = add nuw nsw i32 %16, 1
  %23 = icmp eq i32 %22, %8
  br i1 %23, label %10, label %15, !llvm.loop !15
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_walk(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %3)
  %4 = add nsw i32 %3, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %4)
  %5 = xor i32 %3, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %5)
  %6 = and i32 %3, 1
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds i32, ptr @g, i64 %7
  br label %13

9:                                                ; preds = %13
  %10 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %11 = add nsw i32 %10, %19
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  ret i32 %12

13:                                               ; preds = %2, %13
  %14 = phi i32 [ 0, %2 ], [ %20, %13 ]
  %15 = phi i32 [ 0, %2 ], [ %19, %13 ]
  %16 = phi ptr [ %8, %2 ], [ %17, %13 ]
  %17 = getelementptr inbounds i8, ptr %16, i64 4
  %18 = load i32, ptr %16, align 4, !tbaa !6
  %19 = add nsw i32 %18, %15
  store i32 %19, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %20 = add nuw nsw i32 %14, 1
  %21 = icmp eq i32 %20, 3
  br i1 %21, label %9, label %13, !llvm.loop !16
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_before(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = add nsw i32 %4, 3
  %8 = and i32 %1, 1
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %11, label %10

10:                                               ; preds = %3
  store i32 %7, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  br label %11

11:                                               ; preds = %10, %3
  %12 = and i32 %1, 3
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %21

14:                                               ; preds = %21, %11
  %15 = phi i32 [ 0, %11 ], [ %28, %21 ]
  %16 = mul nsw i32 %7, 5
  %17 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %18 = add i32 %15, %16
  %19 = add i32 %18, %17
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  ret i32 %20

21:                                               ; preds = %11, %21
  %22 = phi i32 [ %29, %21 ], [ 0, %11 ]
  %23 = phi i32 [ %28, %21 ], [ 0, %11 ]
  %24 = and i32 %22, 1
  %25 = zext nneg i32 %24 to i64
  %26 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %25
  %27 = load i32, ptr %26, align 4, !tbaa !6
  %28 = add nsw i32 %27, %23
  %29 = add nuw nsw i32 %22, 1
  %30 = icmp eq i32 %29, %12
  br i1 %30, label %14, label %21, !llvm.loop !17
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_after(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = mul nsw i32 %4, 3
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %14

10:                                               ; preds = %14, %3
  %11 = phi i32 [ 0, %3 ], [ %21, %14 ]
  %12 = and i32 %1, 4
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %25, label %24

14:                                               ; preds = %3, %14
  %15 = phi i32 [ %22, %14 ], [ 0, %3 ]
  %16 = phi i32 [ %21, %14 ], [ 0, %3 ]
  %17 = and i32 %15, 1
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !6
  %21 = add nsw i32 %20, %16
  %22 = add nuw nsw i32 %15, 1
  %23 = icmp eq i32 %22, %8
  br i1 %23, label %10, label %14, !llvm.loop !18

24:                                               ; preds = %10
  store i32 %7, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  br label %25

25:                                               ; preds = %24, %10
  %26 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %27 = add nsw i32 %26, %11
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #4
  ret i32 %28
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_in(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = mul nsw i32 %4, 3
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %13

10:                                               ; preds = %17, %3
  %11 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  ret i32 %12

13:                                               ; preds = %3, %17
  %14 = phi i32 [ %18, %17 ], [ 0, %3 ]
  %15 = icmp eq i32 %14, 1
  br i1 %15, label %16, label %17

16:                                               ; preds = %13
  store i32 %7, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  br label %17

17:                                               ; preds = %13, %16
  %18 = add nuw nsw i32 %14, 1
  %19 = icmp eq i32 %18, %8
  br i1 %19, label %10, label %13, !llvm.loop !19
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_guard(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = mul nsw i32 %4, 3
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %13

10:                                               ; preds = %13, %3
  %11 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  ret i32 %12

13:                                               ; preds = %3, %13
  %14 = phi i32 [ %18, %13 ], [ 0, %3 ]
  %15 = and i32 %14, 1
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %16
  store i32 %7, ptr %17, align 4, !tbaa !6
  %18 = add nuw nsw i32 %14, 1
  %19 = icmp eq i32 %18, %8
  br i1 %19, label %10, label %13, !llvm.loop !20
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_trip(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = and i32 %1, 3
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %14

9:                                                ; preds = %23, %3
  %10 = phi i32 [ 0, %3 ], [ %19, %23 ]
  %11 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %12 = add nsw i32 %11, %10
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  ret i32 %13

14:                                               ; preds = %3, %23
  %15 = phi i32 [ %19, %23 ], [ 0, %3 ]
  %16 = phi i32 [ %24, %23 ], [ 0, %3 ]
  %17 = add nuw nsw i32 %16, 3
  %18 = mul nsw i32 %17, %4
  %19 = xor i32 %18, %15
  %20 = and i32 %16, 1
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %23, label %22

22:                                               ; preds = %14
  store i32 %18, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  br label %23

23:                                               ; preds = %22, %14
  %24 = add nuw nsw i32 %16, 1
  %25 = icmp eq i32 %24, %7
  br i1 %25, label %9, label %14, !llvm.loop !21
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_acc(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = load i32, ptr @g, align 16, !tbaa !6
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %15

10:                                               ; preds = %22, %3
  %11 = phi i32 [ %7, %3 ], [ %18, %22 ]
  %12 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  ret i32 %14

15:                                               ; preds = %3, %22
  %16 = phi i32 [ %23, %22 ], [ 0, %3 ]
  %17 = phi i32 [ %18, %22 ], [ %7, %3 ]
  %18 = mul nsw i32 %17, %4
  %19 = and i32 %16, 1
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %22, label %21

21:                                               ; preds = %15
  store i32 %18, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  br label %22

22:                                               ; preds = %15, %21
  %23 = add nuw nsw i32 %16, 1
  %24 = icmp eq i32 %23, %8
  br i1 %24, label %10, label %15, !llvm.loop !22
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_phi_some(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = mul nsw i32 %4, 3
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %15

10:                                               ; preds = %21, %3
  %11 = phi i32 [ %7, %3 ], [ %22, %21 ]
  %12 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  ret i32 %14

15:                                               ; preds = %3, %21
  %16 = phi i32 [ %23, %21 ], [ 0, %3 ]
  %17 = phi i32 [ %22, %21 ], [ %7, %3 ]
  %18 = and i32 %16, 1
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %21, label %20

20:                                               ; preds = %15
  store i32 %17, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  br label %21

21:                                               ; preds = %20, %15
  %22 = mul nsw i32 %17, %4
  %23 = add nuw nsw i32 %16, 1
  %24 = icmp eq i32 %23, %8
  br i1 %24, label %10, label %15, !llvm.loop !23
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_kloop(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = and i32 %4, 3
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %12, label %9

9:                                                ; preds = %3
  %10 = and i32 %1, 1
  %11 = icmp eq i32 %10, 0
  br label %17

12:                                               ; preds = %24, %3
  %13 = phi i32 [ 0, %3 ], [ %22, %24 ]
  %14 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %15 = add nsw i32 %14, %13
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #4
  ret i32 %16

17:                                               ; preds = %9, %24
  %18 = phi i32 [ 0, %9 ], [ %22, %24 ]
  %19 = phi i32 [ 0, %9 ], [ %25, %24 ]
  %20 = add nuw nsw i32 %19, 2
  %21 = mul nsw i32 %20, %4
  %22 = xor i32 %21, %18
  br i1 %11, label %24, label %23

23:                                               ; preds = %17
  store i32 %21, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  br label %24

24:                                               ; preds = %23, %17
  %25 = add nuw nsw i32 %19, 1
  %26 = icmp eq i32 %25, %7
  br i1 %26, label %12, label %17, !llvm.loop !24
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_arm(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = and i32 %1, 3
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %14

9:                                                ; preds = %27, %3
  %10 = phi i32 [ 0, %3 ], [ %28, %27 ]
  %11 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %12 = add nsw i32 %11, %10
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  ret i32 %13

14:                                               ; preds = %3, %27
  %15 = phi i32 [ %28, %27 ], [ 0, %3 ]
  %16 = phi i32 [ %29, %27 ], [ 0, %3 ]
  %17 = shl nuw nsw i32 1, %16
  %18 = and i32 %17, %4
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %27, label %20

20:                                               ; preds = %14
  %21 = add nuw nsw i32 %16, 3
  %22 = mul nsw i32 %21, %4
  %23 = xor i32 %22, %15
  %24 = and i32 %16, 1
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %27, label %26

26:                                               ; preds = %20
  store i32 %22, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  br label %27

27:                                               ; preds = %20, %26, %14
  %28 = phi i32 [ %15, %14 ], [ %23, %26 ], [ %23, %20 ]
  %29 = add nuw nsw i32 %16, 1
  %30 = icmp eq i32 %29, %7
  br i1 %30, label %9, label %14, !llvm.loop !25
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_exit(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %3)
  %4 = add nsw i32 %3, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %4)
  %5 = xor i32 %3, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %5)
  %6 = mul nsw i32 %3, 3
  br label %11

7:                                                ; preds = %11
  store i32 %17, ptr getelementptr inbounds (i8, ptr @g, i64 8), align 8, !tbaa !6
  %8 = load i32, ptr @g, align 16, !tbaa !6
  %9 = add nsw i32 %8, %17
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  ret i32 %10

11:                                               ; preds = %2, %11
  %12 = phi i64 [ 0, %2 ], [ %18, %11 ]
  %13 = phi i32 [ %6, %2 ], [ %17, %11 ]
  %14 = ashr i32 %13, 2
  %15 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %12
  store i32 %14, ptr %15, align 4, !tbaa !6
  %16 = sub nsw i32 %13, %14
  %17 = mul nsw i32 %16, 5
  %18 = add nuw nsw i64 %12, 1
  %19 = icmp eq i64 %12, 0
  br i1 %19, label %11, label %7, !llvm.loop !26
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_exit_zero(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = mul nsw i32 %4, 3
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %13

10:                                               ; preds = %13, %3
  %11 = phi i32 [ %7, %3 ], [ %17, %13 ]
  store i32 %11, ptr getelementptr inbounds (i8, ptr @g, i64 16), align 16, !tbaa !6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  ret i32 %12

13:                                               ; preds = %3, %13
  %14 = phi i32 [ %18, %13 ], [ 0, %3 ]
  %15 = phi i32 [ %17, %13 ], [ %7, %3 ]
  %16 = add nsw i32 %14, %15
  %17 = mul nsw i32 %16, %4
  %18 = add nuw nsw i32 %14, 1
  %19 = icmp eq i32 %18, %8
  br i1 %19, label %10, label %13, !llvm.loop !27
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_exit_both(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %3)
  %4 = add nsw i32 %3, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %4)
  %5 = xor i32 %3, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %5)
  %6 = mul nsw i32 %3, 3
  br label %11

7:                                                ; preds = %11
  store i32 %16, ptr getelementptr inbounds (i8, ptr @g, i64 8), align 8, !tbaa !6
  %8 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 16), align 16, !tbaa !6
  %9 = add nsw i32 %8, %16
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  ret i32 %10

11:                                               ; preds = %2, %11
  %12 = phi i64 [ 0, %2 ], [ %20, %11 ]
  %13 = phi i32 [ %6, %2 ], [ %16, %11 ]
  %14 = trunc nuw nsw i64 %12 to i32
  %15 = add nsw i32 %13, %14
  %16 = mul nsw i32 %15, %3
  %17 = shl nuw nsw i64 %12, 1
  %18 = add nuw nsw i64 %17, 4
  %19 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %18
  store i32 %16, ptr %19, align 8, !tbaa !6
  %20 = add nuw nsw i64 %12, 1
  %21 = icmp eq i64 %12, 0
  br i1 %21, label %11, label %7, !llvm.loop !28
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_exit_twice(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %3)
  %4 = add nsw i32 %3, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %4)
  %5 = xor i32 %3, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %5)
  %6 = mul nsw i32 %3, 3
  br label %10

7:                                                ; preds = %10
  store i32 %14, ptr getelementptr inbounds (i8, ptr @g, i64 16), align 16, !tbaa !6
  store i32 %14, ptr getelementptr inbounds (i8, ptr @g, i64 24), align 8, !tbaa !6
  %8 = shl nsw i32 %14, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  ret i32 %9

10:                                               ; preds = %2, %10
  %11 = phi i32 [ 0, %2 ], [ %15, %10 ]
  %12 = phi i32 [ %6, %2 ], [ %14, %10 ]
  %13 = add nsw i32 %11, %12
  %14 = mul nsw i32 %13, %3
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %11, 0
  br i1 %16, label %10, label %7, !llvm.loop !29
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_exit_nested(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %3)
  %4 = add nsw i32 %3, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %4)
  %5 = xor i32 %3, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %5)
  br label %10

6:                                                ; preds = %15
  %7 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 16), align 16, !tbaa !6
  %8 = add nsw i32 %7, %19
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  ret i32 %9

10:                                               ; preds = %2, %15
  %11 = phi i64 [ 0, %2 ], [ %20, %15 ]
  %12 = phi i32 [ 0, %2 ], [ %19, %15 ]
  %13 = trunc i64 %11 to i32
  %14 = add i32 %3, %13
  br label %22

15:                                               ; preds = %22
  %16 = shl nuw nsw i64 %11, 1
  %17 = add nuw nsw i64 %16, 4
  %18 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %17
  store i32 %26, ptr %18, align 8, !tbaa !6
  %19 = xor i32 %26, %12
  %20 = add nuw nsw i64 %11, 1
  %21 = icmp eq i64 %11, 0
  br i1 %21, label %10, label %6, !llvm.loop !30

22:                                               ; preds = %10, %22
  %23 = phi i32 [ 0, %10 ], [ %27, %22 ]
  %24 = phi i32 [ %14, %10 ], [ %26, %22 ]
  %25 = add nsw i32 %23, %24
  %26 = mul nsw i32 %25, %3
  %27 = add nuw nsw i32 %23, 1
  %28 = icmp eq i32 %23, 0
  br i1 %28, label %22, label %15, !llvm.loop !31
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_exit_kloop(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %3)
  %4 = add nsw i32 %3, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %4)
  %5 = xor i32 %3, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %5)
  %6 = mul nsw i32 %3, 3
  %7 = and i32 %3, 3
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %12

9:                                                ; preds = %12, %2
  %10 = phi i32 [ %6, %2 ], [ %16, %12 ]
  store i32 %10, ptr getelementptr inbounds (i8, ptr @g, i64 16), align 16, !tbaa !6
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  ret i32 %11

12:                                               ; preds = %2, %12
  %13 = phi i32 [ %17, %12 ], [ 0, %2 ]
  %14 = phi i32 [ %16, %12 ], [ %6, %2 ]
  %15 = add nsw i32 %13, %14
  %16 = mul nsw i32 %15, %3
  %17 = add nuw nsw i32 %13, 1
  %18 = icmp eq i32 %17, %7
  br i1 %18, label %9, label %12, !llvm.loop !32
}

; Function Attrs: nounwind ssp uwtable
define i32 @sl_arm_false(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = and i32 %1, 3
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %14

9:                                                ; preds = %29, %3
  %10 = phi i32 [ 0, %3 ], [ %30, %29 ]
  %11 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  %12 = add nsw i32 %11, %10
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  ret i32 %13

14:                                               ; preds = %3, %29
  %15 = phi i32 [ %30, %29 ], [ 0, %3 ]
  %16 = phi i32 [ %31, %29 ], [ 0, %3 ]
  %17 = shl nuw nsw i32 1, %16
  %18 = and i32 %17, %4
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %27

20:                                               ; preds = %14
  %21 = add nuw nsw i32 %16, 3
  %22 = mul nsw i32 %21, %4
  %23 = xor i32 %22, %15
  %24 = and i32 %16, 1
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %29, label %26

26:                                               ; preds = %20
  store i32 %22, ptr getelementptr inbounds (i8, ptr @g, i64 12), align 4, !tbaa !6
  br label %29

27:                                               ; preds = %14
  %28 = add nsw i32 %15, %4
  br label %29

29:                                               ; preds = %20, %26, %27
  %30 = phi i32 [ %28, %27 ], [ %23, %26 ], [ %23, %20 ]
  %31 = add nuw nsw i32 %16, 1
  %32 = icmp eq i32 %31, %7
  br i1 %32, label %9, label %14, !llvm.loop !33
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !11, !12}
!18 = distinct !{!18, !11, !12}
!19 = distinct !{!19, !11, !12}
!20 = distinct !{!20, !11, !12}
!21 = distinct !{!21, !11, !12}
!22 = distinct !{!22, !11, !12}
!23 = distinct !{!23, !11, !12}
!24 = distinct !{!24, !11, !12}
!25 = distinct !{!25, !11, !12}
!26 = distinct !{!26, !11, !12}
!27 = distinct !{!27, !11, !12}
!28 = distinct !{!28, !11, !12}
!29 = distinct !{!29, !11, !12}
!30 = distinct !{!30, !11, !12}
!31 = distinct !{!31, !11, !12}
!32 = distinct !{!32, !11, !12}
!33 = distinct !{!33, !11, !12}
