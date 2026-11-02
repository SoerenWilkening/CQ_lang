; ModuleID = 'param_handoff.c'
source_filename = "param_handoff.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @param_handoff_pred(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = sitofp i32 %1 to double
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %4) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  store i32 7, ptr %3, align 4, !tbaa !6
  %6 = call fastcc i32 @outer(i32 noundef %5, ptr noundef nonnull %3)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #7
  %8 = mul nsw i32 %7, 1000
  %9 = load i32, ptr %3, align 4, !tbaa !6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #7
  %11 = add nsw i32 %10, %8
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #7
  ret i32 %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc i32 @outer(i32 noundef %0, ptr nocapture noundef %1) unnamed_addr #3 {
  %3 = icmp slt i32 %0, 100
  br i1 %3, label %4, label %12

4:                                                ; preds = %2
  %5 = icmp eq i32 %0, 0
  br i1 %5, label %11, label %6

6:                                                ; preds = %4
  %7 = shl nsw i32 %0, 1
  %8 = tail call fastcc i32 @inner(i32 noundef %7, ptr noundef %1)
  %9 = load i32, ptr %1, align 4, !tbaa !6
  %10 = add nsw i32 %9, -1
  store i32 %10, ptr %1, align 4, !tbaa !6
  br label %14

11:                                               ; preds = %4
  store i32 0, ptr %1, align 4, !tbaa !6
  br label %14

12:                                               ; preds = %2
  %13 = add nuw nsw i32 %0, 1
  br label %14

14:                                               ; preds = %12, %11, %6
  %15 = phi i32 [ %8, %6 ], [ 0, %11 ], [ %13, %12 ]
  ret i32 %15
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @param_handoff_plain(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = sitofp i32 %1 to double
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %4) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  store i32 2, ptr %3, align 4, !tbaa !6
  %6 = call fastcc i32 @upd(i32 noundef %5, ptr noundef nonnull %3)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #7
  %8 = mul nsw i32 %7, 1000
  %9 = load i32, ptr %3, align 4, !tbaa !6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #7
  %11 = add nsw i32 %10, %8
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #7
  ret i32 %11
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc range(i32 -2147483648, 1073741824) i32 @upd(i32 noundef %0, ptr nocapture noundef %1) unnamed_addr #3 {
  %3 = add nsw i32 %0, 1
  %4 = tail call fastcc i32 @fwd(i32 noundef %3, ptr noundef %1)
  %5 = load i32, ptr %1, align 4, !tbaa !6
  %6 = add nsw i32 %5, 5
  store i32 %6, ptr %1, align 4, !tbaa !6
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @param_handoff_rec(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = sitofp i32 %1 to double
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %5) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #7
  store i32 9, ptr %4, align 4, !tbaa !6
  %7 = and i32 %6, 3
  %8 = call fastcc i32 @rec(i32 noundef %7, i32 noundef %6, ptr noundef nonnull %4)
  %9 = add nsw i32 %8, %2
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #7
  %11 = mul nsw i32 %10, 1000
  %12 = load i32, ptr %4, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #7
  %14 = add nsw i32 %13, %11
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #7
  ret i32 %14
}

; Function Attrs: nofree noinline nosync nounwind ssp memory(argmem: readwrite) uwtable
define internal fastcc i32 @rec(i32 noundef %0, i32 noundef %1, ptr nocapture noundef %2) unnamed_addr #4 {
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %11, label %5

5:                                                ; preds = %3
  %6 = add nsw i32 %0, -1
  %7 = shl nsw i32 %1, 1
  %8 = tail call fastcc i32 @rec(i32 noundef %6, i32 noundef %7, ptr noundef %2)
  %9 = load i32, ptr %2, align 4, !tbaa !6
  %10 = add nsw i32 %9, -1
  br label %11

