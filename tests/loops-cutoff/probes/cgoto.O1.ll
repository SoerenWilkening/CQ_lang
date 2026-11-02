; ModuleID = 'cgoto.c'
source_filename = "cgoto.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cg_classical.tbl = internal unnamed_addr constant [2 x ptr] [ptr blockaddress(@cg_classical, %13), ptr blockaddress(@cg_classical, %22)], align 16
@cg_quantum.tbl = internal unnamed_addr constant [2 x ptr] [ptr blockaddress(@cg_quantum, %13), ptr blockaddress(@cg_quantum, %15)], align 16
@cg_addr_classical.tbl = internal unnamed_addr constant [3 x ptr] [ptr blockaddress(@cg_addr_classical, %9), ptr blockaddress(@cg_addr_classical, %11), ptr blockaddress(@cg_addr_classical, %13)], align 16
@cg_addr_quantum.tbl = internal unnamed_addr constant [4 x ptr] [ptr blockaddress(@cg_addr_quantum, %8), ptr blockaddress(@cg_addr_quantum, %10), ptr blockaddress(@cg_addr_quantum, %12), ptr blockaddress(@cg_addr_quantum, %8)], align 16
@cg_addr_phi.t1 = internal unnamed_addr constant [2 x ptr] [ptr blockaddress(@cg_addr_phi, %16), ptr blockaddress(@cg_addr_phi, %18)], align 16
@cg_addr_phi.t2 = internal unnamed_addr constant [3 x ptr] [ptr blockaddress(@cg_addr_phi, %18), ptr blockaddress(@cg_addr_phi, %20), ptr blockaddress(@cg_addr_phi, %16)], align 16
@cg_exit.tbl = internal unnamed_addr constant [2 x ptr] [ptr blockaddress(@cg_exit, %16), ptr blockaddress(@cg_exit, %19)], align 16
@cg_exit_k.tbl = internal unnamed_addr constant [2 x ptr] [ptr blockaddress(@cg_exit_k, %18), ptr blockaddress(@cg_exit_k, %20)], align 16
@cg_callee.tbl = internal unnamed_addr constant [3 x ptr] [ptr blockaddress(@cg_callee, %7), ptr blockaddress(@cg_callee, %9), ptr blockaddress(@cg_callee, %11)], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @cg_classical(i32 noundef %0, double noundef %1) #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %24, label %6

6:                                                ; preds = %2, %16
  %7 = phi i32 [ %18, %16 ], [ 0, %2 ]
  %8 = phi i32 [ %17, %16 ], [ 1, %2 ]
  %9 = and i32 %7, 1
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [2 x ptr], ptr @cg_classical.tbl, i64 0, i64 %10
  %12 = load ptr, ptr %11, align 8, !tbaa !6
  indirectbr ptr %12, [label %13, label %22]

13:                                               ; preds = %6
  %14 = mul nsw i32 %8, 3
  %15 = add nsw i32 %14, 1
  br label %16

16:                                               ; preds = %13, %22
  %17 = phi i32 [ %15, %13 ], [ %23, %22 ]
  %18 = add nuw nsw i32 %7, 1
  %19 = shl nuw i32 2, %7
  %20 = and i32 %19, %3
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %24, label %6, !llvm.loop !10

22:                                               ; preds = %6
  %23 = add nsw i32 %8, 7
  br label %16

24:                                               ; preds = %16, %2
  %25 = phi i32 [ 1, %2 ], [ %17, %16 ]
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #4
  ret i32 %26
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @cg_quantum(i32 noundef %0, double noundef %1) #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %17, %2
  %5 = phi i32 [ 1, %2 ], [ %18, %17 ]
  %6 = phi i32 [ 0, %2 ], [ %19, %17 ]
  %7 = add nuw nsw i32 %6, 4
  %8 = lshr i32 %3, %7
  %9 = and i32 %8, 1
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [2 x ptr], ptr @cg_quantum.tbl, i64 0, i64 %10
  %12 = load ptr, ptr %11, align 8, !tbaa !6
  indirectbr ptr %12, [label %13, label %15]

