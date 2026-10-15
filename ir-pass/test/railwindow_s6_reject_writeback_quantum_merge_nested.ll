; railwindow_s6_reject_writeback_quantum_merge_nested.ll — DECLINE (bd
; `test_C_libtooling-01po.19` S6 R11 round 1, finding A-F3).
;
; HAND IR (from `if (argc > 1) { if (q[0]) cq_theta(&q[2], .3); else
; cq_theta(&q[2], .6); }` at clang -O1, edited): a QUANTUM if/else nested in a
; CLASSICAL branch with BOTH merges in ONE block %6 — `phi [Ry.3, %v25],
; [Ry.6, %v27], [q2, %4]; store`. The classical idom (%4) and the direct
; predecessors (unconditional arm jumps and the classical %4) all pass the old
; local guard, so `splitRailWindowWritebacks` would split the QUANTUM merge
; into stores inside the quantum arms (classical control over quantum state,
; R1). THE ONE PREDICATE (the φ's incoming selection never depends on a
; tainted terminator; round 2 widened it, see
; railwindow_s6_reject_writeback_exit_around_merge_quantum.ll) keeps it. The WIN prefix
; pins the splitter's verdict ("kept"); the CHECK pins that the module is
; refused loudly (the if/else itself is bd 01po.19.20/.28).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN --implicit-check-not='write-back split'
; CHECK: cq controlled lowering: control flow under quantum control{{$}}
; WIN: CQ_RAILWINDOW_DBG: write-back kept: {{.*}}store i1 %mphi

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/55dc71b6-862e-46b0-b41f-d1a3c1ba8d1d/scratchpad/s56/c_nest.c'
source_filename = "c_nest.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %3) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %3, i8 0, i64 3, i1 false)
  br label %7

4:                                                ; preds = %7
  %5 = icmp sgt i32 %0, 1
  %c2p = getelementptr inbounds i8, ptr %3, i64 2
  %k2 = load i8, ptr %c2p, align 1, !tbaa !6, !range !10, !noundef !11
  %kt = trunc nuw i8 %k2 to i1
  br i1 %5, label %19, label %6

6:                                                ; preds = %v25, %v27, %4
  %mphi = phi i1 [ %v26, %v25 ], [ %v28, %v27 ], [ %kt, %4 ]
  %mz = zext i1 %mphi to i8
  store i8 %mz, ptr %c2p, align 1, !tbaa !6
  br label %33

7:                                                ; preds = %2, %7
  %8 = phi i64 [ 0, %2 ], [ %17, %7 ]
  %9 = getelementptr inbounds [3 x i8], ptr %3, i64 0, i64 %8
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = trunc nuw nsw i64 %8 to i32
  %13 = uitofp nneg i32 %12 to double
  %14 = tail call double @llvm.fmuladd.f64(double %13, double 2.000000e-01, double 5.000000e-01)
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef %14) #6
  %16 = zext i1 %15 to i8
  store i8 %16, ptr %9, align 1, !tbaa !6
  %17 = add nuw nsw i64 %8, 1
  %18 = icmp eq i64 %17, 3
  br i1 %18, label %4, label %7, !llvm.loop !12

19:                                               ; preds = %4
  %20 = load i8, ptr %3, align 1, !tbaa !6, !range !10, !noundef !11
  %21 = trunc nuw i8 %20 to i1
  %v23 = load i8, ptr %c2p, align 1, !tbaa !6, !range !10, !noundef !11
  %v24 = trunc nuw i8 %v23 to i1
  br i1 %21, label %v25, label %v27

v25:                                               ; preds = %19
  %v26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %v24, double noundef 3.000000e-01) #6
  br label %6

v27:                                               ; preds = %19
  %v28 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %v24, double noundef 6.000000e-01) #6
  br label %6

32:                                               ; preds = %33
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %3) #5
  ret i32 %42

33:                                               ; preds = %6, %33
  %34 = phi i64 [ %43, %33 ], [ 0, %6 ]
  %35 = phi i32 [ %42, %33 ], [ 0, %6 ]
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