11:                                               ; preds = %3, %5
  %12 = phi i32 [ %10, %5 ], [ 0, %3 ]
  %13 = phi i32 [ %8, %5 ], [ %1, %3 ]
  store i32 %12, ptr %2, align 4, !tbaa !6
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @param_handoff_two(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = sitofp i32 %1 to double
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %6) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #7
  store i32 %2, ptr %4, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #7
  %8 = add nsw i32 %2, 1
  store i32 %8, ptr %5, align 4, !tbaa !6
  %9 = call fastcc i32 @outer2(i32 noundef %7, ptr noundef nonnull %4)
  %10 = add nsw i32 %7, 1
  %11 = call fastcc i32 @outer2(i32 noundef %10, ptr noundef nonnull %5)
  %12 = add nsw i32 %11, %9
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #7
  %14 = mul nsw i32 %13, 1000000
  %15 = load i32, ptr %4, align 4, !tbaa !6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #7
  %17 = mul nsw i32 %16, 1000
  %18 = add nsw i32 %17, %14
  %19 = load i32, ptr %5, align 4, !tbaa !6
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #7
  %21 = add nsw i32 %18, %20
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #7
  ret i32 %21
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc noundef i32 @outer2(i32 noundef %0, ptr nocapture noundef %1) unnamed_addr #3 {
  %3 = tail call fastcc i32 @inner2(i32 noundef %0, ptr noundef %1)
  %4 = icmp sgt i32 %0, 5
  br i1 %4, label %5, label %8

5:                                                ; preds = %2
  %6 = load i32, ptr %1, align 4, !tbaa !6
  %7 = mul nsw i32 %6, 3
  store i32 %7, ptr %1, align 4, !tbaa !6
  br label %8

8:                                                ; preds = %5, %2
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @triple_clone_cell(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = sitofp i32 %1 to double
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %6) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #7
  store i32 %2, ptr %4, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #7
  %8 = add nsw i32 %2, 1
  store i32 %8, ptr %5, align 4, !tbaa !6
  %9 = call fastcc i32 @scale(i32 noundef %7, ptr noundef nonnull %4)
  %10 = add nsw i32 %7, 1
  %11 = call fastcc i32 @scale(i32 noundef %10, ptr noundef nonnull %5)
  %12 = add nsw i32 %11, %9
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #7
  %14 = mul nsw i32 %13, 1000000
  %15 = load i32, ptr %4, align 4, !tbaa !6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #7
  %17 = mul nsw i32 %16, 1000
  %18 = add nsw i32 %17, %14
  %19 = load i32, ptr %5, align 4, !tbaa !6
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #7
  %21 = add nsw i32 %18, %20
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #7
  ret i32 %21
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc noundef i32 @scale(i32 noundef %0, ptr nocapture noundef %1) unnamed_addr #3 {
  %3 = icmp sgt i32 %0, 5
  br i1 %3, label %4, label %7

4:                                                ; preds = %2
  %5 = load i32, ptr %1, align 4, !tbaa !6
  %6 = mul nsw i32 %5, 3
  store i32 %6, ptr %1, align 4, !tbaa !6
  br label %7

7:                                                ; preds = %4, %2
  %8 = xor i32 %0, 5
  ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @param_uninit(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = sitofp i32 %1 to double
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %4) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  %6 = call fastcc i32 @nib(i32 noundef %5, ptr noundef nonnull %3)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #7
  %8 = mul nsw i32 %7, 1000
  %9 = load i32, ptr %3, align 4, !tbaa !6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #7
  %11 = add nsw i32 %10, %8
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #7
  ret i32 %11
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc noundef i32 @nib(i32 noundef %0, ptr nocapture noundef %1) unnamed_addr #3 {
  %3 = lshr i32 %0, 4
  %4 = and i32 %3, 7
  switch i32 %4, label %15 [
    i32 0, label %5
    i32 7, label %18
  ]

5:                                                ; preds = %2
  %6 = icmp eq i32 %0, 0
  br i1 %6, label %12, label %7

7:                                                ; preds = %5
  %8 = shl nsw i32 %0, 4
  %9 = tail call fastcc i32 @odd(i32 noundef %8, ptr noundef %1)
  %10 = load i32, ptr %1, align 4, !tbaa !6
  %11 = add nsw i32 %10, -4
  br label %12

12:                                               ; preds = %5, %7
  %13 = phi i32 [ %11, %7 ], [ 0, %5 ]
  %14 = phi i32 [ %9, %7 ], [ 0, %5 ]
  store i32 %13, ptr %1, align 4, !tbaa !6
  br label %18

15:                                               ; preds = %2
  %16 = add nsw i32 %4, -3
  store i32 %16, ptr %1, align 4, !tbaa !6
  %17 = and i32 %0, 15
  br label %18

