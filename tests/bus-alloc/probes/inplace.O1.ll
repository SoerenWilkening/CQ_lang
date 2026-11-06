; ModuleID = 'tests/bus-alloc/probes/inplace.c'
source_filename = "tests/bus-alloc/probes/inplace.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = global [8 x i32] zeroinitializer, align 16

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define void @put(ptr nocapture noundef writeonly %0, i32 noundef %1) local_unnamed_addr #0 {
  store i32 %1, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_read_add(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %5)
  %6 = add nsw i32 %5, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %6)
  %7 = xor i32 %5, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %7)
  %8 = and i32 %1, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %9
  %11 = load i32, ptr %10, align 4, !tbaa !6
  %12 = add nsw i32 %11, %5
  %13 = mul nsw i32 %12, 3
  %14 = and i32 %2, 1
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !6
  store i32 %12, ptr %10, align 4, !tbaa !6
  %18 = xor i32 %13, %17
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #6
  ret i32 %19
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @ip_read_theta(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #1 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %6)
  %7 = add nsw i32 %6, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %7)
  %8 = xor i32 %6, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %8)
  %9 = and i32 %1, 1
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef %4) #5
  %14 = mul nsw i32 %13, 3
  %15 = and i32 %2, 1
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %16
  %18 = load i32, ptr %17, align 4, !tbaa !6
  store i32 %13, ptr %11, align 4, !tbaa !6
  %19 = xor i32 %14, %18
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #6
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_read_theta_nobus(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %5)
  %6 = add nsw i32 %5, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %6)
  %7 = xor i32 %5, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %7)
  %8 = and i32 %1, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %9
  %11 = load i32, ptr %10, align 4, !tbaa !6
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef %3) #5
  %13 = mul nsw i32 %12, 3
  store i32 %12, ptr %10, align 4, !tbaa !6
  %14 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  %15 = xor i32 %14, %13
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #6
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_before_prev(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = add nsw i32 %4, 7
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 12), i32 noundef %7)
  store i32 %4, ptr @g, align 16, !tbaa !6
  %8 = and i32 %1, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %9
  %11 = load i32, ptr %10, align 4, !tbaa !6
  store i32 %7, ptr @g, align 16, !tbaa !6
  %12 = mul nsw i32 %11, 3
  %13 = add nsw i32 %12, %7
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #6
  ret i32 %14
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define void @st(ptr noalias nocapture noundef writeonly %0, ptr noalias nocapture noundef writeonly %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #3 {
  store i32 %2, ptr %0, align 4, !tbaa !6
  store i32 %3, ptr %1, align 4, !tbaa !6
  %5 = add nsw i32 %2, 1
  store i32 %5, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_before_prev_change(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %3)
  %4 = add nsw i32 %3, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %4)
  %5 = xor i32 %3, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %5)
  %6 = add nsw i32 %3, 5
  tail call void @llvm.experimental.noalias.scope.decl(metadata !10)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !13)
  store i32 %3, ptr @g, align 16, !tbaa !6, !alias.scope !10, !noalias !13
  store i32 %6, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6, !alias.scope !13, !noalias !10
  store i32 %4, ptr @g, align 16, !tbaa !6, !alias.scope !10, !noalias !13
  %7 = mul nsw i32 %6, 3
  %8 = add nsw i32 %7, %4
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_change_reader(i32 noundef %0, ptr nocapture noundef writeonly %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  store i32 %4, ptr @g, align 16, !tbaa !6
  store i32 9, ptr %1, align 4, !tbaa !6
  %7 = add nsw i32 %4, 7
  %8 = mul nsw i32 %7, 3
  %9 = getelementptr inbounds i8, ptr %1, i64 4
  store i32 %8, ptr %9, align 4, !tbaa !6
  store i32 %7, ptr @g, align 16, !tbaa !6
  %10 = shl nsw i32 %7, 2
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #6
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_change_reader_d(i32 noundef %0, ptr nocapture noundef writeonly %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  store i32 %4, ptr @g, align 16, !tbaa !6
  store i32 9, ptr %1, align 4, !tbaa !6
  %7 = add nsw i32 %4, 7
  store i32 %7, ptr @g, align 16, !tbaa !6
  %8 = shl nsw i32 %7, 2
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_prev_form_reader(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = load i32, ptr @g, align 16, !tbaa !6
  %8 = add nsw i32 %7, %4
  store i32 %8, ptr @g, align 16, !tbaa !6
  %9 = add nsw i32 %8, 5
  %10 = mul nsw i32 %9, 3
  %11 = and i32 %1, 1
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !6
  store i32 %9, ptr @g, align 16, !tbaa !6
  %15 = xor i32 %14, %10
  %16 = xor i32 %15, %9
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #6
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_loop_k(i32 noundef %0, ptr nocapture noundef writeonly %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = and i32 %4, 3
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %12, label %9

9:                                                ; preds = %3
  %10 = load i32, ptr @g, align 16, !tbaa !6
  %11 = add nsw i32 %10, 1
  br label %15

12:                                               ; preds = %15, %3
  %13 = load i32, ptr @g, align 16, !tbaa !6
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #6
  ret i32 %14

15:                                               ; preds = %9, %15
  %16 = phi i32 [ 0, %9 ], [ %17, %15 ]
  store i32 %11, ptr @g, align 16, !tbaa !6
  store i32 %16, ptr %1, align 4, !tbaa !6
  %17 = add nuw nsw i32 %16, 1
  %18 = icmp eq i32 %17, %7
  br i1 %18, label %12, label %15, !llvm.loop !15
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_loop_classical(i32 noundef %0, i32 noundef %1, ptr nocapture noundef writeonly %2, double noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %5)
  %6 = add nsw i32 %5, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %6)
  %7 = xor i32 %5, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %7)
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %14, label %10

10:                                               ; preds = %4
  %11 = load i32, ptr @g, align 16, !tbaa !6
  %12 = add nsw i32 %11, 1
  %13 = zext nneg i32 %8 to i64
  br label %17

14:                                               ; preds = %17, %4
  %15 = load i32, ptr @g, align 16, !tbaa !6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #6
  ret i32 %16

17:                                               ; preds = %10, %17
  %18 = phi i64 [ 0, %10 ], [ %21, %17 ]
  store i32 %12, ptr @g, align 16, !tbaa !6
  %19 = getelementptr inbounds i32, ptr %2, i64 %18
  %20 = trunc nuw nsw i64 %18 to i32
  store i32 %20, ptr %19, align 4, !tbaa !6
  %21 = add nuw nsw i64 %18, 1
  %22 = icmp eq i64 %21, %13
  br i1 %22, label %14, label %17, !llvm.loop !18
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_loop_classical_i(i32 noundef %0, i32 noundef %1, ptr nocapture noundef writeonly %2, double noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %5)
  %6 = add nsw i32 %5, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %6)
  %7 = xor i32 %5, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %7)
  %8 = and i32 %1, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %13, label %10

