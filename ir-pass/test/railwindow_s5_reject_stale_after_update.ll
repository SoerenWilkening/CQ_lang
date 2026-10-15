; railwindow_s5_reject_stale_after_update.ll — DECLINE (bd `test_C_libtooling-01po.19` S5, in-place cell updates;
; design §4, owner rulings owner-ruling-01po19-rolled-design-2026-10-15 and
; owner-ruling-dm7f51-inplace-qq-2026-10-14). Contract: RailWindow.h,
; RailWindowInPlace.cpp, InPlaceQQ.h.
;
; THE STALE-CELL FENCE OVER AN IN-PLACE UPDATE. `t = q[1]` is read before the
; walk; the walk's CNOT onto q[1] (an in-place update through ANOTHER spelling
; of that cell) moves the rail `t` names, so `cq_measure(t)` would measure the
; updated rail where C says `t` holds the old value. Only the update is a gate
; here (no Ry follows the walk), so this pins S5's addition to the fence's gate
; set (RailWindowFence.cpp `collectUpdates`). Copy-on-read is bd 01po.19.2.
;
; SOURCE (clang -O1, verbatim below):
;   int main(void){ bool q[3]={0};
;     for(int i=0;i<3;i++) cq_theta(&q[i], .5+.2*i);
;     bool t = q[1];
;     for(int i=0;i<2;i++) q[i+1]^=q[i];
;     int r=cq_measure(t); for(int i=0;i<3;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq rail window: quantum-array cell rail read past a non-diagonal gate on that array

; ModuleID = 'railwindow_s5_reject_stale_after_update.c'
source_filename = "railwindow_s5_reject_stale_after_update.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %6

2:                                                ; preds = %6
  %3 = getelementptr inbounds i8, ptr %1, i64 1
  %4 = load i8, ptr %3, align 1, !tbaa !6, !range !10, !noundef !11
  %5 = load i8, ptr %1, align 1
  br label %22

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

18:                                               ; preds = %22
  %19 = trunc nuw i8 %4 to i1
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %19) #5
  %21 = zext i1 %20 to i32
  br label %32

22:                                               ; preds = %2, %22
  %23 = phi i8 [ %5, %2 ], [ %29, %22 ]
  %24 = phi i64 [ 0, %2 ], [ %25, %22 ]
  %25 = add nuw nsw i64 %24, 1
  %26 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %25
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = icmp ne i8 %27, %23
  %29 = zext i1 %28 to i8
  store i8 %29, ptr %26, align 1, !tbaa !6
  %30 = icmp eq i64 %24, 0
  br i1 %30, label %22, label %18, !llvm.loop !15

31:                                               ; preds = %32
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #5
  ret i32 %41

32:                                               ; preds = %18, %32
  %33 = phi i64 [ 0, %18 ], [ %42, %32 ]
  %34 = phi i32 [ %21, %18 ], [ %41, %32 ]
  %35 = shl nsw i32 %34, 1
  %36 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %33
  %37 = load i8, ptr %36, align 1, !tbaa !6, !range !10, !noundef !11
  %38 = trunc nuw i8 %37 to i1
  %39 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %38) #5
  %40 = zext i1 %39 to i32
  %41 = or disjoint i32 %35, %40
  %42 = add nuw nsw i64 %33, 1
  %43 = icmp eq i64 %42, 3
  br i1 %43, label %31, label %32, !llvm.loop !16
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
