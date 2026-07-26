/* slice_libm_real_acoshl.c — bd q2wk Inc 5 (PredMux E6 path-predicated branch
   conditions): the REAL openlibm acoshl body over x86_fp80 `long double`,
   census cell acoshl.f80. OpenBSD/Cephes(Moshier)/FreeBSD-derived, BSD-licensed.

   CORPUS VENDORED (11 files — 9 .c bodies + 2 headers; the WHOLE closure. After
   the Rule-18 keep rewrite below the vendored text calls nothing but other
   vendored bodies — confirmed on the stage-1 IR, whose ONLY external `declare`s
   are @cq_theta_f80 / @cq_measure_f80 and the @llvm.* keeps; no unvendored libm
   symbol leaks):
     /private/tmp/openlibm_reclone/src/math_private_openbsd.h
         ieee_extended_shape_type (the LP64 little-endian ld80 word union) and
         the GET_LDOUBLE_WORDS macro — acoshl's se/i0/i1 exponent-word read.
     /private/tmp/openlibm_reclone/src/amd64_fpmath.h
         union IEEEl2bits (BOTH views) + LDBL_NBIT + mask_nbit_l — the bitfield
         union driven by __isnanl, scalbnl and frexpl.
     /private/tmp/openlibm_reclone/src/s_isnan.c        __isnanl
     /private/tmp/openlibm_reclone/src/polevll.c        __polevll AND __p1evll
     /private/tmp/openlibm_reclone/src/s_scalbnl.c      scalbnl
         (openlibm_strong_reference(scalbnl, ldexpl): ldexpl IS this body; it is
         reached only from e_logl.c's `ldexpl(x,1)` / `ldexpl(z,-1)`.)
     /private/tmp/openlibm_reclone/src/s_frexpl.c       frexpl
     /private/tmp/openlibm_reclone/ld80/e_logl.c        logl + P/Q/R/S/C1/C2
     /private/tmp/openlibm_reclone/ld80/s_log1pl.c      log1pl + P/Q/R/S/C1/C2
     /private/tmp/openlibm_reclone/ld80/e_acoshl.c      acoshl (the entry) — the
         GET_LDOUBLE_WORDS exponent-word classification ladder (x<1 domain arm,
         x>2**30 arm with its inner inf/NaN test, the acosh(1)==0 arm, the x>2
         arm, and the 1<x<2 log1p arm), all five arms intact.
     e_logl.c is INLINED TWICE (the x>2**30 arm and the x>2 arm each call logl);
     s_log1pl.c once. sqrtl is NOT vendored — see KEEP-SET below.

   MECHANICAL EDITS (declared, in corpus order; NO constant, branch, comparison
   or expression changed — every vendored body was mechanically diffed against
   its corpus file after applying only the renames listed here, and every diff
   came back IDENTICAL):
     - math_private_openbsd.h: the __FLOAT_WORD_ORDER__ big-endian variant of
       ieee_extended_shape_type dropped (not-taken preprocessor text on x86-64)
       and the surviving little-endian variant's `#ifdef __LP64__ int padh:32;`
       resolved to `int padh:32;` (LP64 target). SET_LDOUBLE_WORDS /
       GET_LDOUBLE_MSW / SET_LDOUBLE_MSW / GET_LDOUBLE_EXP / SET_LDOUBLE_EXP not
       carried over — acoshl uses none of them.
     - amd64_fpmath.h: license header, $FreeBSD$ line and the LDBL_MANH_SIZE /
       LDBL_MANL_SIZE / LDBL_TO_ARRAY32 tail (unused here) deleted; the union and
       LDBL_NBIT/mask_nbit_l kept VERBATIM. NO memcpy word shim is used at ld80 —
       the pass's promoteFp80Union stage owns this union (3c6m.51 convention).
     - s_isnan.c: license/includes/OLM_DLLEXPORT deleted, and the
       `#ifdef OLM_LONG_DOUBLE` guard around __isnanl unwrapped — that guard is
       TAKEN on x86-64 (openlibm_math.h:31 defines OLM_LONG_DOUBLE whenever the
       target is not __arm__/__wasm__), so the guard text goes and its BODY is
       what is carried over; the (isnan)(double) and
       __isnanf(float) siblings and the trailing openlibm_weak_reference not
       carried over (unreachable from acoshl); entry __isnanl renamed olm_isnanl.
     - polevll.c: license/prose/includes deleted; __polevll -> olm_polevll and
       __p1evll -> olm_p1evll. Both bodies (the do/while Horner loops) verbatim.
     - s_copysignl.c / s_copysign.c are NOT vendored: copysign/copysignl are
       Rule-18 HARDWARE KEEPS (see KEEP-SET below). `scalbnl`'s overflow and
       underflow arms call them, and those 3 call sites are spelled
       __builtin_copysignl / __builtin_copysign.
     - s_scalbnl.c: license/prose/includes/OLM_DLLEXPORT, the
       `#if LDBL_MAX_EXP != 0x4000 #error` guard and the trailing
       openlibm_strong_reference deleted; entry scalbnl renamed olm_scalbnl; the
       colliding file-scope `huge`/`tiny` uniquified `scb_huge`/`scb_tiny`;
       the 3 copysignl/copysign call sites spelled as the keep builtins.
     - s_frexpl.c: license/includes/OLM_DLLEXPORT and the LDBL_MAX_EXP #error
       guard deleted; entry frexpl renamed olm_frexpl. The 3-way `switch
       (u.bits.exp)` and its union write-back are verbatim.
     - e_logl.c: license, the logl.c prose/ACCURACY comment block and the two
       includes deleted; entry logl renamed olm_logl; the file-scope P[]/Q[]/
       R[4]/S[4]/C1/C2 and the SQRTH macro uniquified `*_logl` ONLY because
       s_log1pl.c below declares an identically-named set (the values are
       byte-identical to corpus); intra-body calls retargeted isnan->olm_isnanl,
       frexpl->olm_frexpl, __polevll->olm_polevll, __p1evll->olm_p1evll,
       ldexpl->olm_scalbnl; the openlibm_math.h macros INFINITY and NAN expanded
       to their __MATH_BUILTIN_CONSTANTS definitions `__builtin_inff()` /
       `__builtin_nanf("")` (openlibm_math.h lines 82-83).
     - s_log1pl.c: identical treatment, uniquified `*_log1pl`; log1pl ->
       olm_log1pl. (log1pl calls no ldexpl.)
     - e_acoshl.c: license, the acoshl.c Method/Special-cases prose and the two
       includes deleted; entry acoshl renamed olm_acoshl; the `one`/`ln2`
       file-scope constants kept verbatim (no collision); intra-body calls
       retargeted logl->olm_logl, log1pl->olm_log1pl, sqrtl->__builtin_sqrtl.
     - Global to all bodies: `u_int32_t` supplied by a local
       `typedef unsigned int u_int32_t;` (+ <stdint.h> for the memcpy shim's
       uint64_t); every vendored function marked
       `__attribute__((always_inline)) static inline` so plain clang -O1
       collapses the whole closure into ONE function, matching the census shape.
       Corpus trailing whitespace on 4 lines (e_logl.c 152/175, s_log1pl.c
       150/176 — all `\t}\t`) is stripped, per the convention of the already
       verified ld80 slices (erfl/coshl/hypot carry zero trailing whitespace).

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution):
     e_acoshl.c calls sqrtl at 2 sites — `sqrtl(t-one)` in the x>2 arm and
     `sqrtl(2.0*t+t*t)` in the 1<x<2 arm. sqrtl is a HARDWARE KEEP: at the real
     ship floor (plain clang -O1, builtins ON) it folds to @llvm.sqrt.f80 before
     codegen and cq-lowering rewrites that to cq_template_sqrt_f80. Spelling it
     `__builtin_sqrtl` emits exactly that construct and needs no libm
     declaration; vendoring openlibm's software e_sqrtl.c here would
     MISREPRESENT the ship floor (the census bug bd 3c6m.60 fixed).
     A SECOND keep rides in from clang, not from the corpus text: default
     fp-contract fuses the Horner/rational products into @llvm.fmuladd.f80,
     which is likewise a Rule-18 keep and lowers to cq_template_fma_f80_*.
     copysignl and copysign are ALSO keeps (they fold to @llvm.copysign.f80 /
     @llvm.copysign.f64 at -O1, measured on this host) and reach the slice
     through scalbnl's overflow/underflow arms; both are spelled as builtins.
     An earlier draft of this slice VENDORED openlibm's software s_copysignl.c /
     s_copysign.c bodies there, inherited from slice_libm_real_erfl.c. That was a
     Rule-18 violation and it was live, not dead code: removing it changes the
     trace, so the slice had been modelling a program the ship floor never
     compiles — exactly the class of error bd 3c6m.60 fixed at the census level.
     Caught by the bd q2wk faithfulness audit; 47 other committed slices still
     carry the same block (bd tkju).
     logl / log1pl / frexpl / scalbnl / __polevll / __p1evll / __isnanl are
     LIBRARY functions and are therefore vendored as SOURCE — none of them is
     __builtin_'d.

   LOWERING EXERCISED (every figure below MEASURED on the lowered IR / trace):
     Pre-pass @slice (stage 1, plain clang -O1): 119 basic blocks (118 labeled +
     entry), 115 `br` of which 55 are conditional, plus 3 `switch` (the three
     olm_frexpl exponent switches — one per log-family inline), and 12 rolled
     single-block loops (each block branches to itself), each carrying exactly 1
     @llvm.fmuladd.f80: the __polevll/__p1evll Horner do/whiles, 4 per log-family
     inline x 3 inlines. Stage-1 llvm call sites: 31 @llvm.fmuladd.f80,
     2 @llvm.sqrt.f80, 4 @llvm.copysign (2 .f80 + 2 .f64, from scalbnl's
     overflow/underflow arms), 15+15 lifetime.start/end.
     THE E2 ACYCLICITY RISK DID NOT FIRE: all 12 loops are force-unrolled and
     lowered @slice has 2 blocks, exactly 1 `br` (unconditional, into the measure
     block), 0 conditional `br`, 0 `switch`, 0 loops. The unroll is visible as an
     EXACT arithmetic identity on the fma keeps: 31 stage-1 fmuladd sites - 12
     in-loop sites = 19 straight-line, and lowered @slice has 70
     cq_template_fma_f80_* CALL SITES, of which 67 = 19 + 48 are reached at
     runtime (48 = the sum of the 12 trip counts = 3 log-family inlines x
     (3 + 2 + 6 + 5); the 3 unreached sites sit on a speculated arm the trace
     never prints). Nothing was dropped: the 2 @llvm.sqrt.f80 lower 1:1 to 2
     cq_template_sqrt_f80 calls (one per acoshl sqrt arm — BOTH arms survive -O1
     and BOTH are lowered), and the 4 @llvm.copysign lower to
     cq_template_copysign_f80_lh / _f64_lh (2 of each reached).
     Trace (3934 lines, byte-identical across 2 consecutive runs):
       cqrt_alloc_f80 62 · cqrt_alloc_i1 365 · cqrt_alloc_i32 22 ·
       cqrt_alloc_i64 3   (452 allocations total)
       cqrt_ry_f80 1 · cqrt_measure_f80 1
       cqrt_toffoli 730 · cqrt_cnot 432 · cqrt_x 146 · cqrt_free 757
       cqrt_copy_f80_controlled 108 · cqrt_copy_i32_controlled 32 ·
       cqrt_copy_i64_controlled 6   (the kjd1 fp select-copy family carrying the
       flattened five-arm acoshl ladder + both log-family arm splits)
       1269 cq_template_* lines over 74 distinct template symbols, including the
       Rule-18 keeps cq_template_sqrt_f80 x2, cq_template_copysign_f80_lh x2 +
       _f64_lh x2, and cq_template_fma_f80_qql 42 / _qlq 15 / _qll 10 (=67),
       and the fp80 union promotion web
       cq_template_bitcast_f80_to_i80 28 / trunc_i80_to_i16 28 /
       zext_i16_to_i64 28 / lshr_i80_hl 29.
       ZERO cqrt_qram* lines: every coefficient read (P/Q/R/S x2 tables) const-
       folds after the unroll, so no QROM is minted.
     The lowered module has ZERO residual @cq_* intrinsic calls and ZERO @llvm.*
     CALL SITES — but a few now-unused `declare @llvm.*` lines (lifetime.start/
     end, sqrt.f80, fmuladd.f80, copysign.f80/.f64) do survive with no uses, so a
     bare grep for @llvm. is not a refutation of that claim.
   This slice is the LINK-layer proof (Rule 2) that every emitted symbol
   resolves, signature-matches, and the trace is stable and deterministic. */
