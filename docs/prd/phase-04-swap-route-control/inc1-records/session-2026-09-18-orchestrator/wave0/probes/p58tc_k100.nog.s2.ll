; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_k100.nog.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_k100.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  br label %3

2:                                                ; preds = %3
  ret i32 %7

3:                                                ; preds = %3, %1
  %4 = phi i32 [ 0, %1 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %8, %3 ]
  %h = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %h_op)
  %6 = add i32 %m, %4
  %7 = add i32 %6, %m1
  %8 = add nuw nsw i32 %5, 1
  %9 = icmp eq i32 %8, 100
  br i1 %9, label %2, label %3, !llvm.loop !6
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  br label %1

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %6, %1 ]
  %h = call i32 @cqrt_alloc_i32(i32 1)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %h_op)
  %4 = add i32 %m, %2
  %5 = add i32 %4, %m1
  %6 = add nuw nsw i32 %3, 1
  %7 = icmp eq i32 %6, 100
  br i1 %7, label %8, label %1, !llvm.loop !6

8:                                                ; preds = %1
  ret i32 %5
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

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
