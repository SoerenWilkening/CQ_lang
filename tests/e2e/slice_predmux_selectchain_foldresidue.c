/* slice_predmux_selectchain_foldresidue.c — bd 20xt.5.1 blocker (e) e2e smoke:
   the residual-select fold driven through the full clang -O1 → opt cq-lowering →
   link → run pipeline (the only layer that LINKS every emitted symbol, Rule 2).

   SOURCE INTENT (the atan2l quadrant residue, minimized to just the fold path):
   a tainted special-case whose classical guard reads the fp80 exponent of a
   POSITIVE classical constant x=0.5L. clang -O1 does NOT promote an fp80 union
   in memory, so `ux.bits.exp` stays a load past -O1; cq-lowering's fp80-union
   promotion folds it to the constant 16382 (exp of 0.5L), and
   `foldConstantConeAndBranches` collapses the guard `ex==16383` (the `x==1.0`
   test) to `false`. But ConstantFold is all-or-nothing — it leaves the
   PARTIAL-constant residue `and i1 false, %hi` (the `& hi` conjunct) feeding the
   `cond ? 3.0L : …` select.

   WHY (e) IS EXERCISED: without the post-flatten residue fold, `collectCondTree`
   hits that `false` ConstantInt leaf and the whole nest declines
   ("control flow under quantum control"). The 20xt.5.1 fold collapses
   `and i1 false,%hi → false` and the dead `select i1 false, 3.0, X → X`, so the
   surviving `hi ? (y+1) : (y+2)` value select and the two enclosing diamonds
   lower via the 4.4 controlled-XOR copy merge.

   WHY THE TRACE IS DETERMINISTIC + CORRECT: the runtime is trace-only and the
   nest flattens to straight-line code, so every gate fires unconditionally. The
   fold reduces the dead special-case to EXACTLY the lowering of the equivalent
   residue-free source (verified byte-identical during development), so the dead
   arm constant 3.0L never reaches a gate. 1 cqrt_ry + 1 cqrt_measure (Rule 5),
   0 double-frees; `hi` stays live (feeds the inner select), so no dead sign
   handle. cq_theta/cq_measure resolve from CQ.h (force-included by
   run_slice.sh); the `union IEEEl2bits` is the openlibm amd64 x86_fp80 view. */
#include <stdint.h>

union IEEEl2bits {
    long double e;
    struct { uint32_t manl:32; uint32_t manh:32; uint32_t exp:15;
             uint32_t sign:1; uint32_t junkl:16; uint32_t junkh:32; } bits;
    struct { uint64_t man:64; uint32_t expsign:16; uint64_t junk:48; } xbits;
};

long double slice(void) {
    long double y = cq_theta(0.5L, 0.5);  /* taint y -> handle (alloc, ry)       */
    long double x = 0.5L;                  /* classical const (x == 1.0 is false) */
    union IEEEl2bits ux; ux.e = x;         /* fp80 union stays in memory at -O1   */
    int32_t ex = ux.bits.exp;              /* exp(0.5L) = 16382 (cq folds this)   */
    int32_t kfalse = (ex == 16383);        /* -> false via promotion + ConstantFold */
    int32_t hi = (y > 50.0L);              /* tainted, stays LIVE (used twice)    */
    int32_t cond = kfalse & hi;            /* -> residue `and i1 false, hi`       */
    long double r;
    if (y > 0.0L) {                        /* outer tainted branch (region root)  */
        if (y < 100.0L) {                  /* nested tainted branch -> PredMux claim */
            /* the dead residue guards the outer select; the fold collapses it to
               the surviving live `hi`-select, as atan2l's quadrant does */
            r = cond ? 3.0L : (hi ? (y + 1.0L) : (y + 2.0L));
        } else {
            r = y + 7.0L;
        }
    } else {
        r = y;
    }
    return cq_measure(r);                  /* reads the flattened select-chain    */
}
int main(void) { (void) slice(); return 0; }
