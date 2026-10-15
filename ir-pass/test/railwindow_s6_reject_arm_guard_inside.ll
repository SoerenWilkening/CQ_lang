; railwindow_s6_reject_arm_guard_inside.ll — DECLINE (bd
; `test_C_libtooling-01po.19` S6 R11 round 2, finding F2, reviewer probe
; review_s6R2/p5.c). Under a CELL condition, two Ry on runtime cells q[i] and
; q[j]. S7 versions the arm on `&q[i] != &q[j]`, and its guard sits INSIDE the
; quantum arm, so each class is proven only there. Promoting the arm would
; hoist the in-loads to the quantum branch and write back at the merge, where
; i == j is possible: `promoteRailWindowArms` now asks `railWindowPairProven`
; at those plan points too and skips the region (WIN line), and the classical
; version branch inside the quantum arm is refused loudly by the control chain.
; (Lowering it — version the whole quantum region instead — is bd 01po.19.28.)
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdbool.h>
;   int main(int argc, char **argv){ bool q[4]={0};
;     int i = argc & 1, j = (argc >> 1) & 1;
;     for(int k=0;k<4;k++) cq_theta(&q[k], .5+.1*k);
;     if (q[3]) { cq_theta(&q[i], .3); cq_theta(&q[j], .7); }
;     int r=0; for(int k=0;k<4;k++) r=2*r+cq_measure(q[k]); return r; }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; CHECK: cq controlled lowering: control flow under quantum control{{$}}
; WIN: CQ_RAILWINDOW_DBG: arm not promoted: cell pair unproven at the arm, its branch or its merge

; ModuleID = 'railwindow_s6_reject_arm_guard_inside.c'
source_filename = "railwindow_s6_reject_arm_guard_inside.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #4
  store i32 0, ptr %3, align 4
  %4 = lshr i32 %0, 1
  br label %10

5:                                                ; preds = %10
  %6 = getelementptr inbounds i8, ptr %3, i64 3
  %7 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  br i1 %8, label %22, label %9

9:                                                ; preds = %22, %5
  br label %38

10:                                               ; preds = %2, %10
  %11 = phi i64 [ 0, %2 ], [ %20, %10 ]
  %12 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !10, !noundef !11
  %14 = trunc nuw i8 %13 to i1
  %15 = trunc nuw nsw i64 %11 to i32
  %16 = uitofp nneg i32 %15 to double
  %17 = tail call double @llvm.fmuladd.f64(double %16, double 1.000000e-01, double 5.000000e-01)
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %14, double noundef %17) #5
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %12, align 1, !tbaa !6
  %20 = add nuw nsw i64 %11, 1
  %21 = icmp eq i64 %20, 4
  br i1 %21, label %5, label %10, !llvm.loop !12

22:                                               ; preds = %5
  %23 = and i32 %4, 1
  %24 = and i32 %0, 1
  %25 = zext nneg i32 %24 to i64
  %26 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %25
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %28, double noundef 3.000000e-01) #5
  %30 = zext i1 %29 to i8
  store i8 %30, ptr %26, align 1, !tbaa !6
  %31 = zext nneg i32 %23 to i64
  %32 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %31
  %33 = load i8, ptr %32, align 1, !tbaa !6, !range !10, !noundef !11
  %34 = trunc nuw i8 %33 to i1
  %35 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %34, double noundef 0x3FE6666666666666) #5
  %36 = zext i1 %35 to i8
  store i8 %36, ptr %32, align 1, !tbaa !6
  br label %9

37:                                               ; preds = %38
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #4
  ret i32 %47

38:                                               ; preds = %9, %38
  %39 = phi i64 [ %48, %38 ], [ 0, %9 ]
  %40 = phi i32 [ %47, %38 ], [ 0, %9 ]
  %41 = shl nsw i32 %40, 1
  %42 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %39
  %43 = load i8, ptr %42, align 1, !tbaa !6, !range !10, !noundef !11
  %44 = trunc nuw i8 %43 to i1
  %45 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %44) #4
  %46 = zext i1 %45 to i32
  %47 = or disjoint i32 %41, %46
  %48 = add nuw nsw i64 %39, 1
  %49 = icmp eq i64 %48, 4
  br i1 %49, label %37, label %38, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
