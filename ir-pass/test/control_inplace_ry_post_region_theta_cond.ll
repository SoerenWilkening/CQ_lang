; control_inplace_ry_post_region_theta_cond.ll — ACCEPT (FLAT, no loop): a
; control-in-place Ry arm whose CONDITION wire gains a non-diagonal gate that is
; PROVABLY AFTER the region's entire emitted stream (PRD §13.4b, bd
; test_C_libtooling-drbq Increment 3 part 3b).
;
;     if (q == 5) r = cq_theta(r, .9);
;     q = cq_theta(q, .3);              <-- the Ry reflection on the CONDITION
;
; THIS DECLINED BEFORE INCREMENT 3, AND IT IS NOT A LOOP SHAPE. `ArmClassify`'s
; final P1 fence read `if (DeferredWireGate && (SawValueArm || !SawPhaseArm))`,
; which is PHASE-ARM-ONLY: a control-in-place rotation arm sets `SawRotationArm`
; and never `SawPhaseArm`, so `!SawPhaseArm` was true and the region declined
; `condition predates a non-diagonal gate`. Swap the reflection to `cq_phi` and the
; identical program ACCEPTED — the fence was keyed on the arm's SPELLING, not on
; its physics. That is half of the recorded over-decline bd drbq.7.
;
; THE ARGUMENT IS P1's OWN, WITH THE ARM CLASS SUBSTITUTED. P1 refuses a VALUE arm
; because method-B copies a basis LABEL out and replays the chain on the routed
; rail, so a later in-place Ry on that wire is a genuine staleness hazard. An
; in-place rotation arm copies nothing, replays nothing and allocates no work rail:
; its entire emitted stream is
;     mint(f from C) ; [x(f)] cRy(f, R, t) [x(f)] ; strip(f from C) ; free(f)
; all inserted before the branch. `ProvenPostRegion` means the wire gate `G`
; satisfies `provablyBefore(BI, G)`, and `condWireDisposition`'s own lemma carries
; that to every call in the stream (dominance over `BI` implies dominance over each
; stream call, which precedes `BI` in `BI`'s block; unreachability likewise). So at
; the moment `G` fires the flag is already stripped and freed and `R`'s relabelling
; is complete — and R4 has proved `R`'s wire disjoint from every condition wire, so
; `G` is not on the register this arm touched.
;
; ⚠ ONE SENTENCE OF THE ARGUMENT ABOVE WAS AN OVERCLAIM AND IS STRUCK (bd drbq
; Inc 3, round-1 lens L8, F-L8-1). The shipped version of this header, of PRD
; §13.4b and of the notes all said the DERIVED-condition residual "has been owned
; since bd `lyyf` by M-A's `warnLiveRecordRotations` as a `DS_Warning`". It has
; not: M-A does not fire for an ESCAPING condition record (`int d = q & 6;`
; measured after the region — the `and` rail is never uncomputed, is live and
; entangled when the post-region Ry fires, and stderr is EMPTY). That gap is
; arm-class-independent and PRE-EXISTING — the `cq_phi`-arm twin behaves
; identically and equally silently on the pre-Inc-3 ORACLE — so it is not this
; clause's to fix. It is simply not what makes the clause safe. The ORDER argument
; above is, and it is measured: see the two accept fixtures added by the same
; round, `control_inplace_ry_post_region_theta_derived_cond.ll` (the whole
; condition chain `_unc`'d and freed BEFORE the deferred gate) and
; `control_inplace_ry_post_region_theta_negated.ll`.
;
; ⚠ AND "half of the recorded over-decline bd drbq.7" IS LITERAL: the OTHER half
; — a rotated register that gates a SECOND region — still declines on both
; binaries and this increment does not move it.
;
; IT IS ALSO THE FENCE THE FLAGSHIP CUSTOMER NEEDS: canonical Grover in a loop is
; an Rz oracle, a controlled Ry on an ancilla, and an **Ry** reflection on `q` —
; two fences away from compiling, of which only one is a loop fence. Shipping the
; loop half alone would have delivered the Rz-reflection and dtzb-offset loops and
; still declined the program the increment was scoped for (Rule 17).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the post-region reflection lands UNCONTROLLED on the condition handle, after the
; whole stream has discharged:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 3.0
;
; WHOLE-FILE, via the `NOROUTE` prefix rather than a trailing `CHECK-NOT` (bd
; drbq Inc 3, round-1 lens L6, F-L6-1): a `CHECK-NOT` here would have scanned
; only from the last positive match to EOF, so a route or an unlowered rotation
; ANYWHERE ABOVE the deferred gate would have gone unchecked.
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c  = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r0, %entry ]
  %qn = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  %ma = call i32 @cq_measure_si32(i32 %qn)
  %mb = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %ma, %mb
  ret i32 %s
}
