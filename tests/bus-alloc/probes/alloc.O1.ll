; ModuleID = 'tests/bus-alloc/probes/alloc.c'
source_filename = "tests/bus-alloc/probes/alloc.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind uwtable
define i32 @p_calloc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %5 = tail call dereferenceable_or_null(16) ptr @calloc(i64 noundef 4, i64 noundef 4) #12
  %6 = and i32 %4, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds i32, ptr %5, i64 %7
  store i32 %2, ptr %8, align 4, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %5, i64 4
  %10 = load i32, ptr %9, align 4, !tbaa !6
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #13
  ret i32 %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,zeroed") allocsize(0,1) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @calloc(i64 noundef, i64 noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind uwtable
define i32 @p_calloc_rail(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %5 = and i32 %4, 3
  %6 = add nuw nsw i32 %5, 1
  %7 = zext nneg i32 %6 to i64
  %8 = tail call ptr @calloc(i64 noundef %7, i64 noundef 4) #12
  store i32 %2, ptr %8, align 4, !tbaa !6
  %9 = and i32 %4, 1
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds i32, ptr %8, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #13
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define i32 @p_aligned(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %5 = tail call align 64 dereferenceable_or_null(64) ptr @aligned_alloc(i64 noundef 64, i64 noundef 64) #14
  %6 = and i32 %4, 1
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds i32, ptr %5, i64 %7
  store i32 %2, ptr %8, align 4, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %5, i64 4
  %10 = load i32, ptr %9, align 4, !tbaa !6
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #13
  ret i32 %11
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @aligned_alloc(i64 allocalign noundef, i64 noundef) local_unnamed_addr #4

; Function Attrs: nounwind uwtable
define i32 @p_vla_rail(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %5 = and i32 %4, 3
  %6 = add nuw nsw i32 %5, 1
  %7 = zext nneg i32 %6 to i64
  %8 = alloca i32, i64 %7, align 16
  store i32 %2, ptr %8, align 16, !tbaa !6
  %9 = and i32 %4, 1
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds i32, ptr %8, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #13
  ret i32 %13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #5

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #5

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @p_copy_runtime(i32 noundef %0, double noundef %1, i32 noundef %2, ptr nocapture noundef readonly %3) local_unnamed_addr #0 {
  %5 = alloca [8 x i8], align 8
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #13
  store i64 578437695752307201, ptr %5, align 8
  %7 = and i32 %6, 7
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [8 x i8], ptr %5, i64 0, i64 %8
  store i8 9, ptr %9, align 1, !tbaa !10
  %10 = and i32 %2, 7
  %11 = zext nneg i32 %10 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 %5, ptr align 1 %3, i64 %11, i1 false)
  %12 = and i32 %6, 1
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [8 x i8], ptr %5, i64 0, i64 %13
  %15 = load i8, ptr %14, align 1, !tbaa !10
  %16 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %15) #13
  %17 = zext i8 %16 to i32
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #13
  ret i32 %17
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #6

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @p_copy_pred(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i8], align 4
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #13
  store i32 67305985, ptr %4, align 4
  %6 = and i32 %5, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %7
  store i8 9, ptr %8, align 1, !tbaa !10
  %9 = and i32 %5, 16
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %12, label %11

11:                                               ; preds = %3
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(3) %4, ptr noundef nonnull align 1 dereferenceable(3) %2, i64 3, i1 false)
  br label %12

12:                                               ; preds = %11, %3
  %13 = lshr i32 %5, 1
  %14 = and i32 %13, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !10
  %18 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %17) #13
  %19 = zext i8 %18 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #13
  ret i32 %19
}

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @p_copy_len_pred(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i8], align 4
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #13
  store i32 67305985, ptr %4, align 4
  %6 = and i32 %5, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %7
  store i8 9, ptr %8, align 1, !tbaa !10
  %9 = and i32 %5, 16
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %15, label %11

11:                                               ; preds = %3
  %12 = lshr i32 %5, 2
  %13 = and i32 %12, 3
  %14 = zext nneg i32 %13 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 4 %4, ptr align 1 %2, i64 %14, i1 false)
  br label %15

15:                                               ; preds = %11, %3
  %16 = lshr i32 %5, 1
  %17 = and i32 %16, 3
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %18
  %20 = load i8, ptr %19, align 1, !tbaa !10
  %21 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %20) #13
  %22 = zext i8 %21 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #13
  ret i32 %22
}

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @p_set_rail(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #13
  store i32 67305985, ptr %3, align 4
  %5 = and i32 %4, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %6
  store i8 9, ptr %7, align 1, !tbaa !10
  %8 = lshr i32 %4, 8
  %9 = trunc i32 %8 to i8
  %10 = lshr i32 %4, 4
  %11 = and i32 %10, 3
  %12 = zext nneg i32 %11 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 4 %3, i8 %9, i64 %12, i1 false)
  %13 = lshr i32 %4, 1
  %14 = and i32 %13, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !10
  %18 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %17) #13
  %19 = zext i8 %18 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #13
  ret i32 %19
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #7

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @p_set_pred(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [8 x i8], align 8
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #13
  store i64 578437695752307201, ptr %3, align 8
  %5 = and i32 %4, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %6
  store i8 9, ptr %7, align 1, !tbaa !10
  %8 = and i32 %4, 16
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %12, label %10

10:                                               ; preds = %2
  %11 = getelementptr inbounds i8, ptr %3, i64 %6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %11, i8 7, i64 3, i1 false)
  br label %12

