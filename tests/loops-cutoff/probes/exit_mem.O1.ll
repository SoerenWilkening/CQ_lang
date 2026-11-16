; ModuleID = 'exit_mem.c'
source_filename = "exit_mem.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@em_T = local_unnamed_addr global [8 x i32] [i32 3, i32 9, i32 0, i32 7, i32 60, i32 2, i32 5, i32 1], align 16
@em_S = local_unnamed_addr global [8 x i32] zeroinitializer, align 16
@__const.em_ret.w = private unnamed_addr constant [8 x i32] [i32 65, i32 256, i32 66, i32 67, i32 68, i32 69, i32 0, i32 0], align 16
@__const.em_cbr.w = private unnamed_addr constant [8 x i32] [i32 1, i32 2, i32 0, i32 1, i32 144, i32 1, i32 0, i32 0], align 16
@__const.em_tail.w = private unnamed_addr constant [8 x i32] [i32 65, i32 256, i32 66, i32 67, i32 0, i32 69, i32 0, i32 0], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @em_load(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %5 = and i32 %2, 7
  %6 = tail call fastcc i32 @em_load_f(i32 noundef %4, i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #12
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc i32 @em_load_f(i32 noundef %0, i32 noundef %1) unnamed_addr #3 {
  br label %3

3:                                                ; preds = %19, %2
  %4 = phi i32 [ %0, %2 ], [ %20, %19 ]
  %5 = phi i32 [ %1, %2 ], [ %21, %19 ]
  %6 = phi i32 [ undef, %2 ], [ %22, %19 ]
  %7 = icmp eq i32 %5, 0
  br i1 %7, label %24, label %8

8:                                                ; preds = %3
  %9 = and i32 %4, 7
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr @em_T, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %19, label %14

14:                                               ; preds = %8
  %15 = icmp ugt i32 %12, 50
  br i1 %15, label %19, label %16

16:                                               ; preds = %14
  %17 = add i32 %12, %4
  %18 = tail call i32 @llvm.usub.sat.i32(i32 %5, i32 %12)
  br label %19

19:                                               ; preds = %14, %8, %16
  %20 = phi i32 [ %17, %16 ], [ %4, %8 ], [ %4, %14 ]
  %21 = phi i32 [ %18, %16 ], [ %5, %8 ], [ %5, %14 ]
  %22 = phi i32 [ %6, %16 ], [ -1, %8 ], [ 50, %14 ]
  %23 = phi i1 [ true, %16 ], [ false, %8 ], [ false, %14 ]
  br i1 %23, label %3, label %24

24:                                               ; preds = %3, %19
  %25 = phi i32 [ %22, %19 ], [ 7, %3 ]
  ret i32 %25
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @em_store(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %4 = and i32 %3, 255
  %5 = tail call fastcc i32 @em_store_f(i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #12
  %7 = shl nsw i32 %6, 4
  %8 = load i32, ptr getelementptr inbounds (i8, ptr @em_S, i64 4), align 4, !tbaa !6
  %9 = and i32 %8, 15
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #12
  %11 = add i32 %10, %7
  ret i32 %11
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(write, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc i32 @em_store_f(i32 noundef %0) unnamed_addr #4 {
  %2 = icmp eq i32 %0, 0
  br i1 %2, label %19, label %3

3:                                                ; preds = %1, %13
  %4 = phi i32 [ %14, %13 ], [ 0, %1 ]
  %5 = phi i32 [ %15, %13 ], [ %0, %1 ]
  %6 = and i32 %4, 7
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [8 x i32], ptr @em_S, i64 0, i64 %7
  store i32 %5, ptr %8, align 4, !tbaa !6
  %9 = and i32 %5, 3
  %10 = icmp eq i32 %9, 3
  br i1 %10, label %11, label %13

11:                                               ; preds = %3
  %12 = mul nuw nsw i32 %5, 3
  br label %19

13:                                               ; preds = %3
  %14 = add nuw nsw i32 %4, 1
  %15 = lshr i32 %5, 2
  %16 = icmp ult i32 %5, 4
  br i1 %16, label %17, label %3, !llvm.loop !10

17:                                               ; preds = %13
  %18 = xor i32 %4, -1
  br label %19

19:                                               ; preds = %1, %17, %11
  %20 = phi i32 [ %12, %11 ], [ 0, %1 ], [ %18, %17 ]
  ret i32 %20
}

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @em_wcs(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [16 x i8], align 16
  %5 = alloca [8 x i32], align 16
  %6 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #12
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %5) #12
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %5, ptr noundef nonnull align 16 dereferenceable(32) @__const.em_ret.w, i64 32, i1 false)
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %0, ptr %7, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  store i32 %8, ptr %7, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #12
  store ptr %5, ptr %6, align 8, !tbaa !13
  %9 = and i32 %2, 7
  %10 = call fastcc i32 @em_wcs_f(ptr noundef nonnull %4, ptr noundef nonnull %6, i32 noundef %9)
  %11 = call i32 @cq_measure_ui32(i32 noundef %10) #12
  %12 = getelementptr inbounds i8, ptr %4, i64 1
  %13 = load i8, ptr %12, align 1, !tbaa !15
  %14 = call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %13) #12
  %15 = load ptr, ptr %6, align 8, !tbaa !13
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
  %27 = call i32 @cq_measure_ui32(i32 noundef %22) #12
  %28 = add i32 %26, %27
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #12
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %5) #12
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #12
  ret i32 %28
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #5

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #6

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define internal fastcc i32 @em_wcs_f(ptr nocapture noundef writeonly %0, ptr nocapture noundef %1, i32 noundef %2) unnamed_addr #7 {
  %4 = icmp eq i32 %2, 0
  br i1 %4, label %33, label %5

5:                                                ; preds = %3, %27
  %6 = phi ptr [ %29, %27 ], [ %0, %3 ]
  %7 = phi i32 [ %28, %27 ], [ %2, %3 ]
  %8 = load ptr, ptr %1, align 8, !tbaa !13
  %9 = load i32, ptr %8, align 4, !tbaa !6
  %10 = add i32 %9, -128
  %11 = icmp ult i32 %10, -127
  br i1 %11, label %12, label %23

12:                                               ; preds = %5
  %13 = icmp eq i32 %9, 0
  br i1 %13, label %14, label %16

14:                                               ; preds = %12
  store i8 0, ptr %6, align 1, !tbaa !15
  store ptr null, ptr %1, align 8, !tbaa !13
  %15 = sub i32 %2, %7
  br label %33

16:                                               ; preds = %12
  %17 = tail call fastcc i32 @em_put(ptr noundef %6, i32 noundef %9)
  %18 = icmp eq i32 %17, -1
  br i1 %18, label %33, label %19

19:                                               ; preds = %16
  %20 = zext i32 %17 to i64
  %21 = getelementptr inbounds i8, ptr %6, i64 %20
  %22 = sub i32 %7, %17
  br label %27

23:                                               ; preds = %5
  %24 = trunc nuw i32 %9 to i8
  %25 = getelementptr inbounds i8, ptr %6, i64 1
  store i8 %24, ptr %6, align 1, !tbaa !15
  %26 = add i32 %7, -1
  br label %27

27:                                               ; preds = %23, %19
  %28 = phi i32 [ %22, %19 ], [ %26, %23 ]
  %29 = phi ptr [ %21, %19 ], [ %25, %23 ]
  %30 = load ptr, ptr %1, align 8, !tbaa !13
  %31 = getelementptr inbounds i8, ptr %30, i64 4
  store ptr %31, ptr %1, align 8, !tbaa !13
  %32 = icmp eq i32 %28, 0
  br i1 %32, label %33, label %5, !llvm.loop !16

33:                                               ; preds = %16, %27, %3, %14
  %34 = phi i32 [ %15, %14 ], [ %2, %3 ], [ %2, %27 ], [ -1, %16 ]
  ret i32 %34
}

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @em_const(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #12
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %4, ptr noundef nonnull align 16 dereferenceable(32) @__const.em_tail.w, i64 32, i1 false)
  %5 = getelementptr inbounds i8, ptr %4, i64 4
  store i32 %0, ptr %5, align 4, !tbaa !6
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  store i32 %6, ptr %5, align 4, !tbaa !6
  %7 = and i32 %2, 7
  %8 = call fastcc i32 @em_const_f(ptr noundef nonnull %4, i32 noundef %7)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #12
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #12
  ret i32 %9
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define internal fastcc i32 @em_const_f(ptr nocapture noundef readonly %0, i32 noundef %1) unnamed_addr #8 {
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %24, label %4

