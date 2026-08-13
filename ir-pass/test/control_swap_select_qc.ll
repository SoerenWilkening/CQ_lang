; control_swap_select_qc.ll — ACCEPT: tainted-condition integer-data `select`,
; one quantum + one classical operand (the §5a controlled-XOR copy merge).
; Graduated from control_swap_defer_select.ll (Rule 12 deliberate baseline: the
; WI-1 transitional `control flow` decline is replaced by the WI-3 accept).
;
; `(q>5) ? q : x` lowers to: mint the flag from the icmp -> alloc the |0> result
; rail -> copy the TRUE operand (q) on the flag -> X-bracketed copy the FALSE
; operand (x, materialized via cqrt_alloc) on ¬flag -> icmp_inv strip -> the ONE
; cqrt_free (the flag) -> RAUW %sel -> %out. NO cqrt_cswap, NO rail/route, NO
; phi, NO RegionFlatten, NO reverse-play, ZERO controlled rotations (the merge is
; a COPY, not a route). q, %out, and the materialized scratch are LEFT ALLOCATED
; (never freed — freeing an operand entangled with %out via the copy is a hidden
; measurement, Rule 6/8).
;
; This is also the §16.6 §3c-vacuity fixture: q is BOTH the condition base and the
; true operand (the operand-is-condition-register shape), yet no `arm rewrites a
; condition operand` clobber diagnostic fires — a select has no straight-through
; edge, so that proof obligation can never be met (the ACC RUN pins no diagnostic).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCT < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; the controlled-XOR copy merge stream, in §5a contract order:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[XH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; the merge is a copy, not a route — no cswap, no phi, no controlled rotation
; (NARROWED: bare `_controlled` would false-fire on the intended copy_controlled):
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_rz{{.*}}_controlled
; CHECK-NOT: cqrt_ry{{.*}}_controlled
; CHECK-NOT: phi i32

; THE ¬flag bracket scope is order-sensitive (§16.3, verify-clean-invisible): a
; mis-bracket (x before BOTH copies) yields the IDENTICAL symbol multiset, so the
; structural CHECKs above are order-blind. Pin copy -> x -> copy -> x:
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(

; exactly ONE cqrt_free (the flag; uncompute adds none — q/%out/scratch leak):
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; EXACTLY TWO cqrt_x — pins the bracket COUNT, not just its order (§8.1 / WI-5
; adversarial finding): the ORD prefix above is order-correct but blind to a STRAY
; cqrt_x (an unbalanced 3-x bracket computes the swapped/dirty-flag unitary
; out=f?b:a yet still matches ORD; previously caught ONLY by the e2e byte-diff).
; Its own RUN/prefix because the two x's PRECEDE cqrt_free in the stream — folding
; this into CNT would scan past the free and fail. COUNT-2 then NOT pins the multiset.
; XCT-COUNT-2: call void @cqrt_x(
; XCT-NOT:     call void @cqrt_x(

; the select ACCEPTS (lowers) — no decline of any kind, in particular no §3c
; clobber (§16.6 vacuity); the only icmp is the mint/strip pair, not a leaked one:
; ACC-NOT: under quantum control
; ACC-NOT: arm rewrites a condition operand
