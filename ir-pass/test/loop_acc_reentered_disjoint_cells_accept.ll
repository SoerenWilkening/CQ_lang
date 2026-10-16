; loop_acc_reentered_disjoint_cells_accept.ll — ACCEPT (bd 01po.19.18.10; R11 round
; 2b rA2b-F2, an over-decline the first per-entry check introduced).
;
; SOURCE (clang -O1, verbatim below; the reviewer's rA2b/p4.c):
;   #include <stdio.h>
;   #include <math.h>
;   #define N 3
;   #define K 1
;   int main(void) {
;       bool q[2*N] = {0};
;       for (int o = 0; o < 2; o++)
;         for (int j = 0; j < N; j++) cq_theta(&q[o*N+j], 1.0);
;       for (int o = 0; o < 2; o++) {
;           int c = 0;
;           for (int i = 0; i < N; i++) {
;               for (int v = 0; v <= K; v++) {
;                   double p = (double)(K - v) / (N - i);
;                   if (p < 0) p = 0;
;                   if (p > 1) p = 1;
;                   if (c == v) cq_theta(&q[o*N+i], 2.0 * asin(sqrt(p)));
;               }
;               if (q[o*N+i]) c = c + 1;
;           }
;       }
;       for (int o = 0; o < 2; o++) for (int i = 0; i < N; i++) printf("%d", cq_measure(q[o*N+i]));
;       printf("\n");
;       return 0;
;   }
;
; The counting loop is re-entered, so each entry's register is dead at the next
; mint; but entry o reads and rotates only cells q[3o .. 3o+2], so no cell an
; earlier entry recorded is ever rotated again. The per-entry check now asks PER
; CELL ACROSS ENTRIES by SCEV over the enclosing loop: the step's cell address
; {{0,+,12}<o>,+,4}<i> (i32 handle cells) covers [12o, 12o+8] in entry o, and the
; gate's address in entry o' > o starts 12(o'-o) >= 12 > 8 past it — disjoint for
; every pair of entries. Unprovable shapes still fail closed (loud).
; Each entry's register is dead after its loop and its cells are only measured
; afterwards, so it is left allocated and reported (WARN, option (a)).
; ANALYTIC CHECK (scratch state-vector replay of this lowering, linked and run;
; every register rotated here is an i1 cell, the counters are only permuted, so
; the bit-0 replay is exact): the two halves never share a qubit or a record, so
; the measured distribution FACTORS, P(abc def) = P3(abc) P3(def), e.g.
; P(100100) = 0.228900 = 0.478440^2, P(000000) = 0.000012, P(010100) = 0.065605
; = P3(010) P3(100); a dephasing leak across entries would break no factor here
; (the second entry moves no recorded cell) — the point is that the check proves
; it rather than refusing. Every freed rail |0>; stage 2b 3 sites verified / 0
; violations / 0 unproven, CENSUS 2 rail-mint sites left allocated (the cells,
; the dead counters — WARN), 0 template rails dirty.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; WARN: warning: {{.*}}dead loop accumulator left allocated
; RUN: %filecheck %s < %t.ll
; CHECK: %cq.acc = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_add_i32(i32 %{{h_cast[0-9]+}}, i32 %cq.acc), !cq.inplace.qq

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [6 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 6, ptr nonnull %1) #7
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %1, i8 0, i64 6, i1 false)
  br label %2

2:                                                ; preds = %0, %5
  %3 = phi i64 [ 0, %0 ], [ %6, %5 ]
  %4 = mul nuw nsw i64 %3, 3
  br label %8

5:                                                ; preds = %8
  %6 = add nuw nsw i64 %3, 1
  %7 = icmp eq i64 %3, 0
  br i1 %7, label %2, label %18, !llvm.loop !6

8:                                                ; preds = %2, %8
  %9 = phi i64 [ 0, %2 ], [ %16, %8 ]
  %10 = add nuw nsw i64 %9, %4
  %11 = getelementptr inbounds [6 x i8], ptr %1, i64 0, i64 %10
  %12 = load i8, ptr %11, align 1, !tbaa !9, !range !13, !noundef !14
  %13 = trunc nuw i8 %12 to i1
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef 1.000000e+00) #8
  %15 = zext i1 %14 to i8
  store i8 %15, ptr %11, align 1, !tbaa !9
  %16 = add nuw nsw i64 %9, 1
  %17 = icmp eq i64 %16, 3
  br i1 %17, label %5, label %8, !llvm.loop !15