#include <stdint.h>

typedef unsigned int u_int32_t;

/* src/math_private_openbsd.h — the LP64 little-endian ld80 word union +
   GET_LDOUBLE_WORDS (verbatim; x86-64 is always little-endian). */
typedef union
{
  long double value;
  struct {
    u_int32_t lsw;
    u_int32_t msw;
    int exp:16;
    int padl:16;
    int padh:32;
  } parts;
} ieee_extended_shape_type;

#define GET_LDOUBLE_WORDS(se,ix0,ix1,d)				\
do {								\
  ieee_extended_shape_type ew_u;				\
  ew_u.value = (d);						\
  (se) = ew_u.parts.exp;					\
  (ix0) = ew_u.parts.msw;					\
  (ix1) = ew_u.parts.lsw;					\
} while (0)

/* src/amd64_fpmath.h — union IEEEl2bits + LDBL_NBIT + mask_nbit_l (verbatim —
   BOTH views; used by olm_isnanl, olm_scalbnl, olm_frexpl via .bits/.e). */
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
#define LDBL_NBIT       0x80000000
#define mask_nbit_l(u)  ((u).bits.manh &= ~LDBL_NBIT)

/* src/s_isnan.c __isnanl (verbatim). */
__attribute__((always_inline)) static inline int
olm_isnanl(long double e)
{
    union IEEEl2bits u;
    u.e = e;
    mask_nbit_l(u);
    return (u.bits.exp == 32767 && (u.bits.manl != 0 || u.bits.manh != 0));
}

