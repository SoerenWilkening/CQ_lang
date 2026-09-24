; railbank_stale_reject_inloop_xor_read_before_and_after.ll — found by this track's
; round-2 mutation matrix (mutant N7, 'ask only the FIRST cell load', was MISSED by
; every other fixture): the bank is read in TWO loops, one BEFORE the in-place xor
; loop (legitimate) and one AFTER it (stale). Pre-fix it ACCEPTS. The fence must
; ask EVERY cell load, not the first; the first here is the legitimate one.
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
;    int q = cq_theta(seed, 0.5); int b[n]; int s = 0; int r = cq_theta(seed, .2);
;    for (int i = 0; i < n; ++i) b[i] = q;
;    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;    for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q ^= 3; }
;    for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;    return s + cq_measure(q) + cq_measure(r);
;   }
;   int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq loop lowering: rail record read past an in-place gate on the same rail

source_filename = "probes3/u1_two_read_loops.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %0, 2
  br i1 %3, label %55, label %4

4:                                                ; preds = %2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #5
  %6 = zext nneg i32 %0 to i64
  %7 = tail call ptr @llvm.stacksave.p0()
  %8 = alloca i32, i64 %6, align 16
  %9 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.000000e-01) #5
  %10 = zext nneg i32 %0 to i64
  br label %13

11:                                               ; preds = %13
  %12 = zext nneg i32 %0 to i64
  br label %20

13:                                               ; preds = %4, %13
  %14 = phi i64 [ 0, %4 ], [ %16, %13 ]
  %15 = getelementptr inbounds i32, ptr %8, i64 %14
  store i32 %5, ptr %15, align 4, !tbaa !6
  %16 = add nuw nsw i64 %14, 1
  %17 = icmp eq i64 %16, %10
  br i1 %17, label %11, label %13, !llvm.loop !10

18:                                               ; preds = %20
  %19 = tail call i32 @llvm.smax.i32(i32 %0, i32 1)
  br label %32

20:                                               ; preds = %11, %20
  %21 = phi i64 [ 0, %11 ], [ %27, %20 ]
  %22 = phi i32 [ 0, %11 ], [ %26, %20 ]
  %23 = getelementptr inbounds i32, ptr %8, i64 %21
  %24 = load i32, ptr %23, align 4, !tbaa !6
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24) #5
  %26 = add nsw i32 %25, %22
  %27 = add nuw nsw i64 %21, 1
  %28 = icmp eq i64 %27, %12
  br i1 %28, label %18, label %20, !llvm.loop !13

29:                                               ; preds = %37
  %30 = tail call i32 @llvm.smax.i32(i32 %0, i32 1)
  %31 = zext nneg i32 %30 to i64
  br label %46

32:                                               ; preds = %18, %37
  %33 = phi i32 [ %39, %37 ], [ 0, %18 ]
  %34 = phi i32 [ %38, %37 ], [ %5, %18 ]
  %35 = icmp sgt i32 %9, %33
  br i1 %35, label %36, label %37

36:                                               ; preds = %32
  tail call void @cq_phi(double noundef 3.000000e-01) #5
  br label %37

37:                                               ; preds = %36, %32
  %38 = xor i32 %34, 3
  %39 = add nuw nsw i32 %33, 1
  %40 = icmp eq i32 %39, %19
  br i1 %40, label %29, label %32, !llvm.loop !14

41:                                               ; preds = %46
  %42 = tail call i32 @cq_measure_si32(i32 noundef %38) #5
  %43 = add nsw i32 %42, %52
  %44 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %45 = add nsw i32 %43, %44
  tail call void @llvm.stackrestore.p0(ptr %7)
  br label %55

46:                                               ; preds = %29, %46
  %47 = phi i64 [ 0, %29 ], [ %53, %46 ]
  %48 = phi i32 [ %26, %29 ], [ %52, %46 ]
  %49 = getelementptr inbounds i32, ptr %8, i64 %47
  %50 = load i32, ptr %49, align 4, !tbaa !6
  %51 = tail call i32 @cq_measure_si32(i32 noundef %50) #5
  %52 = add nsw i32 %51, %48
  %53 = add nuw nsw i64 %47, 1
  %54 = icmp eq i64 %53, %31
  br i1 %54, label %41, label %46, !llvm.loop !15

55:                                               ; preds = %2, %41
  %56 = phi i32 [ %45, %41 ], [ 0, %2 ]
  ret i32 %56
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 2
  %4 = tail call i32 @slice(i32 noundef %3, i32 noundef %0)
  ret i32 %4
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!14 = distinct !{!14, !11, !12}
!15 = distinct !{!15, !11, !12}
