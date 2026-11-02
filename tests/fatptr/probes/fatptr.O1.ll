; ModuleID = 'fatptr.c'
source_filename = "fatptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.tri = type { i32, i32, i32 }

@G = global [8 x i32] zeroinitializer, align 16
@H = global [8 x i32] zeroinitializer, align 16
@QA = internal unnamed_addr constant [300 x i32] [i32 3, i32 0, i32 0, i32 0, i32 0, i32 0, i32 6, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 100, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 255, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 262, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 299], align 16
@QB = internal unnamed_addr constant [300 x i32] [i32 5, i32 0, i32 0, i32 0, i32 0, i32 0, i32 60, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 1000, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 2550, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 2620, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 2990], align 16
@__const.f_ptr_roundtrip.c = private unnamed_addr constant [4 x i32] [i32 20, i32 21, i32 22, i32 23], align 16
@NT1 = internal unnamed_addr constant [8 x i32] [i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17], align 16
@NT2 = internal unnamed_addr constant [8 x i32] [i32 20, i32 21, i32 22, i32 23, i32 24, i32 25, i32 26, i32 27], align 16
@NG1 = global [8 x i32] zeroinitializer, align 16
@NG2 = global [8 x i32] zeroinitializer, align 16
@__const.f_neg_inttoptr.b = private unnamed_addr constant [8 x i32] [i32 9, i32 8, i32 7, i32 6, i32 5, i32 4, i32 3, i32 2], align 16
@T2A = internal unnamed_addr constant [4 x [5 x i32]] [[5 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5], [5 x i32] [i32 6, i32 7, i32 8, i32 9, i32 10], [5 x i32] [i32 11, i32 12, i32 13, i32 14, i32 15], [5 x i32] [i32 16, i32 17, i32 18, i32 19, i32 20]], align 16
@T2B = internal unnamed_addr constant [4 x [5 x i32]] [[5 x i32] [i32 21, i32 22, i32 23, i32 24, i32 25], [5 x i32] [i32 26, i32 27, i32 28, i32 29, i32 30], [5 x i32] [i32 31, i32 32, i32 33, i32 34, i32 35], [5 x i32] [i32 36, i32 37, i32 38, i32 39, i32 40]], align 16
@LW = internal unnamed_addr constant [4 x i64] [i64 100, i64 -200, i64 300, i64 -400], align 16
@HG1 = local_unnamed_addr global [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16
@HG2 = local_unnamed_addr global [6 x i32] [i32 5, i32 6, i32 7, i32 8, i32 9, i32 10], align 16
@__const.f_int_bytes.b = private unnamed_addr constant [4 x i32] [i32 10, i32 11, i32 12, i32 13], align 16
@IG1 = global [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16
@IG2 = global [6 x i32] [i32 5, i32 6, i32 7, i32 8, i32 9, i32 10], align 16
@ITAB = local_unnamed_addr global [2 x ptr] zeroinitializer, align 16
@QG1 = internal global [8 x i32] zeroinitializer, align 16
@QG2 = internal global [8 x i32] zeroinitializer, align 16
@PT1 = internal unnamed_addr constant [3 x double] [double 1.500000e+00, double 2.500000e+00, double 3.500000e+00], align 16
@PT2 = internal unnamed_addr constant [3 x double] [double -1.000000e+00, double 2.500000e-01, double 8.000000e+00], align 16
@PT3 = internal unnamed_addr constant [3 x double] [double 4.000000e+00, double 5.000000e+00, double 6.000000e+00], align 16
@PT4 = internal unnamed_addr constant [3 x double] [double 7.000000e+00, double -7.000000e+00, double 5.000000e-01], align 16
@PI1 = internal unnamed_addr constant [8 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8], align 16
@PI2 = internal unnamed_addr constant [8 x i32] [i32 10, i32 20, i32 30, i32 40, i32 50, i32 60, i32 70, i32 80], align 16
@__const.f_triple_store.y = private unnamed_addr constant [2 x double] [double 5.000000e-01, double 1.500000e+00], align 16
@__const.f_triple_store.w = private unnamed_addr constant [2 x double] [double 2.000000e+00, double -1.000000e+00], align 16
@UG = local_unnamed_addr global [4 x i32] [i32 5, i32 6, i32 7, i32 8], align 16
@UH = global [6 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6], align 16
@UP = local_unnamed_addr global ptr @UH, align 8

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
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, ptr noundef nonnull align 16 dereferenceable(16) @__const.f_int_bytes.b, i64 16, i1 false)
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

; Function Attrs: nounwind ssp uwtable
define i32 @f_neg_qrom(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  %6 = select i1 %5, ptr getelementptr inbounds (i8, ptr @NT2, i64 16), ptr getelementptr inbounds (i8, ptr @NT1, i64 16)
  %7 = lshr i32 %3, 1
  %8 = and i32 %7, 7
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr i32, ptr %6, i64 %9
  %11 = getelementptr i8, ptr %10, i64 -16
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #10
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_neg_qrom_sext(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  %6 = select i1 %5, ptr getelementptr inbounds (i8, ptr @NT2, i64 16), ptr getelementptr inbounds (i8, ptr @NT1, i64 16)
  %7 = ashr i32 %3, 28
  %8 = sext i32 %7 to i64
  %9 = getelementptr inbounds i32, ptr %6, i64 %8
  %10 = load i32, ptr %9, align 4, !tbaa !6
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #10
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_neg_cmp(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  %6 = select i1 %5, ptr getelementptr inbounds (i8, ptr @NG2, i64 16), ptr getelementptr inbounds (i8, ptr @NG1, i64 16)
  %7 = lshr i32 %3, 1
  %8 = and i32 %7, 7
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds i32, ptr %6, i64 %9
  %11 = getelementptr inbounds i8, ptr %10, i64 -16
  %12 = icmp ult ptr %11, getelementptr inbounds (i8, ptr @NG1, i64 12)
  %13 = zext i1 %12 to i32
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #10
  %15 = icmp eq ptr %11, getelementptr inbounds (i8, ptr @NG1, i64 8)
  %16 = zext i1 %15 to i32
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #10
  %18 = shl nsw i32 %17, 1
  %19 = add nsw i32 %18, %14
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_neg_inttoptr(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [8 x i32], align 16
  %5 = alloca [8 x i32], align 16
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #10
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
  %13 = getelementptr inbounds i8, ptr %4, i64 16
  %14 = add nsw i32 %2, 4
  store i32 %14, ptr %13, align 16, !tbaa !6
  %15 = getelementptr inbounds i8, ptr %4, i64 20
  %16 = add nsw i32 %2, 5
  store i32 %16, ptr %15, align 4, !tbaa !6
  %17 = getelementptr inbounds i8, ptr %4, i64 24
  %18 = add nsw i32 %2, 6
  store i32 %18, ptr %17, align 8, !tbaa !6
  %19 = getelementptr inbounds i8, ptr %4, i64 28
  %20 = add nsw i32 %2, 7
  store i32 %20, ptr %19, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %5) #10
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %5, ptr noundef nonnull align 16 dereferenceable(32) @__const.f_neg_inttoptr.b, i64 32, i1 false)
  %21 = and i32 %6, 1
  %22 = icmp eq i32 %21, 0
  %23 = getelementptr inbounds i8, ptr %5, i64 16
  %24 = select i1 %22, ptr %23, ptr %13
  %25 = ptrtoint ptr %24 to i64
  %26 = shl i32 %6, 1
  %27 = and i32 %26, 28
  %28 = zext nneg i32 %27 to i64
  %29 = add nsw i64 %28, -16
  %30 = add i64 %29, %25
  %31 = inttoptr i64 %30 to ptr
  %32 = load i32, ptr %31, align 4, !tbaa !6
  %33 = call i32 @cq_measure_si32(i32 noundef %32) #10
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %5) #10
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #10
  ret i32 %33
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_2d_qrom(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  %6 = select i1 %5, ptr @T2B, ptr @T2A
  %7 = lshr i32 %3, 1
  %8 = and i32 %7, 3
  %9 = zext nneg i32 %8 to i64
  %10 = lshr i32 %3, 3
  %11 = urem i32 %10, 5
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [5 x i32], ptr %6, i64 %9, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #10
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_2d_qram(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [3 x [4 x i32]], align 16
  %5 = alloca [3 x [4 x i32]], align 16
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 48, ptr nonnull %4) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(48) %4, i8 0, i64 48, i1 false)
  call void @llvm.lifetime.start.p0(i64 48, ptr nonnull %5) #10
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(48) %5, i8 0, i64 48, i1 false)
  %7 = and i32 %6, 1
  %8 = icmp eq i32 %7, 0
  %9 = select i1 %8, ptr %5, ptr %4
  %10 = lshr i32 %6, 1
  %11 = urem i32 %10, 3
  %12 = zext nneg i32 %11 to i64
  %13 = lshr i32 %6, 3
  %14 = and i32 %13, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [4 x i32], ptr %9, i64 %12, i64 %15
  store i32 %2, ptr %16, align 4, !tbaa !6
  %17 = getelementptr inbounds i8, ptr %4, i64 24
  %18 = load i32, ptr %17, align 8, !tbaa !6
  %19 = getelementptr inbounds i8, ptr %5, i64 44
  %20 = load i32, ptr %19, align 4, !tbaa !6
  %21 = shl nsw i32 %20, 1
  %22 = add nsw i32 %21, %18
  %23 = load i32, ptr %4, align 16, !tbaa !6
  %24 = shl nsw i32 %23, 2
  %25 = add nsw i32 %22, %24
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #10
  call void @llvm.lifetime.end.p0(i64 48, ptr nonnull %5) #10
  call void @llvm.lifetime.end.p0(i64 48, ptr nonnull %4) #10
  ret i32 %26
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_sel_cells(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %4 = lshr i32 %3, 1
  %5 = and i32 %4, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds i32, ptr @NT1, i64 %6
  %8 = lshr i32 %3, 4
  %9 = and i32 %8, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds i64, ptr @LW, i64 %10
  %12 = and i32 %3, 1
  %13 = icmp eq i32 %12, 0
  %14 = select i1 %13, ptr %11, ptr %7, !unpredictable !16
  %15 = load i32, ptr %14, align 4, !tbaa !6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #10
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_sel_classical(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  %7 = select i1 %6, i32 3, i32 1
  %8 = select i1 %6, i32 7, i32 3
  %9 = select i1 %6, ptr @NT2, ptr @NT1
  %10 = lshr i32 %4, %7
  %11 = and i32 %10, %8
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds i32, ptr %9, i64 %12
  %14 = and i32 %4, 2
  %15 = icmp eq i32 %14, 0
  %16 = lshr i32 %4, 4
  %17 = and i32 %16, 1
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr @NT2, i64 %18
  %20 = select i1 %15, ptr @NT1, ptr %19
  %21 = icmp eq i32 %2, 0
  %22 = select i1 %21, ptr %20, ptr %13
  %23 = load i32, ptr %22, align 4, !tbaa !6
  %24 = getelementptr inbounds i8, ptr %22, i64 4
  %25 = load i32, ptr %24, align 4, !tbaa !6
  %26 = add nsw i32 %25, %23
  %27 = tail call i32 @cq_measure_si32(i32 noundef %26) #10
  ret i32 %27
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_host_idx(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %5 = icmp ugt i32 %2, 3
  %6 = select i1 %5, i32 0, i32 %2
  %7 = and i32 %4, 1
  %8 = icmp eq i32 %7, 0
  %9 = select i1 %8, ptr getelementptr inbounds (i8, ptr @HG2, i64 8), ptr @HG1
  %10 = zext nneg i32 %6 to i64
  %11 = getelementptr inbounds i32, ptr %9, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #10
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_slot_store(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5, i32 noundef %6) local_unnamed_addr #0 {
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %8) #10
  store i32 %2, ptr %8, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %9) #10
  store i32 %4, ptr %9, align 4, !tbaa !6
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #9
  %11 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #9
  store i32 %11, ptr %8, align 4, !tbaa !6
  %12 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %5) #9
  store i32 %12, ptr %9, align 4, !tbaa !6
  %13 = and i32 %10, 2
  %14 = icmp eq i32 %13, 0
  %15 = select i1 %14, i32 %6, i32 %10
  %16 = and i32 %10, 1
  %17 = icmp eq i32 %16, 0
  %18 = select i1 %17, ptr %9, ptr %8
  store i32 %15, ptr %18, align 4, !tbaa !6
  %19 = call fastcc i32 @peek1(ptr noundef nonnull %18)
  %20 = load i32, ptr %8, align 4, !tbaa !6
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #10
  %22 = load i32, ptr %9, align 4, !tbaa !6
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #10
  %24 = shl nsw i32 %23, 1
  %25 = add nsw i32 %24, %21
  %26 = tail call i32 @cq_measure_si32(i32 noundef %19) #10
  %27 = shl nsw i32 %26, 2
  %28 = add nsw i32 %25, %27
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %9) #10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8) #10
  ret i32 %28
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_slot_cls(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #10
  store i32 %2, ptr %6, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #10
  store i32 %4, ptr %7, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #9
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #9
  store i32 %9, ptr %6, align 4, !tbaa !6
  %10 = and i32 %8, 1
  %11 = icmp eq i32 %10, 0
  %12 = select i1 %11, ptr %7, ptr %6
  %13 = load i32, ptr %12, align 4, !tbaa !6
  %14 = add nsw i32 %13, 1
  store i32 %14, ptr %12, align 4, !tbaa !6
  %15 = call fastcc i32 @peek1(ptr noundef nonnull %12)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %13) #10
  %17 = load i32, ptr %6, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #10
  %19 = shl nsw i32 %18, 1
  %20 = add nsw i32 %19, %16
  %21 = load i32, ptr %7, align 4, !tbaa !6
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #10
  %23 = shl nsw i32 %22, 2
  %24 = add nsw i32 %20, %23
  %25 = tail call i32 @cq_measure_si32(i32 noundef %15) #10
  %26 = shl nsw i32 %25, 3
  %27 = add nsw i32 %24, %26
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #10
  ret i32 %27
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_host_zero(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  %6 = select i1 %5, i32 1, i32 5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #10
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_slot_plain(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, double noundef %6) local_unnamed_addr #0 {
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
  store i32 7, ptr %14, align 4, !tbaa !6
  call fastcc void @bump2(ptr noundef nonnull %14)
  %15 = load i32, ptr %8, align 4, !tbaa !6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #10
  %17 = load i32, ptr %9, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #10
  %19 = add nsw i32 %18, %16
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %9) #10
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8) #10
  ret i32 %19
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @bump2(ptr nocapture noundef %0) unnamed_addr #7 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = add nsw i32 %2, 1
  store i32 %3, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_int_unknown(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = alloca [4 x i32], align 16
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
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, ptr noundef nonnull align 16 dereferenceable(16) @__const.f_int_bytes.b, i64 16, i1 false)
  %13 = ptrtoint ptr %4 to i64
  %14 = ptrtoint ptr %5 to i64
  %15 = and i32 %6, 1
  %16 = zext nneg i32 %15 to i64
  %17 = sub nsw i64 0, %16
  %18 = and i64 %17, %13
  %19 = icmp eq i32 %15, 0
  %20 = select i1 %19, i64 %14, i64 0
  %21 = or i64 %18, %20
  %22 = shl i32 %6, 1
  %23 = and i32 %22, 12
  %24 = zext nneg i32 %23 to i64
  %25 = or disjoint i64 %21, %24
  %26 = inttoptr i64 %25 to ptr
  %27 = load i32, ptr %26, align 4, !tbaa !6
  %28 = call i32 @cq_measure_si32(i32 noundef %27) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  ret i32 %28
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_int_bytes(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = alloca [4 x i32], align 16
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
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, ptr noundef nonnull align 16 dereferenceable(16) @__const.f_int_bytes.b, i64 16, i1 false)
  %13 = and i32 %6, 1
  %14 = icmp eq i32 %13, 0
  %15 = select i1 %14, ptr %5, ptr %4
  %16 = ptrtoint ptr %15 to i64
  %17 = shl i32 %6, 1
  %18 = and i32 %17, 12
  %19 = zext nneg i32 %18 to i64
  %20 = or disjoint i64 %16, %19
  %21 = inttoptr i64 %20 to ptr
  %22 = getelementptr inbounds i8, ptr %21, i64 2
  %23 = load i16, ptr %22, align 2, !tbaa !10
  %24 = sext i16 %23 to i32
  %25 = load i32, ptr %21, align 4, !tbaa !6
  %26 = add nsw i32 %25, %24
  %27 = call i32 @cq_measure_si32(i32 noundef %26) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  ret i32 %27
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_host_interior(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %6 = icmp ugt i32 %2, 3
  %7 = select i1 %6, i32 0, i32 %2
  %8 = icmp ugt i32 %3, 5
  %9 = select i1 %8, i32 0, i32 %3
  %10 = zext nneg i32 %7 to i64
  %11 = getelementptr inbounds [4 x i32], ptr @IG1, i64 0, i64 %10
  %12 = zext nneg i32 %9 to i64
  %13 = getelementptr inbounds i32, ptr @IG2, i64 %12
  %14 = and i32 %5, 1
  %15 = icmp eq i32 %14, 0
  %16 = select i1 %15, ptr %11, ptr %13
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #10
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_host_interior_tab(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %6 = icmp ugt i32 %2, 3
  %7 = select i1 %6, i32 0, i32 %2
  %8 = icmp ugt i32 %3, 5
  %9 = select i1 %8, i32 0, i32 %3
  %10 = zext nneg i32 %7 to i64
  %11 = getelementptr inbounds [4 x i32], ptr @IG1, i64 0, i64 %10
  store ptr %11, ptr @ITAB, align 16, !tbaa !17
  %12 = zext nneg i32 %9 to i64
  %13 = getelementptr inbounds i32, ptr @IG2, i64 %12
  store ptr %13, ptr getelementptr inbounds (i8, ptr @ITAB, i64 8), align 8, !tbaa !17
  %14 = and i32 %5, 1
  %15 = icmp eq i32 %14, 0
  %16 = select i1 %15, ptr %11, ptr %13
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #10
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_qram_addr(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  %7 = select i1 %6, ptr @QG2, ptr @QG1
  %8 = lshr i32 %4, 1
  %9 = and i32 %8, 7
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds i32, ptr %7, i64 %10
  store i32 %2, ptr %11, align 4, !tbaa !6
  %12 = and i32 %4, 16
  %13 = icmp eq i32 %12, 0
  %14 = select i1 %13, ptr @QG2, ptr @QG1
  %15 = lshr i32 %4, 5
  %16 = and i32 %15, 7
  %17 = zext nneg i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %14, i64 %17
  %19 = icmp eq ptr %11, %18
  %20 = zext i1 %19 to i32
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #10
  %22 = load i32, ptr getelementptr inbounds (i8, ptr @QG1, i64 12), align 4, !tbaa !6
  %23 = load i32, ptr getelementptr inbounds (i8, ptr @QG2, i64 20), align 4, !tbaa !6
  %24 = add nsw i32 %23, %22
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24) #10
  %26 = shl nsw i32 %25, 1
  %27 = add nsw i32 %26, %21
  ret i32 %27
}

; Function Attrs: nounwind ssp uwtable
define double @f_phi_tables(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %5 = icmp ugt i32 %4, 200
  br i1 %5, label %11, label %6

6:                                                ; preds = %3
  %7 = icmp ugt i32 %4, 100
  br i1 %7, label %11, label %8

8:                                                ; preds = %6
  %9 = icmp ugt i32 %4, 50
  %10 = select i1 %9, ptr @PT3, ptr @PT4
  br label %11

11:                                               ; preds = %6, %3, %8
  %12 = phi ptr [ %10, %8 ], [ @PT1, %3 ], [ @PT2, %6 ]
  %13 = load double, ptr %12, align 8, !tbaa !19
  %14 = getelementptr inbounds i8, ptr %12, i64 8
  %15 = load double, ptr %14, align 8, !tbaa !19
  %16 = getelementptr inbounds i8, ptr %12, i64 16
  %17 = load double, ptr %16, align 8, !tbaa !19
  %18 = tail call double @llvm.fmuladd.f64(double %2, double %17, double %15)
  %19 = tail call double @llvm.fmuladd.f64(double %2, double %18, double %13)
  %20 = tail call double @cq_measure_f64(double noundef %19) #10
  ret double %20
}

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #5

; Function Attrs: nounwind ssp uwtable
define i32 @f_phi_idx(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %5 = icmp ugt i32 %2, 7
  %6 = select i1 %5, i32 0, i32 %2
  %7 = and i32 %4, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %14, label %9

9:                                                ; preds = %3
  %10 = lshr i32 %4, 1
  %11 = and i32 %10, 7
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds i32, ptr @PI1, i64 %12
  br label %20

14:                                               ; preds = %3
  %15 = and i32 %4, 2
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %20, label %17

17:                                               ; preds = %14
  %18 = zext nneg i32 %6 to i64
  %19 = getelementptr inbounds i32, ptr @PI2, i64 %18
  br label %20

20:                                               ; preds = %14, %17, %9
  %21 = phi ptr [ %13, %9 ], [ %19, %17 ], [ @PI2, %14 ]
  %22 = load i32, ptr %21, align 4, !tbaa !6
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #10
  ret i32 %23
}

; Function Attrs: nounwind ssp uwtable
define i64 @f_slot_base(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #10
  store i32 %5, ptr %3, align 16, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %3, i64 4
  %7 = add i32 %5, 1
  store i32 %7, ptr %6, align 4, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %3, i64 8
  %9 = add i32 %5, 2
  store i32 %9, ptr %8, align 8, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %3, i64 12
  %11 = add i32 %5, 3
  store i32 %11, ptr %10, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #10
  store i32 0, ptr %4, align 16, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %4, i64 4
  store i32 %5, ptr %12, align 4, !tbaa !6
  %13 = getelementptr inbounds i8, ptr %4, i64 8
  store i32 0, ptr %13, align 8, !tbaa !6
  %14 = getelementptr inbounds i8, ptr %4, i64 12
  store i32 %5, ptr %14, align 4, !tbaa !6
  %15 = and i32 %5, 1
  %16 = icmp eq i32 %15, 0
  %17 = select i1 %16, ptr %14, ptr %6
  %18 = and i32 %5, 2
  %19 = icmp eq i32 %18, 0
  %20 = select i1 %19, ptr %4, ptr %8
  %21 = icmp ult ptr %17, %20
  %22 = select i1 %21, i64 4, i64 0
  %23 = call i64 @cq_measure_sl(i64 noundef %22) #10
  %24 = and i32 %0, 1
  %25 = zext nneg i32 %24 to i64
  %26 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %25
  %27 = load i32, ptr %26, align 4, !tbaa !6
  %28 = load i32, ptr %12, align 4, !tbaa !6
  %29 = add i32 %28, %27
  %30 = call i32 @cq_measure_ui32(i32 noundef %29) #10
  %31 = zext i32 %30 to i64
  %32 = add nsw i64 %23, %31
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #10
  ret i64 %32
}

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define double @f_triple_store(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x double], align 16
  %5 = alloca [2 x double], align 16
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #10
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) @__const.f_triple_store.y, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, ptr noundef nonnull align 16 dereferenceable(16) @__const.f_triple_store.w, i64 16, i1 false)
  %7 = and i32 %2, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %14, label %9

