; loop_acc_reject_dead_reentered_read.ll — DECLINE (bd 01po.19.18.10; R11 round 2b
; rA2b-F1, SILENT before the fix).
;
; SOURCE (clang -O1, verbatim below; the reviewer's rA2b/p1.c):
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
;           if (c == 1) cq_phi(0.5);
;       }
;       for (int i = 0; i < N; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; loop_acc_reject_dead_reentered.ll plus ONE read of the counter after the i loop
; (`if (c == 1) cq_phi(0.5)`). That read keeps the FIRST entry's register alive only
; until the outer loop mints the next entry's register under the same SSA name; the
; first register is then a dead record of the cells the second entry rotates. The
; first per-entry check stopped its walk at any read of the name and counted the
; next entry's reads as the old register's: rc 0, no diagnostic, and the replay
; matched the dephased model (000: 0.084512 against the program's 0.018259; the
; reviewer's null control validated the replay). The check now treats the mint as
; a CUT: a path from the loop exit that reaches the mint again re-enters, whatever
; it reads on the way (only a MEASUREMENT of the register observes it first), and
; liveness never looks past a re-execution of the mint.
; RETIREMENT TRIGGER: bd 8h7d.20 reverses each entry's register at its loop exit.
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

11:                                               ; preds = %2, %49
  %12 = phi i32 [ %50, %49 ], [ 0, %2 ]
  br label %13

13:                                               ; preds = %11, %22
  %14 = phi i64 [ 0, %11 ], [ %27, %22 ]
  %15 = phi i32 [ 0, %11 ], [ %26, %22 ]
  %16 = trunc i64 %14 to i32
  %17 = sub i32 3, %16
  %18 = uitofp nneg i32 %17 to double
  %19 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %14
  br label %29

20:                                               ; preds = %22
  %21 = icmp eq i32 %26, 1
  br i1 %21, label %48, label %49

22:                                               ; preds = %45
  %23 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %14
  %24 = load i8, ptr %23, align 1, !tbaa !6, !range !10, !noundef !11
  %25 = zext nneg i8 %24 to i32
  %26 = add nuw nsw i32 %15, %25
  %27 = add nuw nsw i64 %14, 1
  %28 = icmp eq i64 %27, 3
  br i1 %28, label %20, label %13, !llvm.loop !15

29:                                               ; preds = %13, %45
  %30 = phi i32 [ 0, %13 ], [ %46, %45 ]
  %31 = icmp eq i32 %15, %30
  br i1 %31, label %32, label %45

32:                                               ; preds = %29
  %33 = sub nuw nsw i32 1, %30
  %34 = uitofp nneg i32 %33 to double
  %35 = fdiv double %34, %18
  %36 = fcmp ogt double %35, 1.000000e+00
  %37 = select i1 %36, double 1.000000e+00, double %35
  %38 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %39 = trunc nuw i8 %38 to i1
  %40 = tail call double @llvm.sqrt.f64(double %37)
  %41 = tail call double @llvm.asin.f64(double %40)
  %42 = fmul double %41, 2.000000e+00
  %43 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %39, double noundef %42) #8
  %44 = zext i1 %43 to i8
  store i8 %44, ptr %19, align 1, !tbaa !6
  br label %45

45:                                               ; preds = %32, %29
  %46 = add nuw nsw i32 %30, 1
  %47 = icmp eq i32 %30, 0
  br i1 %47, label %29, label %22, !llvm.loop !16

48:                                               ; preds = %20
  tail call void @cq_phi(double noundef 5.000000e-01) #7
  br label %49

49:                                               ; preds = %48, %20
  %50 = add nuw nsw i32 %12, 1
  %51 = icmp eq i32 %12, 0
  br i1 %51, label %11, label %54, !llvm.loop !17

52:                                               ; preds = %54
  %53 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #7
  ret i32 0

54:                                               ; preds = %49, %54
  %55 = phi i64 [ %62, %54 ], [ 0, %49 ]
  %56 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %55
  %57 = load i8, ptr %56, align 1, !tbaa !6, !range !10, !noundef !11
  %58 = trunc nuw i8 %57 to i1
  %59 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %58) #7
  %60 = zext i1 %59 to i32
  %61 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %60)
  %62 = add nuw nsw i64 %55, 1
  %63 = icmp eq i64 %62, 3
  br i1 %63, label %52, label %54, !llvm.loop !18
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

declare void @cq_phi(double noundef) local_unnamed_addr #3

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
