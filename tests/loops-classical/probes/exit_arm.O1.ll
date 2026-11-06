; ModuleID = '/Users/sorenwilkening/Desktop/Projects/wt/fm-mloop/tests/loops-classical/probes/exit_arm.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/wt/fm-mloop/tests/loops-classical/probes/exit_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [10 x i8] c"12.5e3 Ab\00", align 1
@__const.pc3.x = private unnamed_addr constant <{ i8, i8, i8, i8, i8, [11 x i8] }> <{ i8 1, i8 2, i8 3, i8 4, i8 5, [11 x i8] zeroinitializer }>, align 16

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define i32 @cf(ptr nocapture noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %24

5:                                                ; preds = %3
  %6 = zext i32 %2 to i64
  %7 = zext nneg i32 %1 to i64
  br label %8

8:                                                ; preds = %5, %12
  %9 = phi i64 [ 0, %5 ], [ %17, %12 ]
  %10 = phi i32 [ 0, %5 ], [ %16, %12 ]
  %11 = icmp eq i64 %9, %6
  br i1 %11, label %21, label %12

12:                                               ; preds = %8
  %13 = getelementptr inbounds i8, ptr %0, i64 %9
  %14 = load i8, ptr %13, align 1
  %15 = sext i8 %14 to i32
  %16 = add nsw i32 %10, %15
  %17 = add nuw nsw i64 %9, 1
  %18 = icmp eq i64 %17, %7
  br i1 %18, label %19, label %8, !llvm.loop !6

19:                                               ; preds = %12
  %20 = add nsw i32 %16, 100
  br label %24

21:                                               ; preds = %8
  %22 = add nsw i32 %10, 200
  %23 = trunc i32 %22 to i8
  br label %24

24:                                               ; preds = %3, %19, %21
  %25 = phi i64 [ 3, %21 ], [ 2, %19 ], [ 2, %3 ]
  %26 = phi i8 [ %23, %21 ], [ 9, %19 ], [ 9, %3 ]
  %27 = phi i32 [ %22, %21 ], [ %20, %19 ], [ 100, %3 ]
  %28 = getelementptr inbounds i8, ptr %0, i64 %25
  store i8 %26, ptr %28, align 1
  %29 = getelementptr inbounds i8, ptr %0, i64 2
  %30 = load i8, ptr %29, align 1
  %31 = sext i8 %30 to i32
  %32 = add nsw i32 %27, %31
  %33 = getelementptr inbounds i8, ptr %0, i64 3
  %34 = load i8, ptr %33, align 1
  %35 = sext i8 %34 to i32
  %36 = add nsw i32 %32, %35
  ret i32 %36
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @pc5b(i8 noundef signext %0) local_unnamed_addr #2 {
  %2 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #8
  store i64 578437695752307201, ptr %2, align 8
  %3 = getelementptr inbounds i8, ptr %2, i64 1
  store i8 %0, ptr %3, align 1
  %4 = tail call signext i8 @cq_theta_c(i8 noundef signext %0, double noundef 3.000000e-01) #9
  store i8 %4, ptr %3, align 1
  %5 = call i32 @cf(ptr noundef nonnull %2, i32 noundef 3, i32 noundef 1)
  %6 = call i32 @cf(ptr noundef nonnull %2, i32 noundef 3, i32 noundef 7)
  %7 = call i32 @cf(ptr noundef nonnull %2, i32 noundef 0, i32 noundef 7)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #8
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #8
  %10 = tail call i32 @cq_measure_si32(i32 noundef %7) #8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #8
  ret i32 0
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable
define i32 @g(ptr nocapture noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %14

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %6

6:                                                ; preds = %4, %11
  %7 = phi i64 [ 0, %4 ], [ %12, %11 ]
  %8 = getelementptr inbounds i8, ptr %0, i64 %7
  %9 = load i8, ptr %8, align 1
  %10 = icmp eq i8 %9, 0
  br i1 %10, label %20, label %11

11:                                               ; preds = %6
  %12 = add nuw nsw i64 %7, 1
  %13 = icmp eq i64 %12, %5
  br i1 %13, label %14, label %6, !llvm.loop !9

14:                                               ; preds = %11, %2
  %15 = phi i32 [ 0, %2 ], [ %1, %11 ]
  store i8 9, ptr %0, align 1
  %16 = getelementptr inbounds i8, ptr %0, i64 1
  %17 = load i8, ptr %16, align 1
  %18 = sext i8 %17 to i32
  %19 = add nsw i32 %18, 1
  br label %22

20:                                               ; preds = %6
  %21 = trunc nuw nsw i64 %7 to i32
  br label %22

22:                                               ; preds = %20, %14
  %23 = phi i32 [ %15, %14 ], [ %21, %20 ]
  %24 = phi i32 [ %19, %14 ], [ 0, %20 ]
  %25 = add nsw i32 %24, %23
  %26 = load i8, ptr %0, align 1
  %27 = sext i8 %26 to i32
  %28 = add nsw i32 %25, %27
  ret i32 %28
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @pa2b(i8 noundef signext %0, i8 noundef signext %1) local_unnamed_addr #2 {
  %3 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #8
  store i64 578437695752307201, ptr %3, align 8
  %4 = getelementptr inbounds i8, ptr %3, i64 1
  store i8 %0, ptr %4, align 1
  %5 = getelementptr inbounds i8, ptr %3, i64 2
  store i8 %1, ptr %5, align 2
  %6 = tail call signext i8 @cq_theta_c(i8 noundef signext %0, double noundef 3.000000e-01) #9
  store i8 %6, ptr %4, align 1
  %7 = tail call signext i8 @cq_theta_c(i8 noundef signext %1, double noundef 4.000000e-01) #9
  store i8 %7, ptr %5, align 2
  %8 = call i32 @g(ptr noundef nonnull %3, i32 noundef 3)
  %9 = call i32 @g(ptr noundef nonnull %3, i32 noundef 1)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8) #8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) #8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #8
  ret i32 0
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define i64 @h(ptr noundef %0) local_unnamed_addr #5 {
  %2 = ptrtoint ptr %0 to i64
  %3 = and i64 %2, 3
  %4 = icmp eq i64 %3, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %10, %1
  %6 = phi ptr [ %0, %1 ], [ %12, %10 ]
  br label %19

7:                                                ; preds = %1
  %8 = load i8, ptr %0, align 1
  %9 = icmp eq i8 %8, 0
  br i1 %9, label %24, label %10

10:                                               ; preds = %7, %16
  %11 = phi ptr [ %12, %16 ], [ %0, %7 ]
  %12 = getelementptr inbounds i8, ptr %11, i64 1
  %13 = ptrtoint ptr %12 to i64
  %14 = and i64 %13, 3
  %15 = icmp eq i64 %14, 0
  br i1 %15, label %5, label %16

16:                                               ; preds = %10
  %17 = load i8, ptr %12, align 1
  %18 = icmp eq i8 %17, 0
  br i1 %18, label %24, label %10, !llvm.loop !10

19:                                               ; preds = %5, %19
  %20 = phi ptr [ %23, %19 ], [ %6, %5 ]
  %21 = load i8, ptr %20, align 1
  %22 = icmp eq i8 %21, 0
  %23 = getelementptr inbounds i8, ptr %20, i64 1
  br i1 %22, label %24, label %19, !llvm.loop !11

24:                                               ; preds = %16, %19, %7
  %25 = phi ptr [ %0, %7 ], [ %20, %19 ], [ %12, %16 ]
  %26 = ptrtoint ptr %25 to i64
  %27 = sub i64 %26, %2
  ret i64 %27
}

