; lowering_reject_inplace_rail_stale_w2_xor_derived.ll — DECLINE. bd
; test_C_libtooling-eqpx (P1), THE FLAGSHIP. A CONFIRMED, PRE-EXISTING,
; verify-clean silent miscompile: a quantum rail handle emitted into the
; in-place ABI's CLASSICAL-IMMEDIATE slot.
;
;     int ext_f(int a);                        /* a second TU: `return a+100;` */
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int y=5; if (q>5) y=ext_f(7);          /* 6.5 CLASSICAL-CALL ARM -> %out */
;       int w = y & 7;                         /* DERIVED from %out */
;       for(int i=0;i<3;i++){ r = r ^ w; }     /* W2's in-place rail op */
;       return cq_measure(r)+cq_measure(y)+cq_measure(q); }
;
; `clang -O1`, the two TUs `llvm-link`ed, `@main` dropped. `!llvm.loop` VERBATIM.
;
; THE DEFECT, MEASURED on the frozen `main`@16b15b3 binary (and byte-identical on
; the pre-3qlq oracle 52d7764 — this PRE-DATES the 3qlq epic):
;
;     %out   = call i32 @cqrt_alloc_i32(i32 0)                  ; the 6.5 merge rail
;     %h_op  = call i32 @cq_template_and_i32_hl(i32 %out, i32 7) ; a QUANTUM rail
;     call void @cqrt_xorc_i32(i32 %h2, i32 %h_op)              ; <- IMMEDIATE SLOT
;
; printed by the trace runtime as the bare decimal `cqrt_xorc_i32(h1, 6)`, where
; `6` is `h6`'s HANDLE ID. `opt` exit 0, `opt -verify` clean, STRICT stage 2b
; `0 violation(s)`, 21 plausible trace lines. Arithmetically the source computes
; `r ^ w` with `w = y&7 ∈ {5,3}` CORRELATED WITH `y`; the circuit computes `r^6`,
; a value the source produces on neither branch, on a register never entangled
; with `y`. The hand-unrolled twin of the same source emits the CORRECT
; out-of-place `cq_template_xor_i32(h1, h6)` + `_unc` + `free` — rolled != unrolled,
; and unrolled is right.
;
; WHY. `tryCaseA`'s ACCEPT (W2, `LoopLowering.cpp:2281`) marks the `xor` in
; `taint.InPlaceRailOps` at `lowerLoops`, having proved G2
; (`inPlaceValueRailOperand` — EXACTLY ONE tainted operand) under ROUND-1 taint,
; where `w` is still CLASSICAL. `repropagateControlMerges`
; (`CQLoweringPass.cpp:409`) then taints everything derived from the 6.5 `%out`,
; and `lowerOps` honours the marking UNCONDITIONALLY: `rewriteInPlaceValueRail`
; re-picks the rail with `TL = taint.Tainted.count(L)` and hands the OTHER
; operand — now a rail — to the classical-immediate slot. The writer proved the
; RAIL; it never proved THE IMMEDIATE STAYS CLASSICAL.
;
; THE FIX is the consumer tripwire: `lowerOps` Phase 1 re-asks **G2 ALONE**
; (`inPlaceValueRailOperand(BO, taint) != nullptr`) under FINAL taint for every
; `InPlaceRailOps` member W4 did not commit, and declines loudly. G2 alone, not
; the whole M-C fence, because `inPlaceFenceHolds`' G5 refuses any in-loop site
; outright and every W1/W2/W3 member is in a loop by construction.
;
; ⚠ NOT A SILENT FALLBACK TO OUT-OF-PLACE (Rule 1 — no third path). The marking
; is what LICENSED the rest of the transform, and those permissions already stand
; in the module: `taint.IterationLocalBlocks`, the irreversibly-COLLAPSED rail
; phi, `taint.ClaimedRailRoots`. Lowering this one op into a fresh per-iteration
; rail leaves every one of them on a premise that no longer holds — the X1
; cross-iteration dirty rail the marking exists to prevent.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: in-place rail op no longer provable at lowering

; NOTHING is lowered for the op: no in-place gate, and no out-of-place fallback
; either (the module never reaches the emitter).
; CHECK-NOT: cqrt_xorc_i32
; CHECK-NOT: cq_template_xor_i32

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  %4 = icmp sgt i32 %2, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ 5, %1 ]
  %9 = and i32 %8, 7
  br label %16

10:                                               ; preds = %16
  %11 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %15 = add nsw i32 %13, %14
  ret i32 %15

16:                                               ; preds = %16, %7
  %17 = phi i32 [ 0, %7 ], [ %20, %16 ]
  %18 = phi i32 [ %3, %7 ], [ %19, %16 ]
  %19 = xor i32 %18, %9
  %20 = add nuw nsw i32 %17, 1
  %21 = icmp eq i32 %20, 3
  br i1 %21, label %10, label %16, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
