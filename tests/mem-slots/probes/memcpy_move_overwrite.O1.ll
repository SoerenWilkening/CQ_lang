; ModuleID = 'memcpy_move_overwrite.c'
source_filename = "memcpy_move_overwrite.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @memcpy_move_overwrite(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  %6 = add nsw i32 %5, 1
  store i32 %6, ptr %3, align 16, !tbaa !6
  %7 = add nsw i32 %5, 2
  %8 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 %7, ptr %8, align 4, !tbaa !6
  %9 = mul nsw i32 %5, 3
  %10 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 %9, ptr %10, align 8, !tbaa !6
  %11 = xor i32 %5, 9
  %12 = getelementptr inbounds i8, ptr %3, i64 12
  store i32 %11, ptr %12, align 4, !tbaa !6
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) %3, i64 16, i1 false)
  %13 = mul nsw i32 %5, 5
  store i32 %13, ptr %8, align 4, !tbaa !6
  %14 = and i32 %0, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = and i32 %1, 3
  %19 = zext nneg i32 %18 to i64
  %20 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %19
  %21 = load i32, ptr %20, align 4, !tbaa !6
  %22 = add nsw i32 %21, %17
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %22
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @memcpy_move_overwrite_reg(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  %6 = add nsw i32 %5, 1
  store i32 %6, ptr %3, align 16, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 %5, ptr %7, align 4, !tbaa !6
  %8 = mul nsw i32 %5, 3
  %9 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 %8, ptr %9, align 8, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %3, i64 12
  store i32 3, ptr %10, align 4, !tbaa !6
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) %3, i64 16, i1 false)
  %11 = mul nsw i32 %5, 5
  store i32 %11, ptr %7, align 4, !tbaa !6
  %12 = and i32 %0, 3
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %13
  %15 = load i32, ptr %14, align 4, !tbaa !6
  %16 = and i32 %1, 3
  %17 = zext nneg i32 %16 to i64
  %18 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !6
  %20 = add nsw i32 %19, %15
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @memcpy_move_overwrite_seed(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  %6 = add nsw i32 %5, 1
  store i32 %6, ptr %3, align 16, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 7, ptr %7, align 4, !tbaa !6
  %8 = mul nsw i32 %5, 3
  %9 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 %8, ptr %9, align 8, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %3, i64 12
  store i32 3, ptr %10, align 4, !tbaa !6
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) %3, i64 16, i1 false)
  store i32 5, ptr %7, align 4, !tbaa !6
  %11 = and i32 %0, 3
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !6
  %15 = and i32 %1, 3
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %16
  %18 = load i32, ptr %17, align 4, !tbaa !6
  %19 = add nsw i32 %18, %14
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %19
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
; USERCHECK memcpy_move_overwrite
; USERCHECK memcpy_move_overwrite_reg
; USERCHECK memcpy_move_overwrite_seed
