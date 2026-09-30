; railbank_reject_measure_after_nondiagonal_on_parked_rail.ll
;
; A fixed bank parks one rail before an Ry, then reads and explicitly measures the parked values.
;
; Safety net for stale quantum values reached through bank storage.
; Reusing the rotated rail silently changes what these explicit measures observe.
; Coherent basis fanout at the park point can retain earlier basis values and
; their correlations; that operation is not unknown-state cloning (NORTHSTAR
;  goal 1). The current lowering lacks that history and must keep its loud fence.
; Retire this negative when a proved lowering preserves the parked values,
; subsequent interference and explicit measures, with analytic and trace evidence.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq opcode lowering: rotation/measure operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [3 x i32], align 4
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %2) #3
  br label %6

4:                                                ; preds = %6
  %5 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #3
  br label %14

6:                                                ; preds = %1, %6
  %7 = phi i64 [ 0, %1 ], [ %9, %6 ]
  %8 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %7
  store i32 %3, ptr %8, align 4, !tbaa !6
  %9 = add nuw nsw i64 %7, 1
  %10 = icmp eq i64 %9, 3
  br i1 %10, label %4, label %6, !llvm.loop !10

11:                                               ; preds = %14
  %12 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  %13 = add nsw i32 %12, %20
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %2) #3
  ret i32 %13

14:                                               ; preds = %4, %14
  %15 = phi i64 [ 0, %4 ], [ %21, %14 ]
  %16 = phi i32 [ 0, %4 ], [ %20, %14 ]
  %17 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %15
  %18 = load i32, ptr %17, align 4, !tbaa !6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %20 = add nsw i32 %19, %16
  %21 = add nuw nsw i64 %15, 1
  %22 = icmp eq i64 %21, 3
  br i1 %22, label %11, label %14, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i32], align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %1) #3
  br label %5

3:                                                ; preds = %5
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666) #3
  br label %10

5:                                                ; preds = %5, %0
  %6 = phi i64 [ 0, %0 ], [ %8, %5 ]
  %7 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %6
  store i32 %2, ptr %7, align 4, !tbaa !6
  %8 = add nuw nsw i64 %6, 1
  %9 = icmp eq i64 %8, 3
  br i1 %9, label %3, label %5, !llvm.loop !10

10:                                               ; preds = %10, %3
  %11 = phi i64 [ 0, %3 ], [ %17, %10 ]
  %12 = phi i32 [ 0, %3 ], [ %16, %10 ]
  %13 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %11
  %14 = load i32, ptr %13, align 4, !tbaa !6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %16 = add nsw i32 %15, %12
  %17 = add nuw nsw i64 %11, 1
  %18 = icmp eq i64 %17, 3
  br i1 %18, label %19, label %10, !llvm.loop !13

19:                                               ; preds = %10
  %20 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %21 = add nsw i32 %20, %16
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %1) #3
  ret i32 %21
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
