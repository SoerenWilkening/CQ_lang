/* spec_fp_select_fcmp_lib.c — the CLASSICAL library TU for the bd tkmn Inc-1
   fcmp-condition golden. Compiles WITHOUT CQ.h (C18; the tripwire fails loudly if
   the harness force-includes it).

   THE SHAPE, and an honest note about what it is and is not. The increment was
   motivated by openlibm bsdsrc/b_exp.c:171 `return isfinite(x) ? HUGE : x`, which
   `clang -O1` if-converts to a straight-line

       %c = fcmp one double %v, +inf
       %a = select i1 %c, double <const>, double %v

   — a CONST/VALUE fp select whose CONDITION IS AN FCMP, which was the sole clause
   declining the tgamma lever before Inc 1. This slice reproduces that IR SHAPE,
   but NOT the literal isfinite test, and the reason is worth recording because two
   drafts of this slice died to it: the helper's input is an `int`, so clang -O1
   knows a great deal about the widened value and folds the comparison away.
     * `isfinite(v)` on a `sitofp` result is PROVABLY true -> whole body collapses
       to `ret double 2.5`, no fcmp at all.
     * `v != 0.0` is INVERTED back into the integer domain -> `icmp eq i32 %n, 0`,
       again no fcmp.
   Squaring first (`w = v*v`) defeats both: clang will not invert `w != 2.0` to an
   integer predicate, so the `fcmp une` genuinely survives to the pass, with `w`
   itself as the value arm — the same const/value-select-on-an-fcmp shape, and the
   same derived-value arm role `x` plays in b_exp.c. `une` rather than `one` is
   immaterial: both are in the shipped 14-predicate fcmp set and the emitted stream
   differs only in the predicate token (verified against the `one` lit fixture).

   The specializer lifts mhelper to __cq_q_mhelper_1, mints the flag with
   `cq_template_fcmp_une_f64_hl` (the widening's payload — an fcmp family stem
   where only icmp could appear before), materializes the ConstantFP arm to its own
   `cqrt_alloc_f64(2.5)` |const> rail (LEFT allocated, leaked, Rule 6),
   controlled-copies both arms into the |0> out rail, and Bennett-wraps it.

   WHY THIS SLICE EXISTS (Rule 2 / Rule 16, and the bd tkmn Rule-13 blast-radius
   lens finding F1): the fcmp accept path fired in ZERO e2e slices and ZERO census
   cells — the only artifact exercising it was a lit fixture, and fixtures never
   LINK. e2e is the one layer that proves every emitted symbol resolves and
   signature-matches, so without this slice the newly reachable
   `cq_template_fcmp_*_hl` / `_unc` mints had no standing regression proving they
   link. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

double mhelper(int n) {
    double v = (double) n;
    double w = v * v;                   /* defeats clang's sitofp-compare folding */
    return (w != 2.0) ? 2.5 : w;        /* fcmp une + select(const, value) */
}