/* src/polevll.c __polevll + __p1evll (verbatim). */
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

__attribute__((always_inline)) static inline long double
olm_p1evll(long double x, void *PP, int n)
{
	long double y;
	long double *P;

	P = (long double *)PP;
	n -= 1;
	y = x + *P++;
	do {
		y = y * x + *P++;
	} while (--n);

	return (y);
}

/* src/s_scalbnl.c scalbnl (verbatim; colliding tiny/huge uniquified scb_*).
   openlibm_strong_reference(scalbnl, ldexpl): ldexpl IS this body. */
static const long double
scb_huge = 0x1p16000L,
scb_tiny = 0x1p-16000L;

__attribute__((always_inline)) static inline long double
olm_scalbnl(long double x, int n) {
	union IEEEl2bits u;
	int k;
	u.e = x;
        k = u.bits.exp;				/* extract exponent */
        if (k==0) {				/* 0 or subnormal x */
            if ((u.bits.manh|u.bits.manl)==0) return x;	/* +-0 */
	    u.e *= 0x1p+128;
	    k = u.bits.exp - 128;
            if (n< -50000) return scb_tiny*x; 	/*underflow*/
	    }
        if (k==0x7fff) return x+x;		/* NaN or Inf */
        k = k+n;
        if (k >= 0x7fff) return scb_huge*__builtin_copysignl(scb_huge,x); /* overflow  */
        if (k > 0) 				/* normal result */
	    {u.bits.exp = k; return u.e;}
        if (k <= -128) {
            if (n > 50000) 	/* in case integer overflow in n+k */
		return scb_huge*__builtin_copysign(scb_huge,x);	/*overflow*/
	    else return scb_tiny*__builtin_copysign(scb_tiny,x); 	/*underflow*/
        }
	k += 128;				/* subnormal result */
	u.bits.exp = k;
        return u.e*0x1p-128;
}

