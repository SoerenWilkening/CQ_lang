; railwindow_trip_reject_dicke_gate_on_read_cell.ll — DECLINE (bd
; `test_C_libtooling-01po.19.17`; the same-cell side of the merge-discharge
; (MergeStreamPlan step 7) exemption).
;
; railwindow_dicke_n_accept.ll's program with `cq_theta(&q[m-l], 0.2)` between
; `s = 2*q[m-1] + q[m-l]` and `if (s == 3)`: a non-diagonal gate on a cell the
; s chain (its select `%out` included) READ, inside the chain's window. Every
; exemption of 01po.19.17 is for reads of provably DIFFERENT cells, so none
; applies; the condition-wire fence refuses first (the `s == 3` condition
; predates a non-diagonal gate on its own lineage). Physics: the controlled Ry
; must see the pre-gate s, whose record would have to survive a gate on its
; source cell.
; ⚠ WHAT THIS PINS, STATED PRECISELY (review (a) C-F3): it never went red for
; 01po.19.17 — the condition-wire fence refuses it on both binaries, before
; MergeStreamPlan step 7 runs. Step 7's same-cell refusal is not reachable
; from C on this branch: a gate on a cell the s chain read, inside the chain's
; window, always has the chain's condition (or another consumer of it)
; predating the gate, and that fence is earlier in the pipeline (measured on
; the C shapes tried: this one and the gate-before-condition variants). A
; hand-IR isolation of step 7 was not attempted; step 7's same-cell branch has
; no discriminating fixture (owed). Kept as a REGRESSION PIN of the boundary.
;
; SOURCE (clang -O1, verbatim below):
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
;               cq_theta(&q[m - l], 0.2);
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control{{$}}

; ModuleID = 'railwindow_trip_reject_dicke_gate_on_read_cell.c'
source_filename = "railwindow_trip_reject_dicke_gate_on_read_cell.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = icmp ugt i64 %3, 1
  %5 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %6 = zext i1 %4 to i8
  store i8 %6, ptr %5, align 1, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 4
  br i1 %8, label %11, label %2, !llvm.loop !10

9:                                                ; preds = %65, %31
  %10 = icmp ugt i64 %12, 2
  br i1 %10, label %11, label %72, !llvm.loop !13

11:                                               ; preds = %2, %9
  %12 = phi i64 [ %13, %9 ], [ 4, %2 ]
  %13 = add nsw i64 %12, -1
  %14 = add nsw i64 %12, -2
  %15 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %14
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !14, !noundef !15
  %17 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %13
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !14, !noundef !15
  %19 = icmp ne i8 %18, %16
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %17, align 1, !tbaa !6
  br i1 %19, label %21, label %31

21:                                               ; preds = %11
  %22 = trunc nuw i8 %16 to i1
  %23 = trunc nuw nsw i64 %12 to i32
  %24 = uitofp nneg i32 %23 to double
  %25 = fdiv double 1.000000e+00, %24
  %26 = tail call double @llvm.sqrt.f64(double %25)
  %27 = tail call double @llvm.acos.f64(double %26)
  %28 = fmul double %27, 2.000000e+00
  %29 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef %28) #7
  %30 = zext i1 %29 to i8
  store i8 %30, ptr %15, align 1, !tbaa !6
  br label %31

31:                                               ; preds = %21, %11
  %32 = load i8, ptr %15, align 1, !tbaa !6, !range !14, !noundef !15
  %33 = load i8, ptr %17, align 1, !tbaa !6, !range !14, !noundef !15
  %34 = icmp ne i8 %33, %32
  %35 = zext i1 %34 to i8
  store i8 %35, ptr %17, align 1, !tbaa !6
  %36 = icmp ult i64 %12, 3
  br i1 %36, label %9, label %37

37:                                               ; preds = %31
  %38 = add nsw i64 %12, -3
  %39 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %38
  %40 = load i8, ptr %39, align 1, !tbaa !6, !range !14, !noundef !15
  %41 = load i8, ptr %17, align 1, !tbaa !6, !range !14, !noundef !15
  %42 = icmp ne i8 %41, %40
  %43 = zext i1 %42 to i8
  store i8 %43, ptr %17, align 1, !tbaa !6
  %44 = select i1 %42, i32 2, i32 0
  %45 = add nsw i64 %12, -2
  %46 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %45
  %47 = load i8, ptr %46, align 1, !tbaa !6, !range !14, !noundef !15
  %48 = trunc nuw i8 %47 to i1
  %49 = zext nneg i8 %47 to i32
  %50 = or disjoint i32 %44, %49
  %51 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %48, double noundef 2.000000e-01) #7
  %52 = zext i1 %51 to i8
  store i8 %52, ptr %46, align 1, !tbaa !6
  %53 = icmp eq i32 %50, 3
  br i1 %53, label %54, label %65

54:                                               ; preds = %37
  %55 = trunc nuw nsw i64 %12 to i32
  %56 = uitofp nneg i32 %55 to double
  %57 = load i8, ptr %39, align 1, !tbaa !6, !range !14, !noundef !15
  %58 = trunc nuw i8 %57 to i1
  %59 = fdiv double 2.000000e+00, %56
  %60 = tail call double @llvm.sqrt.f64(double %59)
  %61 = tail call double @llvm.acos.f64(double %60)
  %62 = fmul double %61, 2.000000e+00
  %63 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %58, double noundef %62) #7
  %64 = zext i1 %63 to i8
  store i8 %64, ptr %39, align 1, !tbaa !6
  br label %65

65:                                               ; preds = %54, %37
  %66 = load i8, ptr %39, align 1, !tbaa !6, !range !14, !noundef !15
  %67 = load i8, ptr %17, align 1, !tbaa !6, !range !14, !noundef !15
  %68 = icmp ne i8 %67, %66
  %69 = zext i1 %68 to i8
  store i8 %69, ptr %17, align 1, !tbaa !6
  br label %9

70:                                               ; preds = %72
  %71 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

72:                                               ; preds = %9, %72
  %73 = phi i64 [ %80, %72 ], [ 0, %9 ]
  %74 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %73
  %75 = load i8, ptr %74, align 1, !tbaa !6, !range !14, !noundef !15
  %76 = trunc nuw i8 %75 to i1
  %77 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %76) #6
  %78 = zext i1 %77 to i32
  %79 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %78)
  %80 = add nuw nsw i64 %73, 1
  %81 = icmp eq i64 %80, 4
  br i1 %81, label %70, label %72, !llvm.loop !16
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
!13 = distinct !{!13, !11, !12}
!14 = !{i8 0, i8 2}
!15 = !{}
!16 = distinct !{!16, !11, !12}
