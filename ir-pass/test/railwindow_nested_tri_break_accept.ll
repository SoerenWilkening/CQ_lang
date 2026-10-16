; railwindow_nested_tri_break_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19.34.8`,
; N1: a down-counting triangle whose inner loop also `break`s at j == 2).
;
; The break leaves the inner loop TOP-TESTED (-O1 does not rotate it): the
; header computes the index `j - 1` and tests `j > 0`, so over the whole trip
; count the index reaches -1, although the body only runs with j - 1 >= 0. The
; walk over the symbolic max (a umin with the break's count) could not clear
; the zero-extension, and the module declined `aliased cell indices make a
; quantum control its own target`. Now the trip bound may be any single exit's
; own count (`tripBounds`), and the zero-extension is also cleared AT the use
; (`isKnownPredicateAt` under the header's `j > 0`, asked as `W + 1 > 0`).
; Decline twin (j starts at i: a real control == target):
; railwindow_nested_tri_break_reject_self_control.ll.
;
; ANALYTIC CHECK (scratch state-vector of the SOURCE vs replay of the trace,
; equal to 1e-6; no simulator in the repo), q[0] first, nothing else:
;   00000 +0.852525  10000 +0.302735  10100 -0.010440  10101 +0.057635
;   10110 -0.304538  10111 -0.150280  11000 -0.056934  11100 -0.007393
;   11101 +0.040814  11110 -0.215657  11111 -0.106420
; Stage 2b: 0 violations, 0 unproven (`_iv_sym_down_top`: the header-tested
; bound, claimed only for addresses used inside the loop body).
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdio.h>
;   int main(void) {
;       bool q[5];
;       for (int i = 0; i < 5; i++) q[i] = 0;
;       cq_theta(&q[0], 1.1);
;       for (int i = 0; i < 5; i++)
;           for (int j = i - 1; j >= 0; j--) {
;               if (q[j]) cq_theta(&q[i], 0.3 + 0.7 * i + 0.2 * j);
;               if (j == 2) break;
;           }
;       for (int i = 0; i < 5; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK: [[V0:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 [[V0]], double 1.100000e+00)
; CHECK: [[V1:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i1(i1 {{%[-a-zA-Z$._0-9]+}})
; CHECK: call void @cqrt_ry_i1_controlled(i32 {{%[-a-zA-Z$._0-9]+}}, i32 {{%[-a-zA-Z$._0-9]+}}, double {{%[-a-zA-Z$._0-9]+}})
; CHECK: call i1 @cqrt_measure_i1(i32 {{%[-a-zA-Z$._0-9]+}})
; CHECK-NOT: call {{.*}}@cq

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/brk_ok.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/brk_ok.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [5 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 5, ptr nonnull %1) #7
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(5) %1, i8 0, i64 5, i1 false), !tbaa !6
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.100000e+00) #8
  %3 = zext i1 %2 to i8
  store i8 %3, ptr %1, align 1, !tbaa !6
  br label %4

4:                                                ; preds = %0, %29
  %5 = phi i64 [ 0, %0 ], [ %30, %29 ]
  %6 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %5
  %7 = trunc nuw nsw i64 %5 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 0x3FE6666666666666, double 3.000000e-01)
  br label %10

10:                                               ; preds = %4, %27
  %11 = phi i64 [ %5, %4 ], [ %12, %27 ]
  %12 = add nsw i64 %11, -1
  %13 = trunc i64 %12 to i32
  %14 = icmp sgt i64 %11, 0
  br i1 %14, label %15, label %29

15:                                               ; preds = %10
  %16 = and i64 %12, 4294967295
  %17 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = trunc nuw i8 %18 to i1
  br i1 %19, label %20, label %27

20:                                               ; preds = %15
  %21 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  %23 = uitofp nneg i32 %13 to double
  %24 = tail call double @llvm.fmuladd.f64(double %23, double 2.000000e-01, double %9)
  %25 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef %24) #8
  %26 = zext i1 %25 to i8
  store i8 %26, ptr %6, align 1, !tbaa !6
  br label %27

27:                                               ; preds = %20, %15
  %28 = icmp eq i32 %13, 2
  br i1 %28, label %29, label %10, !llvm.loop !12

29:                                               ; preds = %27, %10
  %30 = add nuw nsw i64 %5, 1
  %31 = icmp eq i64 %30, 5
  br i1 %31, label %34, label %4, !llvm.loop !15

32:                                               ; preds = %34
  %33 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 5, ptr nonnull %1) #7
  ret i32 0

34:                                               ; preds = %29, %34
  %35 = phi i64 [ %42, %34 ], [ 0, %29 ]
  %36 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %35
  %37 = load i8, ptr %36, align 1, !tbaa !6, !range !10, !noundef !11
  %38 = trunc nuw i8 %37 to i1
  %39 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %38) #7
  %40 = zext i1 %39 to i32
  %41 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %40)
  %42 = add nuw nsw i64 %35, 1
  %43 = icmp eq i64 %42, 5
  br i1 %43, label %32, label %34, !llvm.loop !16
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

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #6

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #7 = { nounwind }
attributes #8 = { nomerge nounwind }

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
