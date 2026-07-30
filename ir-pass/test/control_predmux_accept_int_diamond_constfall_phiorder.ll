; control_predmux_accept_int_diamond_constfall_phiorder.ll — ACCEPT (bd 0rwu, W7):
; the SWAPPED-PHI-ORDER twin of control_predmux_accept_int_diamond_constfall.ll.
;
; WHY THIS FIXTURE EXISTS. The Rule-13 round refuted the original accept
; fixture's account of flag polarity. That header claimed the minted flag is
; `icmp ne` (rather than the source's `icmp eq`) BECAUSE the merge is the branch's
; FALSE successor. Measured, that is wrong: the determinant is the **phi incoming
; order**, because `convertPhis` seeds its chained select from `In.back()`.
; Successor polarity only decides that a negated edge predicate is materialized by
; leaf inversion at all (PredMux's no-NOT invariant).
;
; This module is byte-for-byte the sibling's program — SAME branch, SAME
; successors, SAME arm, SAME constant — with ONLY the phi's two incomings written
; in the opposite order. `clang -O1` chooses that order freely (Rule 9), so both
; spellings are real inputs and each must be pinned. The emitted stream here is
; the MIRROR of the sibling's: `icmp_eq` instead of `icmp_ne`, and the ARM value
; copied under the bare flag with the CONSTANT under the `cqrt_x`-bracketed
; complement. Both are correct per basis state — they are the two logically
; complementary flags driving oppositely-ordered copies — and together the two
; fixtures pin that the choice tracks phi order and nothing else.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s \
; RUN:  --implicit-check-not='br i1' --implicit-check-not='phi i32' \
; RUN:  --implicit-check-not='cqrt_cswap' --implicit-check-not='cqrt_rz'
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %e  = and i32 %q, 32767
  %c  = icmp eq i32 %e, 32767
  br i1 %c, label %arm, label %merge

arm:
  %lo = and i32 %q, 65535
  %n  = icmp ne i32 %lo, 0
  %z  = zext i1 %n to i32
  br label %merge

merge:
  %isnan = phi i32 [ %z, %arm ], [ 0, %entry ]   ; ARM incoming FIRST (the swap)
  %m = call i32 @cq_measure_si32(i32 %isnan)
  ret i32 %m
}

; The mirror stream. Every operand is pinned — no wildcard on a copy SOURCE,
; because a wildcard there lets a mutant that sources the live qubit instead of
; the constant rail pass (the defect the Rule-13 round found in the
; straightthrough_value_arm fixture).
; CHECK:     %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 32767)
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[E]], i32 32767)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[Z]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[K]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FLAG]], i32 %[[E]], i32 32767)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
