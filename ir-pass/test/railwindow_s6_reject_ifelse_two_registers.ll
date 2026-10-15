; railwindow_s6_reject_ifelse_two_registers.ll — DECLINE (bd
; `test_C_libtooling-01po.19` S6 R11 round 1, finding C-F2; reviewer probe
; review_s6C/p5.c). An if/else under a CELL condition rotating a cell in one
; arm and a scalar in the other. Its merge φ for q[2] has only UNCONDITIONAL
; predecessors (the two arms), so only the region-level guards can see it is a
; quantum merge: the control-dependence predicate and the defensive idom guard
; of `splitRailWindowWritebacks` both keep it (the WIN prefix pins "kept"); split, the
; quantum arm's write-back would sit under classical control. The module is
; refused loudly by the control chain (mixed arms; bd 01po.19.20 lowers it).
; RETIREMENT TRIGGER (L7): when 01po.19.20 lowers this shape, this file becomes
; the accept that must kill the guard-removed mutant before either guard goes.
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdbool.h>
;   int main(void){ bool q[3]={0}; bool s=0;
;     for(int i=0;i<3;i++) cq_theta(&q[i], .5+.2*i);
;     cq_theta(&s, .4);
;     if (q[0]) cq_theta(&q[2], .3); else cq_theta(&s, .9);
;     int r=cq_measure(s); for(int i=0;i<3;i++) r=2*r+cq_measure(q[i]); return r; }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN --implicit-check-not='write-back split'
; CHECK: cq controlled lowering: control flow under quantum control{{$}}
; WIN: CQ_RAILWINDOW_DBG: write-back kept: {{.*}}store i1 %cq.arm.0

; ModuleID = 'railwindow_s6_reject_ifelse_two_registers.c'
source_filename = "railwindow_s6_reject_ifelse_two_registers.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %6

2:                                                ; preds = %6
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #6
  %4 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  br i1 %5, label %18, label %24

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
  br label %26

24:                                               ; preds = %2
  %25 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 9.000000e-01) #6
  br label %26

26:                                               ; preds = %24, %18
  %27 = phi i1 [ %3, %18 ], [ %25, %24 ]
  %28 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %27) #5
  %29 = zext i1 %28 to i32
  br label %31

30:                                               ; preds = %31
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #5
  ret i32 %40

31:                                               ; preds = %26, %31
  %32 = phi i64 [ 0, %26 ], [ %41, %31 ]
  %33 = phi i32 [ %29, %26 ], [ %40, %31 ]
  %34 = shl nsw i32 %33, 1
  %35 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %32
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !10, !noundef !11
  %37 = trunc nuw i8 %36 to i1
  %38 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %37) #5
  %39 = zext i1 %38 to i32
  %40 = or disjoint i32 %34, %39
  %41 = add nuw nsw i64 %32, 1
  %42 = icmp eq i64 %41, 3
  br i1 %42, label %30, label %31, !llvm.loop !15
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