; Function Attrs: nounwind ssp uwtable
define noundef i64 @pa1b(i8 noundef signext %0, i8 noundef signext %1) local_unnamed_addr #2 {
  %3 = alloca [32 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #8
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = getelementptr inbounds i8, ptr %3, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(9) %4, ptr noundef nonnull align 1 dereferenceable(9) @.str, i64 9, i1 false)
  store i8 %0, ptr %3, align 16
  %5 = getelementptr inbounds i8, ptr %3, i64 2
  store i8 %1, ptr %5, align 2
  %6 = tail call signext i8 @cq_theta_c(i8 noundef signext %0, double noundef 3.000000e-01) #9
  store i8 %6, ptr %3, align 16
  %7 = load i8, ptr %5, align 2
  %8 = tail call signext i8 @cq_theta_c(i8 noundef signext %7, double noundef 4.000000e-01) #9
  store i8 %8, ptr %5, align 2
  %9 = call i64 @h(ptr noundef nonnull %3)
  %10 = getelementptr inbounds i8, ptr %3, i64 1
  %11 = call i64 @h(ptr noundef nonnull %10)
  %12 = getelementptr inbounds i8, ptr %3, i64 3
  %13 = call i64 @h(ptr noundef nonnull %12)
  %14 = call i64 @cq_measure_ul(i64 noundef %9) #8
  %15 = call i64 @cq_measure_ul(i64 noundef %11) #8
  %16 = call i64 @cq_measure_ul(i64 noundef %13) #8
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #8
  ret i64 0
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #6

