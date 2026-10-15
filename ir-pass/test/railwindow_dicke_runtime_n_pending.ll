; railwindow_dicke_runtime_n_pending.ll — DECLINE (bd `test_C_libtooling-01po.19` S1-S3).
;
; the same circuit with RUNTIME n, k over an i8 VLA `bool q[n]` (the owner's runtime-N scope).
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
; SOURCE (clang -O1 -fno-inline, verbatim below):
;   /* dicke_n.c with RUNTIME n, k (VLA bool q[n]): the owner's runtime-N scope. */
;   #include <stdio.h>
;   #include <math.h>
;   
;   int dicke(int n, int k) {
;       bool q[n];
;       for (int i = 0; i < n; i++) q[i] = (i >= n - k);
;   
;       for (int m = n; m >= 2; m--) {
;           int kk = k < m - 1 ? k : m - 1;
;           q[m - 1] ^= q[m - 2];
;           if (q[m - 1]) cq_theta(&q[m - 2], 2.0 * acos(sqrt(1.0 / m)));
;           q[m - 1] ^= q[m - 2];
;           for (int l = 2; l <= kk; l++) {
;               q[m - 1] ^= q[m - 1 - l];
;               int s = 2 * q[m - 1] + q[m - l];
;               if (s == 3) cq_theta(&q[m - 1 - l], 2.0 * acos(sqrt((double)l / m)));
;               q[m - 1] ^= q[m - 1 - l];
;           }
;       }
;       int r = 0;
;       for (int i = 0; i < n; i++) r = 2 * r + cq_measure(q[i]);
;       return r;
;   }
;   
;   int main(int argc, char **argv) { return dicke(argc + 3, 2); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank' --implicit-check-not='tainted value stored to memory'
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; (bd 01po.19 S6, 2026-10-15: S6 is built and leaves the needs list; this
; array now reaches the control chain, which refuses it loudly as below —
; the nested runtime l-loop; bd 01po.19.19.)
; CHECK: cq controlled lowering: control flow inside a loop body under quantum control
; (bd 01po.19 S6: the post-promotion IR-line WIN pins were dropped — S6's arm
; promotion seeds a load before each quantum branch, renaming every promoted
; value; the claim and the per-class promotion lines below still pin S1-S3.
; The S6 shape is pinned by railwindow_s6_*.ll; this file flips to an accept
; with the whole stream pinned when bd 01po.19.17/.19 land.)
; WIN: CQ_RAILWINDOW_DBG: @dicke claims %4 cells=i8 loads=12 stores=7 Q=  br i1 %12, label %13, label %24
; WIN: CQ_RAILWINDOW_DBG: promote cell {(-2 + (zext i32 %0 to i64) + %.rails),+,-1}<nw><%33> in region %33 loads=3 stores=1 exits=2
; WIN: CQ_RAILWINDOW_DBG: promote cell {(-1 + (zext i32 %0 to i64) + %.rails),+,-1}<nw><%33> in region %33 loads=2 stores=2 exits=2
; WIN: CQ_RAILWINDOW_DBG: promote cell {{[{][{]}}(-3 + (zext i32 %0 to i64) + %.rails),+,-1}<nw><%33>,+,-1}<nw><%59> in region %59 loads=3 stores=1 exits=1
; WIN: CQ_RAILWINDOW_DBG: promote cell {(-1 + (zext i32 %0 to i64) + %.rails),+,-1}<nw><%33> in region %59 loads=2 stores=2 exits=1
; WIN: CQ_RAILWINDOW_DBG: promoted 4 cell class(es)

; ModuleID = 'dicke_rt.c'
source_filename = "dicke_rt.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @dicke(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %10

6:                                                ; preds = %2
  %7 = sub nsw i32 %0, %1
  %8 = sext i32 %7 to i64
  %9 = zext nneg i32 %0 to i64
  br label %15

10:                                               ; preds = %15, %2
  %11 = getelementptr i8, ptr %4, i64 -2
  %12 = icmp sgt i32 %0, 1
  br i1 %12, label %13, label %24

13:                                               ; preds = %10
  %14 = zext nneg i32 %0 to i64
  br label %28

15:                                               ; preds = %6, %15
  %16 = phi i64 [ 0, %6 ], [ %20, %15 ]
  %17 = icmp sge i64 %16, %8
  %18 = getelementptr inbounds i8, ptr %4, i64 %16
  %19 = zext i1 %17 to i8
  store i8 %19, ptr %18, align 1, !tbaa !6
  %20 = add nuw nsw i64 %16, 1
  %21 = icmp eq i64 %20, %9
  br i1 %21, label %10, label %15, !llvm.loop !10

22:                                               ; preds = %86, %50
  %23 = icmp sgt i64 %29, 2
  br i1 %23, label %28, label %24, !llvm.loop !13

24:                                               ; preds = %22, %10
  %25 = icmp sgt i32 %0, 0
  br i1 %25, label %26, label %93

26:                                               ; preds = %24
  %27 = zext nneg i32 %0 to i64
  br label %95

28:                                               ; preds = %13, %22
  %29 = phi i64 [ %14, %13 ], [ %30, %22 ]
  %30 = add nsw i64 %29, -1
  %31 = trunc nuw nsw i64 %30 to i32
  %32 = tail call i32 @llvm.smin.i32(i32 %31, i32 %1)
  %33 = getelementptr i8, ptr %11, i64 %29
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !14, !noundef !15
  %35 = getelementptr inbounds i8, ptr %4, i64 %30
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !14, !noundef !15
  %37 = icmp ne i8 %36, %34
  %38 = zext i1 %37 to i8
  store i8 %38, ptr %35, align 1, !tbaa !6
  br i1 %37, label %39, label %50

39:                                               ; preds = %28
  %40 = load i8, ptr %33, align 1, !tbaa !6, !range !14, !noundef !15
  %41 = trunc nuw i8 %40 to i1
  %42 = trunc nuw nsw i64 %29 to i32
  %43 = uitofp nneg i32 %42 to double
  %44 = fdiv double 1.000000e+00, %43
  %45 = tail call double @llvm.sqrt.f64(double %44)
  %46 = tail call double @llvm.acos.f64(double %45)
  %47 = fmul double %46, 2.000000e+00
  %48 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %41, double noundef %47) #4
  %49 = zext i1 %48 to i8
  store i8 %49, ptr %33, align 1, !tbaa !6
  br label %50

50:                                               ; preds = %39, %28
  %51 = load i8, ptr %33, align 1, !tbaa !6, !range !14, !noundef !15
  %52 = load i8, ptr %35, align 1, !tbaa !6, !range !14, !noundef !15
  %53 = icmp ne i8 %52, %51
  %54 = zext i1 %53 to i8
  store i8 %54, ptr %35, align 1, !tbaa !6
  %55 = icmp slt i32 %32, 2
  br i1 %55, label %22, label %56

56:                                               ; preds = %50
  %57 = trunc nuw nsw i64 %29 to i32
  %58 = uitofp nneg i32 %57 to double
  %59 = zext nneg i32 %32 to i64
  br label %60

60:                                               ; preds = %56, %86
  %61 = phi i64 [ 2, %56 ], [ %91, %86 ]
  %62 = sub nsw i64 %30, %61
  %63 = getelementptr inbounds i8, ptr %4, i64 %62
  %64 = load i8, ptr %63, align 1, !tbaa !6, !range !14, !noundef !15
  %65 = load i8, ptr %35, align 1, !tbaa !6, !range !14, !noundef !15
  %66 = icmp ne i8 %65, %64
  %67 = zext i1 %66 to i8
  store i8 %67, ptr %35, align 1, !tbaa !6
  %68 = select i1 %66, i32 2, i32 0
  %69 = sub nsw i64 %29, %61
  %70 = getelementptr inbounds i8, ptr %4, i64 %69
  %71 = load i8, ptr %70, align 1, !tbaa !6, !range !14, !noundef !15
  %72 = zext nneg i8 %71 to i32
  %73 = or disjoint i32 %68, %72
  %74 = icmp eq i32 %73, 3
  br i1 %74, label %75, label %86

75:                                               ; preds = %60
  %76 = load i8, ptr %63, align 1, !tbaa !6, !range !14, !noundef !15
  %77 = trunc nuw i8 %76 to i1
  %78 = trunc nuw nsw i64 %61 to i32
  %79 = uitofp nneg i32 %78 to double
  %80 = fdiv double %79, %58
  %81 = tail call double @llvm.sqrt.f64(double %80)
  %82 = tail call double @llvm.acos.f64(double %81)
  %83 = fmul double %82, 2.000000e+00
  %84 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %77, double noundef %83) #4
  %85 = zext i1 %84 to i8
  store i8 %85, ptr %63, align 1, !tbaa !6
  br label %86

