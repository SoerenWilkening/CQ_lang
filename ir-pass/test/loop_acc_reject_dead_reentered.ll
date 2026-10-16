; loop_acc_reject_dead_reentered.ll — DECLINE (bd 01po.19.18.9; the SILENT
; r2j3.44, R11 round 2 rA2-F1).
;
; SOURCE (clang -O1, verbatim below; the reviewer's p5.c):
;   #include <stdio.h>
;   #include <math.h>
;   #define N 3
;   #define K 1
;   int main(void) {
;       bool q[N] = {0};
;       for (int j = 0; j < N; j++) cq_theta(&q[j], 1.0);
;       for (int o = 0; o < 2; o++) {
;           int c = 0;
;           for (int i = 0; i < N; i++) {
;               for (int v = 0; v <= K; v++) {
;                   double p = (double)(K - v) / (N - i);
;                   if (p < 0) p = 0;
;                   if (p > 1) p = 1;
;                   if (c == v) cq_theta(&q[i], 2.0 * asin(sqrt(p)));
;               }
;               if (q[i]) c = c + 1;
;           }
;       }
;       for (int i = 0; i < N; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; The F5 counting loop is RE-ENTERED by the outer `o` loop. Each entry mints a NEW
; register for `c` (`cqrt_alloc_i32(0)` in the loop's entry block, which repeats),
; and the previous entry's register — never read again, never reversed — is a dead
; record of the cells it counted. The second entry then rotates those same cells
; (`cq_theta(&q[i], …)` under `c == v`): a dead record standing at a non-diagonal
; gate on a rail it recorded. Before the fix the module lowered (rc 0, only the
; "left allocated" warning, whose "only measured afterwards" was false) and the
; replay matched the DEPHASED model to 6 digits (outcome 000: 0.084512, the
; program's coherent value 0.015390). The postcondition reasoned about earlier
; trips within ONE entry (`cellMayBeRecorded`), and its `deadAfter` read the next
; entry's register as the old one (same SSA name, different register).
; THE FIX asks the hazard PER ENTRY: when a path leads from the loop's exit back
; to the register's mint without reading it, the previous entry's register is dead
; at re-entry, and every move of a lineage rail (root or cell, no per-cell
; exemption) reachable from the mint is refused. Loud until bd 8h7d.20's post-loop
; reverse loop can uncompute each entry's register.
; RETIREMENT TRIGGER: 8h7d.20 reverses the register at each loop exit; this
; becomes an accept with a trace check against the coherent 0.015390.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: dead loop accumulator records a register moved after its last read

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #7
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 1.000000e+00) #8
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 3
  br i1 %10, label %11, label %2, !llvm.loop !12

11:                                               ; preds = %2, %20
  %12 = phi i32 [ %21, %20 ], [ 0, %2 ]
  br label %13

13:                                               ; preds = %11, %23
  %14 = phi i64 [ 0, %11 ], [ %28, %23 ]
  %15 = phi i32 [ 0, %11 ], [ %27, %23 ]
  %16 = trunc i64 %14 to i32
  %17 = sub i32 3, %16
  %18 = uitofp nneg i32 %17 to double
  %19 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %14
  br label %30

20:                                               ; preds = %23
  %21 = add nuw nsw i32 %12, 1
  %22 = icmp eq i32 %12, 0
  br i1 %22, label %11, label %51, !llvm.loop !15

23:                                               ; preds = %46
  %24 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %14
  %25 = load i8, ptr %24, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = zext nneg i8 %25 to i32
  %27 = add nuw nsw i32 %15, %26
  %28 = add nuw nsw i64 %14, 1
  %29 = icmp eq i64 %28, 3
  br i1 %29, label %20, label %13, !llvm.loop !16

30:                                               ; preds = %13, %46
  %31 = phi i32 [ 0, %13 ], [ %47, %46 ]
  %32 = icmp eq i32 %15, %31
  br i1 %32, label %33, label %46

33:                                               ; preds = %30
  %34 = sub nuw nsw i32 1, %31
  %35 = uitofp nneg i32 %34 to double
  %36 = fdiv double %35, %18
  %37 = fcmp ogt double %36, 1.000000e+00
  %38 = select i1 %37, double 1.000000e+00, double %36
  %39 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %40 = trunc nuw i8 %39 to i1
  %41 = tail call double @llvm.sqrt.f64(double %38)
  %42 = tail call double @llvm.asin.f64(double %41)
  %43 = fmul double %42, 2.000000e+00
  %44 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %40, double noundef %43) #8
  %45 = zext i1 %44 to i8
  store i8 %45, ptr %19, align 1, !tbaa !6
  br label %46

46:                                               ; preds = %33, %30
  %47 = add nuw nsw i32 %31, 1
  %48 = icmp eq i32 %31, 0
  br i1 %48, label %30, label %23, !llvm.loop !17

49:                                               ; preds = %51
  %50 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #7
  ret i32 0

51:                                               ; preds = %20, %51
  %52 = phi i64 [ %59, %51 ], [ 0, %20 ]
  %53 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %52
  %54 = load i8, ptr %53, align 1, !tbaa !6, !range !10, !noundef !11
  %55 = trunc nuw i8 %54 to i1
  %56 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %55) #7
  %57 = zext i1 %56 to i32
  %58 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %57)
  %59 = add nuw nsw i64 %52, 1
  %60 = icmp eq i64 %59, 3
  br i1 %60, label %49, label %51, !llvm.loop !18
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.asin.f64(double) #4

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #5

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #6

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nofree nounwind }
attributes #7 = { nounwind }
attributes #8 = { nomerge nounwind }


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
!18 = distinct !{!18, !13, !14}
