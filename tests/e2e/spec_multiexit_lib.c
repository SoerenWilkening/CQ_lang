/* spec_multiexit_lib.c — the CLASSICAL library TU for the Phase 6 / issue 5po2 I2
   golden: a MULTI-EXIT controlled-return in a lifted fp80 clone (the openlibm
   `expl`-family shape `if(x>MAXLOGL) return C; if(x<MINLOGL) return C'; …return
   f(x)`). Compiles WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh
   applies `-include CQ.h` to the CQ TU only); the tripwire fails LOUDLY if the
   harness ever force-includes CQ.h into a lib TU.

   `mini_expl` is the canonical fp80 controlled-return: two classical-SENTINEL
   early returns (overflow/underflow constants) guarding a tainted fall-through
   reduction. Handed a TAINTED (quantum) x86_fp80 argument, the specializer:
     * rewrites the fp80 arg + return to i32 handles (the 3c6m.54 fp-ABI);
     * `normalizeReturnMerge` folds the three `ret`s to a single-exit merge phi
       (clang -O1 usually pre-merges these itself — idempotent either way);
     * the scoped PredMux fixpoint (claimAll) flattens the diamond to a nested
       `select` chain whose inner condition is the COMPOUND `¬(x>MAX) ∧ ¬(x<MIN)`
       (a `cqrt_toffoli` conjunction of two `cq_template_fcmp_f80` leaf flags);
     * `lowerCloneSelect` mints that condition network FORWARD-ONLY, MATERIALIZES
       the classical sentinels into leaked |const⟩ `cqrt_alloc_f80` rails, and
       emits the 4.4 `cqrt_copy_f80_controlled` XOR muxes;
     * the Bennett wrap plays the SINGLE LIFO reverse (copy⁻¹, the self-inverse
       toffoli, the fcmp/fmul/fma `_unc`s) and frees every proven-|0⟩ rail.
   This is the ONLY layer that LINK-proves @__cq_q_mini_expl_1 +
   cqrt_copy_f80_controlled + cqrt_toffoli + the fp80 producer `_unc` twins
   resolve and signature-match across llvm-link. The materialized sentinel rails
   are left allocated (a safe classical |const⟩ leak, Rule 6) — never freed dirty. */

/* bd p3kd.7.8 (2026-10-07): the lifted clone now runs MAIN'S stage list, so its
   tainted select lowers through main's 4.4 merge (CondTreeEmit/SelectMergeEmit)
   and the Bennett wrap reverses it mechanically. Two trace changes, golden
   regenerated deliberately: the merge's trailing ¬flag `cqrt_x` (nothing reads
   the flag after the second copy) and its mirror at the start of the reverse are
   elided as a pair; where an arm is a constant zero, its materialized |0> rail
   is copied (a no-op) and now freed after the reverse. Every other gate is
   unchanged. The descriptions above are
   the pre-p3kd.7.8 stream. */

#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

long double mini_expl(long double x) {
    if (x > 1.1356e4L)  return 1.0e30L;   /* overflow  → classical sentinel */
    if (x < -1.14e4L)   return 0.0L;      /* underflow → classical sentinel */
    long double xx = x * x;               /* the tainted fall-through reduction */
    return 1.0L + xx * 0.03L;
}
