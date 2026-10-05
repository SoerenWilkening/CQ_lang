/* slice_libm_real_asinhl.c — bd q2wk: the REAL openlibm asinhl (x86_fp80) body.

   CORPUS VENDORED (9 files — 7 .c bodies + 2 headers; this is the WHOLE
   closure. After the Rule-18 keep rewrite below the vendored text calls nothing
   but other vendored bodies and hardware keeps — confirmed on the stage-1 IR,
   whose ONLY external `declare`s are @cq_theta_f80 / @cq_measure_f80 and the
   @llvm.* keeps (fabs.f80, sqrt.f80, copysign.f80, copysign.f64, fmuladd.f80)
   plus the two @llvm.lifetime markers; no unvendored libm symbol survives):
     /private/tmp/openlibm_reclone/ld80/s_asinhl.c    — asinhl(x), the entire
       algorithm (the GET_LDOUBLE_EXP exponent-word classification, the inf/NaN
       arm, the |x|<2**-34 `huge+x>one` inexact arm, and all three magnitude
       arms: logl(|x|)+ln2 for |x|>2**34, logl(2|x|+1/(sqrtl(x*x+1)+|x|)) for
       2<|x|, log1pl(|x|+t/(1+sqrtl(1+t))) for |x|<2, plus the sign fixup).
     ld80/e_logl.c        — logl + its P/Q/R/S/C1/C2 coefficient tables
       (reached from two distinct asinhl arms).
     ld80/s_log1pl.c      — log1pl + its own identically-valued P/Q/R/S/C1/C2
       tables (reached from the third arm).
     src/s_frexpl.c       — frexpl (called by both logl and log1pl).
     src/s_scalbnl.c      — scalbnl (called twice by logl as `ldexpl`; see the
       strong-reference note below).
     src/polevll.c        — __polevll + __p1evll (the Horner kernels).
     src/s_isnan.c        — __isnanl (the `isnan(x)` macro's long-double leg).
     src/amd64_fpmath.h   — union IEEEl2bits (both views) + LDBL_NBIT +
       mask_nbit_l, and src/math_private_openbsd.h — ieee_extended_shape_type +
       GET_LDOUBLE_EXP.
   NOT vendored, deliberately: src/s_copysignl.c and src/s_copysign.c. scalbnl's
   overflow/underflow arms call copysignl/copysign, and copysign IS a Rule-18
   HARDWARE KEEP — vendoring openlibm's software bit-twiddling body for it would
   misrepresent the ship floor exactly the way vendoring s_fabs.c would (this is
   the census bug bd 3c6m.60 fixed). They are spelled as builtins; see KEEP-SET
   CALLS.

   MECHANICAL EDITS (declared, in corpus order per file; no algorithmic change —
   every constant, branch, comparison and expression is the corpus text):
     src/math_private_openbsd.h: kept ONLY the
       `__FLOAT_WORD_ORDER__ == __ORDER_LITTLE_ENDIAN__` spelling of
       ieee_extended_shape_type (x86-64 is little-endian, so the big-endian
       spelling is not-taken preprocessor text) and dropped the `#ifdef __LP64__`
       guard around `int padh:32;` (defined on x86-64, so the field is present);
       the unused GET/SET_LDOUBLE_WORDS / _MSW / SET_LDOUBLE_EXP macros and the
       trailing prototypes dropped; u_int32_t → uint32_t (stdint.h). The
       GET_LDOUBLE_EXP macro body itself is verbatim — an ld80 union READ, NOT a
       memcpy pun (memcpy shims are f32/f64-only; the pass's fp80-union stage
       owns this union).
     src/amd64_fpmath.h: FreeBSD license block deleted; union IEEEl2bits,
       LDBL_NBIT and mask_nbit_l verbatim; the unused LDBL_MANH_SIZE /
       LDBL_MANL_SIZE / LDBL_TO_ARRAY32 dropped.
     src/s_isnan.c: license/FBSDID + 3 includes deleted; the (isnan)(double) and
       __isnanf bodies and the trailing openlibm_weak_reference dropped (not in
       this closure); the `#ifdef OLM_LONG_DOUBLE` guard (taken on x86-64) and
       OLM_DLLEXPORT dropped; __isnanl renamed olm_isnanl, marked
       always_inline static inline.
     src/polevll.c: license/prose + 2 includes deleted; __polevll/__p1evll
       renamed olm_polevll/olm_p1evll, marked always_inline static inline.
     src/s_scalbnl.c: license/prose + 5 includes deleted; the
       `#if LDBL_MAX_EXP != 0x4000 #error` guard deleted (not taken on x86-64);
       OLM_DLLEXPORT deleted; the trailing
       `openlibm_strong_reference(scalbnl, ldexpl)` deleted — declared here
       instead: ldexpl IS this body, which is why e_logl.c's two `ldexpl(...)`
       calls are spelled olm_scalbnl below; the file-scope `huge`/`tiny`
       uniquified to `scb_huge`/`scb_tiny` because s_asinhl.c declares its own
       `huge`; scalbnl renamed olm_scalbnl, always_inline static inline;
       copysignl/copysign → __builtin_copysignl/__builtin_copysign (keep-set).
     src/s_frexpl.c: license/FBSDID + 4 includes deleted; the
       `#if LDBL_MAX_EXP != 0x4000 #error` guard deleted; OLM_DLLEXPORT deleted;
       frexpl renamed olm_frexpl, always_inline static inline.
     ld80/e_logl.c: OpenBSD copyright block + the logl.c SYNOPSIS/DESCRIPTION/
       ACCURACY prose deleted; 2 includes deleted; the two coefficient-table
       header comments deleted (the commented-out leading `1.0` entries inside
       the Q and S initializers are KEPT verbatim — they are load-bearing
       documentation of p1evll's implicit leading coefficient); the file-scope
       P/Q/R/S/C1/C2/SQRTH names uniquified with a `_logl` suffix because
       s_log1pl.c below declares an identically-named set; logl renamed
       olm_logl, always_inline static inline; `isnan(x)` → olm_isnanl(x)
       (openlibm_math.h's isnan macro dispatches long double to __isnanl);
       INFINITY → __builtin_inff() and NAN → __builtin_nanf("") (those are
       verbatim what openlibm_math.h lines 82-83 define them to be);
       frexpl → olm_frexpl; __polevll/__p1evll → olm_polevll/olm_p1evll;
       ldexpl → olm_scalbnl (the strong-reference alias above).
     ld80/s_log1pl.c: same treatment — license + prose + includes + table
       comments deleted, P/Q/R/S/C1/C2/SQRTH uniquified with a `_log1pl` suffix,
       log1pl renamed olm_log1pl always_inline static inline, isnan/INFINITY/NAN/
       frexpl/__polevll/__p1evll renamed as above. Note log1pl does NOT call
       ldexpl (its `y - 0.5 * z` is the corpus text, not a substitution).
     ld80/s_asinhl.c: the SCCS/Sun copyright block and the asinhl Method comment
       deleted; 2 includes deleted; the `one`/`ln2`/`huge` file-scope constants
       and their bit-pattern comments kept verbatim; asinhl renamed olm_asinhl,
       always_inline static inline (this forces the census inline shape at plain
       -O1: the entire 9-file closure collapses into ONE function, @slice);
       logl → olm_logl and log1pl → olm_log1pl; fabsl/sqrtl → the keep builtins.
       There is no OLM_DLLEXPORT and no trailing weak/strong reference in this
       corpus file, so none was removed.
   Note on the uniquified tables: because {P,Q,R,S}_logl and {P,Q,R,S}_log1pl
   have byte-identical initializers, LLVM's GlobalOpt/ConstMerge merges them back
   into a single internal constant global set at -O1 (MEASURED: the pre-pass IR
   contains exactly four tables, @{P,Q,R,S}_log1pl). The uniquification is
   therefore provably semantics-free.

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution):
     - fabsl, 3 source sites in s_asinhl.c (one per magnitude arm) → spelled
       __builtin_fabsl → clang -O1 emits @llvm.fabs.f80 → cq_template_fabs_f80.
       MEASURED 3 → 3 → 3 (source sites → pre-pass call sites → trace lines).
     - sqrtl, 2 source sites in s_asinhl.c → __builtin_sqrtl → @llvm.sqrt.f80 →
       cq_template_sqrt_f80. MEASURED 2 → 2 → 2. BOTH arms survive -O1; neither
       was folded away.
     - copysignl / copysign, reached only from olm_scalbnl's overflow and
       underflow arms → __builtin_copysignl / __builtin_copysign →
       @llvm.copysign.f80 / @llvm.copysign.f64 → cq_template_copysign_f80_lh /
       cq_template_copysign_f64_lh. MEASURED 2 + 2 pre-pass call sites → 2 + 2
       trace lines (clang -O1 prunes scalbnl arms whose `n` is a compile-time
       constant, so the scalbnl inlinings leave exactly this many live sites).
     - fma/fmuladd is a keep but appears in NO corpus text: clang's default
       fp-contract=on fuses the Horner step `y = y*x + *P++` and the
       `0.5*z + 0.5` forms into @llvm.fmuladd.f80. MEASURED 31 pre-pass call
       sites → 67 cq_template_fma_f80_{qll,qlq,qql} in the lowered module (see
       LOWERING EXERCISED for why that grows).
   Everything else in the closure is a LIBRARY function and is vendored as
   source, never __builtin_-ed: logl, log1pl, frexpl, scalbnl/ldexpl, __isnanl,
   __polevll, __p1evll.

   LOWERING EXERCISED (every figure below MEASURED on the lowered IR or the
   golden trace, re-counted 2026-10-05; nothing here is asserted):
   Pre-pass @slice is the whole closure inlined into one function: 115 labelled
   blocks, 112 br (54 of them conditional), 65 phi, 10 select, 66 load and 49
   getelementptr, and 12 REAL BACK-EDGE LOOPS — clang -O1 does not unroll the
   __polevll/__p1evll do-whiles, it leaves each as a counted loop with a pointer
   induction variable over the coefficient table (MEASURED: 3× @R_log1pl trip 3,
   3× @S_log1pl trip 2, 3× @P_log1pl trip 6, 3× @Q_log1pl trip 5 — three
   inlinings, because asinhl reaches logl from two arms and log1pl from a third).
   Lowered @slice is ONE straight line: 1 labelled block, 1 br (unconditional,
   into the measure block), 0 conditional br, 0 phi, 0 select, 0 load, 0
   getelementptr. The 3810-line trace is that straight line executed once, so
   every count below is simultaneously a static call-site count and a dynamic
   one.
     - Rotation/measure spine: trace line 1 is the cq_theta_f80 seed rail
       (the first of the 57 cqrt_alloc_f80), line 2 is the single cqrt_ry_f80,
       and the last line is the single cqrt_measure_f80. 0 cqrt_rz — no phase
       arm in this cell.
     - PredMux flatten substrate: 290 cqrt_alloc_i1 flag rails, 580
       cqrt_toffoli path conjunctions, 280 cqrt_cnot, 142 cqrt_x (¬flag
       brackets), 333 forward compare templates and 330 `_unc` strips (the 3
       unstripped fcmp_olt_f80_hl feed cq_template_sext_i1_to_i32 as DATA and
       stay allocated), and 142 controlled copies (104 cqrt_copy_f80_controlled
       + 32 cqrt_copy_i32_controlled + 6 cqrt_copy_i64_controlled) against
       the 65 phi + 10 select the pre-pass IR contained (a raw side-by-side of
       two measured numbers, not a per-merge ratio). 372 cqrt_alloc total
       (57 f80, 290 i1, 22 i32, 3 i64) against 884 cqrt_free. 0 cqrt_cswap.
     - Bounded-loop rollout: the 12 counted loops are rolled out to their trip
       counts and their const-global coefficient loads resolved to literals —
       which is exactly why the fma count grows. 31 pre-pass fmuladd sites split
       (MEASURED) into 19 straight-line sites and 12 loop-body sites; the 12
       loop bodies contribute 3×(3+2+6+5) = 48 iterations, and 19 + 48 = 67, the
       measured post-pass fma template count. The resolved coefficients show up
       as the literal operand of the _qql/_qlq/_qll forms.
     - Every OTHER stock fp opcode is lowered 1:1, nothing dropped and nothing
       duplicated: fmul 34 → 34 (19 QQ + 15 _hl), fadd 36 → 36 (13 + 23 _hl),
       fdiv 11 → 11 (10 + 1 _lh), fsub 2 → 2, fneg 1 → 1.
     - fp80 union traffic (the GET_LDOUBLE_EXP read plus IEEEl2bits in isnanl /
       frexpl / scalbnl) is promoted to word templates: 29
       cq_template_bitcast_f80_to_i80, 26 lshr_i80_hl, 26 trunc_i80_to_i16, 13
       and_i80_hl, 13 zext_i64_to_i80, 13 bitcast_i80_to_f80, 10
       trunc_i80_to_i64.
   The lowered module has ZERO residual @cq_* intrinsic calls and ZERO @llvm.*
   CALL SITES; 7 now-unused `declare @llvm.*` lines do survive with no uses, so a
   bare grep for @llvm. is not a refutation of that claim. The binary was run
   twice and the two traces are byte-identical. This slice is the LINK-layer
   proof (Rule 2) that every emitted symbol resolves and signature-matches. */
