; DECLINE (bd `test_C_libtooling-01po.19`, review round 1 F3 (a)).
;
; An array declared INSIDE a loop body (`for (k) { int q[8]; ... }`, review probe
; h3_lifetime_two_stores.c): its `lifetime.start` is re-executed every outer trip
; and a `lifetime.end` separates the trips. S1 now claims it as a PER-ITERATION
; object: the quantization point is that `lifetime.start` (the cells get fresh rails
; every iteration, the old ones stay allocated, owner Q3), so the claim's `Q=` names
; it. It used to decline in the one-store bank (`array is written from more than one
; store site`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank'
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; CHECK: cq rail window: quantum array not lowered yet (bd 01po.19), needs S4 borrowed-root cells
; WIN: CQ_RAILWINDOW_DBG: @main claims %2 cells=i32 loads=1 stores=2 Q=  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #4

; ModuleID = 'h3_lifetime_two_stores.c'
source_filename = "h3_lifetime_two_stores.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [8 x i32], align 16
  %3 = icmp sgt i32 %0, 0
  %4 = icmp sgt i32 %0, 0
  %5 = add i32 %0, -1
  %6 = tail call i32 @llvm.umin.i32(i32 %5, i32 7)
  %7 = add nuw nsw i32 %6, 1
  %8 = tail call i32 @llvm.umin.i32(i32 %5, i32 7)
  %9 = add nuw nsw i32 %8, 1
  %10 = zext nneg i32 %7 to i64
  %11 = zext nneg i32 %9 to i64
  br label %13

12:                                               ; preds = %24
  ret i32 %25

13:                                               ; preds = %1, %24
  %14 = phi i32 [ 0, %1 ], [ %26, %24 ]
  %15 = phi i32 [ 0, %1 ], [ %25, %24 ]
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #4
  br i1 %3, label %17, label %16

16:                                               ; preds = %17, %13
  br i1 %4, label %28, label %24

17:                                               ; preds = %13, %17
  %18 = phi i64 [ %22, %17 ], [ 0, %13 ]
  %19 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %18
  store i32 %14, ptr %19, align 4, !tbaa !6
  %20 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-01) #5
  %21 = xor i32 %20, 1
  store i32 %21, ptr %19, align 4, !tbaa !6
  %22 = add nuw nsw i64 %18, 1
  %23 = icmp eq i64 %22, %10
  br i1 %23, label %16, label %17, !llvm.loop !10

24:                                               ; preds = %28, %16
  %25 = phi i32 [ %15, %16 ], [ %34, %28 ]
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #4
  %26 = add nuw nsw i32 %14, 1
  %27 = icmp eq i32 %14, 0
  br i1 %27, label %13, label %12, !llvm.loop !13

28:                                               ; preds = %16, %28
  %29 = phi i64 [ %35, %28 ], [ 0, %16 ]
  %30 = phi i32 [ %34, %28 ], [ %15, %16 ]
  %31 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %29
  %32 = load i32, ptr %31, align 4, !tbaa !6
  %33 = tail call i32 @cq_measure_si32(i32 noundef %32) #4
  %34 = add nsw i32 %33, %30
  %35 = add nuw nsw i64 %29, 1
  %36 = icmp eq i64 %35, %11
  br i1 %36, label %24, label %28, !llvm.loop !14
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

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
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
