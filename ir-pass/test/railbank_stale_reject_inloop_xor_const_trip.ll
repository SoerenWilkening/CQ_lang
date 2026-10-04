; railbank_stale_reject_inloop_xor_const_trip.ll — the reviewer's r_qx33_bank.c:
; runtime bank, CONSTANT trip count (3) on the relabel loop, outside `main`.
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
;   __attribute__((noinline)) int slice(int n, int seed) { if (n <= 1) return 0;
;    int q = seed; cq_theta(&q, 0.5); int b[n]; int s = 0;
;    for (int i = 0; i < n; ++i) b[i] = q;
;    for (int k = 0; k < 3; ++k) { if (q > k) cq_phi(0.3); q ^= 3; }
;    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;    return s + cq_measure(q);
;   }
;   int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq loop lowering: rail record read past an in-place gate on the same rail

source_filename = "probes2/r_qx33_bank.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %0, 2
  br i1 %3, label %38, label %4

4:                                                ; preds = %2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #4
  %6 = zext nneg i32 %0 to i64
  %7 = tail call ptr @llvm.stacksave.p0()
  %8 = alloca i32, i64 %6, align 16
  %9 = zext nneg i32 %0 to i64
  br label %10

10:                                               ; preds = %4, %10
  %11 = phi i64 [ 0, %4 ], [ %13, %10 ]
  %12 = getelementptr inbounds i32, ptr %8, i64 %11
  store i32 %5, ptr %12, align 4, !tbaa !6
  %13 = add nuw nsw i64 %11, 1
  %14 = icmp eq i64 %13, %9
  br i1 %14, label %17, label %10, !llvm.loop !10

15:                                               ; preds = %22
  %16 = zext nneg i32 %0 to i64
  br label %29

17:                                               ; preds = %10, %22
  %18 = phi i32 [ %24, %22 ], [ 0, %10 ]
  %19 = phi i32 [ %23, %22 ], [ %5, %10 ]
  %20 = icmp sgt i32 %19, %18
  br i1 %20, label %21, label %22

21:                                               ; preds = %17
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  br label %22

22:                                               ; preds = %21, %17
  %23 = xor i32 %19, 3
  %24 = add nuw nsw i32 %18, 1
  %25 = icmp eq i32 %24, 3
  br i1 %25, label %15, label %17, !llvm.loop !13

26:                                               ; preds = %29
  %27 = tail call i32 @cq_measure_si32(i32 noundef %23) #4
  %28 = add nsw i32 %27, %35
  tail call void @llvm.stackrestore.p0(ptr %7)
  br label %38

29:                                               ; preds = %15, %29
  %30 = phi i64 [ 0, %15 ], [ %36, %29 ]
  %31 = phi i32 [ 0, %15 ], [ %35, %29 ]
  %32 = getelementptr inbounds i32, ptr %8, i64 %30
  %33 = load i32, ptr %32, align 4, !tbaa !6
  %34 = tail call i32 @cq_measure_si32(i32 noundef %33) #4
  %35 = add nsw i32 %34, %31
  %36 = add nuw nsw i64 %30, 1
  %37 = icmp eq i64 %36, %16
  br i1 %37, label %26, label %29, !llvm.loop !14

38:                                               ; preds = %2, %26
  %39 = phi i32 [ %28, %26 ], [ 0, %2 ]
  ret i32 %39
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 2
  %4 = tail call i32 @slice(i32 noundef %3, i32 noundef %0)
  ret i32 %4
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
