; railwindow_f5_reject_subloop_outer_temp.ll — DECLINE (bd 8h7d.25 / 01po.19.18.1):
; the boundary of the rail-local NEST. F5 with the subloop's condition read off an
; OUTER-BODY TEMPORARY `d = c * c` (a template rail of the accumulator minted in the
; outer trip, before the v-subloop) instead of off the accumulator register.
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdio.h>
;   #include <math.h>
;   #define N 4
;   #define K 2
;   int main(void) {
;       bool q[N] = {0};
;       int c = 0;
;       for (int i = 0; i < N; i++) {
;           int d = c * c;
;           for (int v = 0; v <= K; v++) {
;               double p = (double)(K - v) / (N - i);
;               if (p < 0) p = 0;
;               if (p > 1) p = 1;
;               if (d == v) cq_theta(&q[i], 2.0 * asin(sqrt(p)));
;           }
;           if (q[i]) c = c + 1;
;       }
;       for (int i = 0; i < N; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; `railLocalQualifies` admits a quantum subloop only when it qualifies ON ITS OWN
; (`iterationLocalQualifies`' subloop clause, one spelling) with the OUTER loop's
; collapsed roots as its only outside qubits. `%d` is neither: it is an outer
; temp read inside the subloop, so the outer body is not certified, the trip's
; source rails (and `%d`) cannot be discharged in it, and
; `declineStrandedAccumulatorTemps` fails loudly. (The hazard the clause guards: a
; DAG spanning the subloop boundary reversed once against a K-fold subloop.)
; RETIREMENT TRIGGER: an outer temp discharged after the subloop with a proven
; multiplicity (Uncomputation `multiplicityAgrees` for a nest) makes this lower.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop accumulator source temporaries cannot be discharged in the loop body

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %0, %10
  %3 = phi i64 [ 0, %0 ], [ %15, %10 ]
  %4 = phi i32 [ 0, %0 ], [ %14, %10 ]
  %5 = mul nuw nsw i32 %4, %4
  %6 = trunc i64 %3 to i32
  %7 = sub i32 4, %6
  %8 = uitofp nneg i32 %7 to double
  %9 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  br label %17

10:                                               ; preds = %33
  %11 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %12 = load i8, ptr %11, align 1, !tbaa !6, !range !10, !noundef !11
  %13 = zext nneg i8 %12 to i32
  %14 = add nuw nsw i32 %4, %13
  %15 = add nuw nsw i64 %3, 1
  %16 = icmp eq i64 %15, 4
  br i1 %16, label %38, label %2, !llvm.loop !12

17:                                               ; preds = %2, %33
  %18 = phi i32 [ 0, %2 ], [ %34, %33 ]
  %19 = icmp eq i32 %5, %18
  br i1 %19, label %20, label %33

20:                                               ; preds = %17
  %21 = sub nuw nsw i32 2, %18
  %22 = uitofp nneg i32 %21 to double
  %23 = fdiv double %22, %8
  %24 = fcmp ogt double %23, 1.000000e+00
  %25 = select i1 %24, double 1.000000e+00, double %23
  %26 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %27 = trunc nuw i8 %26 to i1
  %28 = tail call double @llvm.sqrt.f64(double %25)
  %29 = tail call double @llvm.asin.f64(double %28)
  %30 = fmul double %29, 2.000000e+00
  %31 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %27, double noundef %30) #7
  %32 = zext i1 %31 to i8
  store i8 %32, ptr %9, align 1, !tbaa !6
  br label %33

33:                                               ; preds = %20, %17
  %34 = add nuw nsw i32 %18, 1
  %35 = icmp eq i32 %34, 3
  br i1 %35, label %10, label %17, !llvm.loop !15

36:                                               ; preds = %38
  %37 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

38:                                               ; preds = %10, %38
  %39 = phi i64 [ %46, %38 ], [ 0, %10 ]
  %40 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %39
  %41 = load i8, ptr %40, align 1, !tbaa !6, !range !10, !noundef !11
  %42 = trunc nuw i8 %41 to i1
  %43 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %42) #6
  %44 = zext i1 %43 to i32
  %45 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %44)
  %46 = add nuw nsw i64 %39, 1
  %47 = icmp eq i64 %46, 4
  br i1 %47, label %36, label %38, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.asin.f64(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

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
