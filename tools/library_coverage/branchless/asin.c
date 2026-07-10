/* branchless/asin.c — bd 3c6m.19 (libm L2-closure): the AUTHORED branchless asin
   body the census injects for `asin` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This
   file SHADOWS openlibm's branchy e_asin.c in the census symbol index.

   *** WHY openlibm's asin DECLINES (the L6-nested-ctrl blocker). *** openlibm's
   e_asin.c branches on |x| into segments (near 0 / |x|<0.5 / |x|→1) with a nested
   `if` ladder to pick a cancellation-free reconstruction (e_asin.c:77 — nested
   control flow under quantum control). This body dissolves the ladder with the plain
   trig identity

       asin(x) = atan( x / sqrt(1 − x²) )

   and CALLS the authored branchless `atan` leaf — resolved by the census closure-link
   to branchless/atan.c (indexed first) and inlined (the L2-closure spine, mirrors
   acosh/asinh/tanh→their leaves). atan is odd and carries the sign of its argument
   through its own final copysign, so asin needs NO extra copysign: x/√(1−x²) has the
   sign of x, and atan(odd) delivers asin's odd symmetry.

   *** THE fmax CLAMP KILLS THE |x|→1 NaN. *** As x→1⁻, 1−x²→0⁺ and the argument
   x/√(1−x²)→+∞ with atan(+∞)=π/2=asin(1) — but the branchless atan leaf returns NaN
   at a literal +∞ (0·∞ in its big segment). So 1−x² is clamped to a tiny positive
   floor,  s = sqrt(fmax(1 − x², TINY)),  TINY = 1e-300. At x=1 the argument becomes
   1/√1e-300 = 1e150 — a LARGE FINITE value in atan's big segment, where
   atan(1e150) = π/2 − 1e-150 ≈ π/2 (finite, correct), never NaN. The clamp is
   load-bearing: it is what makes asin FINITE and NaN-free across the whole contractual
   domain [−1,1] (for x∈[−1,1], fmax(·,TINY) ∈ [TINY,1] > 0, so s>0 finite, the
   argument finite, and atan is NaN-free on finite input).

   The e2e golden twin is tests/e2e/slice_branchless_asin.c (same body, with atan
   inlined as the static `batan` helper == branchless/atan.c) — keep the two (and
   batan == branchless/atan.c) textually in sync.

   Domain: [−1,1] — asin(0)=0 exactly, asin(±1)=±π/2, odd. |x|>1 is UNSPECIFIED
   (asin is complex there): the fmax floor pins the argument to x/√TINY, so |x|>1
   returns a finite ≈±π/2 all the way out to |x| ≈ 1.8e158 (measured), beyond which
   the argument x/√TINY = x/1e-150 itself overflows to ±∞ and atan returns NaN — the
   out-of-domain edge this body does not contract, matching atan's ±∞→NaN convention
   (note: x² overflowing at ~1.3e154 does NOT trigger the NaN — fmax(−∞,TINY)=TINY
   keeps the argument finite; the NaN onset is the later reciprocal-argument overflow).
   Accuracy: the branchless atan leaf's ≤1.15 ulp on the reduced argument, degrading
   as x→±1 where asin is intrinsically ill-conditioned (trace-only runtime, so
   classical ulp is a sanity check, not a gate).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double atan(double);

double asin(double x) {
    const double TINY = 1e-300;                          /* |x|→1 finite floor      */
    double s = __builtin_sqrt(__builtin_fmax(1.0 - x * x, TINY)); /* √(1−x²), no NaN */
    return atan(x / s);                                  /* = asin(x); atan is odd  */
}