10:                                               ; preds = %4
  %11 = load i32, ptr @g, align 16, !tbaa !6
  %12 = zext nneg i32 %8 to i64
  br label %16

13:                                               ; preds = %16, %4
  %14 = load i32, ptr @g, align 16, !tbaa !6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #6
  ret i32 %15

16:                                               ; preds = %10, %16
  %17 = phi i64 [ 0, %10 ], [ %22, %16 ]
  %18 = trunc i64 %17 to i32
  %19 = add i32 %11, %18
  store i32 %19, ptr @g, align 16, !tbaa !6
  %20 = getelementptr inbounds i32, ptr %2, i64 %17
  %21 = trunc nuw nsw i64 %17 to i32
  store i32 %21, ptr %20, align 4, !tbaa !6
  %22 = add nuw nsw i64 %17, 1
  %23 = icmp eq i64 %22, %12
  br i1 %23, label %13, label %16, !llvm.loop !19
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_narrow_prev(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %3)
  %4 = add nsw i32 %3, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %4)
  %5 = xor i32 %3, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %5)
  store i32 %3, ptr @g, align 16, !tbaa !6
  %6 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  %7 = add nsw i32 %3, 5
  %8 = zext i32 %7 to i64
  store i64 %8, ptr @g, align 16, !tbaa !20
  %9 = load i32, ptr @g, align 16, !tbaa !6
  %10 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  %11 = mul nsw i32 %10, 3
  %12 = mul nsw i32 %6, 5
  %13 = add i32 %9, %12
  %14 = add i32 %13, %11
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #6
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_wide_prev(i32 noundef %0, double noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %3)
  %4 = add nsw i32 %3, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %4)
  %5 = xor i32 %3, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %5)
  %6 = zext i32 %3 to i64
  store i64 %6, ptr @g, align 16, !tbaa !20
  %7 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 8), align 8, !tbaa !6
  %8 = add nsw i32 %3, 5
  %9 = zext i32 %8 to i64
  store i64 %9, ptr @g, align 16, !tbaa !20
  %10 = load i32, ptr @g, align 16, !tbaa !6
  %11 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  %12 = mul nsw i32 %11, 3
  %13 = mul nsw i32 %7, 5
  %14 = add i32 %10, %13
  %15 = add i32 %14, %12
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #6
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_wide_prev_change(i32 noundef %0, ptr nocapture noundef writeonly %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = zext i32 %4 to i64
  store i64 %7, ptr @g, align 16, !tbaa !20
  store i32 77, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  store i32 3, ptr %1, align 4, !tbaa !6
  %8 = add nsw i32 %4, 5
  %9 = zext i32 %8 to i64
  store i64 %9, ptr @g, align 16, !tbaa !20
  %10 = load i32, ptr @g, align 16, !tbaa !6
  %11 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  %12 = mul nsw i32 %11, 3
  %13 = add nsw i32 %12, %10
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #6
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_wide_prev_change_q(i32 noundef %0, ptr nocapture noundef writeonly %1, double noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  tail call void @put(ptr noundef nonnull @g, i32 noundef %4)
  %5 = add nsw i32 %4, 1
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 4), i32 noundef %5)
  %6 = xor i32 %4, 5
  tail call void @put(ptr noundef nonnull getelementptr inbounds (i8, ptr @g, i64 8), i32 noundef %6)
  %7 = zext i32 %4 to i64
  store i64 %7, ptr @g, align 16, !tbaa !20
  store i32 77, ptr %1, align 4, !tbaa !6
  %8 = add nsw i32 %4, 5
  %9 = zext i32 %8 to i64
  store i64 %9, ptr @g, align 16, !tbaa !20
  %10 = load i32, ptr @g, align 16, !tbaa !6
  %11 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  %12 = mul nsw i32 %11, 3
  %13 = add nsw i32 %12, %10
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #6
  ret i32 %14
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite)
declare void @llvm.experimental.noalias.scope.decl(metadata) #4

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
!10 = !{!11}
!11 = distinct !{!11, !12, !"st: argument 0"}
!12 = distinct !{!12, !"st"}
!13 = !{!14}
!14 = distinct !{!14, !12, !"st: argument 1"}
!15 = distinct !{!15, !16, !17}
!16 = !{!"llvm.loop.mustprogress"}
!17 = !{!"llvm.loop.unroll.disable"}
!18 = distinct !{!18, !16, !17}
!19 = distinct !{!19, !16, !17}
!20 = !{!21, !21, i64 0}
!21 = !{!"long", !8, i64 0}
