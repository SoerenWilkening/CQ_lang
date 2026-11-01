; ModuleID = 'fatptr.c'
source_filename = "fatptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.tri = type { i32, i32, i32 }

@G = global [8 x i32] zeroinitializer, align 16
@H = global [8 x i32] zeroinitializer, align 16
@QA = internal unnamed_addr constant [300 x i32] [i32 3, i32 0, i32 0, i32 0, i32 0, i32 0, i32 6, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 100, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 255, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 262, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 299], align 16
@QB = internal unnamed_addr constant [300 x i32] [i32 5, i32 0, i32 0, i32 0, i32 0, i32 0, i32 60, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 1000, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 2550, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 2620, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 2990], align 16
@__const.f_ptr_roundtrip.b = private unnamed_addr constant [4 x i32] [i32 10, i32 11, i32 12, i32 13], align 16
@__const.f_ptr_roundtrip.c = private unnamed_addr constant [4 x i32] [i32 20, i32 21, i32 22, i32 23], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @f_ne_two(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, ptr %4, ptr %3
  %9 = lshr i32 %5, 1
  %10 = and i32 %9, 3
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds i32, ptr %8, i64 %11
  %13 = lshr i32 %5, 3
  %14 = and i32 %13, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %4, i64 %15
  %17 = icmp ne ptr %12, %16
  %18 = zext i1 %17 to i32
  %19 = call i32 @cq_measure_si32(i32 noundef %18) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #10
  ret i32 %19
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @f_eq_three(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [4 x i32], align 16
  %5 = alloca [4 x i32], align 16
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, i8 0, i64 16, i1 false)
  %7 = and i32 %6, 1
  %8 = icmp eq i32 %7, 0
  %9 = and i32 %6, 2
  %10 = icmp eq i32 %9, 0
  %11 = select i1 %10, ptr %5, ptr %4
  %12 = select i1 %8, ptr %11, ptr %3
  %13 = lshr i32 %6, 2
  %14 = and i32 %13, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %12, i64 %15
  %17 = and i32 %6, 16
  %18 = icmp eq i32 %17, 0
  %19 = select i1 %18, ptr %3, ptr %5
  %20 = lshr i32 %6, 5
  %21 = and i32 %20, 3
  %22 = zext nneg i32 %21 to i64
  %23 = getelementptr inbounds i32, ptr %19, i64 %22
  %24 = icmp eq ptr %16, %23
  %25 = zext i1 %24 to i32
  %26 = call i32 @cq_measure_si32(i32 noundef %25) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #10
  ret i32 %26
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_eq_arms(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = lshr i32 %5, 1
  %9 = and i32 %8, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds i32, ptr %3, i64 %10
  %12 = lshr i32 %5, 3
  %13 = and i32 %12, 3
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds i32, ptr %4, i64 %14
  %16 = select i1 %7, ptr %15, ptr %11
  %17 = lshr i32 %5, 5
  %18 = and i32 %17, 3
  %19 = zext nneg i32 %18 to i64
  %20 = getelementptr inbounds i32, ptr %3, i64 %19
  %21 = icmp eq ptr %16, %20
  %22 = zext i1 %21 to i32
  %23 = call i32 @cq_measure_si32(i32 noundef %22) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #10
  ret i32 %23
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_lt_global(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  %6 = select i1 %5, ptr getelementptr inbounds (i8, ptr @G, i64 16), ptr @G
  %7 = lshr i32 %3, 1
  %8 = and i32 %7, 3
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds i32, ptr %6, i64 %9
  %11 = lshr i32 %3, 3
  %12 = and i32 %11, 7
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds i32, ptr @G, i64 %13
  %15 = icmp ult ptr %10, %14
  %16 = zext i1 %15 to i32
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #10
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_eq_signed(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #9
  %4 = srem i32 %3, 4
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds i32, ptr getelementptr inbounds (i8, ptr @G, i64 16), i64 %5
  %7 = ashr i32 %3, 4
  %8 = srem i32 %7, 4
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds i32, ptr getelementptr inbounds (i8, ptr @H, i64 16), i64 %9
  %11 = icmp eq ptr %6, %10
  %12 = zext i1 %11 to i32
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #10
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @f_rail_off(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %7 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef %3) #9
  %8 = and i32 %6, 1
  %9 = icmp eq i32 %8, 0
  %10 = select i1 %9, ptr @QB, ptr @QA
  %11 = icmp ugt i32 %4, 44
  %12 = select i1 %11, i32 0, i32 %4
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds i32, ptr %10, i64 %13
  %15 = zext i8 %7 to i64
  %16 = getelementptr inbounds i32, ptr %14, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #10
  ret i32 %18
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @f_rail_off_store(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = alloca [300 x i32], align 16
  %8 = alloca [300 x i32], align 16
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %10 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef %3) #9
  call void @llvm.lifetime.start.p0(i64 1200, ptr nonnull %7) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(1200) %7, i8 0, i64 1200, i1 false)
  call void @llvm.lifetime.start.p0(i64 1200, ptr nonnull %8) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(1200) %8, i8 0, i64 1200, i1 false)
  %11 = and i32 %9, 1
  %12 = icmp eq i32 %11, 0
  %13 = select i1 %12, ptr %8, ptr %7
  %14 = icmp ugt i32 %4, 44
  %15 = select i1 %14, i32 0, i32 %4
  %16 = icmp ugt i32 %5, 299
  %17 = select i1 %16, i32 0, i32 %5
  %18 = zext nneg i32 %15 to i64
  %19 = getelementptr inbounds i32, ptr %13, i64 %18
  %20 = zext i8 %10 to i64
  %21 = getelementptr inbounds i32, ptr %19, i64 %20
  store i32 7, ptr %21, align 4, !tbaa !6
  %22 = zext nneg i32 %17 to i64
  %23 = getelementptr inbounds [300 x i32], ptr %7, i64 0, i64 %22
  %24 = load i32, ptr %23, align 4, !tbaa !6
  %25 = getelementptr inbounds [300 x i32], ptr %8, i64 0, i64 %22
  %26 = load i32, ptr %25, align 4, !tbaa !6
  %27 = shl nsw i32 %26, 1
  %28 = add nsw i32 %27, %24
  %29 = tail call i32 @cq_measure_si32(i32 noundef %28) #10
  call void @llvm.lifetime.end.p0(i64 1200, ptr nonnull %8) #10
  call void @llvm.lifetime.end.p0(i64 1200, ptr nonnull %7) #10
  ret i32 %29
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_ptr_roundtrip(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = alloca [4 x i32], align 16
  %6 = alloca [4 x i32], align 16
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #10
  store i32 %2, ptr %4, align 16, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %4, i64 4
  %9 = add nsw i32 %2, 1
  store i32 %9, ptr %8, align 4, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %4, i64 8
  %11 = add nsw i32 %2, 2
  store i32 %11, ptr %10, align 8, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %4, i64 12
  %13 = add nsw i32 %2, 3
  store i32 %13, ptr %12, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, ptr noundef nonnull align 16 dereferenceable(16) @__const.f_ptr_roundtrip.b, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %6) #10
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %6, ptr noundef nonnull align 16 dereferenceable(16) @__const.f_ptr_roundtrip.c, i64 16, i1 false)
  %14 = and i32 %7, 1
  %15 = icmp eq i32 %14, 0
  %16 = and i32 %7, 2
  %17 = icmp eq i32 %16, 0
  %18 = select i1 %17, ptr %6, ptr %5
  %19 = select i1 %15, ptr %18, ptr %4
  %20 = lshr i32 %7, 2
  %21 = and i32 %20, 1
  %22 = zext nneg i32 %21 to i64
  %23 = getelementptr inbounds i32, ptr %19, i64 %22
  %24 = ptrtoint ptr %23 to i64
  %25 = lshr i32 %7, 1
  %26 = and i32 %25, 4
  %27 = add nuw nsw i32 %26, 4
  %28 = zext nneg i32 %27 to i64
  %29 = add i64 %28, %24
  %30 = inttoptr i64 %29 to ptr
  %31 = load i32, ptr %30, align 4, !tbaa !6
  %32 = add nsw i32 %31, %2
  %33 = call i32 @cq_measure_si32(i32 noundef %32) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %6) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  ret i32 %33
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #4

