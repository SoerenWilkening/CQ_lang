; control_inplace_ry_reject_stateprep_eqfold_derived_cond.ll — DECLINE (F2), on a
; case PRD §14.2b's prose does not enumerate and its SPELLING already covers
; (measured 2026-09-05, from plain C; bd test_C_libtooling-drbq Inc 4).
;
;     int r = 2;  if ((q & 6) == 2) r = cq_theta(q & 6, .9);
;
; `-O1` proves `(q & 6) == 2` on the arm edge, folds the arm's `q & 6` to the
; literal `2`, and DELETES the second `and`. The module that reaches the pass is
; the one below: an `icmp eq` whose non-constant operand is the DERIVED value
; `%a`, an arm theta seeded with the compare literal, and a pred incoming of the
; same literal. Byte-identical, therefore, to a genuine `int r = 2; if ((q&6)==2)
; r = cq_theta(2, .9);`.
;
; ⚠ THE CONDITION REGISTER F2 IS PROTECTING HERE IS NOT `q` — IT IS `%a`, a rail
; the flag mint's template chain creates. §14.2b's text says "a TAINTED operand
; and a `ConstantInt` k", and *that* is the load-bearing word: it is not "the
; register the arm rotates" and not "the theta's source". An in-place Ry on `%a`
; is forbidden for exactly R4's reason — the strip recomputes `(q & 6) == 2` over
; a register the arm relabelled — and this fold makes that program textually
; indistinguishable from a fresh-rail prep of |2>.
;
; It is committed because the natural reading of F2 ("the seed equals the literal
; the user compared `q` against") would have missed it: nothing here compares `q`
; to anything. The fence asks about the compare's own tainted operand, whatever
; it is, and that is what makes it complete over derived conditions.
;
; ⚠ CONTRAST with `control_inplace_ry_stateprep_cond_derived.ll`, which is THE
; SAME CONDITION with seed `0` and ACCEPTS. The discriminator is the seed's value
; against the compare literal — 0 != 2 there, 2 == 2 here — so F2 is silent by
; VALUE and not by shape, and the derived-condition accept is not a hole in it.
;
; ⚠ THAT CONTRAST IS BETWEEN THE TWO `.ll` FILES, NOT BETWEEN TWO C PROGRAMS
; (corrected 2026-09-05, round-1 Rule-13 review, lens L2 finding F-L2-7). The C
; program a reader would infer for the accept — `int r = 0; if ((q&6)==2) r =
; cq_theta(q&6, .9);` — does NOT produce that fixture: `-O1` folds the arm's
; `q & 6` to `2` there as well, and it then declines on **F1** (seed 2 vs pred
; incoming 0). The accept fixture's C has a source-written `0` in the arm.
;
; ⚠ AND SINCE THE ROUND-1 RANGE REWRITE, "0 != 2 there" IS NO LONGER THE WHOLE
; TEST: F2 now also asks whether either EDGE pins `%a` to the seed. It does not
; here — `and %q, 6` has range `[0,7)`, the `eq` edge is `{2}` and the `ne` edge
; is a six-element set — which is why `..._cond_derived.ll` still accepts and why
; it is the one-token control for
; `control_inplace_ry_reject_stateprep_range_mask1.ll`, whose mask `1` DOES pin.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = and i32 %q, 6
  %c = icmp eq i32 %a, 4
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 2, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 2, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
