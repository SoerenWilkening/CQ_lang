/* branchless/fmod.c — bd 3c6m.32 (libm L1): the AUTHORED branchless fmod body the
   census injects for `fmod` (Rule 18 source injection; owner body-source decision
   2026-07-10 = hand-author per fn, the slice_branchless_exp model). This file
   SHADOWS openlibm's bit-loop e_fmod.c in the census symbol index.

   *** WHY openlibm's fmod DECLINES. *** openlibm's e_fmod.c is a data-dependent
   shift-and-subtract loop over the mantissa words (a bounded loop with tainted trip
   count + special-case branches — the nested tainted control flow the census flags).
   This body dissolves the loop with the direct truncated-quotient identity:

       fmod(x,y) = x - trunc(x / y) * y

   trunc is hardware-kept (@llvm.trunc, roundsd, Rule 18); the whole body is ONE
   fdiv + ONE trunc + ONE fmul + ONE fsub — NO selects, NO branches — so it lowers
   for every taint mask (qc: x/0.5 `_hl`; cq: 0.5/x `_lh`; qq: x/y `_qq`).

   The e2e golden twins are tests/e2e/slice_branchless_fmod{,_cq,_qq}.c — one per
   accepted taint mask (3c6m.48), same body inlined as the static `bfmod` helper.

   Domain: finite x, finite y != 0 with |x/y| within the exactly-representable
   integer range of trunc (|x/y| < 2^53). y == 0 (x/y = +-inf/NaN -> trunc(inf) =
   inf -> inf*y NaN) and the huge-ratio octave (where trunc's rounding drops the
   low-order remainder bits the openlibm bit-loop keeps) are UNSPECIFIED. This is the
   textbook truncated-division remainder — exact for the common small-ratio range,
   with a coarser tail than the bit-exact loop (accuracy is a SANITY check on a
   trace-only runtime, not a gate).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
double fmod(double x, double y) {
    return x - __builtin_trunc(x / y) * y;             /* truncated-division rem  */
}
