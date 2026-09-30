; railbank_stale_reject_runtime_bank_measure_after_ry.ll
;
; A runtime-sized bank parks one rail before an Ry, then explicitly measures its cells.
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

source_filename = "s02_rt_parkloop_ry_measloop.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %0, 2
  br i1 %3, label %30, label %4

4:                                                ; preds = %2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #4
  %6 = zext nneg i32 %0 to i64
  %7 = tail call ptr @llvm.stacksave.p0()
  %8 = alloca i32, i64 %6, align 16
  %9 = zext nneg i32 %0 to i64
  br label %13

10:                                               ; preds = %13
  %11 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 0x3FE6666666666666) #4
  %12 = zext nneg i32 %0 to i64
  br label %21

13:                                               ; preds = %4, %13
  %14 = phi i64 [ 0, %4 ], [ %16, %13 ]
  %15 = getelementptr inbounds i32, ptr %8, i64 %14
  store i32 %5, ptr %15, align 4, !tbaa !6
  %16 = add nuw nsw i64 %14, 1
  %17 = icmp eq i64 %16, %9
  br i1 %17, label %10, label %13, !llvm.loop !10

18:                                               ; preds = %21
  %19 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %20 = add nsw i32 %19, %27
  tail call void @llvm.stackrestore.p0(ptr %7)
  br label %30

21:                                               ; preds = %10, %21
  %22 = phi i64 [ 0, %10 ], [ %28, %21 ]
  %23 = phi i32 [ 0, %10 ], [ %27, %21 ]
  %24 = getelementptr inbounds i32, ptr %8, i64 %22
  %25 = load i32, ptr %24, align 4, !tbaa !6
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #4
  %27 = add nsw i32 %26, %23
  %28 = add nuw nsw i64 %22, 1
  %29 = icmp eq i64 %28, %12
  br i1 %29, label %18, label %21, !llvm.loop !13

30:                                               ; preds = %2, %18
  %31 = phi i32 [ %20, %18 ], [ 0, %2 ]
  ret i32 %31
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 2
  %4 = tail call i32 @slice(i32 noundef %3, i32 noundef 1)
  ret i32 %4
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
