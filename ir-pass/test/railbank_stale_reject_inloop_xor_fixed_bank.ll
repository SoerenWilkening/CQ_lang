; railbank_stale_reject_inloop_xor_fixed_bank.ll — the reviewer's P1_bank_fixed.c:
; FIXED `int b[3]`, the relabel loop's condition reads a DIFFERENT register `r`
; (so the relabelled rail is not the condition's), runtime trip count.
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
;   int main(int argc, char **argv) {
;     int q = cq_theta(argc, 0.5); int b[3]; int s = 0; int r = cq_theta(argc+1, .2);
;     for (int i = 0; i < 3; ++i) b[i] = q;
;     for (int k = 0; k < argc; ++k) { if (r > k) cq_phi(0.3); q ^= 3; }
;     for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
;     return s + cq_measure(q) + cq_measure(r);
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq loop lowering: rail record read past an in-place gate on the same rail

source_filename = "probes2/P1_bank_fixed.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [3 x i32], align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %3) #3
  %5 = add nsw i32 %0, 1
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 2.000000e-01) #3
  br label %9

7:                                                ; preds = %9
  %8 = icmp sgt i32 %0, 0
  br i1 %8, label %16, label %14

9:                                                ; preds = %2, %9
  %10 = phi i64 [ 0, %2 ], [ %12, %9 ]
  %11 = getelementptr inbounds [3 x i32], ptr %3, i64 0, i64 %10
  store i32 %4, ptr %11, align 4, !tbaa !6
  %12 = add nuw nsw i64 %10, 1
  %13 = icmp eq i64 %12, 3
  br i1 %13, label %7, label %9, !llvm.loop !10

14:                                               ; preds = %21, %7
  %15 = phi i32 [ %4, %7 ], [ %22, %21 ]
  br label %30

16:                                               ; preds = %7, %21
  %17 = phi i32 [ %23, %21 ], [ 0, %7 ]
  %18 = phi i32 [ %22, %21 ], [ %4, %7 ]
  %19 = icmp sgt i32 %6, %17
  br i1 %19, label %20, label %21

20:                                               ; preds = %16
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %21

21:                                               ; preds = %20, %16
  %22 = xor i32 %18, 3
  %23 = add nuw nsw i32 %17, 1
  %24 = icmp eq i32 %23, %0
  br i1 %24, label %14, label %16, !llvm.loop !13

25:                                               ; preds = %30
  %26 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %27 = add nsw i32 %26, %36
  %28 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %29 = add nsw i32 %27, %28
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %3) #3
  ret i32 %29

30:                                               ; preds = %14, %30
  %31 = phi i64 [ 0, %14 ], [ %37, %30 ]
  %32 = phi i32 [ 0, %14 ], [ %36, %30 ]
  %33 = getelementptr inbounds [3 x i32], ptr %3, i64 0, i64 %31
  %34 = load i32, ptr %33, align 4, !tbaa !6
  %35 = tail call i32 @cq_measure_si32(i32 noundef %34) #3
  %36 = add nsw i32 %35, %32
  %37 = add nuw nsw i64 %31, 1
  %38 = icmp eq i64 %37, 3
  br i1 %38, label %25, label %30, !llvm.loop !14
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!14 = distinct !{!14, !11, !12}
