; railwindow_nested3_sibling_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19.34.5`,
; R11 round 1 A-F3: a 3-level nest plus a SIBLING subloop).
;
; Loud until now at the Q4 cell-temp postcondition (`temporary read from a
; quantum-array cell is live at a non-diagonal gate on that array`): the
; record `zext(q[m-1])` of the sibling `l2` loop was asked at the j-loop's
; controlled Ry (a gate on another cell, in the previous outer trip's order).
; `recordAbsentAt` exempted a record only through
; `provablyBeforePerActivation(T, R, discharge)`, whose first conjunct is
; `DT.dominates(T, R)`; the j-loop gate sits under that loop's zero-trip guard
; and does not dominate the sibling record, although every path from the record
; back to the gate runs the record's own `cqrt_free`. The new disjunct asks the
; invariant itself: some discharge CI of R lies on every path R -> T and on
; every path R -> R (so no instance outlives its discharge to reach T).
;
; ANALYTIC CHECK (scratch state-vector of the SOURCE vs replay of the trace,
; equal to 1e-6; no simulator in the repo), q[0] first, nothing else:
;   00001 +0.054023  00011 +0.247233  00101 -0.158194  00111 +0.319919
;   01001 -0.004653  01011 +0.242927  01101 +0.112865  01111 -0.054110
;   10001 +0.150976  10011 -0.301643  10101 -0.737178  10111 +0.138335
;   11001 +0.102155  11011 +0.199065  11101 -0.002363  11111 -0.086395
; Every one of the 90 dynamic frees frees a |0> rail; stage 2b 9 of 9 free
; sites verified, 0 unproven (down-counted outer range, signed inner bound,
; two-counter interval difference).
;
; SOURCE (clang -O1, verbatim below):
;   /* H6: three-level nest + a sibling subloop, each level with its own tainted temps. */
;   #include <stdio.h>
;   int main(void) {
;       bool q[5];
;       for (int i = 0; i < 5; i++) q[i] = (i >= 3);
;       for (int m = 5; m >= 2; m--) {
;           for (int l = 1; l <= m - 1; l++) {
;               int s = 2 * q[m - 1] + 1;
;               if (s == 3) cq_theta(&q[m - 1 - l], 0.2 + l);
;               for (int j = 1; j <= m - 1 - l; j++) {
;                   int t = q[m - l - j] + 2 * q[m - 1];
;                   if (t == 3) cq_theta(&q[m - 1 - l - j], 0.1 + j);
;               }
;           }
;           for (int l2 = 1; l2 <= m - 1; l2++) {
;               int u = q[m - 1] + 3;
;               if (u == 4) cq_theta(&q[m - 1 - l2], 0.7);
;           }
;       }
;       for (int i = 0; i < 5; i++) printf("%d", cq_measure(q[i]));
;       return 0;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='cq rail window'
; CHECK-COUNT-3: call void @cqrt_ry_i1_controlled(
; CHECK: call i1 @cqrt_measure_i1

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/nest3.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/506bd29d-3cdd-4ab9-8e19-764fbdc14f66/scratchpad/laneN/fx/nest3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [5 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 5, ptr nonnull %1) #4
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = icmp ugt i64 %3, 2
  %5 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %3
  %6 = zext i1 %4 to i8
  store i8 %6, ptr %5, align 1, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 5
  br i1 %8, label %11, label %2, !llvm.loop !10

9:                                                ; preds = %71
  %10 = icmp ugt i64 %12, 2
  br i1 %10, label %11, label %75, !llvm.loop !13

11:                                               ; preds = %2, %9
  %12 = phi i64 [ %13, %9 ], [ 5, %2 ]
  %13 = add nsw i64 %12, -1
  %14 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %13
  br label %17

15:                                               ; preds = %34
  %16 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %13
  br label %60

17:                                               ; preds = %11, %34
  %18 = phi i64 [ 1, %11 ], [ %35, %34 ]
  %19 = load i8, ptr %14, align 1, !tbaa !6, !range !14, !noundef !15
  %20 = icmp eq i8 %19, 0
  br i1 %20, label %31, label %21

21:                                               ; preds = %17
  %22 = sub nsw i64 %13, %18
  %23 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %22
  %24 = load i8, ptr %23, align 1, !tbaa !6, !range !14, !noundef !15
  %25 = trunc nuw i8 %24 to i1
  %26 = trunc nuw nsw i64 %18 to i32
  %27 = uitofp nneg i32 %26 to double
  %28 = fadd double %27, 2.000000e-01
  %29 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %25, double noundef %28) #5
  %30 = zext i1 %29 to i8
  store i8 %30, ptr %23, align 1, !tbaa !6
  br label %31

31:                                               ; preds = %21, %17
  %32 = sub nsw i64 %13, %18
  %33 = icmp slt i64 %32, 1
  br i1 %33, label %34, label %37

34:                                               ; preds = %57, %31
  %35 = add nuw nsw i64 %18, 1
  %36 = icmp eq i64 %35, %12
  br i1 %36, label %15, label %17, !llvm.loop !16

37:                                               ; preds = %31, %57
  %38 = phi i64 [ %58, %57 ], [ 1, %31 ]
  %39 = add nuw nsw i64 %18, %38
  %40 = sub nsw i64 %12, %39
  %41 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %40
  %42 = load i8, ptr %41, align 1, !tbaa !6, !range !14, !noundef !15
  %43 = load i8, ptr %14, align 1, !tbaa !6, !range !14, !noundef !15
  %44 = shl nuw nsw i8 %43, 1
  %45 = or disjoint i8 %44, %42
  %46 = icmp eq i8 %45, 3
  br i1 %46, label %47, label %57

47:                                               ; preds = %37
  %48 = sub nsw i64 %32, %38
  %49 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %48
  %50 = load i8, ptr %49, align 1, !tbaa !6, !range !14, !noundef !15
  %51 = trunc nuw i8 %50 to i1
  %52 = trunc nuw nsw i64 %38 to i32
  %53 = uitofp nneg i32 %52 to double
  %54 = fadd double %53, 1.000000e-01
  %55 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %51, double noundef %54) #5
  %56 = zext i1 %55 to i8
  store i8 %56, ptr %49, align 1, !tbaa !6
  br label %57

57:                                               ; preds = %47, %37
  %58 = add nuw nsw i64 %38, 1
  %59 = icmp slt i64 %38, %32
  br i1 %59, label %37, label %34, !llvm.loop !17

60:                                               ; preds = %15, %71
  %61 = phi i64 [ 1, %15 ], [ %72, %71 ]
  %62 = load i8, ptr %16, align 1, !tbaa !6, !range !14, !noundef !15
  %63 = icmp eq i8 %62, 0
  br i1 %63, label %71, label %64

64:                                               ; preds = %60
  %65 = sub nsw i64 %13, %61
  %66 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %65
  %67 = load i8, ptr %66, align 1, !tbaa !6, !range !14, !noundef !15
  %68 = trunc nuw i8 %67 to i1
  %69 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %68, double noundef 0x3FE6666666666666) #5
  %70 = zext i1 %69 to i8
  store i8 %70, ptr %66, align 1, !tbaa !6
  br label %71

71:                                               ; preds = %64, %60
  %72 = add nuw nsw i64 %61, 1
  %73 = icmp eq i64 %72, %12
  br i1 %73, label %9, label %60, !llvm.loop !18

74:                                               ; preds = %75
  call void @llvm.lifetime.end.p0(i64 5, ptr nonnull %1) #4
  ret i32 0

75:                                               ; preds = %9, %75
  %76 = phi i64 [ %83, %75 ], [ 0, %9 ]
  %77 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %76
  %78 = load i8, ptr %77, align 1, !tbaa !6, !range !14, !noundef !15
  %79 = trunc nuw i8 %78 to i1
  %80 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %79) #4
  %81 = zext i1 %80 to i32
  %82 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %81)
  %83 = add nuw nsw i64 %76, 1
  %84 = icmp eq i64 %83, 5
  br i1 %84, label %74, label %75, !llvm.loop !19
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = !{i8 0, i8 2}
!15 = !{}
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !11, !12}
!18 = distinct !{!18, !11, !12}
!19 = distinct !{!19, !11, !12}
