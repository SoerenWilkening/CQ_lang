; control_predmux_accept_int_diamond_constfall.ll — ACCEPT (bd 0rwu, W7): the
; CONST-FALLTHROUGH integer sole-phi diamond — the distilled fdlibm `__isnanl`
; tail, which is the ONLY 2-cell compiler lever left in the 123-cell libm
; injection census (`expl.f80` + `log10l.f80`).
;
; SOURCE IDIOM (openlibm src/s_isnan.c:63, the `&&` at col 30):
;     return (u.bits.exp == 32767 && (u.bits.manl != 0 || u.bits.manh != 0));
; `clang -O1` spells the short-circuit as a DIAMOND whose arm computes the
; second conjunct and whose merge phi takes a CONSTANT on the entry edge:
;     %isnan = phi i32 [ 0, %entry ], [ %z, %arm ]
; What was missing was never the merge mechanics, only the `br`-CFG SPELLING of
; them: the SAME two-base integer mux written as a tainted `select` has been
; lowered by the 4.4 controlled-XOR copy merge since kjd1. The Rule-13 round
; verified that directly — the `select` spelling of this shape lowers to an
; instruction-for-instruction IDENTICAL gate stream — so W7 is exactly the missing
; adapter and reuses the cleared substrate verbatim. (An earlier draft cited
; `nexttowardf` as the pre-flattened twin of this idiom. That was FALSE:
; `ld80/s_nexttowardf.c` never calls `isnan`, it hand-writes the NaN test as one
; `or` plus one `icmp`. Do not reinstate it.)
;
; W5 (bd vyqi) deliberately claimed only the SCALAR-FP sole-phi diamond and
; left every INTEGER one to the 4.2 value emitter, which owns their accepts.
; W7 re-admits only the subset no shipped `br` owner can accept, and the
; disjointness is BY CONSTRUCTION (see the W7 comment in PredMuxFlatten.cpp):
; `ArmClassify` sets `Routed = StraightThrough`, here a `ConstantInt`, which no
; accept path can match — the value path's `Chain.Base` is always a tainted
; value, and the phase path's `Base` is this arm's interior instruction. The
; two containment directions are pinned by
; control_predmux_leave_int_diamond_constfall_prereg.ll (the a8c0 empty arm,
; where the non-constant incoming is PRE-REGION) and by the pre-existing
; control_swap_value_diamond.ll / control_swap_value_accept_nonclobber.ll
; (a non-constant straight-through keeps the 4.2 value emitter's stream).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi i32' < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %e  = and i32 %q, 32767
  %c  = icmp eq i32 %e, 32767                   ; TAINTED condition (the exp test)
  br i1 %c, label %arm, label %merge

arm:                                            ; the second conjunct
  %lo = and i32 %q, 65535
  %n  = icmp ne i32 %lo, 0
  %z  = zext i1 %n to i32
  br label %merge

merge:
  %isnan = phi i32 [ 0, %entry ], [ %z, %arm ]  ; CONST fall-through, interior arm value
  %m = call i32 @cq_measure_si32(i32 %isnan)
  ret i32 %m
}

; The arm's conjunct computes unconditionally (speculated — pure dataflow, E4)
; and the merge becomes the 4.4 controlled-XOR copy, then the compare `_unc`
; strip and one flag free. The CFG diamond is gone.
;
; NOTE THE FLAG POLARITY — it is `icmp NE`, not the source's `icmp eq` (Rule 9,
; and do not "fix" it). PredMux's no-NOT invariant materializes a negated edge
; predicate by rewriting the compare leaf into its INVERSE-PREDICATE twin
; (`buildNegation` emits a FRESH compare; it never negates in place), so the
; minted flag is the complement of the source's.
;
; WHAT DECIDES WHICH complement, and it is NOT what an earlier draft of this
; header said (corrected by the Rule-13 round, MEASURED — see
; control_predmux_accept_int_diamond_constfall_phiorder.ll, which is the same
; program with the same branch and only the phi incoming order swapped, and
; which mints `icmp_eq` and copies in the opposite order): the determinant of the
; flag predicate and the copy order is the **phi incoming order**, because
; `convertPhis` seeds its select chain from `In.back()`. Successor polarity alone
; does NOT decide it. Do not re-derive the discarded story that "the merge is the
; false successor, therefore the constant is copied first" — a true-successor
; merge with this same phi order emits this same stream.
;
; Both orders are correct per basis state (they are the two logically
; complementary flags driving oppositely-ordered copies), so this is a fixture
; brittleness note, not a soundness one. The constant gets its own `|0⟩` source
; rail (`%selop`) — the shipped behaviour for a constant select operand, pinned
; for a NONZERO constant by control_predmux_accept_int_diamond_constfall_k5.ll.
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[E:[a-zA-Z0-9_.]+]], i32 32767)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[Z]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[FLAG]], i32 %[[E]], i32 32767)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
