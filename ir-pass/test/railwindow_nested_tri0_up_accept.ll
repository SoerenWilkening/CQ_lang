; railwindow_nested_tri0_up_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19.34.7`, R11 round 2
; rN2-F1: the C-F1 triangle class, outer counter from 0, inner up).
;
; `for i in 0..3 { for j in 0 .. i-1 { if (q[j]) Ry(q[i], .) } }`. q[j] and
; q[i] are never one cell (j < i), but round 1's `nonZeroOverLoop` refused it:
;   the i == 0 trip skips the inner loop through `icmp eq %i, 0`, and
;   `isKnownNegative(-i)` was asked over EVERY outer trip, i == 0 included;
;   the inner trip bound i - 1 is -1 there, a full unsigned range.
; Now the end-point argument reads the trip bound and the signs at the inner
; loop's ENTRY under its guards (`isLoopEntryGuardedByCond`, `applyLoopGuards`,
; `x <= 0 && x != 0` with `!= 0` asked of x and of -x), and a zero-extension
; whose wide counterpart (trunc(W) == operand, SCEV's own fold) walks inside
; [0, 2^w - 1] at entry is replaced by W. Decline twins (j reaching i):
; railwindow_nested_ladder_reject_self_control.ll and
; railwindow_nested_tri_down_reject_self_control.ll.
;
; ANALYTIC CHECK (independent scratch state-vector of the SOURCE vs replay of
; the trace, equal to 1e-6; with and without -g; no simulator in the repo):
;   0000 +0.852525  1000 +0.109698  1001 +0.282161  1010 -0.295295
;   1011 +0.177649  1100 +0.045613  1101 -0.034074  1110 -0.177154
;   1111 -0.167840
; (q[0] first), nothing else. Stage 2b: 0 violations, 0 unproven (its own
; entry-guard and down-counter bounds, `_entry_lo` / `_iv_sym_down`).
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdio.h>
;   int main(void) {
;       bool q[4];
;       for (int i = 0; i < 4; i++) q[i] = 0;
;       cq_theta(&q[0], 1.1);
;       for (int i = 0; i < 4; i++) {
;           for (int j = 0; j < i; j++) {
;               if (q[j]) cq_theta(&q[i], 0.3 + 0.7 * i + 0.2 * j);
;           }
;       }
;       for (int i = 0; i < 4; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK: [[V0:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 [[V0]], double 1.100000e+00)
; CHECK: [[V1:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i1(i1 {{%[-a-zA-Z$._0-9]+}})
; CHECK: {{^}}[[INNER:[0-9]+]]:{{.*}}; preds = {{.*}}%[[INNER]]{{(,|$)}}
; CHECK: call void @cqrt_ry_i1_controlled(i32 {{%[-a-zA-Z$._0-9]+}}, i32 {{%[-a-zA-Z$._0-9]+}}, double {{%[-a-zA-Z$._0-9]+}})
; CHECK: br i1 {{%[-a-zA-Z$._0-9]+}}, {{.*}}label %[[INNER]]
; CHECK: call i1 @cqrt_measure_i1(i32 {{%[-a-zA-Z$._0-9]+}})
; CHECK-NOT: call {{.*}}@cq

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/tri0up.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/tri0up.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  store i32 0, ptr %1, align 4
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00) #7
  %3 = zext i1 %2 to i8
  store i8 %3, ptr %1, align 4, !tbaa !6
  br label %4

4:                                                ; preds = %0, %12
  %5 = phi i64 [ 0, %0 ], [ %13, %12 ]
  %6 = icmp eq i64 %5, 0
  br i1 %6, label %12, label %7

7:                                                ; preds = %4
  %8 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %9 = trunc nuw nsw i64 %5 to i32
  %10 = uitofp nneg i32 %9 to double
  %11 = tail call double @llvm.fmuladd.f64(double %10, double 0x3FE6666666666666, double 3.000000e-01)
  br label %15

12:                                               ; preds = %28, %4
  %13 = add nuw nsw i64 %5, 1
  %14 = icmp eq i64 %13, 4
  br i1 %14, label %33, label %4, !llvm.loop !10

15:                                               ; preds = %7, %28
  %16 = phi i64 [ 0, %7 ], [ %29, %28 ]
  %17 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !13, !noundef !14
  %19 = trunc nuw i8 %18 to i1
  br i1 %19, label %20, label %28

20:                                               ; preds = %15
  %21 = load i8, ptr %8, align 1, !tbaa !6, !range !13, !noundef !14
  %22 = trunc nuw i8 %21 to i1
  %23 = trunc nuw nsw i64 %16 to i32
  %24 = uitofp nneg i32 %23 to double
  %25 = tail call double @llvm.fmuladd.f64(double %24, double 2.000000e-01, double %11)
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef %25) #7
  %27 = zext i1 %26 to i8
  store i8 %27, ptr %8, align 1, !tbaa !6
  br label %28

28:                                               ; preds = %15, %20
  %29 = add nuw nsw i64 %16, 1
  %30 = icmp eq i64 %29, %5
  br i1 %30, label %12, label %15, !llvm.loop !15

31:                                               ; preds = %33
  %32 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

33:                                               ; preds = %12, %33
  %34 = phi i64 [ %41, %33 ], [ 0, %12 ]
  %35 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %34
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !13, !noundef !14
  %37 = trunc nuw i8 %36 to i1
  %38 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %37) #6
  %39 = zext i1 %38 to i32
  %40 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %39)
  %41 = add nuw nsw i64 %34, 1
  %42 = icmp eq i64 %41, 4
  br i1 %42, label %31, label %33, !llvm.loop !16
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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !11, !12}
!16 = distinct !{!16, !11, !12}
