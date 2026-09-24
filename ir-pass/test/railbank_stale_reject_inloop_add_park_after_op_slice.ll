; railbank_stale_reject_inloop_add_park_after_op_slice.ll — reviewer e2_slice: `q += 1;
; b[k] = q;` outside `main`; the source says cells hold q+1, q+2, q+3.
;
; bd `xdu2.1` (Track B), Rule-13 round-3 finding F-R3-1 (2026-09-24) — a P1
; OVER-ACCEPT, PRE-EXISTING on main (preA/preD) and NOT closed by the round-2 fix.
; The value parked in the bank is the IN-PLACE op's own result, INSIDE the loop
; that relabels it: cell k holds the wire after k+1 ops, the next trip's op
; relabels the SAME wire, and the cells are read after the loop. Round-2 binary
; (`cq-opt` 427492b12c4162e2): exit 0, STRICT 2b clean, every bank measure reads
; the FINAL wire. MECHANISM: the round-2 bank-load hop in `staleReadOfValue`
; reused the SSA `Refreshes` cut — "re-running Def makes the NAME denote the new
; value" — which is FALSE for a memory cell (cell k keeps activation k's value),
; so every `Def → back edge → gate` path was cut and `Def → exit → load` was
; gate-free. FIX: the bank hop passes `DefRefreshes=false`. RED on 427492b1
; (accepts), GREEN after (declines with the register fence's string). The
; hand-unrolled register twin ACCEPTS with a correct out-of-place stream, so
; this decline is an OVER-DECLINE of a realizable circuit (filed in
; `TRACK_B.md` §6c) — the Prime-Directive answer until a bank-aware copy-out
; lowering exists. Pinned by the `not` inversion + the verbatim string.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
;   #include <stdlib.h>
;   __attribute__((noinline)) int slice(int seed, int n) {
;     if (n <= 0) return 0; int q = cq_theta(seed, 0.5); int b[n]; int s = 0;
;     for (int k = 0; k < n; ++k) { if (q > k) cq_phi(0.3); q += 1; b[k] = q; }
;     for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;     return s;
;   }
;   int main(int argc, char **argv) { int n = atoi(argv[1]); if (n <= 0) return 1; return slice(argc, n); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq loop lowering: rail record read past an in-place gate on the same rail

source_filename = "probes4/e2_slice.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %1, 1
  br i1 %3, label %33, label %4

4:                                                ; preds = %2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %6 = zext nneg i32 %1 to i64
  %7 = tail call ptr @llvm.stacksave.p0()
  %8 = alloca i32, i64 %6, align 16
  %9 = zext nneg i32 %1 to i64
  br label %12

10:                                               ; preds = %18
  %11 = zext nneg i32 %1 to i64
  br label %24

12:                                               ; preds = %4, %18
  %13 = phi i64 [ 0, %4 ], [ %21, %18 ]
  %14 = phi i32 [ %5, %4 ], [ %19, %18 ]
  %15 = sext i32 %14 to i64
  %16 = icmp slt i64 %13, %15
  br i1 %16, label %17, label %18

17:                                               ; preds = %12
  tail call void @cq_phi(double noundef 3.000000e-01) #5
  br label %18

18:                                               ; preds = %17, %12
  %19 = add nsw i32 %14, 1
  %20 = getelementptr inbounds i32, ptr %8, i64 %13
  store i32 %19, ptr %20, align 4, !tbaa !6
  %21 = add nuw nsw i64 %13, 1
  %22 = icmp eq i64 %21, %9
  br i1 %22, label %10, label %12, !llvm.loop !10

23:                                               ; preds = %24
  tail call void @llvm.stackrestore.p0(ptr %7)
  br label %33

24:                                               ; preds = %10, %24
  %25 = phi i64 [ 0, %10 ], [ %31, %24 ]
  %26 = phi i32 [ 0, %10 ], [ %30, %24 ]
  %27 = getelementptr inbounds i32, ptr %8, i64 %25
  %28 = load i32, ptr %27, align 4, !tbaa !6
  %29 = tail call i32 @cq_measure_si32(i32 noundef %28) #5
  %30 = add nsw i32 %29, %26
  %31 = add nuw nsw i64 %25, 1
  %32 = icmp eq i64 %31, %11
  br i1 %32, label %23, label %24, !llvm.loop !13

33:                                               ; preds = %2, %23
  %34 = phi i32 [ %30, %23 ], [ 0, %2 ]
  ret i32 %34
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #3 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !14
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = icmp slt i32 %5, 1
  br i1 %6, label %9, label %7

7:                                                ; preds = %2
  %8 = tail call i32 @slice(i32 noundef %0, i32 noundef %5)
  br label %9

9:                                                ; preds = %2, %7
  %10 = phi i32 [ %8, %7 ], [ 1, %2 ]
  ret i32 %10
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #4

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = !{!15, !15, i64 0}
!15 = !{!"any pointer", !8, i64 0}
