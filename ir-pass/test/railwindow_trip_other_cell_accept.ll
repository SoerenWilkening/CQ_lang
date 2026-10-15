; railwindow_trip_other_cell_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19.17`,
; in-loop eager uncompute; design §6, owner ruling Q4 (a)).
;
; `s = 2*q[m] + q[m-1]` is a temporary of two cells; under `s == 3` the
; controlled Ry fires on a THIRD cell, q[m-2], in the same trip. Array-granular,
; the s chain was a record "of the array" live at a non-diagonal gate on it
; (Q4 refused, and the spine would not place its `_unc` inside the window). Per
; cell inside ONE activation of the loop body (`railWindowTripDistinctCells`:
; q[m], q[m-1] vs q[m-2], SCEV-distinct, the reads dominating the gate) it is
; another rail's temporary; it is discharged before the trip ends
; (`recordTripLocal`), so no instance reaches the next trip's gate (on q[m-3],
; whose cell this trip's q[m-1] is NOT, and q[m-1]'s next-trip read is fresh).
;
; ANALYTIC CHECK (scratch: state-vector replay of the linked trace vs an
; independent model of the source — Ry(.4+.2i) on q[i], then for m = 4, 3, 2
; Ry(.7) on q[m-2] iff q[m] = q[m-1] = 1): all 32 outcome probabilities agree to
; 1e-5; every freed rail is |0>. The stream below is one trip of the rolled loop:
; the s chain (zext, shl, zext, or, icmp) is built, drives the controlled Ry,
; and is reversed and freed in LIFO order before the back edge.
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdbool.h>
;   int main(void){ bool q[5]={0};
;     for(int i=0;i<5;i++) cq_theta(&q[i], .4+.2*i);
;     for (int m=4; m>=2; m--) {
;       int s = 2*q[m] + q[m-1];
;       if (s == 3) cq_theta(&q[m-2], .7);
;     }
;     int r=0; for(int i=0;i<5;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK: [[V0:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i1(i1 [[V1:%[-a-zA-Z$._0-9]+]])
; CHECK: call void @cqrt_ry_i1(i32 [[V2:%[-a-zA-Z$._0-9]+]], double {{%[-a-zA-Z$._0-9]+}})
; CHECK: [[V3:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_zext_i1_to_i8(i32 [[V4:%[-a-zA-Z$._0-9]+]])
; CHECK: [[V5:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_shl_i8_hl(i32 [[V3]], i8 1)
; CHECK: [[V6:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_zext_i1_to_i8(i32 [[V7:%[-a-zA-Z$._0-9]+]])
; CHECK: [[V8:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_or_i8(i32 [[V5]], i32 [[V6]])
; CHECK: [[V9:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_icmp_eq_i8_hl(i32 [[V8]], i8 3)
; CHECK: call void @cqrt_ry_i1_controlled(i32 [[V9]], i32 [[V10:%[-a-zA-Z$._0-9]+]], double 0x3FE6666666666666)
; CHECK: call void @cq_template_icmp_eq_i8_hl_unc(i32 [[V9]], i32 [[V8]], i8 3)
; CHECK: call void @cq_template_or_i8_unc(i32 [[V8]], i32 [[V5]], i32 [[V6]])
; CHECK: call void @cqrt_free(i32 [[V8]])
; CHECK: call void @cq_template_zext_i1_to_i8_unc(i32 [[V6]], i32 [[V7]])
; CHECK: call void @cqrt_free(i32 [[V6]])
; CHECK: call void @cq_template_shl_i8_hl_unc(i32 [[V5]], i32 [[V3]], i8 1)
; CHECK: call void @cqrt_free(i32 [[V5]])
; CHECK: call void @cq_template_zext_i1_to_i8_unc(i32 [[V3]], i32 [[V4]])
; CHECK: call void @cqrt_free(i32 [[V3]])
; CHECK: call void @cqrt_free(i32 [[V9]])
; CHECK: [[V11:%[-a-zA-Z$._0-9]+]] = call i1 @cqrt_measure_i1(i32 [[V12:%[-a-zA-Z$._0-9]+]])
; CHECK-NOT: call {{.*}}@cq

; ModuleID = 'railwindow_trip_other_cell_accept.c'
source_filename = "railwindow_trip_other_cell_accept.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [5 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 5, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(5) %1, i8 0, i64 5, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 2.000000e-01, double 4.000000e-01)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #6
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 5
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2, %31
  %15 = phi i64 [ %19, %31 ], [ 4, %2 ]
  %16 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = shl nuw nsw i8 %17, 1
  %19 = add nsw i64 %15, -1
  %20 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = or disjoint i8 %18, %21
  %23 = icmp eq i8 %22, 3
  br i1 %23, label %24, label %31

24:                                               ; preds = %14
  %25 = add nsw i64 %15, -2
  %26 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %25
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %28, double noundef 0x3FE6666666666666) #6
  %30 = zext i1 %29 to i8
  store i8 %30, ptr %26, align 1, !tbaa !6
  br label %31

31:                                               ; preds = %24, %14
  %32 = icmp ugt i64 %15, 2
  br i1 %32, label %14, label %34, !llvm.loop !15

33:                                               ; preds = %34
  call void @llvm.lifetime.end.p0(i64 5, ptr nonnull %1) #5
  ret i32 %43

34:                                               ; preds = %31, %34
  %35 = phi i64 [ %44, %34 ], [ 0, %31 ]
  %36 = phi i32 [ %43, %34 ], [ 0, %31 ]
  %37 = shl nsw i32 %36, 1
  %38 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %35
  %39 = load i8, ptr %38, align 1, !tbaa !6, !range !10, !noundef !11
  %40 = trunc nuw i8 %39 to i1
  %41 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %40) #5
  %42 = zext i1 %41 to i32
  %43 = or disjoint i32 %37, %42
  %44 = add nuw nsw i64 %35, 1
  %45 = icmp eq i64 %44, 5
  br i1 %45, label %33, label %34, !llvm.loop !16
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