; Function Attrs: nounwind ssp uwtable
define i32 @f_int_to_ptr(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #10
  store i32 %2, ptr %4, align 16, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %4, i64 4
  %7 = add nsw i32 %2, 1
  store i32 %7, ptr %6, align 4, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %4, i64 8
  %9 = add nsw i32 %2, 2
  store i32 %9, ptr %8, align 8, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %4, i64 12
  %11 = add nsw i32 %2, 3
  store i32 %11, ptr %10, align 4, !tbaa !6
  %12 = ptrtoint ptr %4 to i64
  %13 = shl i32 %5, 2
  %14 = and i32 %13, 12
  %15 = zext nneg i32 %14 to i64
  %16 = or disjoint i64 %15, %12
  %17 = inttoptr i64 %16 to ptr
  %18 = load i32, ptr %17, align 4, !tbaa !6
  %19 = call i32 @cq_measure_si32(i32 noundef %18) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_ptrmask(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [8 x i16], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #10
  %6 = trunc i32 %2 to i16
  store i16 %6, ptr %4, align 16, !tbaa !10
  %7 = getelementptr inbounds i8, ptr %4, i64 2
  store i16 1, ptr %7, align 2, !tbaa !10
  %8 = getelementptr inbounds i8, ptr %4, i64 4
  store i16 2, ptr %8, align 4, !tbaa !10
  %9 = getelementptr inbounds i8, ptr %4, i64 6
  store i16 3, ptr %9, align 2, !tbaa !10
  %10 = getelementptr inbounds i8, ptr %4, i64 8
  %11 = add i16 %6, 4
  store i16 %11, ptr %10, align 8, !tbaa !10
  %12 = getelementptr inbounds i8, ptr %4, i64 10
  store i16 5, ptr %12, align 2, !tbaa !10
  %13 = getelementptr inbounds i8, ptr %4, i64 12
  store i16 6, ptr %13, align 4, !tbaa !10
  %14 = getelementptr inbounds i8, ptr %4, i64 14
  store i16 7, ptr %14, align 2, !tbaa !10
  %15 = and i32 %5, 7
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds i16, ptr %4, i64 %16
  %18 = call align 8 ptr @llvm.ptrmask.p0.i64(ptr nonnull %17, i64 -8)
  %19 = load i16, ptr %18, align 8, !tbaa !10
  %20 = sext i16 %19 to i32
  %21 = load i16, ptr %17, align 2, !tbaa !10
  %22 = sext i16 %21 to i32
  %23 = add nsw i32 %22, %20
  %24 = tail call i32 @cq_measure_si32(i32 noundef %23) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  ret i32 %24
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare ptr @llvm.ptrmask.p0.i64(ptr, i64) #5

; Function Attrs: nounwind ssp uwtable
define i32 @f_ret_ptr(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = alloca [2 x i32], align 4
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #10
  store i32 %2, ptr %4, align 16, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %4, i64 4
  %8 = add nsw i32 %2, 1
  store i32 %8, ptr %7, align 4, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %4, i64 8
  %10 = add nsw i32 %2, 2
  store i32 %10, ptr %9, align 8, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %4, i64 12
  %12 = add nsw i32 %2, 3
  store i32 %12, ptr %11, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #10
  %13 = add nsw i32 %2, 7
  store i32 %13, ptr %5, align 4, !tbaa !6
  %14 = getelementptr inbounds i8, ptr %5, i64 4
  %15 = add nsw i32 %2, 9
  store i32 %15, ptr %14, align 4, !tbaa !6
  %16 = call fastcc ptr @pick2(ptr noundef nonnull %4, ptr noundef nonnull %5, i32 noundef %6)
  %17 = icmp eq ptr %16, null
  br i1 %17, label %20, label %18

18:                                               ; preds = %3
  %19 = load i32, ptr %16, align 4, !tbaa !6
  br label %20

20:                                               ; preds = %3, %18
  %21 = phi i32 [ %19, %18 ], [ -1, %3 ]
  %22 = call i32 @cq_measure_si32(i32 noundef %21) #10
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  ret i32 %22
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc ptr @pick2(ptr noundef readnone %0, ptr noundef readnone %1, i32 noundef %2) unnamed_addr #6 {
  %4 = and i32 %2, 2
  %5 = icmp eq i32 %4, 0
  %6 = lshr i32 %2, 2
  %7 = and i32 %6, 1
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds i32, ptr %1, i64 %8
  %10 = select i1 %5, ptr null, ptr %9
  %11 = lshr i32 %2, 1
  %12 = and i32 %11, 3
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds i32, ptr %0, i64 %13
  %15 = and i32 %2, 1
  %16 = icmp eq i32 %15, 0
  %17 = select i1 %16, ptr %10, ptr %14
  ret ptr %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_slot_rmw(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, double noundef %6, i32 noundef %7, double noundef %8) local_unnamed_addr #0 {
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %10) #10
  store i32 %3, ptr %10, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %11) #10
  store i32 %5, ptr %11, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %12) #10
  store i32 %7, ptr %12, align 4, !tbaa !6
  %13 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #9
  %14 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #9
  store i32 %14, ptr %10, align 4, !tbaa !6
  %15 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %6) #9
  store i32 %15, ptr %11, align 4, !tbaa !6
  %16 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %8) #9
  store i32 %16, ptr %12, align 4, !tbaa !6
  %17 = icmp sgt i32 %13, %2
  %18 = sub nsw i32 0, %2
  %19 = icmp slt i32 %13, %18
  %20 = select i1 %19, ptr %11, ptr %12
  %21 = select i1 %17, ptr %10, ptr %20
  %22 = load i32, ptr %21, align 4, !tbaa !6
  %23 = xor i32 %22, 5
  store i32 %23, ptr %21, align 4, !tbaa !6
  call fastcc void @drop3(ptr noundef nonnull %21)
  %24 = load i32, ptr %10, align 4, !tbaa !6
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24) #10
  %26 = load i32, ptr %11, align 4, !tbaa !6
  %27 = tail call i32 @cq_measure_si32(i32 noundef %26) #10
  %28 = add nsw i32 %27, %25
  %29 = load i32, ptr %12, align 4, !tbaa !6
  %30 = tail call i32 @cq_measure_si32(i32 noundef %29) #10
  %31 = add nsw i32 %28, %30
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %12) #10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %11) #10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %10) #10
  ret i32 %31
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @drop3(ptr nocapture noundef %0) unnamed_addr #7 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = add nsw i32 %2, -3
  store i32 %3, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_slot_rmw_old(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %8) #10
  store i32 %3, ptr %8, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %9) #10
  store i32 %5, ptr %9, align 4, !tbaa !6
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #9
  %11 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #9
  store i32 %11, ptr %8, align 4, !tbaa !6
  %12 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %6) #9
  store i32 %12, ptr %9, align 4, !tbaa !6
  %13 = icmp sgt i32 %10, %2
  %14 = select i1 %13, ptr %8, ptr %9
  %15 = load i32, ptr %14, align 4, !tbaa !6
  %16 = add nsw i32 %15, 1
  store i32 %16, ptr %14, align 4, !tbaa !6
  call fastcc void @bump1(ptr noundef nonnull %14)
  %17 = load i32, ptr %8, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #10
  %19 = load i32, ptr %9, align 4, !tbaa !6
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #10
  %21 = add nsw i32 %20, %18
  %22 = tail call i32 @cq_measure_si32(i32 noundef %11) #10
  %23 = add nsw i32 %21, %22
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %9) #10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8) #10
  ret i32 %23
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @bump1(ptr nocapture noundef %0) unnamed_addr #7 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = add nsw i32 %2, 1
  store i32 %3, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_slot_peek(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %8) #10
  store i32 %3, ptr %8, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %9) #10
  store i32 %5, ptr %9, align 4, !tbaa !6
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #9
  %11 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #9
  store i32 %11, ptr %8, align 4, !tbaa !6
  %12 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %6) #9
  store i32 %12, ptr %9, align 4, !tbaa !6
  %13 = icmp sgt i32 %10, %2
  %14 = select i1 %13, ptr %8, ptr %9
  %15 = load i32, ptr %14, align 4, !tbaa !6
  %16 = add nsw i32 %15, 2
  store i32 %16, ptr %14, align 4, !tbaa !6
  %17 = call fastcc i32 @peek1(ptr noundef nonnull %14)
  %18 = load i32, ptr %8, align 4, !tbaa !6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #10
  %20 = load i32, ptr %9, align 4, !tbaa !6
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #10
  %22 = add nsw i32 %21, %19
  %23 = tail call i32 @cq_measure_si32(i32 noundef %17) #10
  %24 = add nsw i32 %22, %23
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %9) #10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8) #10
  ret i32 %24
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc i32 @peek1(ptr nocapture noundef readonly %0) unnamed_addr #8 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_field_store(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, i32 noundef %6) local_unnamed_addr #0 {
  %8 = alloca [3 x %struct.tri], align 16
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #9
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #9
  call void @llvm.lifetime.start.p0(i64 36, ptr nonnull %8) #10
  store i32 1, ptr %8, align 16, !tbaa !12
  %11 = getelementptr inbounds i8, ptr %8, i64 4
  store i32 %5, ptr %11, align 4, !tbaa !14
  %12 = getelementptr inbounds i8, ptr %8, i64 8
  %13 = add nsw i32 %5, 2
  store i32 %13, ptr %12, align 8, !tbaa !15
  %14 = getelementptr inbounds i8, ptr %8, i64 12
  store i32 2, ptr %14, align 4, !tbaa !12
  %15 = getelementptr inbounds i8, ptr %8, i64 16
  %16 = add nsw i32 %5, 1
  store i32 %16, ptr %15, align 16, !tbaa !14
  %17 = getelementptr inbounds i8, ptr %8, i64 20
  %18 = add nsw i32 %5, 3
  store i32 %18, ptr %17, align 4, !tbaa !15
  %19 = getelementptr inbounds i8, ptr %8, i64 24
  store i32 3, ptr %19, align 8, !tbaa !12
  %20 = getelementptr inbounds i8, ptr %8, i64 28
  store i32 %5, ptr %20, align 4, !tbaa !14
  %21 = getelementptr inbounds i8, ptr %8, i64 32
  %22 = add nsw i32 %5, -1
  store i32 %22, ptr %21, align 16, !tbaa !15
  %23 = icmp slt i32 %9, %2
  br i1 %23, label %24, label %28