4:                                                ; preds = %2, %20
  %5 = phi ptr [ %8, %20 ], [ %0, %2 ]
  %6 = phi i32 [ %21, %20 ], [ %1, %2 ]
  %7 = phi i32 [ %22, %20 ], [ undef, %2 ]
  %8 = getelementptr inbounds i8, ptr %5, i64 4
  %9 = load i32, ptr %5, align 4, !tbaa !6
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %20, label %11

11:                                               ; preds = %4
  %12 = icmp ugt i32 %9, 128
  br i1 %12, label %20, label %13

13:                                               ; preds = %11
  %14 = add i32 %6, -1
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %20, label %16

16:                                               ; preds = %13
  %17 = and i32 %9, 1
  %18 = icmp eq i32 %17, 0
  %19 = select i1 %18, i32 %14, i32 %6
  br label %20

20:                                               ; preds = %13, %11, %4, %16
  %21 = phi i32 [ %19, %16 ], [ %6, %4 ], [ %6, %11 ], [ 0, %13 ]
  %22 = phi i32 [ %7, %16 ], [ -1, %4 ], [ 2, %11 ], [ 3, %13 ]
  %23 = phi i1 [ true, %16 ], [ false, %4 ], [ false, %11 ], [ false, %13 ]
  br i1 %23, label %4, label %24