/* src/s_frexpl.c frexpl (verbatim; the LDBL_MAX_EXP #error guard deleted). */
__attribute__((always_inline)) static inline long double
olm_frexpl(long double x, int *ex)
{
	union IEEEl2bits u;

	u.e = x;
	switch (u.bits.exp) {
	case 0:		/* 0 or subnormal */
		if ((u.bits.manl | u.bits.manh) == 0) {
			*ex = 0;
		} else {
			u.e *= 0x1.0p514;
			*ex = u.bits.exp - 0x4200;
			u.bits.exp = 0x3ffe;
		}
		break;
	case 0x7fff:	/* infinity or NaN; value of *ex is unspecified */
		break;
	default:	/* normal */
		*ex = u.bits.exp - 0x3ffe;
		u.bits.exp = 0x3ffe;
		break;
	}
	return (u.e);
}

/* ld80/e_logl.c logl + its coefficient tables (verbatim; the file-scope
   P/Q/R/S/C1/C2/SQRTH names uniquified _logl because s_log1pl.c below declares
   its own identically-named set). */
static long double P_logl[] = {
 4.5270000862445199635215E-5L,
 4.9854102823193375972212E-1L,
 6.5787325942061044846969E0L,
 2.9911919328553073277375E1L,
 6.0949667980987787057556E1L,
 5.7112963590585538103336E1L,
 2.0039553499201281259648E1L,
};
static long double Q_logl[] = {
/* 1.0000000000000000000000E0,*/
 1.5062909083469192043167E1L,
 8.3047565967967209469434E1L,
 2.2176239823732856465394E2L,
 3.0909872225312059774938E2L,
 2.1642788614495947685003E2L,
 6.0118660497603843919306E1L,
};

