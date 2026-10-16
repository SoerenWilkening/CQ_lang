; railwindow_dicke_n5k3_nested_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19.34`,
; general K: a quantum-controlled region inside a NESTED classically-bounded loop).
;
; The reporter's general-N Dicke circuit at N=5 K=3 (`dicke_n.c -DN=5 -DK=3`),
; ROLLED. Unlike N=4 K=2 (railwindow_dicke_n_accept.ll), the inner `l` loop runs
; up to TWO trips (kk = min(3, m-1)), so -O1 keeps it a real subloop of the `m`
; loop. The `if (q[m-1]) Ry(q[m-2])` region sits in the OUTER body, the
; `s == 3` region in the INNER one.
;
; Until 01po.19.34 `markIfIterationLocal` refused ANY loop holding a quantum
; subloop, so the outer body was never marked and the outer region's R7 grant
; was refused at the final-taint re-ask (`declineUnmarkedRolledIterLocal`):
; `control flow inside a loop body` at the outer `cq_theta` (source line 23).
; It now admits a quantum subloop that is iteration-local ON ITS OWN (the same
; predicate, by recursion: no tainted exit or header phi, every tainted value
; it defines used only inside it, every tainted operand it reads defined inside
; it). The decline twin is railwindow_nested_reject_subloop_reads_outer.ll.
;
; Pinned below: the outer trip's in-place CNOT / controlled Ry / CNOT on cells,
; then the INNER loop block (its own back edge) holding the whole s-chain —
; `%bf` copy, select `%out` by controlled xor-immediate, zext/or/icmp, the
; controlled Ry on cell q[m-1-l], the reverse chain and every free — before
; the inner back edge, i.e. discharged once per INNER trip.
;
; ANALYTIC CHECK (independent scratch state-vector replay of the e2e trace,
; tests/e2e/slice_rolled_dicke_n5_k3.c; no simulator in the repo, owner
; decision 2026-06-10): the final state of q[0..4] is |D^5_3>: the ten
; weight-3 strings, each amplitude +0.316228 (1/sqrt(10)), nothing else; every
; `cqrt_free` frees a |0> rail (stage 2b: 6 of 6 free sites verified).
;
; SOURCE (clang -O1 -DN=5 -DK=3, verbatim below):
;   /* Dicke state |D^N_K> for arbitrary N, K — Bärtschi & Eidenbenz (2019).
;    * Start |0^{N-K} 1^K>, then apply SCS_{m, min(K, m-1)} for m = N down to 2.
;    * Qubits are q[0..N-1]; SCS_m acts on q[0..m-1] with q[m-1] as its last qubit. */
;   #include <stdio.h>
;   #include <math.h>
;   
;   #ifndef N
;   #define N 4
;   #endif
;   #ifndef K
;   #define K 2
;   #endif
;   
;   int main(void) {
;       bool q[N];
;       for (int i = 0; i < N; i++) q[i] = (i >= N - K);
;   
;       for (int m = N; m >= 2; m--) {
;           int kk = K < m - 1 ? K : m - 1;
;   
;           /* 2-qubit block on (q[m-2], q[m-1]) */
;           q[m - 1] ^= q[m - 2];
;           if (q[m - 1]) cq_theta(&q[m - 2], 2.0 * acos(sqrt(1.0 / m)));
;           q[m - 1] ^= q[m - 2];
;   
;           /* 3-qubit blocks l = 2..kk on (q[m-1-l], q[m-l], q[m-1]) */
;           for (int l = 2; l <= kk; l++) {
;               q[m - 1] ^= q[m - 1 - l];
;               int s = 2 * q[m - 1] + q[m - l];
;               if (s == 3) cq_theta(&q[m - 1 - l], 2.0 * acos(sqrt((double)l / m)));
;               q[m - 1] ^= q[m - 1 - l];
;           }
;       }
;   
;       for (int i = 0; i < N; i++) printf("%d", cq_measure(q[i]));
;       printf("\n");
;       return 0;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK: [[V0:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i1(i1 [[V1:%[-a-zA-Z$._0-9]+]])
; CHECK: call void @cqrt_cnot(i32 [[V2:%[-a-zA-Z$._0-9]+]], i32 [[V3:%[-a-zA-Z$._0-9]+]])
; CHECK: call void @cqrt_ry_i1_controlled(i32 [[V3]], i32 [[V2]], double {{%[-a-zA-Z$._0-9]+}})
; CHECK: call void @cqrt_cnot(i32 [[V2]], i32 [[V3]])
; CHECK: {{^}}[[INNER:[0-9]+]]:{{.*}}; preds = {{.*}}%[[INNER]]{{(,|$)}}
; CHECK-NEXT: phi i64 [ 2,
; CHECK: call void @cqrt_cnot(i32 [[V4:%[-a-zA-Z$._0-9]+]], i32 [[V5:%[-a-zA-Z$._0-9]+]])
; CHECK: [[V6:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_cnot(i32 [[V5]], i32 [[V6]])
; CHECK: [[V7:%[-a-zA-Z$._0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[V6]], i32 [[V7]], i32 2)
; CHECK: [[V8:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_zext_i1_to_i8(i32 [[V9:%[-a-zA-Z$._0-9]+]])
; CHECK: [[V10:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_zext_i8_to_i32(i32 [[V8]])
; CHECK: [[V11:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_or_i32(i32 [[V7]], i32 [[V10]])
; CHECK: [[V12:%[-a-zA-Z$._0-9]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 [[V11]], i32 3)
; CHECK: call void @cqrt_ry_i1_controlled(i32 [[V12]], i32 [[V4]], double {{%[-a-zA-Z$._0-9]+}})
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[V12]], i32 [[V11]], i32 3)
; CHECK: call void @cq_template_or_i32_unc(i32 [[V11]], i32 [[V7]], i32 [[V10]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[V6]], i32 [[V7]], i32 2)
; CHECK: call void @cqrt_cnot(i32 [[V5]], i32 [[V6]])
; CHECK: call void @cqrt_free(i32 [[V6]])
; CHECK: call void @cqrt_free(i32 [[V7]])
; CHECK: call void @cqrt_free(i32 [[V11]])
; CHECK: call void @cq_template_zext_i8_to_i32_unc(i32 [[V10]], i32 [[V8]])
; CHECK: call void @cqrt_free(i32 [[V10]])
; CHECK: call void @cq_template_zext_i1_to_i8_unc(i32 [[V8]], i32 [[V9]])
; CHECK: call void @cqrt_free(i32 [[V8]])
; CHECK: call void @cqrt_free(i32 [[V12]])
; CHECK: call void @cqrt_cnot(i32 [[V4]], i32 [[V5]])
; CHECK: br i1 {{%[-a-zA-Z$._0-9]+}}, label %[[INNER]], label
; CHECK: [[V13:%[-a-zA-Z$._0-9]+]] = call i1 @cqrt_measure_i1(i32 [[V14:%[-a-zA-Z$._0-9]+]])
; CHECK-NOT: call {{.*}}@cq

; ModuleID = 'dicke_n.c'
source_filename = "dicke_n.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [5 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 5, ptr nonnull %1) #7
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = icmp ugt i64 %3, 1
  %5 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %3
  %6 = zext i1 %4 to i8
  store i8 %6, ptr %5, align 1, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 5
  br i1 %8, label %11, label %2, !llvm.loop !10

9:                                                ; preds = %69, %33
  %10 = icmp ugt i64 %12, 2
  br i1 %10, label %11, label %78, !llvm.loop !13

11:                                               ; preds = %2, %9
  %12 = phi i64 [ %13, %9 ], [ 5, %2 ]
  %13 = add nsw i64 %12, -1
  %14 = trunc nuw nsw i64 %13 to i32
  %15 = tail call i32 @llvm.smin.i32(i32 %14, i32 3)
  %16 = add nsw i64 %12, -2
  %17 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !14, !noundef !15
  %19 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %13
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !14, !noundef !15
  %21 = icmp ne i8 %20, %18
  %22 = zext i1 %21 to i8
  store i8 %22, ptr %19, align 1, !tbaa !6
  br i1 %21, label %23, label %33

23:                                               ; preds = %11
  %24 = trunc nuw i8 %18 to i1
  %25 = trunc nuw nsw i64 %12 to i32
  %26 = uitofp nneg i32 %25 to double
  %27 = fdiv double 1.000000e+00, %26
  %28 = tail call double @llvm.sqrt.f64(double %27)
  %29 = tail call double @llvm.acos.f64(double %28)
  %30 = fmul double %29, 2.000000e+00
  %31 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %24, double noundef %30) #8
  %32 = zext i1 %31 to i8
  store i8 %32, ptr %17, align 1, !tbaa !6
  br label %33

33:                                               ; preds = %23, %11
  %34 = load i8, ptr %17, align 1, !tbaa !6, !range !14, !noundef !15
  %35 = load i8, ptr %19, align 1, !tbaa !6, !range !14, !noundef !15
  %36 = icmp ne i8 %35, %34
  %37 = zext i1 %36 to i8
  store i8 %37, ptr %19, align 1, !tbaa !6
  %38 = icmp ult i64 %12, 3
  br i1 %38, label %9, label %39

39:                                               ; preds = %33
  %40 = trunc nuw nsw i64 %12 to i32
  %41 = uitofp nneg i32 %40 to double
  %42 = zext i32 %15 to i64
  br label %43

43:                                               ; preds = %39, %69
  %44 = phi i64 [ 2, %39 ], [ %74, %69 ]
  %45 = sub nsw i64 %13, %44
  %46 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %45
  %47 = load i8, ptr %46, align 1, !tbaa !6, !range !14, !noundef !15
  %48 = load i8, ptr %19, align 1, !tbaa !6, !range !14, !noundef !15
  %49 = icmp ne i8 %48, %47
  %50 = zext i1 %49 to i8
  store i8 %50, ptr %19, align 1, !tbaa !6
  %51 = select i1 %49, i32 2, i32 0
  %52 = sub nsw i64 %12, %44
  %53 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %52
  %54 = load i8, ptr %53, align 1, !tbaa !6, !range !14, !noundef !15
  %55 = zext nneg i8 %54 to i32
  %56 = or disjoint i32 %51, %55
  %57 = icmp eq i32 %56, 3
  br i1 %57, label %58, label %69

58:                                               ; preds = %43
  %59 = load i8, ptr %46, align 1, !tbaa !6, !range !14, !noundef !15
  %60 = trunc nuw i8 %59 to i1
  %61 = trunc nuw nsw i64 %44 to i32
  %62 = uitofp nneg i32 %61 to double
  %63 = fdiv double %62, %41
  %64 = tail call double @llvm.sqrt.f64(double %63)
  %65 = tail call double @llvm.acos.f64(double %64)
  %66 = fmul double %65, 2.000000e+00
  %67 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %60, double noundef %66) #8
  %68 = zext i1 %67 to i8
  store i8 %68, ptr %46, align 1, !tbaa !6
  br label %69

69:                                               ; preds = %58, %43
  %70 = load i8, ptr %46, align 1, !tbaa !6, !range !14, !noundef !15
  %71 = load i8, ptr %19, align 1, !tbaa !6, !range !14, !noundef !15
  %72 = icmp ne i8 %71, %70
  %73 = zext i1 %72 to i8
  store i8 %73, ptr %19, align 1, !tbaa !6
  %74 = add nuw nsw i64 %44, 1
  %75 = icmp ult i64 %44, %42
  br i1 %75, label %43, label %9, !llvm.loop !16

76:                                               ; preds = %78
  %77 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 5, ptr nonnull %1) #7
  ret i32 0

78:                                               ; preds = %9, %78
  %79 = phi i64 [ %86, %78 ], [ 0, %9 ]
  %80 = getelementptr inbounds [5 x i8], ptr %1, i64 0, i64 %79
  %81 = load i8, ptr %80, align 1, !tbaa !6, !range !14, !noundef !15
  %82 = trunc nuw i8 %81 to i1
  %83 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %82) #7
  %84 = zext i1 %83 to i32
  %85 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %84)
  %86 = add nuw nsw i64 %79, 1
  %87 = icmp eq i64 %86, 5
  br i1 %87, label %76, label %78, !llvm.loop !17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.acos.f64(double) #3

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #6

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = !{i8 0, i8 2}
!15 = !{}
!16 = distinct !{!16, !11, !12}
!17 = distinct !{!17, !11, !12}
