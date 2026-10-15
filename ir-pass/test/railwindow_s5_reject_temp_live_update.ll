; railwindow_s5_reject_temp_live_update.ll — DECLINE (bd `test_C_libtooling-01po.19` S5, in-place cell updates;
; design §4, owner rulings owner-ruling-01po19-rolled-design-2026-10-15 and
; owner-ruling-dm7f51-inplace-qq-2026-10-14). Contract: RailWindow.h,
; RailWindowInPlace.cpp, InPlaceQQ.h.
;
; Q4 (owner ruling (a)) ON AN IN-PLACE UPDATE. `s = q[1] ^ q[3]` is a
; temporary of q[1] still owed its uncompute when `q[1] ^= q[0]` would fire in
; place; its adjoint after the update would read the relabelled rail. The
; quantum-source round's G7 (prior use not settled) refuses the conversion,
; and refusing an eligible dead cell is loud (dm7f.51 Q1), never out of place.
; RETIREMENT TRIGGER: eager scope-end uncompute of `s` before the update
; (design §6) flips this to an accept.
;
; SOURCE (clang -O1, verbatim below):
;   int main(void){ bool q[4]={0};
;     for(int i=0;i<4;i++) cq_theta(&q[i], .5+.2*i);
;     bool s = q[1] != q[3];
;     q[1] ^= q[0];
;     q[2] ^= s;
;     cq_theta(&q[1], .3);
;     int r=0; for(int i=0;i<4;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: quantum reassignment of a dead register is not provable in place

; ModuleID = 'railwindow_s5_reject_temp_live_update.c'
source_filename = "railwindow_s5_reject_temp_live_update.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %18

2:                                                ; preds = %18
  %3 = getelementptr inbounds i8, ptr %1, i64 1
  %4 = load i8, ptr %3, align 1, !tbaa !6, !range !10, !noundef !11
  %5 = getelementptr inbounds i8, ptr %1, i64 3
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = icmp ne i8 %4, %6
  %8 = load i8, ptr %1, align 4, !tbaa !6, !range !10, !noundef !11
  %9 = icmp ne i8 %4, %8
  %10 = zext i1 %9 to i8
  store i8 %10, ptr %3, align 1, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %1, i64 2
  %12 = load i8, ptr %11, align 2, !tbaa !6, !range !10, !noundef !11
  %13 = zext i1 %7 to i8
  %14 = icmp ne i8 %12, %13
  %15 = zext i1 %14 to i8
  store i8 %15, ptr %11, align 2, !tbaa !6
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 3.000000e-01) #5
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %3, align 1, !tbaa !6
  br label %31

18:                                               ; preds = %0, %18
  %19 = phi i64 [ 0, %0 ], [ %28, %18 ]
  %20 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  %23 = trunc nuw nsw i64 %19 to i32
  %24 = uitofp nneg i32 %23 to double
  %25 = tail call double @llvm.fmuladd.f64(double %24, double 2.000000e-01, double 5.000000e-01)
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef %25) #5
  %27 = zext i1 %26 to i8
  store i8 %27, ptr %20, align 1, !tbaa !6
  %28 = add nuw nsw i64 %19, 1
  %29 = icmp eq i64 %28, 4
  br i1 %29, label %2, label %18, !llvm.loop !12

30:                                               ; preds = %31
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %40

31:                                               ; preds = %2, %31
  %32 = phi i64 [ 0, %2 ], [ %41, %31 ]
  %33 = phi i32 [ 0, %2 ], [ %40, %31 ]
  %34 = shl nsw i32 %33, 1
  %35 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %32
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !10, !noundef !11
  %37 = trunc nuw i8 %36 to i1
  %38 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %37) #4
  %39 = zext i1 %38 to i32
  %40 = or disjoint i32 %34, %39
  %41 = add nuw nsw i64 %32, 1
  %42 = icmp eq i64 %41, 4
  br i1 %42, label %30, label %31, !llvm.loop !15
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