static long double R_logl[4] = {
 1.9757429581415468984296E-3L,
-7.1990767473014147232598E-1L,
 1.0777257190312272158094E1L,
-3.5717684488096787370998E1L,
};
static long double S_logl[4] = {
/* 1.00000000000000000000E0L,*/
-2.6201045551331104417768E1L,
 1.9361891836232102174846E2L,
-4.2861221385716144629696E2L,
};
static const long double C1_logl = 6.9314575195312500000000E-1L;
static const long double C2_logl = 1.4286068203094172321215E-6L;

#define SQRTH_logl 0.70710678118654752440L

__attribute__((always_inline)) static inline long double
olm_logl(long double x)
{
long double y, z;
int e;

if( olm_isnanl(x) )
	return(x);
if( x == __builtin_inff() )
	return(x);
/* Test for domain */
if( x <= 0.0L )
	{
	if( x == 0.0L )
		return( -__builtin_inff() );
	else
		return( __builtin_nanf("") );
	}

/* separate mantissa from exponent */

/* Note, frexp is used so that denormal numbers
 * will be handled properly.
 */
x = olm_frexpl( x, &e );

/* logarithm using log(x) = z + z**3 P(z)/Q(z),
 * where z = 2(x-1)/x+1)
 */
if( (e > 2) || (e < -2) )
{
if( x < SQRTH_logl )
	{ /* 2( 2x-1 )/( 2x+1 ) */
	e -= 1;
	z = x - 0.5L;
	y = 0.5L * z + 0.5L;
	}
else
	{ /*  2 (x-1)/(x+1)   */
	z = x - 0.5L;
	z -= 0.5L;
	y = 0.5L * x  + 0.5L;
	}
x = z / y;
z = x*x;
z = x * ( z * olm_polevll( z, R_logl, 3 ) / olm_p1evll( z, S_logl, 3 ) );
z = z + e * C2_logl;
z = z + x;
z = z + e * C1_logl;
return( z );
}


/* logarithm using log(1+x) = x - .5x**2 + x**3 P(x)/Q(x) */

if( x < SQRTH_logl )
	{
	e -= 1;
	x = olm_scalbnl( x, 1 ) - 1.0L; /*  2x - 1  */
	}
else
	{
	x = x - 1.0L;
	}
z = x*x;
y = x * ( z * olm_polevll( x, P_logl, 6 ) / olm_p1evll( x, Q_logl, 6 ) );
y = y + e * C2_logl;
z = y - olm_scalbnl( z, -1 );   /*  y - 0.5 * z  */
/* Note, the sum of above terms does not exceed x/4,
 * so it contributes at most about 1/4 lsb to the error.
 */
z = z + x;
z = z + e * C1_logl; /* This sum has an error of 1/2 lsb. */
return( z );
}

/* ld80/s_log1pl.c log1pl + its coefficient tables (verbatim; the file-scope
   P/Q/R/S/C1/C2/SQRTH names uniquified _log1pl — see e_logl.c above). */
static long double P_log1pl[] = {
 4.5270000862445199635215E-5L,
 4.9854102823193375972212E-1L,
 6.5787325942061044846969E0L,
 2.9911919328553073277375E1L,
 6.0949667980987787057556E1L,
 5.7112963590585538103336E1L,
 2.0039553499201281259648E1L,
};
static long double Q_log1pl[] = {
/* 1.0000000000000000000000E0,*/
 1.5062909083469192043167E1L,
 8.3047565967967209469434E1L,
 2.2176239823732856465394E2L,
 3.0909872225312059774938E2L,
 2.1642788614495947685003E2L,
 6.0118660497603843919306E1L,
};

