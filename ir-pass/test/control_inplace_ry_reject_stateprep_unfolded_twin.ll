; control_inplace_ry_reject_stateprep_unfolded_twin.ll — DECLINE: the UNFOLDED
; TWIN, and it is the ORDER-SENSITIVITY WITNESS for why F2 is a DECLINE
; predicate and not an ACCEPT predicate (PRD §14.2b).
;
;     int r = 0;  if (q + 1 == 6) r = cq_theta(q, .9);    // probe `p08s`, from C
;
; `-O1` canonicalizes the compare to `icmp eq i32 %q, 5` — and then does NOT fold
; the arm's `cq_theta(%q, .9)`. So the SAME SOURCE FAMILY reaches the pass folded
; (`p08h`) or unfolded (this one) depending on incidental pass order. An accept
; predicate reading "this LOOKS like state prep" is therefore order-sensitive by
; construction; a decline predicate reading "this COULD HAVE BEEN the condition
; register" is not.
;
; ⚠ THE MESSAGE IS `condition predates a non-diagonal gate`, NOT R4's `rotation
; arm on a condition wire`, AND PRD §14.3 ROW F2-8 IS CORRECTED BY THIS FIXTURE.
; The reason is `declineArm`'s re-spelling: the arm's own theta IS a non-diagonal
; gate on the condition's provenance wire, so `condWireDisposition` adjudicates
; the region BEFORE the rotation clause ever runs. There is no way to unmask it
; by moving a post-region gate, because the masking gate is the arm itself.
; MEASURED IDENTICAL ON THE PRE-INC-4 ORACLE (2026-09-04) — this row is untouched
; by Inc 4, which is exactly what makes it the twin of the folded fixture.
; F2 — THE EQUALITY-FOLD AMBIGUITY (PRD §14.2b). `clang -O1` (IPSCCP with
; PredicateInfo) replaces every use of the condition handle by the literal `k` on
; the edge where `q == k` is a theorem — on BOTH edges of an `icmp eq`/`ne`
; diamond. The consequence, MEASURED: two programs CQ must decline arrive as a
; module BYTE-IDENTICAL to a genuine state prep whose seed is `k`. An Inc 4 that
; read the shape as state prep would turn TWO LOUD DECLINES INTO SILENCE — the
; class the Inc-2b clearance blocked on.
;
; THERE IS NO POLARITY CLAUSE, and that is a proof rather than a convenience (a
; polarity clause is exactly where bd `ogw2` put a wrong unitary): F2 asks the
; branch's predicate AND its inverse and declines if EITHER edge pins the
; condition's tainted operand to the seed's value, so there is no edge in the
; test to get backwards.
;
; ⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L2 finding F-L2-5). This
; paragraph used to say "on an eq/ne diamond EXACTLY ONE successor is the edge on
; which the equality is a theorem, so there are exactly TWO physical readings,
; and given F1 both collapse to the single condition `seed == k`". The algebra was
; right and THE ENUMERATION WAS THE DEFECT: there is a THIRD reading (A3) in which
; an edge proves `H != k` and `H`'s own RANGE makes the surviving set a singleton
; whose value is NOT `k`. `int t = q & 1; int r = 1; if (t) r = cq_theta(t, θ);`
; is that reading, it is plain `clang -O1` C, and the literal test was silent on
; it BY DESIGN — a CONFIRMED silent miscompile at the Inc-4 hand-back. F2 is now
; RANGE-based on both edges; see
; `control_inplace_ry_reject_stateprep_range_mask1.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