#include <stdint.h>

/* src/math_private_openbsd.h — the LP64 little-endian ld80 word union +
   GET_LDOUBLE_EXP (verbatim; x86-64 is always little-endian and __LP64__). */
typedef union
{
  long double value;
  struct {
    uint32_t lsw;
    uint32_t msw;
    int exp:16;
    int padl:16;
    int padh:32;
  } parts;
} ieee_extended_shape_type;

#define GET_LDOUBLE_EXP(se,d)					\
do {								\
  ieee_extended_shape_type ge_u;				\
  ge_u.value = (d);						\
  (se) = ge_u.parts.exp;					\
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

/* ld80/s_asinhl.c asinhl (verbatim; logl→olm_logl, log1pl→olm_log1pl,
   fabsl→__builtin_fabsl and sqrtl→__builtin_sqrtl (Rule-18 hardware keeps)). */
static const long double
one =  1.000000000000000000000e+00L, /* 0x3FFF, 0x00000000, 0x00000000 */
ln2 =  6.931471805599453094287e-01L, /* 0x3FFE, 0xB17217F7, 0xD1CF79AC */
huge=  1.000000000000000000e+4900L;

__attribute__((always_inline)) static inline long double
olm_asinhl(long double x)
{
	long double t,w;
	int32_t hx,ix;
	GET_LDOUBLE_EXP(hx,x);
	ix = hx&0x7fff;
	if(ix==0x7fff) return x+x;	/* x is inf or NaN */
	if(ix< 0x3fde) {	/* |x|<2**-34 */
	    if(huge+x>one) return x;	/* return x inexact except 0 */
	}
	if(ix>0x4020) {		/* |x| > 2**34 */
	    w = olm_logl(__builtin_fabsl(x))+ln2;
	} else if (ix>0x4000) {	/* 2**34 > |x| > 2.0 */
	    t = __builtin_fabsl(x);
	    w = olm_logl(2.0*t+one/(__builtin_sqrtl(x*x+one)+t));
	} else {		/* 2.0 > |x| > 2**-28 */
	    t = x*x;
	    w =olm_log1pl(__builtin_fabsl(x)+t/(one+__builtin_sqrtl(one+t)));
	}
	if(hx&0x8000) return -w; else return w;
}

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);
    return cq_measure_f80(olm_asinhl(q));
}
int main(void) { (void) slice(); return 0; }
