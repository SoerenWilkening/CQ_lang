; railwindow_nested_hoisted_condition_accept.ll — ACCEPT (bd `test_C_libtooling-8h7d.24`:
; a quantum subloop reading an OUTER-body temporary).
;
; `for m { for l <= m { if (c[m] + c[m+1] == 1) Ry(q[l]) } }`: -O1 hoists the
; loop-invariant condition chain (zext, add) into the OUTER body, so the inner
; loop reads a tainted value defined outside it, and `markIfIterationLocal`
; refused the nest (the outer body stayed unmarked; the hoisted rail's
; exit-discharge obligation then failed loudly: `hoisted invariant rail
; admitted for in-loop discharge was not discharged`). Now a subloop may read
; such a value when it is clause (ii-d)'s shape one level down
; (`hoistedParentRoot`: an out-of-place template rail defined in the parent
; body, every user inside the subloop, one subloop exit), and the obligation is
; recorded; `anchorForConsumer` discharges it at the inner loop's exit, once per
; outer trip (pinned below: the `_unc` chain in the inner exit block).
;
; ANALYTIC CHECK (scratch state-vector of the SOURCE vs replay of the trace,
; equal to 1e-6; c[0..3] then q[0..3], nothing else):
;   00000000 +0.733367  00100000 +0.232489  00100010 +0.127009  00100100 +0.176739
;   00100110 +0.096553  00101000 +0.084865  00101010 +0.046362  00101100 +0.064515
;   00101110 +0.035245  01000000 +0.209987  01000100 +0.064957  01001000 +0.053619
;   01001100 +0.016586  01100000 +0.086304  01100010 +0.047148  01100100 +0.031503
;   01100110 +0.017210  01101000 +0.026697  01101010 +0.014585  01101100 +0.009745
;   01101110 +0.005324  10000000 +0.447385  10001000 +0.044888  10100000 +0.136634
;   10100010 +0.074643  10100100 +0.103870  10100110 +0.056744  10101000 +0.066002
;   10101010 +0.036057  10101100 +0.050175  10101110 +0.027411  11000000 +0.131383
;   11000100 +0.040642  11001000 +0.019857  11001100 +0.006142  11100000 +0.054283
;   11100010 +0.029655  11100100 +0.019815  11100110 +0.010825  11101000 +0.011004
;   11101010 +0.006011  11101100 +0.004017  11101110 +0.002194
; Stage 2b: 4 of 4 free sites verified, 0 unproven (T4 in lockstep:
; `streams_alternate`, `reaches_between`).
;
; SOURCE (clang -O1, verbatim below):
;   /* bd 8h7d.24: a quantum condition computed in the OUTER body (LICM hoists it
;      out of the inner loop) and read by every trip of a quantum inner loop. */
;   #include <stdio.h>
;   int main(void) {
;       bool c[4], q[4];
;       for (int i = 0; i < 4; i++) { c[i] = 0; q[i] = 0; }
;       cq_theta(&c[0], 1.1);
;       cq_theta(&c[1], 0.6);
;       cq_theta(&c[2], 0.9);
;       for (int m = 0; m < 3; m++) {
;           for (int l = 0; l <= m; l++)
;               if (c[m] + c[m + 1] == 1) cq_theta(&q[l], 0.2 + 0.3 * l + 0.1 * m);
;       }
;       for (int i = 0; i < 4; i++) printf("%d", cq_measure(c[i]));
;       for (int i = 0; i < 4; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='cq controlled lowering'
; CHECK: [[OP:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_add_i8(
; CHECK: {{^}}[[EXIT:[0-9]+]]:
; CHECK-NEXT: call void @cq_template_add_i8_unc(i32 [[OP]],
; CHECK-NEXT: call void @cqrt_free(i32 [[OP]])
; CHECK: call void @cqrt_ry_i1_controlled(
; CHECK: call i1 @cqrt_measure_i1

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/h24/p_outer.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/h24/p_outer.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  %2 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #6
  store i32 0, ptr %1, align 4
  store i32 0, ptr %2, align 4
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00) #7
  %4 = zext i1 %3 to i8
  store i8 %4, ptr %1, align 4, !tbaa !6
  %5 = getelementptr inbounds i8, ptr %1, i64 1
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = trunc nuw i8 %6 to i1
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef 6.000000e-01) #7
  %9 = zext i1 %8 to i8
  store i8 %9, ptr %5, align 1, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %1, i64 2
  %11 = load i8, ptr %10, align 2, !tbaa !6, !range !10, !noundef !11
  %12 = trunc nuw i8 %11 to i1
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %12, double noundef 9.000000e-01) #7
  %14 = zext i1 %13 to i8
  store i8 %14, ptr %10, align 2, !tbaa !6
  br label %15

15:                                               ; preds = %0, %27
  %16 = phi i64 [ 0, %0 ], [ %20, %27 ]
  %17 = phi i64 [ 1, %0 ], [ %28, %27 ]
  %18 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %16
  %19 = load i8, ptr %18, align 1, !tbaa !6, !range !10, !noundef !11
  %20 = add nuw nsw i64 %16, 1
  %21 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = add nuw nsw i8 %22, %19
  %24 = icmp eq i8 %23, 1
  %25 = trunc nuw nsw i64 %16 to i32
  %26 = uitofp nneg i32 %25 to double
  br label %30

27:                                               ; preds = %42
  %28 = add nuw nsw i64 %17, 1
  %29 = icmp eq i64 %20, 3
  br i1 %29, label %45, label %15, !llvm.loop !12

30:                                               ; preds = %15, %42
  %31 = phi i64 [ 0, %15 ], [ %43, %42 ]
  br i1 %24, label %32, label %42

32:                                               ; preds = %30
  %33 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %31
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !10, !noundef !11
  %35 = trunc nuw i8 %34 to i1
  %36 = trunc nuw nsw i64 %31 to i32
  %37 = uitofp nneg i32 %36 to double
  %38 = tail call double @llvm.fmuladd.f64(double %37, double 3.000000e-01, double 2.000000e-01)
  %39 = tail call double @llvm.fmuladd.f64(double %26, double 1.000000e-01, double %38)
  %40 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %35, double noundef %39) #7
  %41 = zext i1 %40 to i8
  store i8 %41, ptr %33, align 1, !tbaa !6
  br label %42

42:                                               ; preds = %30, %32
  %43 = add nuw nsw i64 %31, 1
  %44 = icmp eq i64 %43, %17
  br i1 %44, label %27, label %30, !llvm.loop !15

45:                                               ; preds = %27, %45
  %46 = phi i64 [ %53, %45 ], [ 0, %27 ]
  %47 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %46
  %48 = load i8, ptr %47, align 1, !tbaa !6, !range !10, !noundef !11
  %49 = trunc nuw i8 %48 to i1
  %50 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %49) #6
  %51 = zext i1 %50 to i32
  %52 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %51)
  %53 = add nuw nsw i64 %46, 1
  %54 = icmp eq i64 %53, 4
  br i1 %54, label %57, label %45, !llvm.loop !16

55:                                               ; preds = %57
  %56 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

57:                                               ; preds = %45, %57
  %58 = phi i64 [ %65, %57 ], [ 0, %45 ]
  %59 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %58
  %60 = load i8, ptr %59, align 1, !tbaa !6, !range !10, !noundef !11
  %61 = trunc nuw i8 %60 to i1
  %62 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %61) #6
  %63 = zext i1 %62 to i32
  %64 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %63)
  %65 = add nuw nsw i64 %58, 1
  %66 = icmp eq i64 %65, 4
  br i1 %66, label %55, label %57, !llvm.loop !17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }

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
!17 = distinct !{!17, !13, !14}