24:                                               ; preds = %20, %2
  %25 = phi i32 [ 9, %2 ], [ %22, %20 ]
  ret i32 %25
}

; Function Attrs: nounwind ssp uwtable
define i32 @em_ret(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [16 x i8], align 16
  %5 = alloca [8 x i32], align 16
  %6 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #12
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %5) #12
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %5, ptr noundef nonnull align 16 dereferenceable(32) @__const.em_ret.w, i64 32, i1 false)
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %0, ptr %7, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  store i32 %8, ptr %7, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #12
  store ptr %5, ptr %6, align 8, !tbaa !13
  %9 = and i32 %2, 7
  %10 = call fastcc i32 @em_ret_f(ptr noundef nonnull %4, ptr noundef nonnull %6, i32 noundef %9)
  %11 = call i32 @cq_measure_ui32(i32 noundef %10) #12
  %12 = shl i32 %11, 12
  %13 = getelementptr inbounds i8, ptr %4, i64 1
  %14 = load i8, ptr %13, align 1, !tbaa !15
  %15 = call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %14) #12
  %16 = zext i8 %15 to i32
  %17 = shl nuw nsw i32 %16, 4
  %18 = or disjoint i32 %17, %12
  %19 = load ptr, ptr %6, align 8, !tbaa !13
  %20 = ptrtoint ptr %19 to i64
  %21 = ptrtoint ptr %5 to i64
  %22 = sub i64 %20, %21
  %23 = lshr exact i64 %22, 2
  %24 = trunc i64 %23 to i32
  %25 = call i32 @cq_measure_ui32(i32 noundef %24) #12
  %26 = add i32 %18, %25
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #12
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %5) #12
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #12
  ret i32 %26
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define internal fastcc range(i32 -1, 8) i32 @em_ret_f(ptr nocapture noundef writeonly %0, ptr nocapture noundef %1, i32 noundef %2) unnamed_addr #7 {
  %4 = icmp eq i32 %2, 0
  br i1 %4, label %29, label %5

5:                                                ; preds = %3, %23
  %6 = phi ptr [ %25, %23 ], [ %0, %3 ]
  %7 = phi i32 [ %24, %23 ], [ %2, %3 ]
  %8 = load ptr, ptr %1, align 8, !tbaa !13
  %9 = load i32, ptr %8, align 4, !tbaa !6
  %10 = add i32 %9, -128
  %11 = icmp ult i32 %10, -127
  br i1 %11, label %12, label %19

