; control_swap_reject_value_bool_loop_hoisted_clobber.ll — bd x5fp.
;
; THE OWNER'S SCALAR-LOOP SPELLING, VERBATIM. This is the `clang -O1` stage-1
; module (no `-g`) of
;
;     int a = 5; bool b = 0;
;     for (int i = 0; i < 2; ++i) { if (a >= 3) b = cq_theta(b, 0.5); if (b) a -= 3; }
;     return cq_measure(a) + cq_measure(b);
;
; i.e. `trackL/probes/s_loop_n2.c` (session 2026-09-13, SCOPE_loop.md §1.2 wall
; S-1), which bd `x5fp` was filed from.
;
; ⚠ IT DOES NOT REACH THE `diagonalAliasHit` PRONG, AND THE BEAD'S OWN TEXT SAYS
; IT DOES — measured, `CQ_CTRL_DBG=1`, 2026-09-18. `walkValueChain` follows
; `BinaryOperator`s ONLY, and the arm's merge contribution is
; `%15 = zext i1 %14 to i8` (a CAST — the carried `_Bool` is an `i8` WIRE in
; every loop form, bd `test_C_libtooling-r903`), so `Chain.Ops` is EMPTY, the
; `if (!Chain.Ops.empty())` block is skipped entirely, and control reaches the
; HOISTED/LEAF disposition whose evidence is `Prov.count(StraightThrough)`.
; The decline anchors on that `zext`, not on `Chain.Ops.front()`.
;
; ⚠ AND BOTH BRANCHES OF THAT SITE DECLINE, so the per-activation reading there
; is a DIAGNOSTIC correction and can never be an accept: `Clobber` chooses only
; between the PERMANENT `arm rewrites a condition operand` and the deferred
; `value-arm swap-route`. The overlap here is `%9` (the `b` φ) reachable from
; `icmp sgt i32 %10, 2` only through `%10`'s LATCH incoming, so branding it
; information-theoretically impossible is exactly the "unproven evidence" the
; §3c block's own §8-review note forbids.
;
; ORACLE `cq-opt` 9bd01598…: `arm rewrites a condition operand`.
; SUBJECT 33bba13b…: the string below, SAME anchor (`x01_owner_scalar.c:10:23`).
;
; ⚠ RETIREMENT TRIGGER (L8), TWO WAYS, and they are different beads:
;   * bd `test_C_libtooling-r903` (the `_Bool` `trunc`/`zext` wire) makes the arm
;     a bare `@cq_theta_i1` call, so `inPlaceRotationArmTheta` (R1) claims it and
;     this file stops reaching the value path AT ALL. Measured on the ORACLE with
;     the `i8` wire removed by hand: the module then declines
;     `condition predates a non-diagonal gate` (gate 2c, bd `drbq.12`). So bd
;     `x5fp` is NOT on this program's critical path once `r903` lands.
;   * bd `3qlq.6` / bd `1dbk` item 1 (the in-loop VALUE arm) is what would turn
;     the OTHER §3c site into an accept. It does not reach this one.
; Re-derive rather than delete on either.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}value-arm swap-route under quantum control

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() local_unnamed_addr #0 {
  br label %7

1:                                                ; preds = %16
  %2 = tail call i32 @cq_measure_si32(i32 noundef %20) #2
  %3 = trunc nuw i8 %17 to i1
  %4 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #2
  %5 = zext i1 %4 to i32
  %6 = add nsw i32 %2, %5
  ret i32 %6

7:                                                ; preds = %0, %16
  %8 = phi i32 [ 0, %0 ], [ %21, %16 ]
  %9 = phi i8 [ 0, %0 ], [ %17, %16 ]
  %10 = phi i32 [ 5, %0 ], [ %20, %16 ]
  %11 = icmp sgt i32 %10, 2
  br i1 %11, label %12, label %16

12:                                               ; preds = %7
  %13 = trunc nuw i8 %9 to i1
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef 5.000000e-01) #2
  %15 = zext i1 %14 to i8
  br label %16

16:                                               ; preds = %12, %7
  %17 = phi i8 [ %15, %12 ], [ %9, %7 ]
  %18 = trunc nuw i8 %17 to i1
  %19 = add nsw i32 %10, -3
  %20 = select i1 %18, i32 %19, i32 %10
  %21 = add nuw nsw i32 %8, 1
  %22 = icmp eq i32 %8, 0
  br i1 %22, label %7, label %1, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