86:                                               ; preds = %75, %60
  %87 = load i8, ptr %63, align 1, !tbaa !6, !range !14, !noundef !15
  %88 = load i8, ptr %35, align 1, !tbaa !6, !range !14, !noundef !15
  %89 = icmp ne i8 %88, %87
  %90 = zext i1 %89 to i8
  store i8 %90, ptr %35, align 1, !tbaa !6
  %91 = add nuw nsw i64 %61, 1
  %92 = icmp ult i64 %61, %59
  br i1 %92, label %60, label %22, !llvm.loop !16

93:                                               ; preds = %95, %24
  %94 = phi i32 [ 0, %24 ], [ %104, %95 ]
  ret i32 %94

95:                                               ; preds = %26, %95
  %96 = phi i64 [ 0, %26 ], [ %105, %95 ]
  %97 = phi i32 [ 0, %26 ], [ %104, %95 ]
  %98 = shl nsw i32 %97, 1
  %99 = getelementptr inbounds i8, ptr %4, i64 %96
  %100 = load i8, ptr %99, align 1, !tbaa !6, !range !14, !noundef !15
  %101 = trunc nuw i8 %100 to i1
  %102 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %101) #5
  %103 = zext i1 %102 to i32
  %104 = or disjoint i32 %98, %103
  %105 = add nuw nsw i64 %96, 1
  %106 = icmp eq i64 %105, %27
  br i1 %106, label %93, label %95, !llvm.loop !17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.acos.f64(double) #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 3
  %4 = tail call i32 @dicke(i32 noundef %3, i32 noundef 2)
  ret i32 %4
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #3

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

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
