; ModuleID = 'fatptr.c'
source_filename = "fatptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@G = global [8 x i32] zeroinitializer, align 16
@H = global [8 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @f_ne_two(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
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
  %19 = call i32 @cq_measure_si32(i32 noundef %18) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
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
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #5
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
  %26 = call i32 @cq_measure_si32(i32 noundef %25) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %26
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_eq_arms(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
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
  %23 = call i32 @cq_measure_si32(i32 noundef %22) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %23
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_lt_global(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
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
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_eq_signed(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = srem i32 %3, 4
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds i32, ptr getelementptr inbounds (i8, ptr @G, i64 16), i64 %5
  %7 = ashr i32 %3, 4
  %8 = srem i32 %7, 4
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds i32, ptr getelementptr inbounds (i8, ptr @H, i64 16), i64 %9
  %11 = icmp eq ptr %6, %10
  %12 = zext i1 %11 to i32
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #5
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
