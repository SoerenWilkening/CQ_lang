; control_inplace_ry_reject_stateprep_eqfold_coincidence.ll — DECLINE (F2, the
; A1 reading): the seed EQUALS the compare literal, on the ARM edge.
;
;     int r = 5;  if (q == 5) r = cq_theta(5, .9);       // probe `p06a`, from C
;
; ⚠ THIS MODULE IS BYTE-IDENTICAL (slice-body diff at `-O1`, measured
; 2026-09-04) TO TWO PROGRAMS CQ MUST DECLINE:
;     int r = 5; if (q == 5)      r = cq_theta(q, .9);   // `p08e` — an in-place
;                                                        // Ry on the CONDITION
;                                                        // register: R4 forbids it
;     int r = 5; if (q > 4 && q < 6) r = cq_theta(q, .9); // `p08c` — the same,
;                                                        // via a singleton range
; An Ry RELABELS the basis, so the strip `icmp_..._unc` would be computed over a
; register the arm moved and the flag would not return to |0>. There is no
; correct re-anchor for this stem (unlike Rz, which is diagonal — see §14.2d and
; `tryEqFoldArm`), so the only options are "accept as a fresh rail", which is
; WRONG whenever the source meant `q`, or "decline". F2 declines.
;
; THE COST IS A GENUINE OVER-DECLINE AND IT IS THE SHIPPED DISPOSITION (PRD
; §14.11 Q1): the source above is a well-formed, unambiguous state prep. The
; workaround is ONE CHARACTER — any seed other than the compare literal, e.g.
; `control_inplace_ry_stateprep_seed_nonzero.ll` (seed 7, k 5), which ACCEPTS.
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

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
