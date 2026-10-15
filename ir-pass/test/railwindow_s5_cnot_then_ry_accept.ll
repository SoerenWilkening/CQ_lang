; railwindow_s5_cnot_then_ry_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19` S5, in-place cell updates;
; design §4, owner rulings owner-ruling-01po19-rolled-design-2026-10-15 and
; owner-ruling-dm7f51-inplace-qq-2026-10-14). Contract: RailWindow.h,
; RailWindowInPlace.cpp, InPlaceQQ.h.
;
; THE r2j3.33 ANALYTIC PIN, ROLLED. The CNOT walk `q[i+1] ^= q[i]` must lower
; IN PLACE (`cqrt_cnot(q[i], q[i+1])`): out of place, the old q[i+1] rail stays
; beside the new one and jointly records q[i], so the later Ry on q[0] is
; dephased. Measured on the unroll branch: P(q0=0) = 0.836 (out of place)
; versus the program's 0.736. This stream gives 0.736122 (scratch state-vector
; propagation of the e2e trace slice_rolled_cnot_then_ry, 2026-10-15:
; Ry(.5)⊗Ry(.7)⊗Ry(.9) on |000>, CNOT(0->1), CNOT(1->2), Ry(.7) on q0).
; The preheader load -O1's GVN creates for the header φ has no `!range`; one
; ranged access of the `_Bool` array plus bit-valued stores keep the rail i1
; (railTypeForImpl). The φ itself is re-materialized as a cell load (Q6 (a)).
;
; SOURCE (clang -O1, verbatim below):
;   int main(void){ bool q[3]={0};
;     for(int i=0;i<3;i++) cq_theta(&q[i], .5+.2*i);
;     for(int i=0;i<2;i++) q[i+1]^=q[i];
;     cq_theta(&q[0], .7);
;     int r=0; for(int i=0;i<3;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='error:' --implicit-check-not=cqrt_free \
; RUN:       --implicit-check-not=cq_template_
; CHECK-LABEL: define i32 @main(
; CHECK: %.rails = alloca i32, i64 3, align 4, !cq.railwindow
; CHECK: call void @cqrt_ry_i1(i32 %.rail, double %{{[0-9]+}})
; CHECK: %.rail3 = load i32, ptr %.rails, align 4
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %.rail3, double 0x3FE6666666666666)
; CHECK: %.cell = load i32, ptr %cq.cell.addr, align 4
; CHECK: %.rail4 = load i32, ptr %cq.rail.addr1, align 4
; CHECK-NEXT: call void @cqrt_cnot(i32 %.cell, i32 %.rail4), !cq.inplace.qq
; CHECK-NEXT: store i32 %.rail4, ptr %cq.rail.addr1, align 4
; CHECK: %m = call i1 @cqrt_measure_i1(i32 %.rail6)

; ModuleID = 'railwindow_s5_cnot_then_ry_accept.c'
source_filename = "railwindow_s5_cnot_then_ry_accept.c"
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

14:                                               ; preds = %2
  %15 = load i8, ptr %1, align 1
  br label %21

16:                                               ; preds = %21
  %17 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = trunc nuw i8 %17 to i1
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %18, double noundef 0x3FE6666666666666) #6
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %1, align 1, !tbaa !6
  br label %31

21:                                               ; preds = %14, %21
  %22 = phi i8 [ %15, %14 ], [ %28, %21 ]
  %23 = phi i64 [ 0, %14 ], [ %24, %21 ]
  %24 = add nuw nsw i64 %23, 1
  %25 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %24
  %26 = load i8, ptr %25, align 1, !tbaa !6, !range !10, !noundef !11
  %27 = icmp ne i8 %26, %22
  %28 = zext i1 %27 to i8
  store i8 %28, ptr %25, align 1, !tbaa !6
  %29 = icmp eq i64 %23, 0
  br i1 %29, label %21, label %16, !llvm.loop !15

30:                                               ; preds = %31
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #5
  ret i32 %40

31:                                               ; preds = %16, %31
  %32 = phi i64 [ 0, %16 ], [ %41, %31 ]
  %33 = phi i32 [ 0, %16 ], [ %40, %31 ]
  %34 = shl nsw i32 %33, 1
  %35 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %32
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !10, !noundef !11
  %37 = trunc nuw i8 %36 to i1
  %38 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %37) #5
  %39 = zext i1 %38 to i32
  %40 = or disjoint i32 %34, %39
  %41 = add nuw nsw i64 %32, 1
  %42 = icmp eq i64 %41, 3
  br i1 %42, label %30, label %31, !llvm.loop !16
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