12:                                               ; preds = %5
  %13 = tail call fastcc i32 @em_put(ptr noundef %6, i32 noundef %9)
  %14 = icmp eq i32 %13, -1
  br i1 %14, label %29, label %15

15:                                               ; preds = %12
  %16 = zext nneg i32 %13 to i64
  %17 = getelementptr inbounds i8, ptr %6, i64 %16
  %18 = sub i32 %7, %13
  br label %23

19:                                               ; preds = %5
  %20 = trunc nuw i32 %9 to i8
  %21 = getelementptr inbounds i8, ptr %6, i64 1
  store i8 %20, ptr %6, align 1, !tbaa !15
  %22 = add i32 %7, -1
  br label %23

23:                                               ; preds = %19, %15
  %24 = phi i32 [ %18, %15 ], [ %22, %19 ]
  %25 = phi ptr [ %17, %15 ], [ %21, %19 ]
  %26 = load ptr, ptr %1, align 8, !tbaa !13
  %27 = getelementptr inbounds i8, ptr %26, i64 4
  store ptr %27, ptr %1, align 8, !tbaa !13
  %28 = icmp eq i32 %24, 0
  br i1 %28, label %29, label %5, !llvm.loop !17

29:                                               ; preds = %12, %23, %3
  %30 = phi i32 [ %2, %3 ], [ -1, %12 ], [ %2, %23 ]
  ret i32 %30
}

; Function Attrs: nounwind ssp uwtable
define i32 @em_cbr(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %5) #12
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %5, ptr noundef nonnull align 16 dereferenceable(32) @__const.em_cbr.w, i64 32, i1 false)
  %6 = and i32 %0, 255
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %6, ptr %7, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %6, double noundef %1) #11
  store i32 %8, ptr %7, align 4, !tbaa !6
  %9 = and i32 %2, 7
  %10 = and i32 %3, 1
  %11 = call fastcc i32 @em_cbr_f(ptr noundef nonnull %5, i32 noundef %9, i32 noundef %10)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #12
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %5) #12
  ret i32 %12
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define internal fastcc i32 @em_cbr_f(ptr nocapture noundef readonly %0, i32 noundef %1, i32 noundef %2) unnamed_addr #8 {
  %4 = icmp ne i32 %2, 0
  br label %5

5:                                                ; preds = %21, %3
  %6 = phi i32 [ %1, %3 ], [ %22, %21 ]
  %7 = phi ptr [ %0, %3 ], [ %11, %21 ]
  %8 = phi i32 [ undef, %3 ], [ %23, %21 ]
  %9 = icmp eq i32 %6, 0
  br i1 %9, label %25, label %10

10:                                               ; preds = %5
  %11 = getelementptr inbounds i8, ptr %7, i64 4
  %12 = load i32, ptr %7, align 4, !tbaa !6
  %13 = icmp eq i32 %12, 0
  %14 = select i1 %4, i1 %13, i1 false
  br i1 %14, label %21, label %15

15:                                               ; preds = %10
  %16 = icmp ugt i32 %12, 128
  br i1 %16, label %17, label %19

17:                                               ; preds = %15
  %18 = sub i32 %1, %6
  br label %21

19:                                               ; preds = %15
  %20 = tail call i32 @llvm.usub.sat.i32(i32 %6, i32 %12)
  br label %21

21:                                               ; preds = %10, %19, %17
  %22 = phi i32 [ %6, %17 ], [ %20, %19 ], [ %6, %10 ]
  %23 = phi i32 [ %18, %17 ], [ %8, %19 ], [ -1, %10 ]
  %24 = phi i1 [ false, %17 ], [ true, %19 ], [ false, %10 ]
  br i1 %24, label %5, label %25, !llvm.loop !18

25:                                               ; preds = %5, %21
  %26 = phi i32 [ %23, %21 ], [ %1, %5 ]
  ret i32 %26
}

