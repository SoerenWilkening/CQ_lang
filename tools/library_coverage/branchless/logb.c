/* branchless/logb.c — bd 3c6m.38 (libm L1): the AUTHORED branchless logb body the
   census injects for `logb` (Rule 18 source injection; owner body-source decision
   2026-07-10 = hand-author per fn, the slice_branchless_exp model). This file
   SHADOWS openlibm's branchy s_logb.c in the census symbol index.

   *** WHY openlibm's logb DECLINES. *** openlibm's s_logb.c is a ladder of
   data-dependent special-case branches (x subnormal -> rescale, x == 0 -> -inf,
   inf/NaN -> x*x) around a single exponent-field extract — the nested tainted
   control flow the census flags. This body keeps ONLY the field extract:

       logb(x) = (double)( ((bits(x) >> 52) & 0x7FF) - 1023 )   [x normal]

   the unbiased binary exponent of a finite NORMAL x. Pure straight-line integer +
   bitcast + sitofp opcodes — ZERO selects, zero control flow — so the taint pass
   lowers it directly.

   The e2e golden twin is tests/e2e/slice_branchless_logb.c (same body, inlined at
   the slice level as the static `blogb` helper) — keep the two textually in sync.

   Domain: finite NORMAL x (either sign — logb ignores the sign). x == 0 (openlibm
   returns -inf), subnormal (openlibm unbiases below -1022), inf/NaN are UNSPECIFIED
   — exactly the data-dependent branches this branchless body deliberately omits (at
   x == 0 the field is 0 so it yields the finite -1023.0, not -inf; never NaN/Inf on
   the contractual normal range). On finite normal x this is openlibm's exact result
   (the exponent field is exact).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c` with NO
   -fno-builtin (a "no-builtins" definition attribute makes the probe caller's
   no-builtin-logb set a non-superset and the O2 inliner then refuses to inline the
   body — TLI areInlineCompatible, InlineCallerSupersetNoBuiltin). */
double logb(double x) {
    unsigned long long bits;
    __builtin_memcpy(&bits, &x, 8);                    /* bitcast f64->i64        */
    int e = (int)((bits >> 52) & 0x7FFULL) - 1023;     /* biased exp field - bias */
    return (double)e;                                  /* sitofp i32->f64         */
}