declare i64 @cq_measure_ul(i64 noundef) local_unnamed_addr #4

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define i32 @scan(ptr nocapture noundef readonly %0) local_unnamed_addr #5 {
  br label %2

2:                                                ; preds = %1, %14
  %3 = phi i32 [ 0, %1 ], [ %16, %14 ]
  %4 = phi ptr [ %0, %1 ], [ %15, %14 ]
  %5 = tail call i32 @llvm.smax.i32(i32 %3, i32 3)
  br label %6

6:                                                ; preds = %2, %10
  %7 = phi i32 [ %3, %2 ], [ %12, %10 ]
  %8 = phi ptr [ %4, %2 ], [ %11, %10 ]
  %9 = load i8, ptr %8, align 1
  switch i8 %9, label %10 [
    i8 0, label %18
    i8 37, label %14
  ]

10:                                               ; preds = %6
  %11 = getelementptr inbounds i8, ptr %8, i64 1
  %12 = add i32 %7, 1
  %13 = icmp eq i32 %7, %5
  br i1 %13, label %18, label %6, !llvm.loop !12

14:                                               ; preds = %6
  %15 = getelementptr inbounds i8, ptr %8, i64 1
  %16 = add nsw i32 %7, 2
  %17 = icmp sgt i32 %7, 1
  br i1 %17, label %18, label %2, !llvm.loop !13

18:                                               ; preds = %14, %10, %6
  %19 = phi i32 [ -1, %10 ], [ %7, %6 ], [ -1, %14 ]
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @pc4(i8 noundef signext %0, i8 noundef signext %1) local_unnamed_addr #2 {
  %3 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #8
  store i64 1976943381783809, ptr %3, align 8
  store i8 %0, ptr %3, align 8
  %4 = getelementptr inbounds i8, ptr %3, i64 2
  store i8 %1, ptr %4, align 2
  %5 = tail call signext i8 @cq_theta_c(i8 noundef signext %0, double noundef 3.000000e-01) #9
  store i8 %5, ptr %3, align 8
  %6 = tail call signext i8 @cq_theta_c(i8 noundef signext %1, double noundef 4.000000e-01) #9
  store i8 %6, ptr %4, align 2
  %7 = call i32 @scan(ptr noundef nonnull %3)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #8
  ret i32 0
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define noundef i64 @len0(ptr noundef %0) local_unnamed_addr #5 {
  br label %2

2:                                                ; preds = %2, %1
  %3 = phi ptr [ %0, %1 ], [ %6, %2 ]
  %4 = load i8, ptr %3, align 1
  %5 = icmp eq i8 %4, 0
  %6 = getelementptr inbounds i8, ptr %3, i64 1
  br i1 %5, label %7, label %2, !llvm.loop !14

7:                                                ; preds = %2
  %8 = ptrtoint ptr %3 to i64
  %9 = ptrtoint ptr %0 to i64
  %10 = sub i64 %8, %9
  ret i64 %10
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define ptr @chrn(ptr noundef %0, i32 noundef %1) local_unnamed_addr #5 {
  %3 = and i32 %1, 255
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %2
  %6 = tail call i64 @len0(ptr noundef %0)
  %7 = getelementptr inbounds i8, ptr %0, i64 %6
  br label %39

8:                                                ; preds = %2
  %9 = ptrtoint ptr %0 to i64
  %10 = and i64 %9, 3
  %11 = icmp eq i64 %10, 0
  %12 = ptrtoint ptr %0 to i64
  %13 = and i64 %12, 3
  %14 = icmp eq i64 %13, 0
  %15 = or i1 %11, %14
  br i1 %15, label %29, label %16

16:                                               ; preds = %8
  %17 = trunc i32 %1 to i8
  br label %18

18:                                               ; preds = %16, %24
  %19 = phi ptr [ %0, %16 ], [ %25, %24 ]
  %20 = load i8, ptr %19, align 1
  %21 = icmp eq i8 %20, 0
  %22 = icmp eq i8 %20, %17
  %23 = or i1 %21, %22
  br i1 %23, label %39, label %24

