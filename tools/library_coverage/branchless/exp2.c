/* branchless/exp2.c — bd 3c6m.30 (libm L2-closure): the AUTHORED branchless exp2
   body the census injects for `exp2` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This
   file SHADOWS openlibm's table-driven s_exp2.c in the census symbol index.

   *** WHY openlibm's exp2 DECLINES (the L5-qrom blocker). *** openlibm's s_exp2.c
   reduces x, then reads a 256-entry accuracy table `tbl[i0]` with a data-dependent
   index (s_exp2.c:376 — a tainted-index const-global read, the Phase-7.5 QROM
   surface). This body dissolves the table with the plain identity

       exp2(x) = 2^x = e^(x·ln2) = exp(x · ln2)

   and CALLS the authored branchless `exp` leaf — resolved by the census closure-link
   to branchless/exp.c (indexed first) and inlined (the L2-closure spine, mirrors
   acosh/asinh/tanh→their leaves). ln2 = 0.69314718055994530942. No table, no scratch
   memory, no control flow beyond exp's single inherited round-bias fp select (the
   kjd1 accept shape). exp itself has no tainted branch, so exp2 injects as pure
   straight-line opcodes.

   The e2e golden twin is tests/e2e/slice_branchless_exp2.c (same body, with the exp
   leaf inlined as the static `bexp` helper == branchless/exp.c) — keep the two (and
   bexp == branchless/exp.c) textually in sync.

   Domain: finite x on the representable range of 2^x. Accuracy is the branchless
   exp leaf's degree-5-Taylor level — worst-case ≈3e-6 relative (measured 3.24e-6;
   the truncation drops r^6/720 ≈ 2e-6 at the |r| ≤ ln2/2 reduced-range edge); the
   runtime is trace-only, so classical ulp is a SANITY check, not a gate — is this
   really 2^x and not garbage. overflow/underflow/NaN are UNSPECIFIED — the branchy
   special cases (and the accuracy table) the branchless exp leaf deliberately omits.

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double exp(double);

double exp2(double x) {
    return exp(x * 0.69314718055994530942);              /* 2^x = e^(x·ln2)         */
}
