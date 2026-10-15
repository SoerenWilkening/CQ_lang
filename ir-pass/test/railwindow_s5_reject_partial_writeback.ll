; railwindow_s5_reject_partial_writeback.ll — DECLINE (bd `test_C_libtooling-01po.19` S5 R11 round 1,
; finding C-F1; the one predicate `railWindowWritesBack`, RailWindow.h).
;
; A WRITE-BACK ON ONE PATH ONLY. `x = q[2] ^ q[0]` is stored back into q[2]
; only when argc > 1. On c16aacb6 the CNOT fired unconditionally at x's
; definition, so on the argc <= 1 path cell 2 held q2 ^ q0 where C keeps q2 (the
; measure loop reads it): a verify-clean silent miscompile. Out of place is not
; right either (on the store path the dead old q2 would stand beside x, the
; r2j3.33 record), so it is pending, loud: condition (2) of
; `railWindowWritesBack` (a MUST write-back) fails. Lowering: bd 01po.19.14.
;
; SOURCE (clang -O1, verbatim below):
;   int main(int argc, char **argv) {
;     bool q[3] = {0};
;     for (int i = 0; i < 3; i++) cq_theta(&q[i], .5 + .2 * i);
;     bool x = q[2] ^ q[0];
;     if (argc > 1) { q[2] = x; cq_theta(&q[1], .3); }
;     int r = cq_measure(x);
;     for (int i = 0; i < 3; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq rail window: quantum array not lowered yet (bd 01po.19), needs S5 cell update not written back once on every path (bd 01po.19.14){{$}}

; ModuleID = 'railwindow_s5_reject_partial_writeback.c'
source_filename = "railwindow_s5_reject_partial_writeback.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %3) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %3, i8 0, i64 3, i1 false)
  br label %10

4:                                                ; preds = %10
  %5 = getelementptr inbounds i8, ptr %3, i64 2
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = load i8, ptr %3, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = icmp ne i8 %6, %7
  %9 = icmp sgt i32 %0, 1
  br i1 %9, label %22, label %29

10:                                               ; preds = %2, %10
  %11 = phi i64 [ 0, %2 ], [ %20, %10 ]
  %12 = getelementptr inbounds [3 x i8], ptr %3, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !10, !noundef !11
  %14 = trunc nuw i8 %13 to i1
  %15 = trunc nuw nsw i64 %11 to i32
  %16 = uitofp nneg i32 %15 to double
  %17 = tail call double @llvm.fmuladd.f64(double %16, double 2.000000e-01, double 5.000000e-01)
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %14, double noundef %17) #6
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %12, align 1, !tbaa !6
  %20 = add nuw nsw i64 %11, 1
  %21 = icmp eq i64 %20, 3
  br i1 %21, label %4, label %10, !llvm.loop !12

22:                                               ; preds = %4
  %23 = zext i1 %8 to i8
  store i8 %23, ptr %5, align 1, !tbaa !6
  %24 = getelementptr inbounds i8, ptr %3, i64 1
  %25 = load i8, ptr %24, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = trunc nuw i8 %25 to i1
  %27 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef 3.000000e-01) #6
  %28 = zext i1 %27 to i8
  store i8 %28, ptr %24, align 1, !tbaa !6
  br label %29

29:                                               ; preds = %22, %4
  %30 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8) #5
  %31 = zext i1 %30 to i32
  br label %33

32:                                               ; preds = %33
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %3) #5
  ret i32 %42

33:                                               ; preds = %29, %33
  %34 = phi i64 [ 0, %29 ], [ %43, %33 ]
  %35 = phi i32 [ %31, %29 ], [ %42, %33 ]
  %36 = shl nsw i32 %35, 1
  %37 = getelementptr inbounds [3 x i8], ptr %3, i64 0, i64 %34
  %38 = load i8, ptr %37, align 1, !tbaa !6, !range !10, !noundef !11
  %39 = trunc nuw i8 %38 to i1
  %40 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %39) #5
  %41 = zext i1 %40 to i32
  %42 = or disjoint i32 %36, %41
  %43 = add nuw nsw i64 %34, 1
  %44 = icmp eq i64 %43, 3
  br i1 %44, label %32, label %33, !llvm.loop !15
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
