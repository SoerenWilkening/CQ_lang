/* branchless/fdim.c — bd 3c6m.16 (libm L1): the AUTHORED branchless fdim body the
   census injects for `fdim` (Rule 18 source injection; owner body-source decision
   2026-07-10 = hand-author per fn, the slice_branchless_exp model). This file
   SHADOWS openlibm's branchy s_fdim.c in the census symbol index.

   *** WHY openlibm's fdim DECLINES. *** openlibm's s_fdim.c branches on isnan and
   `x <= y ? 0 : x - y` — the tainted control flow the census flags. fdim is the
   positive difference, which is exactly a keep-set fmax over the difference:

       fdim(x,y) = (x > y) ? x - y : 0   ==   fmax(x - y, 0.0)

   ONE fsub + ONE @llvm.maxnum (fmax is hardware-kept, Rule 18) — NO selects, NO
   branches — so the taint pass lowers it directly for every taint mask (qc/cq/qq).
   fmax(NaN, 0) = 0 handles the x/y = NaN edge the way the C spec's fdim does not
   promise, but on the finite contractual domain the two agree exactly.

   The e2e golden twins are tests/e2e/slice_branchless_fdim{,_cq,_qq}.c — one per
   accepted taint mask (3c6m.48: each mask is a distinct unitary and gets its own
   linked golden), same body inlined as the static `bfdim` helper. Keep in sync.

   Domain: all finite x,y (fdim is total on the finite reals — no division, no
   cancellation hazard; the fmax clamp keeps the result finite and >= 0). Exact:
   x - y is the true difference when x > y, else exactly 0. Overflow of x - y at
   the extreme octaves (|x-y| > DBL_MAX) is UNSPECIFIED (openlibm overflows too).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
double fdim(double x, double y) {
    return __builtin_fmax(x - y, 0.0);                 /* positive difference     */
}
