/* branchless/acos.c — bd 3c6m.17 (libm L2-closure): the AUTHORED branchless acos
   body the census injects for `acos` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This
   file SHADOWS openlibm's branchy e_acos.c in the census symbol index.

   *** WHY openlibm's acos DECLINES (the L6-nested-ctrl blocker). *** openlibm's
   e_acos.c branches on |x| into segments (|x|<0.5 / x→1 / x→−1) with a nested `if`
   ladder (e_acos.c:71 — nested control flow under quantum control). This body
   dissolves the ladder with the plain identity

       acos(x) = π/2 − asin(x)

   and CALLS the authored branchless `asin` leaf — resolved by the census closure-link
   to branchless/asin.c (indexed first), which itself closes to branchless/atan.c
   (the two-level L2-closure spine). All the range/NaN care lives in asin (the fmax
   clamp that keeps 1−x² off zero at |x|→1); acos is one subtraction on top.

   The e2e golden twin is tests/e2e/slice_branchless_acos.c (same body, with asin and
   atan inlined as static `basin`/`batan` helpers == branchless/{asin,atan}.c) — keep
   the two (and basin == branchless/asin.c, batan == branchless/atan.c) textually in
   sync.

   Domain: [−1,1] — acos(1)=0, acos(0)=π/2, acos(−1)=π; the range is [0,π]. Because
   asin is finite and NaN-free on [−1,1] (its fmax clamp), so is acos. |x|>1 is
   UNSPECIFIED (acos is complex there): it inherits asin's out-of-domain behaviour
   (|x|>1 → finite π/2∓π/2 ∈ {0,π} out to |x| ≈ 1.8e158, beyond which asin → NaN via
   the reciprocal-argument overflow). Accuracy: asin's,
   plus the exactly-representable π/2 constant (trace-only runtime, so classical ulp
   is a sanity check, not a gate).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double asin(double);

double acos(double x) {
    return 1.57079632679489661923 - asin(x);             /* π/2 − asin(x)           */
}
