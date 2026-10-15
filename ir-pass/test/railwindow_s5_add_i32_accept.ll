; railwindow_s5_add_i32_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19` S5, in-place cell updates;
; design §4, owner rulings owner-ruling-01po19-rolled-design-2026-10-15 and
; owner-ruling-dm7f51-inplace-qq-2026-10-14). Contract: RailWindow.h,
; RailWindowInPlace.cpp, InPlaceQQ.h.
;
; The `add` twin of the CNOT walk over an `int` array: `q[i+1] += q[i]` lowers
; in place as `cqrt_add_i32(q[i], q[i+1])` (dm7f.51's quantum-source add,
; Cuccaro-style), never as an out-of-place `cq_template_add_i32` rebinding the
; cell beside its live old rail. The cells' rails are the i32 rails the walk at
; Q mints from the classical values 0, 1, 2.
;
; SOURCE (clang -O1, verbatim below):
;   int main(void){ int q[3]={0,1,2};
;     for(int i=0;i<3;i++) cq_theta(&q[i], .5+.2*i);
;     for(int i=0;i<2;i++) q[i+1]+=q[i];
;     cq_theta(&q[0], .7);
;     int r=0; for(int i=0;i<3;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='error:' --implicit-check-not=cqrt_free \
; RUN:       --implicit-check-not=cq_template_
; CHECK-LABEL: define i32 @main(
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %cq.rail.init)
; CHECK: %.cell = load i32, ptr %cq.cell.addr, align 4
; CHECK: %.rail4 = load i32, ptr %cq.rail.addr1, align 4
; CHECK-NEXT: call void @cqrt_add_i32(i32 %.cell, i32 %.rail4), !cq.inplace.qq
; CHECK-NEXT: store i32 %.rail4, ptr %cq.rail.addr1, align 4

; ModuleID = 'railwindow_s5_add_i32_accept.c'
source_filename = "railwindow_s5_add_i32_accept.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.main.q = private unnamed_addr constant [3 x i32] [i32 0, i32 1, i32 2], align 4

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %1) #5
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(12) %1, ptr noundef nonnull align 4 dereferenceable(12) @__const.main.q, i64 12, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %10, %2 ]
  %4 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !6
  %6 = trunc nuw nsw i64 %3 to i32
  %7 = uitofp nneg i32 %6 to double
  %8 = tail call double @llvm.fmuladd.f64(double %7, double 2.000000e-01, double 5.000000e-01)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %8) #6
  store i32 %9, ptr %4, align 4, !tbaa !6
  %10 = add nuw nsw i64 %3, 1
  %11 = icmp eq i64 %10, 3
  br i1 %11, label %12, label %2, !llvm.loop !10

12:                                               ; preds = %2
  %13 = load i32, ptr %1, align 4
  br label %17

14:                                               ; preds = %17
  %15 = load i32, ptr %1, align 4, !tbaa !6
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 0x3FE6666666666666) #6
  store i32 %16, ptr %1, align 4, !tbaa !6
  br label %26

17:                                               ; preds = %12, %17
  %18 = phi i32 [ %13, %12 ], [ %23, %17 ]
  %19 = phi i64 [ 0, %12 ], [ %20, %17 ]
  %20 = add nuw nsw i64 %19, 1
  %21 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %20
  %22 = load i32, ptr %21, align 4, !tbaa !6
  %23 = add nsw i32 %22, %18
  store i32 %23, ptr %21, align 4, !tbaa !6
  %24 = icmp eq i64 %19, 0
  br i1 %24, label %17, label %14, !llvm.loop !13

25:                                               ; preds = %26
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %1) #5
  ret i32 %33

26:                                               ; preds = %14, %26
  %27 = phi i64 [ 0, %14 ], [ %34, %26 ]
  %28 = phi i32 [ 0, %14 ], [ %33, %26 ]
  %29 = shl nsw i32 %28, 1
  %30 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %27
  %31 = load i32, ptr %30, align 4, !tbaa !6
  %32 = tail call i32 @cq_measure_si32(i32 noundef %31) #5
  %33 = add nsw i32 %32, %29
  %34 = add nuw nsw i64 %27, 1
  %35 = icmp eq i64 %34, 3
  br i1 %35, label %25, label %26, !llvm.loop !14
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