; Function Attrs: nounwind ssp uwtable
define i32 @em_top(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %5 = and i32 %2, 31
  %6 = tail call fastcc i32 @em_top_f(i32 noundef %4, i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #12
  ret i32 %7
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc range(i32 -1, 132) i32 @em_top_f(i32 noundef %0, i32 noundef %1) unnamed_addr #3 {
  br label %3

3:                                                ; preds = %13, %2
  %4 = phi i32 [ %0, %2 ], [ %15, %13 ]
  %5 = phi i32 [ 0, %2 ], [ %14, %13 ]
  %6 = and i32 %4, 7
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [8 x i32], ptr @em_T, i64 0, i64 %7
  %9 = load i32, ptr %8, align 4, !tbaa !6
  %10 = icmp ult i32 %9, 50
  br i1 %10, label %11, label %17

11:                                               ; preds = %3
  %12 = icmp eq i32 %9, 0
  br i1 %12, label %19, label %13

13:                                               ; preds = %11
  %14 = add nuw nsw i32 %9, %5
  %15 = add i32 %4, 3
  %16 = icmp ugt i32 %14, %1
  br i1 %16, label %19, label %3, !llvm.loop !19

17:                                               ; preds = %3
  %18 = add nuw nsw i32 %5, 100
  br label %19

19:                                               ; preds = %13, %11, %17
  %20 = phi i32 [ %18, %17 ], [ -1, %11 ], [ %14, %13 ]
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @em_tail(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [16 x i8], align 16
  %5 = alloca [8 x i32], align 16
  %6 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #12
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %5) #12
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %5, ptr noundef nonnull align 16 dereferenceable(32) @__const.em_tail.w, i64 32, i1 false)
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %0, ptr %7, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  store i32 %8, ptr %7, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #12
  store ptr %5, ptr %6, align 8, !tbaa !13
  %9 = and i32 %8, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %14, label %11

11:                                               ; preds = %3
  %12 = and i32 %2, 7
  %13 = call fastcc i32 @em_wcs_f(ptr noundef nonnull %4, ptr noundef nonnull %6, i32 noundef %12)
  br label %14

14:                                               ; preds = %11, %3
  %15 = phi i32 [ %13, %11 ], [ 5, %3 ]
  %16 = call i32 @cq_measure_ui32(i32 noundef %15) #12
  %17 = shl i32 %16, 4
  %18 = getelementptr inbounds i8, ptr %4, i64 1
  %19 = load i8, ptr %18, align 1, !tbaa !15
  %20 = call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %19) #12
  %21 = zext i8 %20 to i32
  %22 = add i32 %17, %21
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #12
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %5) #12
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #12
  ret i32 %22
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc range(i32 -1, 3) i32 @em_put(ptr nocapture noundef writeonly %0, i32 noundef %1) unnamed_addr #9 {
  %3 = icmp ult i32 %1, 128
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = trunc nuw nsw i32 %1 to i8
  store i8 %5, ptr %0, align 1, !tbaa !15
  br label %16

6:                                                ; preds = %2
  %7 = icmp ult i32 %1, 2048
  br i1 %7, label %8, label %16

8:                                                ; preds = %6
  %9 = lshr i32 %1, 6
  %10 = trunc nuw i32 %9 to i8
  %11 = or disjoint i8 %10, -64
  store i8 %11, ptr %0, align 1, !tbaa !15
  %12 = trunc i32 %1 to i8
  %13 = and i8 %12, 63
  %14 = or disjoint i8 %13, -128
  %15 = getelementptr inbounds i8, ptr %0, i64 1
  store i8 %14, ptr %15, align 1, !tbaa !15
  br label %16

16:                                               ; preds = %6, %8, %4
  %17 = phi i32 [ 1, %4 ], [ 2, %8 ], [ -1, %6 ]
  ret i32 %17
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.usub.sat.i32(i32, i32) #10

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(read, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree noinline norecurse nosync nounwind ssp memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #6 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #9 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #10 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #11 = { nomerge nounwind }
attributes #12 = { nounwind }

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
!13 = !{!14, !14, i64 0}
!14 = !{!"any pointer", !8, i64 0}
!15 = !{!8, !8, i64 0}
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !11, !12}
!18 = distinct !{!18, !11, !12}
!19 = distinct !{!19, !11, !12}
