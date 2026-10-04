; railbank_stale_reject_inloop_xor_park_after_op.ll — reviewer a1: `q ^= 3; b[k] = q;`
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
;   int main(int argc, char **argv) {
;     int n = atoi(argv[1]); if (n <= 0) return 1;
;     int q = argc; cq_theta(&q, 0.5); int b[n]; int s = 0;
;     for (int k = 0; k < n; ++k) { if (q > k) cq_phi(0.3); q ^= 3; b[k] = q; }
;     for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;     return s + cq_measure(q);
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq loop lowering: rail record read past an in-place gate on the same rail

source_filename = "probes4/a1_park_after_xor.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = icmp slt i32 %5, 1
  br i1 %6, label %38, label %7

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #4
  %9 = zext nneg i32 %5 to i64
  %10 = tail call ptr @llvm.stacksave.p0()
  %11 = alloca i32, i64 %9, align 16
  %12 = zext nneg i32 %5 to i64
  br label %15

13:                                               ; preds = %21
  %14 = zext nneg i32 %5 to i64
  br label %29

15:                                               ; preds = %7, %21
  %16 = phi i64 [ 0, %7 ], [ %24, %21 ]
  %17 = phi i32 [ %8, %7 ], [ %22, %21 ]
  %18 = sext i32 %17 to i64
  %19 = icmp slt i64 %16, %18
  br i1 %19, label %20, label %21

20:                                               ; preds = %15
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  br label %21

21:                                               ; preds = %20, %15
  %22 = xor i32 %17, 3
  %23 = getelementptr inbounds i32, ptr %11, i64 %16
  store i32 %22, ptr %23, align 4, !tbaa !10
  %24 = add nuw nsw i64 %16, 1
  %25 = icmp eq i64 %24, %12
  br i1 %25, label %13, label %15, !llvm.loop !12

26:                                               ; preds = %29
  %27 = tail call i32 @cq_measure_si32(i32 noundef %22) #4
  %28 = add nsw i32 %27, %35
  tail call void @llvm.stackrestore.p0(ptr %10)
  br label %38

29:                                               ; preds = %13, %29
  %30 = phi i64 [ 0, %13 ], [ %36, %29 ]
  %31 = phi i32 [ 0, %13 ], [ %35, %29 ]
  %32 = getelementptr inbounds i32, ptr %11, i64 %30
  %33 = load i32, ptr %32, align 4, !tbaa !10
  %34 = tail call i32 @cq_measure_si32(i32 noundef %33) #4
  %35 = add nsw i32 %34, %31
  %36 = add nuw nsw i64 %30, 1
  %37 = icmp eq i64 %36, %14
  br i1 %37, label %26, label %29, !llvm.loop !15

38:                                               ; preds = %2, %26
  %39 = phi i32 [ %28, %26 ], [ 1, %2 ]
  ret i32 %39
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #3

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
