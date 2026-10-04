; railbank_stale_reject_inloop_xor_runtime_bank.ll — the reviewer's P1_bank.c:
; runtime `int b[n]`, the relabel loop's condition reads `q` itself (a kickback
; on `q > k`), runtime trip count.
;
; bd `xdu2.1` (Track B), Rule-13 round-2 finding F-1 (2026-09-24) — a P1
; OVER-ACCEPT, the bd `3d8q` class through memory for the THIRD time. A rail
; PARKED in a rail bank, then relabelled by an in-place `xor` the ROLLED in-loop
; collapse (`collapseRailPhisIn`) commits via `markInPlaceRailOp`, then read back
; from the bank. Pre-fix (`cq-opt` c6f61f80a5d524c6 / main e36d9df4): exit 0,
; STRICT 2b clean, trace `ry(h0); …; cqrt_xorc_i32(h0,3) per trip; measure(h0)`
; — the bank measures observe `q ^ 3` where the source says `q`. The REGISTER
; spelling (`c = q; …; cq_measure(c)`) declines with this string on the same
; binary. MECHANISM: `LoopLowering::staleReadOfValue` enumerated the parked
; value's SSA users, found the bank STORE (before the loop, so no gate between
; def and "read") and never saw the cell LOADS; the reader fence's memory hop
; walks for `cq_theta_` gates only and runs before the collapse commits the
; in-place op. FIX: `staleReadOfValue` asks every cell load of every bank the
; value is parked in (`railBankCellReadsOf`, the forward hop read backwards).
; RED on the pre-fix binary (it ACCEPTS); GREEN after (declines with the
; register twin's string). The property is pinned by the `not` inversion and
; the verbatim string (Rule 12 (b)).
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
;   #include <stdlib.h>
;   int main(int argc, char **argv) {
;     int n = atoi(argv[1]); if (n <= 0) return 1;
;     int q = argc; cq_theta(&q, 0.5); int b[n]; int s = 0;
;     for (int i = 0; i < n; ++i) b[i] = q;                         /* park q            */
;     for (int k = 0; k < n; ++k) { if (q > k) cq_phi(0.3); q ^= 3; } /* relabels q's wire */
;     for (int i = 0; i < n; ++i) s += cq_measure(b[i]);            /* source: PRE-loop q */
;     return s + cq_measure(q);
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq loop lowering: rail record read past an in-place gate on the same rail

source_filename = "probes2/P1_bank.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = icmp slt i32 %5, 1
  br i1 %6, label %42, label %7

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %9 = zext nneg i32 %5 to i64
  %10 = tail call ptr @llvm.stacksave.p0()
  %11 = alloca i32, i64 %9, align 16
  %12 = zext nneg i32 %5 to i64
  br label %13

13:                                               ; preds = %7, %13
  %14 = phi i64 [ 0, %7 ], [ %16, %13 ]
  %15 = getelementptr inbounds i32, ptr %11, i64 %14
  store i32 %8, ptr %15, align 4, !tbaa !10
  %16 = add nuw nsw i64 %14, 1
  %17 = icmp eq i64 %16, %12
  br i1 %17, label %21, label %13, !llvm.loop !12

18:                                               ; preds = %26
  %19 = tail call i32 @llvm.smax.i32(i32 %5, i32 1)
  %20 = zext nneg i32 %19 to i64
  br label %33

21:                                               ; preds = %13, %26
  %22 = phi i32 [ %28, %26 ], [ 0, %13 ]
  %23 = phi i32 [ %27, %26 ], [ %8, %13 ]
  %24 = icmp sgt i32 %23, %22
  br i1 %24, label %25, label %26

25:                                               ; preds = %21
  tail call void @cq_phi(double noundef 3.000000e-01) #5
  br label %26

26:                                               ; preds = %25, %21
  %27 = xor i32 %23, 3
  %28 = add nuw nsw i32 %22, 1
  %29 = icmp eq i32 %28, %5
  br i1 %29, label %18, label %21, !llvm.loop !15

30:                                               ; preds = %33
  %31 = tail call i32 @cq_measure_si32(i32 noundef %27) #5
  %32 = add nsw i32 %31, %39
  tail call void @llvm.stackrestore.p0(ptr %10)
  br label %42

33:                                               ; preds = %18, %33
  %34 = phi i64 [ 0, %18 ], [ %40, %33 ]
  %35 = phi i32 [ 0, %18 ], [ %39, %33 ]
  %36 = getelementptr inbounds i32, ptr %11, i64 %34
  %37 = load i32, ptr %36, align 4, !tbaa !10
  %38 = tail call i32 @cq_measure_si32(i32 noundef %37) #5
  %39 = add nsw i32 %38, %35
  %40 = add nuw nsw i64 %34, 1
  %41 = icmp eq i64 %40, %20
  br i1 %41, label %30, label %33, !llvm.loop !16

42:                                               ; preds = %2, %30
  %43 = phi i32 [ %32, %30 ], [ 1, %2 ]
  ret i32 %43
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

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind }

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
!16 = distinct !{!16, !13, !14}