24:                                               ; preds = %7
  %25 = add nsw i32 %10, %5
  %26 = sext i32 %6 to i64
  %27 = getelementptr inbounds [3 x %struct.tri], ptr %8, i64 0, i64 %26, i32 2
  store i32 %25, ptr %27, align 4, !tbaa !15
  br label %28

28:                                               ; preds = %24, %7
  %29 = load i32, ptr %12, align 8, !tbaa !15
  %30 = load i32, ptr %17, align 4, !tbaa !15
  %31 = add nsw i32 %30, %29
  %32 = load i32, ptr %21, align 16, !tbaa !15
  %33 = add nsw i32 %31, %32
  %34 = sext i32 %6 to i64
  %35 = getelementptr inbounds [3 x %struct.tri], ptr %8, i64 0, i64 %34, i32 1
  %36 = load i32, ptr %35, align 4, !tbaa !14
  %37 = add nsw i32 %33, %36
  %38 = tail call i32 @cq_measure_si32(i32 noundef %37) #10
  call void @llvm.lifetime.end.p0(i64 36, ptr nonnull %8) #10
  ret i32 %38
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #9 = { nomerge nounwind }
attributes #10 = { nounwind }

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
!11 = !{!"short", !8, i64 0}
!12 = !{!13, !7, i64 0}
!13 = !{!"tri", !7, i64 0, !7, i64 4, !7, i64 8}
!14 = !{!13, !7, i64 4}
!15 = !{!13, !7, i64 8}
