; railwindow_dicke_n_pending.ll — DECLINE (bd `test_C_libtooling-01po.19` S1-S3).
;
; the reporter's general-N Dicke circuit, N=4 K=2 (`~/Desktop/alg_test/dicke/dicke_n.c`).
;
; Before S1-S3 this array declined in the one-store rail bank. Now the rolled
; window model (RailWindow.h; owner rulings `owner-ruling-01po19-rolled-not-
; unrolled-2026-10-15`, `owner-ruling-01po19-rolled-design-2026-10-15`) claims it
; (S1), places its quantization point (S2) and promotes its windows (S3), and then
; declines with exactly the steps it still needs. The WIN prefix pins the claim,
; the quantization point and every promoted cell class, and the window IR (one SSA name per cell inside a window, one write-back per window exit; reviewed against the source).
; (bd 01po.19 S5, 2026-10-15: S5 removed from the list, as its trigger says.)
; RETIREMENT TRIGGER: each of S4-S7 that lands removes its name from the CHECK
; line; when none is left this file becomes an ACCEPT with an analytic trace check.
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
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank' --implicit-check-not='tainted value stored to memory'
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; (bd 01po.19 S6, 2026-10-15: S6 is built and leaves the needs list; this
; array now reaches the control chain, which refuses it loudly as below —
; every q[m-1] update lowers in place and the s==3 condition lowers, but the
; per-trip temporaries of `s` are not uncomputed before the next in-place
; gate, so Q4 (declineLiveWindowRecords) refuses; bd 01po.19.17.)
; CHECK: cq rail window: temporary read from a quantum-array cell is live at a non-diagonal gate on that array
; (bd 01po.19 S6: the post-promotion IR-line WIN pins were dropped — S6's arm
; promotion seeds a load before each quantum branch, renaming every promoted
; value; the claim and the per-class promotion lines below still pin S1-S3.
; The S6 shape is pinned by railwindow_s6_*.ll; this file flips to an accept
; with the whole stream pinned when bd 01po.19.17/.19 land.)
; WIN: CQ_RAILWINDOW_DBG: @main claims %1 cells=i8 loads=11 stores=7 Q=  br label %11
; WIN: CQ_RAILWINDOW_DBG: promote cell {(2 + %.rails)<nuw>,+,-1}<nw><%14> in region %14 loads=4 stores=1 exits=1
; WIN: CQ_RAILWINDOW_DBG: promote cell {(3 + %.rails)<nuw>,+,-1}<nw><%14> in region %14 loads=4 stores=4 exits=1
; WIN: CQ_RAILWINDOW_DBG: promote cell {(1 + %.rails)<nuw>,+,-1}<nw><%14> in region %14 loads=3 stores=1 exits=1
; WIN: CQ_RAILWINDOW_DBG: promoted 3 cell class(es)

; ModuleID = 'dicke_n.c'
source_filename = "dicke_n.c"
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

9:                                                ; preds = %62, %31
  %10 = icmp ugt i64 %12, 2
  br i1 %10, label %11, label %69, !llvm.loop !13

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
  %48 = zext nneg i8 %47 to i32
  %49 = or disjoint i32 %44, %48
  %50 = icmp eq i32 %49, 3
  br i1 %50, label %51, label %62

51:                                               ; preds = %37
  %52 = trunc nuw nsw i64 %12 to i32
  %53 = uitofp nneg i32 %52 to double
  %54 = load i8, ptr %39, align 1, !tbaa !6, !range !14, !noundef !15
  %55 = trunc nuw i8 %54 to i1
  %56 = fdiv double 2.000000e+00, %53
  %57 = tail call double @llvm.sqrt.f64(double %56)
  %58 = tail call double @llvm.acos.f64(double %57)
  %59 = fmul double %58, 2.000000e+00
  %60 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %55, double noundef %59) #7
  %61 = zext i1 %60 to i8
  store i8 %61, ptr %39, align 1, !tbaa !6
  br label %62

62:                                               ; preds = %51, %37
  %63 = load i8, ptr %39, align 1, !tbaa !6, !range !14, !noundef !15
  %64 = load i8, ptr %17, align 1, !tbaa !6, !range !14, !noundef !15
  %65 = icmp ne i8 %64, %63
  %66 = zext i1 %65 to i8
  store i8 %66, ptr %17, align 1, !tbaa !6
  br label %9

67:                                               ; preds = %69
  %68 = tail call i32 @putchar(i32 10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 0

69:                                               ; preds = %9, %69
  %70 = phi i64 [ %77, %69 ], [ 0, %9 ]
  %71 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %70
  %72 = load i8, ptr %71, align 1, !tbaa !6, !range !14, !noundef !15
  %73 = trunc nuw i8 %72 to i1
  %74 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %73) #6
  %75 = zext i1 %74 to i32
  %76 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %75)
  %77 = add nuw nsw i64 %70, 1
  %78 = icmp eq i64 %77, 4
  br i1 %78, label %67, label %69, !llvm.loop !16
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