18:                                               ; preds = %2, %15, %12
  %19 = phi i32 [ %17, %15 ], [ %14, %12 ], [ %0, %2 ]
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @sibling_arm_store(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = sitofp i32 %1 to double
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %4) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  %6 = call fastcc i32 @nib2(i32 noundef %5, ptr noundef nonnull %3)
  %7 = load i32, ptr %3, align 4, !tbaa !6
  %8 = add i32 %7, -9
  %9 = icmp ult i32 %8, -6
  br i1 %9, label %10, label %17

10:                                               ; preds = %2
  %11 = icmp ult i32 %6, 7
  br i1 %11, label %12, label %15

12:                                               ; preds = %10
  %13 = add nsw i32 %7, -1
  store i32 %13, ptr %3, align 4, !tbaa !6
  %14 = shl nuw nsw i32 %6, 1
  br label %22

15:                                               ; preds = %10
  %16 = add nsw i32 %6, -1
  br label %22

17:                                               ; preds = %2
  %18 = icmp ult i32 %6, 4
  br i1 %18, label %19, label %22

19:                                               ; preds = %17
  %20 = add nsw i32 %7, -1
  store i32 %20, ptr %3, align 4, !tbaa !6
  %21 = add nuw nsw i32 %6, 3
  br label %22

22:                                               ; preds = %17, %19, %12, %15
  %23 = phi i32 [ %14, %12 ], [ %16, %15 ], [ %21, %19 ], [ %6, %17 ]
  %24 = mul nuw nsw i32 %23, 100
  %25 = load i32, ptr %3, align 4, !tbaa !6
  %26 = add nsw i32 %24, %25
  %27 = tail call i32 @cq_measure_si32(i32 noundef %26) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #7
  ret i32 %27
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc noundef range(i32 0, 16) i32 @nib2(i32 noundef %0, ptr nocapture noundef writeonly %1) unnamed_addr #5 {
  %3 = lshr i32 %0, 4
  %4 = and i32 %3, 7
  store i32 %4, ptr %1, align 4, !tbaa !6
  %5 = and i32 %0, 15
  ret i32 %5
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc range(i32 -2147483648, 1073741824) i32 @inner(i32 noundef %0, ptr nocapture noundef writeonly %1) unnamed_addr #5 {
  %3 = icmp sgt i32 %0, 3
  br i1 %3, label %4, label %7

4:                                                ; preds = %2
  %5 = add nsw i32 %0, -3
  store i32 %5, ptr %1, align 4, !tbaa !6
  %6 = lshr i32 %0, 1
  br label %7

7:                                                ; preds = %2, %4
  %8 = phi i32 [ %6, %4 ], [ %0, %2 ]
  ret i32 %8
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc range(i32 -2147483648, 1073741824) i32 @fwd(i32 noundef %0, ptr nocapture noundef writeonly %1) unnamed_addr #5 {
  %3 = tail call fastcc i32 @inner(i32 noundef %0, ptr noundef %1)
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc noundef i32 @inner2(i32 noundef %0, ptr nocapture noundef writeonly %1) unnamed_addr #5 {
  %3 = and i32 %0, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %2
  %6 = add nsw i32 %0, 3
  store i32 %6, ptr %1, align 4, !tbaa !6
  br label %7

7:                                                ; preds = %5, %2
  %8 = xor i32 %0, 5
  ret i32 %8
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc noundef range(i32 -1073741824, 1073741824) i32 @odd(i32 noundef %0, ptr nocapture noundef writeonly %1) unnamed_addr #5 {
  %3 = and i32 %0, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %6, label %5

5:                                                ; preds = %2
  store i32 %0, ptr %1, align 4, !tbaa !6
  br label %6

6:                                                ; preds = %5, %2
  %7 = ashr i32 %0, 1
  ret i32 %7
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree noinline nosync nounwind ssp memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

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
; CHECK __cq_q_outer_11: %cq.cells = alloca [1 x i32]
; CHECK __cq_q_rec_111_b3_ctl_d1: %cq.cells = alloca [1 x i32]
; CHECK __cq_q_outer2_1001: %cq.cells = alloca [1 x i32]
; CHECK __cq_q_nib_10: call void @cqrt_copy_i32(i32 %3, i32 %4)
; USERCHECK param_handoff_pred
; USERCHECK param_handoff_plain
; USERCHECK param_handoff_rec
; USERCHECK param_handoff_two
; USERCHECK triple_clone_cell
; USERCHECK param_uninit
; USERCHECK sibling_arm_store
