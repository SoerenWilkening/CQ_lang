; railwindow_s6_p16_cascade_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19`
; S6; was railwindow_p16_pending.ll, which declined "needs S6 quantum control
; on cells"). docs/CQ_FINDINGS.md F5's p16: the controlled-Ry CASCADE over a
; `_Bool` array, rolled.
;
; Each trip i reads q[i-1] as the CONDITION REGISTER (a cell read, `CellCond`)
; and rotates q[i] in place under it (clause (d): q[i] is reloaded every trip);
; `promoteRailWindowArms` gave the arm its diamond, the target is frozen (R6),
; and nothing is minted, stripped or freed.
;
; ANALYTIC READING of the stream (e2e slice_rolled_p16_cascade, scratch
; state-vector propagation): Ry(.5) on q0, then CRy(q0 -> q1, .6),
; CRy(q1 -> q2, .9), CRy(q2 -> q3, 1.2) — the textbook cascade the source
; spells, angle .3*(i+1) per trip.
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdbool.h>
;   int main(void) {
;     bool q[4] = {0};
;     cq_theta(&q[0], .5);
;     for (int i = 1; i < 4; i++)
;       if (q[i-1]) cq_theta(&q[i], .3 * (i + 1));
;     int r = 0;
;     for (int i = 0; i < 4; i++) r += cq_measure(q[i]);
;     return r;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='error:' --implicit-check-not=cqrt_free \
; RUN:       --implicit-check-not=cq_template_ --implicit-check-not='call void @cqrt_ry_i1_controlled'
; CHECK-LABEL: define i32 @main(
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK: store i32 %h, ptr %.rails, align 4
; CHECK: %.rail = load i32, ptr %cq.rail.addr1, align 4
; CHECK: %cq.arm.in = load i32, ptr %cq.rail.addr, align 4
; CHECK: call void @cqrt_ry_i1_controlled(i32 %.rail, i32 %cq.arm.in, double %{{[0-9]+}})
; CHECK-NEXT: store i32 %cq.arm.in, ptr %cq.rail.addr, align 4
; CHECK: %m = call i1 @cqrt_measure_i1(i32 %.rail4)

; ModuleID = 'p16.c'
source_filename = "p16.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %3 = zext i1 %2 to i8
  store i8 %3, ptr %1, align 4, !tbaa !6
  br label %4

4:                                                ; preds = %0, %20
  %5 = phi i64 [ 1, %0 ], [ %21, %20 ]
  %6 = add nsw i64 %5, -1
  %7 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  br i1 %9, label %10, label %20

10:                                               ; preds = %4
  %11 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %12 = load i8, ptr %11, align 1, !tbaa !6, !range !10, !noundef !11
  %13 = trunc nuw i8 %12 to i1
  %14 = trunc i64 %5 to i32
  %15 = add i32 %14, 1
  %16 = uitofp nneg i32 %15 to double
  %17 = fmul double %16, 3.000000e-01
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef %17) #4
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %11, align 1, !tbaa !6
  br label %20

20:                                               ; preds = %4, %10
  %21 = add nuw nsw i64 %5, 1
  %22 = icmp eq i64 %21, 4
  br i1 %22, label %24, label %4, !llvm.loop !12

23:                                               ; preds = %24
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %32

24:                                               ; preds = %20, %24
  %25 = phi i64 [ %33, %24 ], [ 0, %20 ]
  %26 = phi i32 [ %32, %24 ], [ 0, %20 ]
  %27 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %25
  %28 = load i8, ptr %27, align 1, !tbaa !6, !range !10, !noundef !11
  %29 = trunc nuw i8 %28 to i1
  %30 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %29) #3
  %31 = zext i1 %30 to i32
  %32 = add nuw nsw i32 %26, %31
  %33 = add nuw nsw i64 %25, 1
  %34 = icmp eq i64 %33, 4
  br i1 %34, label %23, label %24, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