24:                                               ; preds = %18
  %25 = getelementptr inbounds i8, ptr %19, i64 1
  %26 = ptrtoint ptr %25 to i64
  %27 = and i64 %26, 3
  %28 = icmp eq i64 %27, 0
  br i1 %28, label %29, label %18, !llvm.loop !15

29:                                               ; preds = %24, %8
  %30 = phi ptr [ %0, %8 ], [ %25, %24 ]
  %31 = trunc i32 %1 to i8
  br label %32

32:                                               ; preds = %32, %29
  %33 = phi ptr [ %30, %29 ], [ %38, %32 ]
  %34 = load i8, ptr %33, align 1
  %35 = icmp eq i8 %34, 0
  %36 = icmp eq i8 %34, %31
  %37 = or i1 %35, %36
  %38 = getelementptr inbounds i8, ptr %33, i64 1
  br i1 %37, label %39, label %32, !llvm.loop !16

39:                                               ; preds = %18, %32, %5
  %40 = phi ptr [ %7, %5 ], [ %33, %32 ], [ %19, %18 ]
  ret ptr %40
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @pa5(i8 noundef signext %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = alloca [16 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #8
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  store i8 %0, ptr %3, align 16
  %4 = getelementptr inbounds i8, ptr %3, i64 1
  store i8 3, ptr %4, align 1
  %5 = getelementptr inbounds i8, ptr %3, i64 2
  store i8 4, ptr %5, align 2
  %6 = getelementptr inbounds i8, ptr %3, i64 3
  store i8 0, ptr %6, align 1
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #9
  %8 = call ptr @chrn(ptr noundef nonnull %3, i32 noundef %7)
  %9 = ptrtoint ptr %8 to i64
  %10 = ptrtoint ptr %3 to i64
  %11 = sub i64 %9, %10
  %12 = call i64 @cq_measure_sl(i64 noundef %11) #8
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #8
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #4

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define ptr @wordscan(ptr noundef readonly %0, i8 noundef signext %1) local_unnamed_addr #5 {
  %3 = load i8, ptr %0, align 1
  %4 = icmp eq i8 %3, 0
  br i1 %4, label %13, label %5

5:                                                ; preds = %2, %10
  %6 = phi i8 [ %11, %10 ], [ %3, %2 ]
  %7 = phi ptr [ %9, %10 ], [ %0, %2 ]
  %8 = icmp eq i8 %6, %1
  %9 = getelementptr inbounds i8, ptr %7, i64 1
  br i1 %8, label %13, label %10

10:                                               ; preds = %5
  %11 = load i8, ptr %9, align 1
  %12 = icmp eq i8 %11, 0
  br i1 %12, label %13, label %5, !llvm.loop !17

13:                                               ; preds = %10, %5, %2
  %14 = phi ptr [ %0, %2 ], [ %9, %5 ], [ %9, %10 ]
  ret ptr %14
}

; Function Attrs: nounwind ssp uwtable
define noundef i64 @pc3(i8 noundef signext %0, i8 noundef signext %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = alloca [16 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #8
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) @__const.pc3.x, i64 16, i1 false)
  %5 = getelementptr inbounds i8, ptr %4, i64 1
  store i8 %0, ptr %5, align 1
  %6 = getelementptr inbounds i8, ptr %4, i64 3
  store i8 %1, ptr %6, align 1
  %7 = tail call signext i8 @cq_theta_c(i8 noundef signext %0, double noundef 3.000000e-01) #9
  store i8 %7, ptr %5, align 1
  %8 = load i8, ptr %6, align 1
  %9 = tail call signext i8 @cq_theta_c(i8 noundef signext %8, double noundef 4.000000e-01) #9
  store i8 %9, ptr %6, align 1
  %10 = and i32 %2, 1
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %14

12:                                               ; preds = %3
  %13 = call ptr @wordscan(ptr noundef nonnull %4, i8 noundef signext 3)
  br label %14

14:                                               ; preds = %12, %3
  %15 = phi ptr [ %4, %3 ], [ %13, %12 ]
  %16 = ptrtoint ptr %15 to i64
  %17 = ptrtoint ptr %4 to i64
  %18 = sub i64 %16, %17
  %19 = call i64 @cq_measure_sl(i64 noundef %18) #8
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #8
  ret i64 0
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #7

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #7 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { nounwind }
attributes #9 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !8}
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !8}
!13 = distinct !{!13, !8}
!14 = distinct !{!14, !7, !8}
!15 = distinct !{!15, !7, !8}
!16 = distinct !{!16, !7, !8}
!17 = distinct !{!17, !8}
