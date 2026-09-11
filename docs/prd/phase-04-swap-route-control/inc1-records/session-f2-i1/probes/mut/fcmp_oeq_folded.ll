; control_inplace_ry_reject_stateprep_fcmp_oeq_folded.ll — DECLINE (F2, the fp
; ANCHOR half). A LIVE f64 register pinned to a `ConstantFP` by the region's OWN
; `fcmp oeq`, with the arm's seed EQUAL to that constant.
;
; ⚠ ROUND-4 RULE-13 FINDING (lens R4, F-R4-1, CONFIRMED-MISCOMPILE, hand IR).
; Source `$S/review4/R4/h/hf01_fcmp_folded.ll`. F2's BACKWARD half is
; `LazyValueInfo::getConstantRangeOnEdge`, which is defined over `ConstantRange`
; — an INTEGER lattice — and its anchor loop was therefore `isIntegerTy()`-gated.
; So NO floating-point register was ever asked F2's question at all: `%t` is
; tainted, dominates the branch, and is dropped FOR ITS TYPE. The only i1 anchor
; left is the `fcmp` itself, whose sole user is the `br` (void => skipped), so
; the walk was empty and F2 returned false. MEASURED at the round-3 HEAD:
; ACCEPT, exit 0, strict-2b clean, linked, RUN — emitting a FRESH rail at 5.0,
; rotating THAT, and measuring `%t` UNROTATED.
;
; THE TWIN THAT SETTLES THE UNITARY is `control_inplace_ry_stateprep_fcmp_oeq_twin.ll`
; (R4's `hf04_uncond_fmul.ll`), which is byte-identical on BOTH binaries and
; lowers `cq_theta(%t, 0.9)` to an IN-PLACE `cqrt_ry_f64` on `%t`'s own rail. So
; CQ's own reading of an f64 `cq_theta` on a live register is: rotate that rail.
; Source: one wire. Accepted circuit: two, with the measured one unrotated.
; Different unitary — the F2 ambiguity, at fp.
;
; THE FIX IS AN ANCHOR, NOT A WIDER LVI QUERY (there is no wider query to make:
; LVI has no fp edge fact to give, at any predicate, ever). On the edge where an
; EQUALITY `fcmp` against a `ConstantFP` HOLDS, its tainted operand IS that
; constant — a theorem, seeded directly into `F2State::Cst`, which already
; carries an exact constant for ANY type. The FORWARD half then does the rest
; unchanged, so no second walker was minted (the 8h7d.5 F-1/F-3 discipline:
; reuse the closure rather than compute a new one beside it).
;
; ±0.0 AND NaN CONSTANTS ARE REFUSED, and the reason is in the code: `fcmp oeq
; %x, 0.0` is TRUE for `-0.0` as well as `+0.0`, so the equality edge is NOT a
; singleton and pinning would claim more than the edge supports; a NaN `K` makes
; the equality edge either unreachable (`oeq`) or universal (`ueq`), so it never
; yields a singleton either.
;
; THIS SHAPE IS NOT `clang -O1`-REACHABLE AT LLVM 19, and the fixture says so
; rather than implying otherwise: `propagateEquality` does not substitute across
; `fcmp oeq` (`+0.0 == -0.0`), and `EarlyCSE` runs before `IPSCCP`, so a
; pre-branch fp derivation is CSE'd and `PredicateInfo` has nothing to rename
; (R4 measured seven `-O1` dumps, `p/fp01`-`fp12`). The shape `clang` ACTUALLY
; produces is `control_inplace_ry_reject_stateprep_fcmp_oeq_unfolded.ll`, which
; declines on BOTH binaries with `condition predates a non-diagonal gate`. What
; made this worth fixing rather than filing is that the shipped comment carried a
; RETIREMENT TRIGGER asserting the clause "needs no change" the day LLVM gains
; that substitution — false in both halves, and an invitation to a future widener
; to read "already covered" and ship.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_f64_controlled
; CHECK-NOT: cqrt_alloc_f64

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %t = fmul double %q, 2.000000e+00
  %c = fcmp oeq double %t, 6.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 5.000000e+00, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 5.000000e+00, %entry ]
  %mr = call double @cq_measure_f64(double %rm)
  %mt = call double @cq_measure_f64(double %t)
  %s  = fadd double %mr, %mt
  ret double %s
}