static long double R_log1pl[4] = {
 1.9757429581415468984296E-3L,
-7.1990767473014147232598E-1L,
 1.0777257190312272158094E1L,
-3.5717684488096787370998E1L,
};
static long double S_log1pl[4] = {
/* 1.00000000000000000000E0L,*/
-2.6201045551331104417768E1L,
 1.9361891836232102174846E2L,
-4.2861221385716144629696E2L,
};
static const long double C1_log1pl = 6.9314575195312500000000E-1L;
static const long double C2_log1pl = 1.4286068203094172321215E-6L;

#define SQRTH_log1pl 0.70710678118654752440L

__attribute__((always_inline)) static inline long double
olm_log1pl(long double xm1)
{
long double x, y, z;
int e;

if( olm_isnanl(xm1) )
	return(xm1);
if( xm1 == __builtin_inff() )
	return(xm1);
if(xm1 == 0.0)
	return(xm1);

x = xm1 + 1.0L;

/* Test for domain errors.  */
if( x <= 0.0L )
	{
	if( x == 0.0L )
		return( -__builtin_inff() );
	else
		return( __builtin_nanf("") );
	}

/* Separate mantissa from exponent.
   Use frexp so that denormal numbers will be handled properly.  */
x = olm_frexpl( x, &e );

/* logarithm using log(x) = z + z^3 P(z)/Q(z),
   where z = 2(x-1)/x+1)  */
if( (e > 2) || (e < -2) )
{
if( x < SQRTH_log1pl )
	{ /* 2( 2x-1 )/( 2x+1 ) */
	e -= 1;
	z = x - 0.5L;
	y = 0.5L * z + 0.5L;
	}
else
	{ /*  2 (x-1)/(x+1)   */
	z = x - 0.5L;
	z -= 0.5L;
	y = 0.5L * x  + 0.5L;
	}
x = z / y;
z = x*x;
z = x * ( z * olm_polevll( z, R_log1pl, 3 ) / olm_p1evll( z, S_log1pl, 3 ) );
z = z + e * C2_log1pl;
z = z + x;
z = z + e * C1_log1pl;
return( z );
}


/* logarithm using log(1+x) = x - .5x**2 + x**3 P(x)/Q(x) */

if( x < SQRTH_log1pl )
	{
	e -= 1;
	if (e != 0)
	  x = 2.0 * x - 1.0L;
	else
	  x = xm1;
	}
else
	{
	  if (e != 0)
	    x = x - 1.0L;
	  else
	    x = xm1;
	}
z = x*x;
y = x * ( z * olm_polevll( x, P_log1pl, 6 ) / olm_p1evll( x, Q_log1pl, 6 ) );
y = y + e * C2_log1pl;
z = y - 0.5 * z;
z = z + x;
z = z + e * C1_log1pl;
return( z );
}

/* ld80/e_acoshl.c acoshl (verbatim; logl→olm_logl, log1pl→olm_log1pl,
   sqrtl→__builtin_sqrtl (Rule-18 hardware keep)). */
static const long double
one	= 1.0,
ln2	= 6.931471805599453094287e-01L; /* 0x3FFE, 0xB17217F7, 0xD1CF79AC */

__attribute__((always_inline)) static inline long double
olm_acoshl(long double x)
{
	long double t;
	u_int32_t se,i0,i1;
	GET_LDOUBLE_WORDS(se,i0,i1,x);
	if(se<0x3fff || se & 0x8000) {	/* x < 1 */
	    return (x-x)/(x-x);
	} else if(se >=0x401d) {	/* x > 2**30 */
	    if(se >=0x7fff) {		/* x is inf of NaN */
		return x+x;
	    } else
		return olm_logl(x)+ln2;	/* acoshl(huge)=logl(2x) */
	} else if(((se-0x3fff)|i0|i1)==0) {
	    return 0.0;			/* acosh(1) = 0 */
	} else if (se > 0x4000) {	/* 2**28 > x > 2 */
	    t=x*x;
	    return olm_logl(2.0*x-one/(x+__builtin_sqrtl(t-one)));
	} else {			/* 1<x<2 */
	    t = x-one;
	    return olm_log1pl(t+__builtin_sqrtl(2.0*t+t*t));
	}
}

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);
    return cq_measure_f80(olm_acoshl(q));
}
int main(void) { (void) slice(); return 0; }