12:                                               ; preds = %10, %2
  %13 = lshr i32 %4, 1
  %14 = and i32 %13, 7
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !10
  %18 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %17) #13
  %19 = zext i8 %18 to i32
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #13
  ret i32 %19
}

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @p_copy_rails(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) local_unnamed_addr #0 {
  %4 = alloca [8 x i8], align 8
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #13
  store i64 578437695752307201, ptr %4, align 8
  %6 = lshr i32 %5, 8
  %7 = and i32 %6, 7
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [8 x i8], ptr %4, i64 0, i64 %8
  store i8 9, ptr %9, align 1, !tbaa !10
  %10 = and i32 %5, 1
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds i8, ptr %4, i64 %11
  %13 = lshr i32 %5, 1
  %14 = and i32 %13, 1
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds i8, ptr %2, i64 %15
  %17 = load i16, ptr %16, align 1
  store i16 %17, ptr %12, align 1
  %18 = and i32 %13, 3
  %19 = zext nneg i32 %18 to i64
  %20 = getelementptr inbounds [8 x i8], ptr %4, i64 0, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !10
  %22 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %21) #13
  %23 = zext i8 %22 to i32
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #13
  ret i32 %23
}

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @p_move(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #13
  store i32 67305985, ptr %3, align 4
  %5 = and i32 %4, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %6
  store i8 9, ptr %7, align 1, !tbaa !10
  %8 = getelementptr inbounds i8, ptr %3, i64 1
  call void @llvm.memmove.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %8, ptr noundef nonnull align 4 dereferenceable(3) %3, i64 3, i1 false)
  %9 = lshr i32 %4, 2
  %10 = and i32 %9, 3
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !10
  %14 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %13) #13
  %15 = zext i8 %14 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #13
  ret i32 %15
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg) #6

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @p_len_loaded(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i8], align 2
  %5 = alloca [4 x i8], align 4
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %4) #13
  store i16 513, ptr %4, align 2
  %7 = and i32 %6, 1
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %8
  store i8 3, ptr %9, align 1, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #13
  store i32 67305985, ptr %5, align 4
  %10 = and i32 %6, 3
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %11
  store i8 9, ptr %12, align 1, !tbaa !10
  %13 = lshr i32 %6, 1
  %14 = and i32 %13, 1
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !10
  %18 = zext i8 %17 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 4 %5, ptr align 1 %2, i64 %18, i1 false)
  %19 = and i32 %13, 3
  %20 = zext nneg i32 %19 to i64
  %21 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !10
  %23 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %22) #13
  %24 = zext i8 %23 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #13
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %4) #13
  ret i32 %24
}

; Function Attrs: nounwind uwtable
define i32 @p_realloc_pred(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %5 = tail call dereferenceable_or_null(8) ptr @malloc(i64 noundef 8) #15
  %6 = and i32 %4, 1
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds i32, ptr %5, i64 %7
  store i32 %2, ptr %8, align 4, !tbaa !6
  %9 = and i32 %4, 16
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %13, label %11

11:                                               ; preds = %3
  %12 = tail call dereferenceable_or_null(16) ptr @realloc(ptr noundef %5, i64 noundef 16) #14
  br label %13

13:                                               ; preds = %11, %3
  %14 = phi ptr [ %12, %11 ], [ %5, %3 ]
  %15 = getelementptr inbounds i8, ptr %14, i64 4
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #13
  ret i32 %17
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #8

; Function Attrs: mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite)
declare noalias noundef ptr @realloc(ptr allocptr nocapture noundef, i64 noundef) local_unnamed_addr #9

; Function Attrs: nounwind uwtable
define i32 @p_free_pred(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %5 = tail call dereferenceable_or_null(8) ptr @malloc(i64 noundef 8) #15
  %6 = and i32 %4, 1
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds i32, ptr %5, i64 %7
  store i32 %2, ptr %8, align 4, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %5, i64 4
  %10 = load i32, ptr %9, align 4, !tbaa !6
  %11 = and i32 %4, 16
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %14, label %13

13:                                               ; preds = %3
  tail call void @free(ptr noundef %5)
  br label %14

14:                                               ; preds = %13, %3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %10) #13
  ret i32 %15
}

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #10

; Function Attrs: nounwind uwtable
define i32 @p_vla_loop(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #11
  %5 = and i32 %4, 1
  %6 = zext i32 %2 to i64
  br label %8

7:                                                ; preds = %8
  ret i32 %21

8:                                                ; preds = %3, %8
  %9 = phi i64 [ 1, %3 ], [ %22, %8 ]
  %10 = add nuw i64 %9, %6
  %11 = and i64 %10, 4294967295
  %12 = tail call ptr @llvm.stacksave.p0()
  %13 = alloca i32, i64 %11, align 16
  %14 = trunc i64 %10 to i32
  %15 = add i32 %14, -1
  %16 = and i32 %5, %15
  %17 = zext nneg i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %13, i64 %17
  %19 = trunc nuw nsw i64 %9 to i32
  store i32 %19, ptr %18, align 4, !tbaa !6
  %20 = load i32, ptr %13, align 16, !tbaa !6
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #13
  tail call void @llvm.stackrestore.p0(ptr %12)
  %22 = add nuw nsw i64 %9, 1
  %23 = icmp eq i64 %22, 3
  br i1 %23, label %7, label %8, !llvm.loop !11
}

attributes #0 = { nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn allockind("alloc,zeroed") allocsize(0,1) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #6 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #8 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #9 = { mustprogress nounwind willreturn allockind("realloc") allocsize(1) memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #10 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #11 = { nomerge nounwind }
attributes #12 = { allocsize(0,1) }
attributes #13 = { nounwind }
attributes #14 = { allocsize(1) }
attributes #15 = { allocsize(0) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!8, !8, i64 0}
!11 = distinct !{!11, !12, !13}
!12 = !{!"llvm.loop.mustprogress"}
!13 = !{!"llvm.loop.unroll.disable"}
