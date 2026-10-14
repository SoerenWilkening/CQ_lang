; control_swap_accept_select_rail_after_prep_negated.ll — ACCEPT, and it is a
; DISCRIMINATOR rather than a red-green pin: GREEN ON BOTH BINARIES (bd
; `boi6` D-B / Track M, probe `m19`).
;
; THE POINT OF THIS FILE. Track M widens ONE analysis gate so that the MERGE φ of
; an already-accepted controlled-state-prep region is admitted as a rail leaf of a
; 4.4 data select (`collectCondTree`'s `AllowRailPhi`). This module is the SAME
; PROGRAM one pipeline stage later — the module as `classifySelectRegion` would
; see it if `emitInPlaceRotationRegion` had already run: the prep's `cq_theta` is
; HOISTED into the entry block and M-β has RAUW'd the merge φ to it
; (`SwapRouteEmit.cpp`, `MergePhi->replaceAllUsesWith(Gates.back().first)`), so
; the select's condition is a bare `cq_theta_i1` CALL and the PRE-EXISTING r9e5
; rail-root path (`control_swap_select_rail_const.ll`) lowers it unchanged.
;
; So this fixture pins the thing the widening must NOT do: it must add an
; ACCEPT, never a STREAM. Whatever Track M emits for the φ-conditioned spelling
; must be byte-identical to the stream below, because by EMIT time the two
; modules ARE the same module. Read it together with
; `control_swap_accept_select_mergephi_rail_negated.ll` (the plain-C/φ spelling) and
; `tests/e2e/slice_control_cascade_two_bools_uncond.c` (the plain-C twin of the
; UN-negated hand IR, `m17`).
;
; ⚠ RETIREMENT TRIGGER (L8 — they work). If the emitted stream here ever diverges
; from `control_swap_accept_select_mergephi_rail_negated.ll`'s, ONE of the two is wrong
; and the widening is no longer "an accept, not a stream". Re-derive BOTH from
; the pass output; do not edit one to match the other.
;
; THE NEGATED PREP (`m18`) — THE OWNER'S OWN SHAPE. `if (b0 == 0)
; cq_theta(&b1, .5)` is an ORIENTATION-B diamond, and the emitter spells the
; anti-control by Ry ADDITIVITY (never a `cqrt_x` on a user register): rotate the
; fresh rail UNCONDITIONALLY by θ, then cancel it under `b0` with −θ. So M-β's
; RAUW target is the CHAINED cancelling clone `%tneg`, not the first theta — two
; `cq_theta_i1` calls on ONE physical rail, which `lowerRotations` collapses onto
; one handle (`ry` then `ry` with the negated angle, both uncontrolled HERE
; because this hand IR is the module AFTER the controlled mint was replaced by
; the chain — see `tests/e2e/slice_control_cascade_two_bools.c` for the real
; `cqrt_ry_i1_controlled`). The un-negated twin is `..._after_prep.ll`.
;
; ⚠ THE SELECT'S CONDITION IS THE *LAST* GATE OF THE CHAIN, and that is M-β, not
; M-α (`SwapRouteEmit.cpp`: "M-β's RAUW target is the LAST gate in the stream").
; M-α (RAUW to the base) would make the prepped register classical here.
;
; UNITARY (analytic, Rule 2): see `control_swap_select_rail_const.ll`'s header for
; the rail-root CNOT-copy argument — `Σ α_x |x⟩_b |x⟩_bf`, one write per basis
; branch, `bf` back to `x ⊕ x = 0` on every branch ⇒ a proven-|0⟩ free. Here it
; runs TWICE over two independent registers: `%h` (the `b0` rail, whose select is
; the peeled a-mux) and `%h4` (the prepped `b1` rail). Both registers are read
; ONLY as `cqrt_cnot` CONTROLS — never `cqrt_x`-bracketed, never freed (Rule 6:
; `Ry(θ)|0⟩ ≠ |0⟩`); the four `cqrt_x` are on the two ancillas `%bf`/`%bf2`.
; The chain-final rail `%h_op` (`cq_template_add_i32_hl`) is LEFT ALLOCATED and
; NOT `_unc`'d — the Rule-6 "value arm's chain-final rail left allocated" case
; (stage 2b counts it among the left-allocated mints).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOUNC < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNOTCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %amux = select i1 %b0, i32 2, i32 5
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %tneg = call zeroext i1 @cq_theta_i1(i1 zeroext %t, double -5.000000e-01)
  %d = add nsw i32 %amux, -3
  %sel = select i1 %tneg, i32 %d, i32 %amux
  %m0 = call zeroext i1 @cq_measure_i1(i1 zeroext %b0)
  %z0 = zext i1 %m0 to i32
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %tneg)
  %z1 = zext i1 %m1 to i32
  %s1 = add nuw nsw i32 %z1, %z0
  %m2 = call i32 @cq_measure_si32(i32 %sel)
  %s2 = add nsw i32 %s1, %m2
  ret i32 %s2
}

; ---- The whole stream, instruction for instruction.
; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H0]], i32 %[[BF]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[T2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[F5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[F5]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double -5.000000e-01)
; CHECK-NEXT: %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[OUT]], i32 -3)
; CHECK-NEXT: %[[BF2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H1]], i32 %[[BF2]])
; CHECK-NEXT: %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[OP]], i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[OUT]], i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF2]])
; bd r2j3.32: the FIRST merge rail `%out` is the second merge's copy source
; and has no other reader, so once that core has read it it is reversed --
; its own core re-emitted in reverse under the SAME flag, its flag strip
; DEFERRED to after that, then `%out` freed (it used to leak; a later gate on
; the condition register dephased against it). The second merge's strip
; follows.
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[F5]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[T2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H0]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H1]], i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF2]])
; CHECK-NEXT: %{{.*}} = call i1 @cqrt_measure_i1(i32 %[[H0]])

; THE ¬flag BRACKET SCOPE is order-sensitive and verify-clean-invisible: a
; mis-bracket has the IDENTICAL symbol multiset. Pin cnot -> copy -> x -> copy ->
; x -> cnot -> free, TWICE.
; bd r2j3.32: the first merge's strip is DEFERRED past the second merge's core
; (which reads `%out`), after the first core's reverse; the bracket scope of
; every core, forward and reversed, is still cnot/x-delimited exactly as below.
; ORD: call void @cqrt_cnot(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_cnot(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_cnot(
; ORD: call void @cqrt_free(
; ORD: call void @cqrt_free(
; ORD: call void @cqrt_cnot(
; ORD: call void @cqrt_free(

; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive
; line inside one WINDOWS every negative after it — the 3qlq F-L6-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: cqrt_ry{{.*}}_controlled
; NOROUTE-NOT: cqrt_toffoli
; NOROUTE-NOT: call i1 @cq_theta_i1(
; NOROUTE-NOT: cq_phi
; NO `cqrt_x` ON A USER REGISTER, EVER. Both registers are named below because a
; pure-negative prefix cannot bind a capture; they are DERIVED from the pass
; output (`%h` = the `b0` rail, `%h4` = the prepped `b1` rail).
; NOX-NOT: call void @cqrt_x(i32 %h)
; NOX-NOT: call void @cqrt_x(i32 %h4)
; The MERGE-OUT rail too (round-2 finding F2-3): it is the register the
; source's variable ends up in and the one this fixture MEASURES, so an X
; landing on it is a basis flip of the user's answer.  An EXTRA x is caught
; by the count prefix and a SUBSTITUTED one by the ordered positive stream;
; this closes the gap where neither is looking.
; NOX-NOT: call void @cqrt_x(i32 %out3)
; NEITHER USER REGISTER IS FREED — `Ry(θ)|0⟩ ≠ |0⟩` (Rule 6). Only the two
; ancillas are, plus `%out` once reversed (bd r2j3.32); `%out3`/`%h_op` are left
; allocated.
; NOFREE-NOT: call void @cqrt_free(i32 %h)
; NOFREE-NOT: call void @cqrt_free(i32 %h4)
; `%out` (the first merge rail) IS freed since bd r2j3.32 -- after its core is
; reversed, at a proven |0>; the positive stream pins where.
; NOFREE-NOT: call void @cqrt_free(i32 %h_op)
; The MERGE-OUT rail too (round-2 finding F2-3) — freeing the user's answer
; register is a hidden measurement (Rule 6), and it was named by no free
; negative here before.
; NOFREE-NOT: call void @cqrt_free(i32 %out3)
; A rail condition mints NO compare, so it strips NOTHING; and the hoisted
; `add` chain is left allocated rather than adjointed.
; NOUNC-NOT: _unc(
; XCNT-COUNT-6: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CNOTCNT-COUNT-4: call void @cqrt_cnot(
; CNOTCNT-NOT:     call void @cqrt_cnot(
; CPCNT-COUNT-6: call void @cqrt_copy_i32_controlled(
; CPCNT-NOT:     call void @cqrt_copy
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; ACNT-COUNT-8: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
