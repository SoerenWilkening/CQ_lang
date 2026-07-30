/* slice_libm_real_expl.c — bd 0rwu (PredMux W7, the CONST-FALLTHROUGH integer
   sole-phi diamond): the REAL openlibm expl body over x86_fp80 `long double` —
   census cell expl.f80. The LINK-layer proof (Rule 2) for one of the two cells
   the W7 witness unblocked; slice_libm_real_log10l.c is the other.

   WHY THIS CELL WAS BLOCKED. `isnan(x)` (ld80/e_expl.c:102) inlines __isnanl,
   whose `&&` (src/s_isnan.c:63, col 30) `clang -O1` spells as a 2-block DIAMOND
   whose merge takes a CONSTANT on the entry edge:
       %isnan = phi i32 [ 0, %entry ], [ %zext, %arm ]
   That is a sole 2-incoming INTEGER merge phi, which W5 deliberately left to the
   4.2 value emitter — and the 4.2 emitter cannot take it either, because
   `ArmClassify` sets `Routed = StraightThrough` = the folded `0` and no accept
   path can match a `ConstantInt`. So the region declined
   `value-arm swap-route under quantum control` at ArmClassify.cpp:1171 with no
   owner anywhere. MEASURED (2026-07-30): expl.f80 and log10l.f80 are the ONLY
   two of the census's 123 cells that decline-anchor there. W7 claims the diamond
   for PredMux; the flatten reduces it to exactly the tainted `select` the
   4.4/kjd1 controlled-XOR copy merge has lowered all along: the SAME two-base
   integer mux written as a tainted `select` lowers to an instruction-for-instruction
   identical gate stream (verified in the Rule-13 round), so the gap was the `br`-CFG
   SPELLING and nothing else.

   THE FLATTEN PATH IS NOT NEW CODE ON A NEW SHAPE. This exact expl body,
   including this exact __isnanl diamond, ALREADY flattens today inside a
   Bennett clone: slice_libm_real_coshl.c calls expl under tainted control, so
   Phase-6 clones it as @__cq_q_olm_expl_1 and `lowerCloneControl` drives PredMux
   with `claimAll=true`, which DROPS the W witness and claims every tainted
   diamond in the body. That slice is committed, Rule-13-cleared and its 9036-line
   golden is green. W7 supplies only the TOP-LEVEL witness so the standalone cell
   reaches the same shipped flatten. The regions below are therefore taken from
   that verified slice — BODIES AND TABLES byte-identical, with one systematic
   re-decoration noted after the list — so its per-file mechanical-edit ledger
   applies to them unchanged:
     /private/tmp/openlibm/src/amd64_fpmath.h — union IEEEl2bits (BOTH views) +
       LDBL_NBIT + mask_nbit_l, driven by olm_isnanl and olm_scalbnl.
     /private/tmp/openlibm/src/s_isnan.c      — __isnanl. THE CELL'S BLOCKER
       LIVES HERE.
     /private/tmp/openlibm/src/polevll.c      — __polevll (expl drives it twice;
       __p1evll has no expl caller and is NOT vendored).
     /private/tmp/openlibm/src/s_scalbnl.c    — scalbnl, which is what expl's two
       `ldexpl(x,1)` / `ldexpl(x,n)` sites resolve to (openlibm ships ldexpl ONLY
       as the assembler alias `.set ldexpl, scalbnl`), plus that alias forward.
       Its colliding statics stay uniquified `*_scalbnl`.
     /private/tmp/openlibm/ld80/e_expl.c      — expl + its own P/Q/C1/C2/MAXLOGL/
       MINLOGL/LOG2EL tables, file-scope names uniquified `*_expl`.
   Corpus verified at 82e90ae, byte-identical to the openlibm_reclone the earlier
   ld80 slices were vendored from.

   THE DELIBERATE DIFFERENCE FROM THE coshl COPY — and it is a re-decoration of
   FIVE functions, not one (an earlier draft said "the one difference … `olm_expl`",
   which the Rule-13 round corrected). In coshl every vendored helper is plain
   `static` so that `olm_expl` in particular stays OUTLINED and rides the Phase-6
   clone + `claimAll` path. Here all five — `olm_isnanl`, `olm_polevll`,
   `olm_scalbnl`, `olm_ldexpl`, `olm_expl` — carry
   `__attribute__((always_inline)) static inline`, and their declarator lines are
   reflowed from one line to three accordingly. NOTHING ELSE CHANGED: every body,
   constant and table is identical to coshl's after stripping the storage class and
   whitespace (verified).
   The re-decoration is load-bearing for what this slice PROVES. Inlined, the
   `__isnanl` diamond lands in `@slice` at the TOP LEVEL, where the W witness
   applies and only W7 can claim it — and it matches the census cell, whose harness
   inlines the corpus body into `probe`. An outlined spelling would re-prove the
   pre-existing clone path and prove nothing about W7.

   KEEP-SET CALLS (bd tkju — Rule 18 ship-floor fold, NOT a body substitution):
   floorl (expl's Cody-Waite round) and copysignl/copysign (scalbnl's overflow/
   underflow arms) are HARDWARE KEEPS. At the real ship floor — plain `clang -O1`,
   builtins ON — they fold to @llvm.{floor,copysign} before codegen, so a keep has
   NO injectable body and vendoring openlibm's software s_floorl.c / s_copysign*.c
   here would MISREPRESENT the compiled program. They are spelled
   __builtin_<fn>: no math.h is included, so the builtin spelling names the
   intrinsic without a libm declaration.

   Mechanical edits ONLY (libm-real-slice-recipe): includes/license/prose deleted,
   entries renamed olm_*, colliding file-scope statics uniquified per body,
   intra-body calls retargeted to the olm_ names or to the keep builtins above,
   u_int32_t mapped to stdint, INFINITY written as the __builtin_infl() it
   promotes to. No constant, branch or expression changed.

   WHAT THE TRACE SHOWS, INCLUDING THE PART THAT LOOKS WRONG AND IS NOT. 796
   deterministic lines (two runs byte-identical), exactly 1 cqrt_ry_f80 + 1
   cqrt_measure_f80 (Rule 5 — the compiler inserted no measurement), 151
   cqrt_free, and 32 cqrt_copy_f80_controlled. Of the 87 compare flag mints, 85
   carry a paired `_unc` strip and TWO do not: one `icmp_ne_i64_hl` and the sole
   `icmp_ugt_i64_hl`. Those two are exactly __isnanl's own conjuncts
   (`manl != 0` and the `manh != 0` that -O1 spells `ugt`), and their asymmetry
   is the W7 flatten working as designed rather than a leak: after the flatten
   those compares are no longer CONTROL flags to be stripped at a branch, they
   are speculated DATA that `or`/`zext` feed into the controlled-copy merge. They
   are therefore left ALLOCATED as dirty data rails, never freed dirty, which is
   the Rule-6 posture.

   BE PRECISE ABOUT WHICH GATE PROVES WHICH HALF OF THAT (an earlier draft of this
   paragraph over-claimed, corrected by the Rule-13 round). Stage 2b
   (`free_pairing_check.py`, run STRICT here with no `--allow-unproven`) states its
   obligation PER `cqrt_free`, so an UNFREED rail is outside its universe and it
   asserts nothing positive about these two. What it is, is a live TRIPWIRE for the
   hazard: mutating the lowered IR to add `cqrt_free` on either rail makes it fail
   loudly (`VIOLATION T1-no-reversal … freed with no matching … _unc reversal`),
   verified. The claim that they are LEFT allocated is pinned instead by the golden
   byte-diff, and that is airtight here because `cqrt_alloc_handle` is a monotonic
   `next_handle++` with no recycling (runtime/cq_runtime.c), so a handle absent from
   every `cqrt_free` line in the trace can never have been freed under another name.
   The precedent is real but smaller than an earlier draft implied: the committed,
   Rule-13-cleared slice_libm_real_logl and slice_libm_real_log1pl goldens each
   carry exactly ONE unstripped compare (an `fcmp_olt_f80_hl` feeding a `sext`),
   not two — so an unstripped compare is not something W7 introduced, though this
   slice is the first with two.

   The probe pins the census cell expl.f80: the single argument is theta-tainted
   (`cq_theta_f80(0.5L, 0.5)`), matching the census cell convention exactly. */
