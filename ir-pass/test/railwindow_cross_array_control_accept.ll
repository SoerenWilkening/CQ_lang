; railwindow_cross_array_control_accept.ll — ACCEPT (bd `test_C_libtooling-8h7d.24`,
; found on the way: a quantum control from ONE array onto a cell of ANOTHER).
;
; `if (c[m] + c[m+1] == 1) Ry(q[m])` in a single loop declined `control flow
; under quantum control`: the S6 arm promotion of `q`'s window seeded its
; quantum-data closure with `q`'s own cell loads only, so a condition built
; from `c` was not "quantum" to it and the arm's cell store stayed unpromoted
; (an off-pattern merge). The closure is now seeded with the loads of every
; array holding a tainted value (`promoteRailWindowArms`).
;
; ANALYTIC CHECK (scratch state-vector of the SOURCE vs replay of the trace,
; equal to 1e-6; c[0..3] then q[0..3], nothing else):
;   00000000 +0.814448  01000000 +0.247865  01000100 +0.037461  01001000 +0.024869
;   01001100 +0.003759  10000000 +0.496848  10001000 +0.049851  11000000 +0.152730
;   11000100 +0.023083
; Stage 2b: 4 of 4 free sites verified, 0 unproven.
;
; SOURCE (clang -O1, verbatim below):
;   /* single-level: control from array c, target in array q */
;   #include <stdio.h>
;   int main(void) {
;       bool c[4], q[4];
;       for (int i = 0; i < 4; i++) { c[i] = 0; q[i] = 0; }
;       cq_theta(&c[0], 1.1);
;       cq_theta(&c[1], 0.6);
;       for (int m = 0; m < 3; m++)
;           if (c[m] + c[m + 1] == 1) cq_theta(&q[m], 0.2 + 0.1 * m);
;       for (int i = 0; i < 4; i++) printf("%d", cq_measure(c[i]));
;       for (int i = 0; i < 4; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='cq controlled lowering'
; CHECK: call void @cqrt_ry_i1_controlled(i32 {{%[-a-zA-Z$._0-9]+}}, i32 %cq.arm.in, double {{%[-a-zA-Z$._0-9]+}})
; CHECK: call i1 @cqrt_measure_i1

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/h24/p_two.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/h24/p_two.c"
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
  br label %10

10:                                               ; preds = %0, %28
  %11 = phi i64 [ 0, %0 ], [ %14, %28 ]
  %12 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !10, !noundef !11
  %14 = add nuw nsw i64 %11, 1
  %15 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %14
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = add nuw nsw i8 %16, %13
  %18 = icmp eq i8 %17, 1
  br i1 %18, label %19, label %28

19:                                               ; preds = %10
  %20 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %11
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  %23 = trunc nuw nsw i64 %11 to i32
  %24 = uitofp nneg i32 %23 to double
  %25 = tail call double @llvm.fmuladd.f64(double %24, double 1.000000e-01, double 2.000000e-01)
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef %25) #7
  %27 = zext i1 %26 to i8
  store i8 %27, ptr %20, align 1, !tbaa !6
  br label %28

28:                                               ; preds = %10, %19
  %29 = icmp eq i64 %14, 3
  br i1 %29, label %30, label %10, !llvm.loop !12

30:                                               ; preds = %28, %30
  %31 = phi i64 [ %38, %30 ], [ 0, %28 ]
  %32 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %31
  %33 = load i8, ptr %32, align 1, !tbaa !6, !range !10, !noundef !11
  %34 = trunc nuw i8 %33 to i1
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34) #6
  %36 = zext i1 %35 to i32
  %37 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %36)
  %38 = add nuw nsw i64 %31, 1
  %39 = icmp eq i64 %38, 4
  br i1 %39, label %42, label %30, !llvm.loop !15

40:                                               ; preds = %42
  %41 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

42:                                               ; preds = %30, %42
  %43 = phi i64 [ %50, %42 ], [ 0, %30 ]
  %44 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %43
  %45 = load i8, ptr %44, align 1, !tbaa !6, !range !10, !noundef !11
  %46 = trunc nuw i8 %45 to i1
  %47 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %46) #6
  %48 = zext i1 %47 to i32
  %49 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %48)
  %50 = add nuw nsw i64 %43, 1
  %51 = icmp eq i64 %50, 4
  br i1 %51, label %40, label %42, !llvm.loop !16
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
