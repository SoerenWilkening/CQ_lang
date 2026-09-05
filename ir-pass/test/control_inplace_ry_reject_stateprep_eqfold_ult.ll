; control_inplace_ry_reject_stateprep_eqfold_ult.ll — DECLINE (F2): an UNSIGNED
; singleton range, and a MIXED-SIGNEDNESS pair of suffixes.
;
;     unsigned u = cq_theta(3u, .3);  int r = 0;
;     if (u < 1u) r = cq_theta((int)u, .9);          // probe `p08g`, from C
;
; `u < 1u` is true only at 0, so instcombine rewrites it to `icmp eq i32 %u, 0`
; and the fold turns the arm into `cq_theta(0, .9)`. The condition register is
; minted by `cq_theta_ui32` and the arm by `cq_theta_si32`: F2 must still fire,
; and it does, because signedness is not part of the ABI width — the runtime
; handle is always `i32` (Rule 15) and F2 compares the compare literal's LLVM
; TYPE and bits against the seed's, both `i32 0`.
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

declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_ui32(i32)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_ui32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 0
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_ui32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