#include <stdint.h>

/* openlibm src/amd64_fpmath.h (verbatim — BOTH views; the fp80 pass owns the
   union, never memcpy-shim ld80 word access). */
union IEEEl2bits {
    long double e;
    struct {
        unsigned int manl : 32;
        unsigned int manh : 32;
        unsigned int exp  : 15;
        unsigned int sign : 1;
        unsigned int junkl : 16;
        unsigned int junkh : 32;
    } bits;
    struct {
        unsigned long man     : 64;
        unsigned int  expsign : 16;
        unsigned long junk    : 48;
    } xbits;
};
#define LDBL_NBIT 0x80000000
#define mask_nbit_l(u) ((u).bits.manh &= ~LDBL_NBIT)

/* openlibm src/s_isnan.c __isnanl (verbatim). */
__attribute__((always_inline)) static inline int
olm_isnanl(long double e)
{
    union IEEEl2bits u;

    u.e = e;
    mask_nbit_l(u);
    return (u.bits.exp == 32767 && (u.bits.manl != 0 || u.bits.manh != 0));
}

/* openlibm src/polevll.c __polevll (verbatim). */
__attribute__((always_inline)) static inline long double
olm_polevll(long double x, void *PP, int n)
{
    long double y;
    long double *P;

    P = (long double *)PP;
    y = *P++;
    do {
        y = y * x + *P++;
    } while (--n);

    return (y);
}