9:                                                ; preds = %3
  call fastcc void @tc_upd(double noundef %6, ptr noundef nonnull %4)
  %10 = load double, ptr %4, align 16, !tbaa !19
  %11 = getelementptr inbounds i8, ptr %4, i64 8
  %12 = load double, ptr %11, align 8, !tbaa !19
  %13 = fsub double %10, %12
  br label %20

14:                                               ; preds = %3
  %15 = fmul double %6, 3.000000e+00
  call fastcc void @tc_upd(double noundef %15, ptr noundef nonnull %5)
  %16 = load double, ptr %5, align 16, !tbaa !19
  %17 = getelementptr inbounds i8, ptr %5, i64 8
  %18 = load double, ptr %17, align 8, !tbaa !19
  %19 = fadd double %16, %18
  br label %20

20:                                               ; preds = %14, %9
  %21 = phi double [ %19, %14 ], [ %13, %9 ]
  %22 = tail call double @cq_measure_f64(double noundef %21) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #10
  ret double %22
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @tc_upd(double noundef %0, ptr nocapture noundef %1) unnamed_addr #7 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load double, ptr %3, align 8, !tbaa !19
  %5 = fadd double %4, %0
  store double %5, ptr %1, align 8, !tbaa !19
  %6 = fmul double %4, %5
  store double %6, ptr %3, align 8, !tbaa !19
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_unknown_extent(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  %6 = load ptr, ptr @UP, align 8
  %7 = select i1 %5, ptr @UG, ptr %6
  %8 = getelementptr inbounds i8, ptr %7, i64 8
  %9 = load i32, ptr %8, align 4, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %7, i64 4
  %11 = load i32, ptr %10, align 4, !tbaa !6
  %12 = add nsw i32 %11, %9
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #10
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_triple_qrom(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [8 x i32], align 16
  %6 = alloca [8 x i32], align 16
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #9
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %5) #10
  store i32 %2, ptr %5, align 16, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 1, ptr %8, align 4, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %5, i64 8
  store i32 2, ptr %9, align 8, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %5, i64 12
  store i32 3, ptr %10, align 4, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %5, i64 16
  store i32 4, ptr %11, align 16, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %5, i64 20
  store i32 5, ptr %12, align 4, !tbaa !6
  %13 = getelementptr inbounds i8, ptr %5, i64 24
  store i32 6, ptr %13, align 8, !tbaa !6
  %14 = getelementptr inbounds i8, ptr %5, i64 28
  store i32 7, ptr %14, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %6) #10
  store i32 9, ptr %6, align 16, !tbaa !6
  %15 = getelementptr inbounds i8, ptr %6, i64 4
  store i32 8, ptr %15, align 4, !tbaa !6
  %16 = getelementptr inbounds i8, ptr %6, i64 8
  store i32 7, ptr %16, align 8, !tbaa !6
  %17 = getelementptr inbounds i8, ptr %6, i64 12
  store i32 6, ptr %17, align 4, !tbaa !6
  %18 = getelementptr inbounds i8, ptr %6, i64 16
  store i32 5, ptr %18, align 16, !tbaa !6
  %19 = getelementptr inbounds i8, ptr %6, i64 20
  store i32 %2, ptr %19, align 4, !tbaa !6
  %20 = getelementptr inbounds i8, ptr %6, i64 24
  store i32 3, ptr %20, align 8, !tbaa !6
  %21 = getelementptr inbounds i8, ptr %6, i64 28
  store i32 2, ptr %21, align 4, !tbaa !6
  %22 = and i32 %3, 1
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %26, label %24

24:                                               ; preds = %4
  %25 = call fastcc i32 @hq_pick(ptr noundef nonnull %5, i32 noundef %7)
  br label %29

26:                                               ; preds = %4
  %27 = add i32 %7, 1
  %28 = call fastcc i32 @hq_pick(ptr noundef nonnull %6, i32 noundef %27)
  br label %29

29:                                               ; preds = %26, %24
  %30 = phi i32 [ %25, %24 ], [ %28, %26 ]
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30) #10
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %6) #10
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %5) #10
  ret i32 %31
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc i32 @hq_pick(ptr nocapture noundef readonly %0, i32 noundef %1) unnamed_addr #8 {
  %3 = and i32 %1, 7
  %4 = zext nneg i32 %3 to i64
  %5 = getelementptr inbounds i32, ptr %0, i64 %4
  %6 = load i32, ptr %5, align 4, !tbaa !6
  ret i32 %6
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
!16 = !{}
!17 = !{!18, !18, i64 0}
!18 = !{!"any pointer", !8, i64 0}
!19 = !{!20, !20, i64 0}
!20 = !{!"double", !8, i64 0}
