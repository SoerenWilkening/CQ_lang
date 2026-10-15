; railwindow_s6_negated_cell_cond_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19` S6, quantum control on
; cells; design §5, owner ruling owner-ruling-01po19-rolled-design-2026-10-15).
; Contract: RailWindow.h (RailWindowArms.cpp), ArmClassify `CellCond`, clause (d).
;
; A NEGATED cell condition in a loop (clause (d): the target cell is reloaded
; every trip). Nothing non-diagonal fires on a user register under control
; (R6): the anti-controlled Ry is `ry(t, θ); ry_controlled(c, t, -θ)`
; (Ry additivity: c=0 gives Ry(θ), c=1 gives Ry(0)). Per trip i: Ry(q[i], .3)
; then CRy(q[i-1] -> q[i], -.3).
;
; SOURCE (clang -O1, verbatim below):
;   int main(void){ bool q[3]={0};
;     for(int i=0;i<3;i++) cq_theta(&q[i], .5+.2*i);
;     for(int i=1;i<3;i++) if (!q[i-1]) cq_theta(&q[i], .3);
;     int r=0; for(int i=0;i<3;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='error:' --implicit-check-not=cqrt_free \
; RUN:       --implicit-check-not=cq_template_ --implicit-check-not='call void @cqrt_ry_i1_controlled'
; CHECK-LABEL: define i32 @main(
; CHECK: %cq.arm.in = load i32, ptr %cq.rail.addr1, align 4
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %cq.arm.in, double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %.rail3, i32 %cq.arm.in, double -3.000000e-01)

; ModuleID = 'railwindow_s6_negated_cell_cond_accept.c'
source_filename = "railwindow_s6_negated_cell_cond_accept.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 2.000000e-01, double 5.000000e-01)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #6
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 3
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2, %26
  %15 = phi i64 [ %27, %26 ], [ 1, %2 ]
  %16 = add nsw i64 %15, -1
  %17 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = trunc nuw i8 %18 to i1
  br i1 %19, label %26, label %20

20:                                               ; preds = %14
  %21 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %15
  %22 = load i8, ptr %21, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = trunc nuw i8 %22 to i1
  %24 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %23, double noundef 3.000000e-01) #6
  %25 = zext i1 %24 to i8
  store i8 %25, ptr %21, align 1, !tbaa !6
  br label %26

26:                                               ; preds = %14, %20
  %27 = add nuw nsw i64 %15, 1
  %28 = icmp eq i64 %27, 3
  br i1 %28, label %30, label %14, !llvm.loop !15

29:                                               ; preds = %30
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #5
  ret i32 %39

30:                                               ; preds = %26, %30
  %31 = phi i64 [ %40, %30 ], [ 0, %26 ]
  %32 = phi i32 [ %39, %30 ], [ 0, %26 ]
  %33 = shl nsw i32 %32, 1
  %34 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %31
  %35 = load i8, ptr %34, align 1, !tbaa !6, !range !10, !noundef !11
  %36 = trunc nuw i8 %35 to i1
  %37 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %36) #5
  %38 = zext i1 %37 to i32
  %39 = or disjoint i32 %33, %38
  %40 = add nuw nsw i64 %31, 1
  %41 = icmp eq i64 %40, 3
  br i1 %41, label %29, label %30, !llvm.loop !16
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
!16 = distinct !{!16, !13, !14}