static const long double
huge_scalbnl = 0x1p16000L,
tiny_scalbnl = 0x1p-16000L;

/* openlibm src/s_scalbnl.c scalbnl (verbatim — from the verified
   slice_libm_real_coshl.c; ldexpl is its alias, forwarded below). */
__attribute__((always_inline)) static inline long double
olm_scalbnl(long double x, int n) {
    union IEEEl2bits u;
    int k;
    u.e = x;
    k = u.bits.exp;                             /* extract exponent */
    if (k==0) {                                 /* 0 or subnormal x */
        if ((u.bits.manh|u.bits.manl)==0) return x;   /* +-0 */
        u.e *= 0x1p+128;
        k = u.bits.exp - 128;
        if (n< -50000) return tiny_scalbnl*x;   /*underflow*/
    }
    if (k==0x7fff) return x+x;                  /* NaN or Inf */
    k = k+n;
    if (k >= 0x7fff) return huge_scalbnl*__builtin_copysignl(huge_scalbnl,x); /* overflow  */
    if (k > 0)                                  /* normal result */
        {u.bits.exp = k; return u.e;}
    if (k <= -128) {
        if (n > 50000)                          /* in case integer overflow in n+k */
            return huge_scalbnl*__builtin_copysign(huge_scalbnl,x);   /*overflow*/
        else return tiny_scalbnl*__builtin_copysign(tiny_scalbnl,x);  /*underflow*/
    }
    k += 128;                                   /* subnormal result */
    u.bits.exp = k;
    return u.e*0x1p-128;
}

/* openlibm s_ldexpl.c: ldexpl is scalbnl (the alias forward). */
__attribute__((always_inline)) static inline long double
olm_ldexpl(long double x, int n) {
    return olm_scalbnl(x, n);
}

/* openlibm ld80/e_expl.c expl (verbatim; Cephes). INFINITY is float +inf
   promoted to long double — written __builtin_infl(), the identical value. */
static long double P_expl[3] = {
 1.2617719307481059087798E-4L,
 3.0299440770744196129956E-2L,
 9.9999999999999999991025E-1L,
};
static long double Q_expl[4] = {
 3.0019850513866445504159E-6L,
 2.5244834034968410419224E-3L,
 2.2726554820815502876593E-1L,
 2.0000000000000000000897E0L,
};
static const long double C1_expl = 6.9314575195312500000000E-1L;
static const long double C2_expl = 1.4286068203094172321215E-6L;
static const long double MAXLOGL_expl = 1.1356523406294143949492E4L;
static const long double MINLOGL_expl = -1.13994985314888605586758E4L;
static const long double LOG2EL_expl = 1.4426950408889634073599E0L;

__attribute__((always_inline)) static inline long double
olm_expl(long double x) {
long double px, xx;
int n;

if( olm_isnanl(x) )
	return(x);
if( x > MAXLOGL_expl)
	return( __builtin_infl() );

if( x < MINLOGL_expl )
	return(0.0L);

/* Express e**x = e**g 2**n
 *   = e**g e**( n loge(2) )
 *   = e**( g + n loge(2) )
 */
px = __builtin_floorl( LOG2EL_expl * x + 0.5L ); /* floor() truncates toward -infinity. */
n = px;
x -= px * C1_expl;
x -= px * C2_expl;

/* rational approximation for exponential
 * of the fractional part:
 * e**x =  1 + 2x P(x**2)/( Q(x**2) - P(x**2) )
 */
xx = x * x;
px = x * olm_polevll( xx, P_expl, 2 );
x =  px/( olm_polevll( xx, Q_expl, 3 ) - px );
x = 1.0L + olm_ldexpl( x, 1 );

x = olm_ldexpl( x, n );
return(x);
}

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);
    return cq_measure_f80(olm_expl(q));
}
int main(void) { (void) slice(); return 0; }
