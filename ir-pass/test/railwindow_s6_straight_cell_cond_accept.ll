; railwindow_s6_straight_cell_cond_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19` S6, quantum control on
; cells; design §5, owner ruling owner-ruling-01po19-rolled-design-2026-10-15).
; Contract: RailWindow.h (RailWindowArms.cpp), ArmClassify `CellCond`, clause (d).
;
; A CELL READ AS THE CONDITION (design §5 item 1) and an in-place controlled Ry
; on another cell (item 2). -O1 leaves the arm as `load q[2]; Ry; store` with no
; merge φ; `promoteRailWindowArms` loads q[2] before the branch and writes it
; back at the merge, giving the in-place controlled-Ry diamond. The condition
; q[0] is read as the register itself — never minted, bracketed or freed.
; Stream: Ry walk, CRy(q0 -> q2, .3), measure. q0 is not q2 (constant cells).
;
; SOURCE (clang -O1, verbatim below):
;   int main(void){ bool q[3]={0};
;     for(int i=0;i<3;i++) cq_theta(&q[i], .5+.2*i);
;     if (q[0]) cq_theta(&q[2], .3);
;     int r=0; for(int i=0;i<3;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='error:' --implicit-check-not=cqrt_free \
; RUN:       --implicit-check-not=cq_template_ --implicit-check-not='call void @cqrt_ry_i1_controlled'
; CHECK-LABEL: define i32 @main(
; CHECK: %.rail = load i32, ptr %.rails, align 4
; CHECK: %cq.arm.in = load i32, ptr %cq.rail.addr1, align 4
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %.rail, i32 %cq.arm.in, double 3.000000e-01)

; ModuleID = 'railwindow_s6_straight_cell_cond_accept.c'
source_filename = "railwindow_s6_straight_cell_cond_accept.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %6

2:                                                ; preds = %6
  %3 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %4 = trunc nuw i8 %3 to i1
  br i1 %4, label %18, label %5

5:                                                ; preds = %18, %2
  br label %25

6:                                                ; preds = %0, %6
  %7 = phi i64 [ 0, %0 ], [ %16, %6 ]
  %8 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %7
  %9 = load i8, ptr %8, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = trunc nuw i8 %9 to i1
  %11 = trunc nuw nsw i64 %7 to i32
  %12 = uitofp nneg i32 %11 to double
  %13 = tail call double @llvm.fmuladd.f64(double %12, double 2.000000e-01, double 5.000000e-01)
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef %13) #6
  %15 = zext i1 %14 to i8
  store i8 %15, ptr %8, align 1, !tbaa !6
  %16 = add nuw nsw i64 %7, 1
  %17 = icmp eq i64 %16, 3
  br i1 %17, label %2, label %6, !llvm.loop !12

18:                                               ; preds = %2
  %19 = getelementptr inbounds i8, ptr %1, i64 2
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %21 = trunc nuw i8 %20 to i1
  %22 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %21, double noundef 3.000000e-01) #6
  %23 = zext i1 %22 to i8
  store i8 %23, ptr %19, align 1, !tbaa !6
  br label %5

24:                                               ; preds = %25
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #5
  ret i32 %34

25:                                               ; preds = %5, %25
  %26 = phi i64 [ %35, %25 ], [ 0, %5 ]
  %27 = phi i32 [ %34, %25 ], [ 0, %5 ]
  %28 = shl nsw i32 %27, 1
  %29 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %26
  %30 = load i8, ptr %29, align 1, !tbaa !6, !range !10, !noundef !11
  %31 = trunc nuw i8 %30 to i1
  %32 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %31) #5
  %33 = zext i1 %32 to i32
  %34 = or disjoint i32 %28, %33
  %35 = add nuw nsw i64 %26, 1
  %36 = icmp eq i64 %35, 3
  br i1 %36, label %24, label %25, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }

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
