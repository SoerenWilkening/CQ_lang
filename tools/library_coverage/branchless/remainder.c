/* branchless/remainder.c — bd 3c6m.41 (libm L1): the AUTHORED branchless remainder
   body the census injects for `remainder` (Rule 18 source injection; owner
   body-source decision 2026-07-10 = hand-author per fn, the slice_branchless_exp
   model). This file SHADOWS openlibm's bit-loop e_remainder.c in the census index.

   *** WHY openlibm's remainder DECLINES. *** openlibm's e_remainder.c calls the
   e_fmod bit-loop then applies a rounding correction under data-dependent branches
   (the nested tainted control flow the census flags). remainder differs from fmod
   only in using round-to-nearest instead of truncation for the quotient, which is
   exactly the keep-set rint:

       remainder(x,y) = x - rint(x / y) * y

   rint is hardware-kept (@llvm.rint, roundsd round-to-nearest-even, Rule 18); the
   whole body is ONE fdiv + ONE rint + ONE fmul + ONE fsub — NO selects, NO branches
   — so it lowers for every taint mask (qc: x/0.5 `_hl`; cq: 0.5/x `_lh`; qq `_qq`).
   The IEEE round-to-nearest-even that `remainder` requires IS rint's default mode,
   so the |remainder| <= |y|/2 tie-breaking matches.

   The e2e golden twins are tests/e2e/slice_branchless_remainder{,_cq,_qq}.c — one per
   accepted taint mask (3c6m.48), same body inlined as the static `bremainder` helper.

   Domain: finite x, finite y != 0 with |x/y| within the exactly-representable
   integer range of rint (|x/y| < 2^53). y == 0 (x/y = +-inf/NaN) and the huge-ratio
   octave are UNSPECIFIED. Exact for the common small-ratio range (accuracy is a
   SANITY check on a trace-only runtime, not a gate).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
double remainder(double x, double y) {
    return x - __builtin_rint(x / y) * y;              /* nearest-division rem    */
}
