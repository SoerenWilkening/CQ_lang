; control_inplace_ry_reject_stateprep_eqfold_cast.ll — DECLINE (F2): the seed
; arrived through a CAST LAUNDER, and the fold erased the cast.
;
;     int r = 0;  if (q == 0) r = cq_theta((int)(signed char)q, .9);  // probe `q27`
;
; `-O1` proves `q == 0` on the arm edge, folds `(signed char)q` to `0`, folds the
; `sext` back to `0`, and DELETES both casts — so the module that reaches the
; pass is byte-identical to `if (q == 0) r = cq_theta(0, .9)` (`p08a_prep0`) AND
; to `if (q == 0) r = cq_theta(q, .9)` (`p08a`, the R4-forbidden spelling).
; Measured, all three.
;
; It is worth its own fixture even though the IR is a `k = 0` instance of the
; family, because it is the row that shows F2 cannot be replaced by any SYNTACTIC
; look at the arm: there is no cast left to see, no `sext`, nothing but a
; literal. The only surviving evidence that the arm MIGHT have named the
; condition register is the compare itself.
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
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 0
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
