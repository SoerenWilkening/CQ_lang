; control_swap_select_fanout_alloc.ll — ACCEPT, but the §16.5 SAFE-LEAK probe:
; a select operand that ALSO heads a separate template chain is copied into %out
; (entangling its rail with %out) AND left ALLOCATED — never reverse-played + freed.
;
; THE RULE-13 FINDING (WI-3, this fixture is its regression guard). The plan of
; record (IMPLEMENTATION-4.4 §16.5 / §6 hazard 5) prescribed adding an
; `isControlledCopyOut` exemption to `ChainWalk::forwardConsumerCount` so a
; controlled-copy reading an upstream handle would NOT count toward that handle's
; fan-out. Adversarial review (analytic + this fixture's A/B) REFUTED it: the
; controlled copy `cqrt_copy_<W>_controlled(f, q, out)` is a real fan-out consumer
; of q — q's basis label is copied into %out, so q's rail is ENTANGLED with %out
; and MUST stay live. With the exemption, `forwardConsumerCount(q)` drops to 1, the
; fan-out bail does NOT fire, and the uncompute spine REVERSE-PLAYS q's chain
; (`mul_inv` -> theta `ry_inv`) and FREES the rail — a free of a rail entangled
; with %out = a hidden measurement collapsing %out (Rule 6/8), a verify-clean
; silent miscompile. The exemption was therefore NOT added; the DEFAULT fan-out
; bail (counting the copy) correctly LEAVES q's chain allocated (a qubits-not-scarce
; leak, Rule 6 — never a dirty free). See [[select-merge-no-chainwalk-exemption]].
;
; Shape: condition on a DISTINCT theta %y; the true operand %q also feeds a dead-end
; `mul` scratch. The ONLY free is the flag; the q*3 scratch and q's rail leak.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, i32 %z) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %t   = mul nsw i32 %q, 3                 ; dead-end scratch chain THROUGH q
  %c   = icmp sgt i32 %y, 5                 ; condition on the DISTINCT theta %y
  %sel = select i1 %c, i32 %q, i32 %z
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; q is copied into %out (entangled) AND fed to the mul scratch; the merge fires:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[SCRATCH:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 3)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; the entangled q rail and the q*3 scratch are LEFT ALLOCATED — no reverse-play,
; no second free (the exemption that WOULD reverse-play+free them was rejected):
; CHECK-NOT: cq_template_mul_i32_hl_inv
; CHECK-NOT: cqrt_cswap

; exactly ONE cqrt_free (the flag only) — the entangled operand rail is never freed:
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