18:                                               ; preds = %5, %30
  %19 = phi i64 [ %31, %30 ], [ 0, %5 ]
  %20 = mul nuw nsw i64 %19, 3
  %21 = mul nuw nsw i64 %19, 3
  br label %22

22:                                               ; preds = %18, %33
  %23 = phi i64 [ 0, %18 ], [ %39, %33 ]
  %24 = phi i32 [ 0, %18 ], [ %38, %33 ]
  %25 = trunc i64 %23 to i32
  %26 = sub i32 3, %25
  %27 = uitofp nneg i32 %26 to double
  %28 = add nuw nsw i64 %23, %20
  %29 = getelementptr inbounds [6 x i8], ptr %1, i64 0, i64 %28
  br label %41

30:                                               ; preds = %33
  %31 = add nuw nsw i64 %19, 1
  %32 = icmp eq i64 %19, 0
  br i1 %32, label %18, label %60, !llvm.loop !16

33:                                               ; preds = %57
  %34 = add nuw nsw i64 %23, %21
  %35 = getelementptr inbounds [6 x i8], ptr %1, i64 0, i64 %34
  %36 = load i8, ptr %35, align 1, !tbaa !9, !range !13, !noundef !14
  %37 = zext nneg i8 %36 to i32
  %38 = add nuw nsw i32 %24, %37
  %39 = add nuw nsw i64 %23, 1
  %40 = icmp eq i64 %39, 3
  br i1 %40, label %30, label %22, !llvm.loop !17

41:                                               ; preds = %22, %57
  %42 = phi i32 [ 0, %22 ], [ %58, %57 ]
  %43 = icmp eq i32 %24, %42
  br i1 %43, label %44, label %57

44:                                               ; preds = %41
  %45 = sub nuw nsw i32 1, %42
  %46 = uitofp nneg i32 %45 to double
  %47 = fdiv double %46, %27
  %48 = fcmp ogt double %47, 1.000000e+00
  %49 = select i1 %48, double 1.000000e+00, double %47
  %50 = load i8, ptr %29, align 1, !tbaa !9, !range !13, !noundef !14
  %51 = trunc nuw i8 %50 to i1
  %52 = tail call double @llvm.sqrt.f64(double %49)
  %53 = tail call double @llvm.asin.f64(double %52)
  %54 = fmul double %53, 2.000000e+00
  %55 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %51, double noundef %54) #8
  %56 = zext i1 %55 to i8
  store i8 %56, ptr %29, align 1, !tbaa !9
  br label %57

57:                                               ; preds = %44, %41
  %58 = add nuw nsw i32 %42, 1
  %59 = icmp eq i32 %42, 0
  br i1 %59, label %41, label %33, !llvm.loop !18

60:                                               ; preds = %30, %65
  %61 = phi i64 [ %66, %65 ], [ 0, %30 ]
  %62 = mul nuw nsw i64 %61, 3
  br label %68

63:                                               ; preds = %65
  %64 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 6, ptr nonnull %1) #7
  ret i32 0

65:                                               ; preds = %68
  %66 = add nuw nsw i64 %61, 1
  %67 = icmp eq i64 %61, 0
  br i1 %67, label %60, label %63, !llvm.loop !19

68:                                               ; preds = %60, %68
  %69 = phi i64 [ 0, %60 ], [ %77, %68 ]
  %70 = add nuw nsw i64 %69, %62
  %71 = getelementptr inbounds [6 x i8], ptr %1, i64 0, i64 %70
  %72 = load i8, ptr %71, align 1, !tbaa !9, !range !13, !noundef !14
  %73 = trunc nuw i8 %72 to i1
  %74 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %73) #7
  %75 = zext i1 %74 to i32
  %76 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %75)
  %77 = add nuw nsw i64 %69, 1
  %78 = icmp eq i64 %77, 3
  br i1 %78, label %65, label %68, !llvm.loop !20
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


!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{!10, !10, i64 0}
!10 = !{!"_Bool", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !7, !8}
!16 = distinct !{!16, !7, !8}
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
!19 = distinct !{!19, !7, !8}
!20 = distinct !{!20, !7, !8}
