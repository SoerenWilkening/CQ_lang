; railwindow_s5_straight_xor_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19` S5, in-place cell updates;
; design §4, owner rulings owner-ruling-01po19-rolled-design-2026-10-15 and
; owner-ruling-dm7f51-inplace-qq-2026-10-14). Contract: RailWindow.h,
; RailWindowInPlace.cpp, InPlaceQQ.h.
;
; A straight-line cell update between two constant-index cells (no loop): the
; same in-place CNOT, then the Ry on the SOURCE cell q[0] reads q[0]'s rail.
; Stream: Ry walk, CNOT(q0 -> q2), Ry(.7) on q0, measure.
;
; SOURCE (clang -O1, verbatim below):
;   int main(void){ bool q[3]={0};
;     for(int i=0;i<3;i++) cq_theta(&q[i], .5+.2*i);
;     q[2] ^= q[0];
;     cq_theta(&q[0], .7);
;     int r=0; for(int i=0;i<3;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='error:' --implicit-check-not=cqrt_free \
; RUN:       --implicit-check-not=cq_template_ --implicit-check-not='call void @cqrt_cnot'
; CHECK-LABEL: define i32 @main(
; CHECK: %.rail = load i32, ptr %.rails, align 4
; CHECK-NEXT: %cq.rail.addr = getelementptr i32, ptr %.rails, i64 2
; CHECK-NEXT: %.rail2 = load i32, ptr %cq.rail.addr, align 4
; CHECK-NEXT: call void @cqrt_cnot(i32 %.rail, i32 %.rail2), !cq.inplace.qq
; CHECK-NEXT: store i32 %.rail2, ptr %cq.rail.addr, align 4
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %.rail, double 0x3FE6666666666666)

; ModuleID = 'railwindow_s5_straight_xor_accept.c'
source_filename = "railwindow_s5_straight_xor_accept.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %11

2:                                                ; preds = %11
  %3 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %4 = getelementptr inbounds i8, ptr %1, i64 2
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = icmp ne i8 %5, %3
  %7 = zext i1 %6 to i8
  store i8 %7, ptr %4, align 1, !tbaa !6
  %8 = trunc nuw i8 %3 to i1
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 0x3FE6666666666666) #6
  %10 = zext i1 %9 to i8
  store i8 %10, ptr %1, align 1, !tbaa !6
  br label %24

11:                                               ; preds = %0, %11
  %12 = phi i64 [ 0, %0 ], [ %21, %11 ]
  %13 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = trunc nuw nsw i64 %12 to i32
  %17 = uitofp nneg i32 %16 to double
  %18 = tail call double @llvm.fmuladd.f64(double %17, double 2.000000e-01, double 5.000000e-01)
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef %18) #6
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %13, align 1, !tbaa !6
  %21 = add nuw nsw i64 %12, 1
  %22 = icmp eq i64 %21, 3
  br i1 %22, label %2, label %11, !llvm.loop !12

23:                                               ; preds = %24
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #5
  ret i32 %33

24:                                               ; preds = %2, %24
  %25 = phi i64 [ 0, %2 ], [ %34, %24 ]
  %26 = phi i32 [ 0, %2 ], [ %33, %24 ]
  %27 = shl nsw i32 %26, 1
  %28 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %25
  %29 = load i8, ptr %28, align 1, !tbaa !6, !range !10, !noundef !11
  %30 = trunc nuw i8 %29 to i1
  %31 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %30) #5
  %32 = zext i1 %31 to i32
  %33 = or disjoint i32 %27, %32
  %34 = add nuw nsw i64 %25, 1
  %35 = icmp eq i64 %34, 3
  br i1 %35, label %23, label %24, !llvm.loop !15
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