13:                                               ; preds = %4
  %14 = mul nsw i32 %5, 5
  br label %17

15:                                               ; preds = %4
  %16 = add nsw i32 %5, 3
  br label %17

17:                                               ; preds = %15, %13
  %18 = phi i32 [ %14, %13 ], [ %16, %15 ]
  %19 = add nuw nsw i32 %6, 1
  %20 = shl i32 2, %6
  %21 = and i32 %20, %3
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %4, !llvm.loop !13

23:                                               ; preds = %17
  %24 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  ret i32 %24
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_addr_classical(i32 noundef %0, i32 noundef %1, double noundef %2) #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  %5 = urem i32 %1, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [3 x ptr], ptr @cg_addr_classical.tbl, i64 0, i64 %6
  %8 = load ptr, ptr %7, align 8, !tbaa !6
  indirectbr ptr %8, [label %9, label %11, label %13]

9:                                                ; preds = %3
  %10 = add nsw i32 %4, 1
  br label %15

11:                                               ; preds = %3
  %12 = mul nsw i32 %4, 3
  br label %15

13:                                               ; preds = %3
  %14 = xor i32 %4, 5
  br label %15

15:                                               ; preds = %13, %11, %9
  %16 = phi i32 [ %10, %9 ], [ %14, %13 ], [ %12, %11 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #4
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_addr_quantum(i32 noundef %0, double noundef %1) #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %4 = and i32 %3, 3
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds [4 x ptr], ptr @cg_addr_quantum.tbl, i64 0, i64 %5
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  indirectbr ptr %7, [label %8, label %10, label %12]

8:                                                ; preds = %2
  %9 = add nsw i32 %3, 1
  br label %14

10:                                               ; preds = %2
  %11 = mul nsw i32 %3, 3
  br label %14

12:                                               ; preds = %2
  %13 = xor i32 %3, 5
  br label %14

14:                                               ; preds = %12, %10, %8
  %15 = phi i32 [ %9, %8 ], [ %13, %12 ], [ %11, %10 ]
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #4
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_addr_phi(i32 noundef %0, i32 noundef %1, double noundef %2) #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  %5 = icmp sgt i32 %4, 3
  br i1 %5, label %6, label %10

6:                                                ; preds = %3
  %7 = and i32 %1, 1
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [2 x ptr], ptr @cg_addr_phi.t1, i64 0, i64 %8
  br label %23

10:                                               ; preds = %3
  %11 = urem i32 %4, 3
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [3 x ptr], ptr @cg_addr_phi.t2, i64 0, i64 %12
  %14 = mul i32 %4, 5
  %15 = add i32 %14, -10
  br label %23

16:                                               ; preds = %23
  %17 = add nsw i32 %4, 1
  br label %20

18:                                               ; preds = %23
  %19 = mul nsw i32 %4, 3
  br label %20

20:                                               ; preds = %23, %18, %16
  %21 = phi i32 [ %17, %16 ], [ %19, %18 ], [ %24, %23 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #4
  ret i32 %22

23:                                               ; preds = %10, %6
  %24 = phi i32 [ undef, %6 ], [ %15, %10 ]
  %25 = phi ptr [ %9, %6 ], [ %13, %10 ]
  %26 = load ptr, ptr %25, align 8, !tbaa !6
  indirectbr ptr %26, [label %16, label %18, label %20]
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_addr_carried(i32 noundef %0, i32 noundef %1, double noundef %2) #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %23

6:                                                ; preds = %3, %18
  %7 = phi i32 [ %21, %18 ], [ 0, %3 ]
  %8 = phi i32 [ %20, %18 ], [ 1, %3 ]
  %9 = phi ptr [ %19, %18 ], [ blockaddress(@cg_addr_carried, %10), %3 ]
  indirectbr ptr %9, [label %10, label %16]

10:                                               ; preds = %6
  %11 = mul nsw i32 %8, 3
  %12 = shl nuw i32 1, %7
  %13 = and i32 %12, %4
  %14 = icmp eq i32 %13, 0
  %15 = select i1 %14, ptr blockaddress(@cg_addr_carried, %10), ptr blockaddress(@cg_addr_carried, %16)
  br label %18

16:                                               ; preds = %6
  %17 = add nsw i32 %8, 7
  br label %18

18:                                               ; preds = %16, %10
  %19 = phi ptr [ %15, %10 ], [ blockaddress(@cg_addr_carried, %10), %16 ]
  %20 = phi i32 [ %11, %10 ], [ %17, %16 ]
  %21 = add nuw nsw i32 %7, 1
  %22 = icmp eq i32 %21, %1
  br i1 %22, label %23, label %6, !llvm.loop !14

23:                                               ; preds = %18, %3
  %24 = phi i32 [ 1, %3 ], [ %20, %18 ]
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24) #4
  ret i32 %25
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_addr_reload(i32 noundef %0, i32 noundef %1, double noundef %2) #0 {
  %4 = alloca [2 x ptr], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  store ptr blockaddress(@cg_addr_reload, %14), ptr %4, align 16, !tbaa !6
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, ptr blockaddress(@cg_addr_reload, %14), ptr blockaddress(@cg_addr_reload, %16)
  %9 = getelementptr inbounds i8, ptr %4, i64 8
  store ptr %8, ptr %9, align 8, !tbaa !6
  %10 = and i32 %1, 1
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [2 x ptr], ptr %4, i64 0, i64 %11
  %13 = load ptr, ptr %12, align 8, !tbaa !6
  indirectbr ptr %13, [label %14, label %16]

14:                                               ; preds = %3
  %15 = add nsw i32 %1, 1
  br label %18

16:                                               ; preds = %3
  %17 = mul nsw i32 %1, 3
  br label %18

18:                                               ; preds = %16, %14
  %19 = phi i32 [ %15, %14 ], [ %17, %16 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_addr_kloop(i32 noundef %0, double noundef %1) #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %16, %2
  %5 = phi ptr [ blockaddress(@cg_addr_kloop, %8), %2 ], [ %17, %16 ]
  %6 = phi i32 [ 1, %2 ], [ %18, %16 ]
  %7 = phi i32 [ 0, %2 ], [ %19, %16 ]
  indirectbr ptr %5, [label %8, label %14]

8:                                                ; preds = %4
  %9 = mul nsw i32 %6, 3
  %10 = shl nuw i32 1, %7
  %11 = and i32 %10, %3
  %12 = icmp eq i32 %11, 0
  %13 = select i1 %12, ptr blockaddress(@cg_addr_kloop, %8), ptr blockaddress(@cg_addr_kloop, %14)
  br label %16

14:                                               ; preds = %4
  %15 = add nsw i32 %6, 7
  br label %16

16:                                               ; preds = %14, %8
  %17 = phi ptr [ %13, %8 ], [ blockaddress(@cg_addr_kloop, %8), %14 ]
  %18 = phi i32 [ %9, %8 ], [ %15, %14 ]
  %19 = add nuw nsw i32 %7, 1
  %20 = shl i32 512, %7
  %21 = and i32 %20, %3
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %4, !llvm.loop !15

23:                                               ; preds = %16
  %24 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  ret i32 %24
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_addr_qram(i32 noundef %0, i32 noundef %1, double noundef %2) #0 {
  %4 = alloca [4 x ptr], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  store ptr blockaddress(@cg_addr_qram, %16), ptr %4, align 16, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %4, i64 8
  store ptr blockaddress(@cg_addr_qram, %16), ptr %6, align 8, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %4, i64 16
  store ptr blockaddress(@cg_addr_qram, %16), ptr %7, align 16, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %4, i64 24
  store ptr blockaddress(@cg_addr_qram, %16), ptr %8, align 8, !tbaa !6
  %9 = and i32 %5, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [4 x ptr], ptr %4, i64 0, i64 %10
  store ptr blockaddress(@cg_addr_qram, %18), ptr %11, align 8, !tbaa !6
  %12 = and i32 %1, 3
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [4 x ptr], ptr %4, i64 0, i64 %13
  %15 = load ptr, ptr %14, align 8, !tbaa !6
  indirectbr ptr %15, [label %16, label %18]

16:                                               ; preds = %3
  %17 = add nsw i32 %1, 1
  br label %20

18:                                               ; preds = %3
  %19 = mul nsw i32 %1, 3
  br label %20

20:                                               ; preds = %18, %16
  %21 = phi i32 [ %17, %16 ], [ %19, %18 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #4
  ret i32 %22
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_addr_clone(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  %5 = tail call fastcc i32 @cg_callee(i32 noundef %4, i32 noundef %1)
  %6 = tail call fastcc i32 @cg_callee(i32 noundef %1, i32 noundef 1)
  %7 = add nsw i32 %6, %5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  ret i32 %8
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc i32 @cg_callee(i32 noundef %0, i32 noundef %1) #2 {
  %3 = urem i32 %0, 3
  %4 = zext nneg i32 %3 to i64
  %5 = getelementptr inbounds [3 x ptr], ptr @cg_callee.tbl, i64 0, i64 %4
  %6 = load ptr, ptr %5, align 8, !tbaa !6
  indirectbr ptr %6, [label %7, label %9, label %11]

7:                                                ; preds = %2
  %8 = add nsw i32 %1, %0
  br label %13

9:                                                ; preds = %2
  %10 = mul nsw i32 %0, 3
  br label %13

11:                                               ; preds = %2
  %12 = xor i32 %1, %0
  br label %13

13:                                               ; preds = %11, %9, %7
  %14 = phi i32 [ %8, %7 ], [ %12, %11 ], [ %10, %9 ]
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_exit(i32 noundef %0, i32 noundef %1, double noundef %2) #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %19

6:                                                ; preds = %3, %16
  %7 = phi i32 [ %17, %16 ], [ 0, %3 ]
  %8 = phi i32 [ %10, %16 ], [ 1, %3 ]
  %9 = mul nsw i32 %8, 3
  %10 = add nsw i32 %9, %7
  %11 = lshr i32 %4, %7
  %12 = and i32 %11, 1
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [2 x ptr], ptr @cg_exit.tbl, i64 0, i64 %13
  %15 = load ptr, ptr %14, align 8, !tbaa !6
  indirectbr ptr %15, [label %16, label %19]

16:                                               ; preds = %6
  %17 = add nuw nsw i32 %7, 1
  %18 = icmp slt i32 %17, %1
  br i1 %18, label %6, label %19, !llvm.loop !16

19:                                               ; preds = %16, %3, %6
  %20 = phi i32 [ %10, %6 ], [ 1, %3 ], [ %10, %16 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #4
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @cg_exit_k(i32 noundef %0, double noundef %1) #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %18, %2
  %5 = phi i32 [ 1, %2 ], [ %8, %18 ]
  %6 = phi i32 [ 0, %2 ], [ %19, %18 ]
  %7 = mul nsw i32 %5, 3
  %8 = add nsw i32 %7, %6
  %9 = and i32 %6, 31
  %10 = lshr i32 %3, %9
  %11 = and i32 %10, 1
  %12 = icmp ugt i32 %6, 30
  %13 = zext i1 %12 to i32
  %14 = or i32 %11, %13
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [2 x ptr], ptr @cg_exit_k.tbl, i64 0, i64 %15
  %17 = load ptr, ptr %16, align 8, !tbaa !6
  indirectbr ptr %17, [label %18, label %20]

18:                                               ; preds = %4
  %19 = add nuw nsw i32 %6, 1
  br label %4, !llvm.loop !17

20:                                               ; preds = %4
  %21 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  ret i32 %21
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
!15 = distinct !{!15, !11, !12}
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !12}
