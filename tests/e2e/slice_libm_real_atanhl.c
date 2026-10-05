/* slice_libm_real_atanhl.c — bd q2wk (PredMux L6, inc 5): the REAL openlibm
   atanhl body over x86_fp80 `long double` — census cell atanhl.f80. This is the
   LINK-layer proof (Rule 2) for one of the 12 cells the E6 path-predicated
   branch-condition widening unblocked.

   CORPUS VENDORED (7 regions; this is the WHOLE closure — after the vendoring
   below the slice calls no libm name at all, only one clang-synthesized keep):
     /private/tmp/openlibm_reclone/ld80/e_atanhl.c    — atanhl, the entire body
       (the |x|>1 NaN arm, the |x|==1 x/zero arm, the x<2**-28 (huge+x)>zero
       early-out, the SET_LDOUBLE_EXP sign clear, and BOTH the x<0.5 and x>=0.5
       log1p reductions plus the final sign restore).
     /private/tmp/openlibm_reclone/ld80/s_log1pl.c    — log1pl + its P/Q/R/S/C1/
       C2/SQRTH coefficient tables (both exponent-range halves: the
       z + z^3 P(z)/Q(z) form for |e|>2 and the x - .5x^2 + x^3 P(x)/Q(x) form
       otherwise, including the e!=0 fallbacks to the raw xm1).
     /private/tmp/openlibm_reclone/src/polevll.c      — __polevll and __p1evll,
       the two Horner do/while evaluators log1pl drives.
     /private/tmp/openlibm_reclone/src/s_frexpl.c     — frexpl (log1pl's
       mantissa/exponent split; a BY-REF library function, so Rule 18 requires
       it be vendored as SOURCE, never spelled as a builtin).
     /private/tmp/openlibm_reclone/src/s_isnan.c      — __isnanl, which is what
       openlibm_math.h's sizeof-dispatch `isnan(x)` macro selects for a
       long double argument.
     /private/tmp/openlibm_reclone/src/amd64_fpmath.h — union IEEEl2bits (both
       views) + LDBL_NBIT + mask_nbit_l, driven by __isnanl and frexpl.
     /private/tmp/openlibm_reclone/src/math_private_openbsd.h —
       ieee_extended_shape_type + GET_LDOUBLE_WORDS + SET_LDOUBLE_EXP, driven by
       atanhl.

   MECHANICAL EDITS (declared per file, in corpus order; no algorithmic change —
   every constant, branch, comparison and expression is byte-for-byte the corpus
   text, diff-verified region by region against the corpus files):

   src/math_private_openbsd.h
     - kept exactly corpus lines 129-141 (the __FLOAT_WORD_ORDER__ ==
       __ORDER_LITTLE_ENDIAN__ ieee_extended_shape_type), 145-154
       (GET_LDOUBLE_WORDS + its comment) and 195-203 (SET_LDOUBLE_EXP + its
       comment). The enclosing `#if __FLOAT_WORD_ORDER__ …` / `#endif` guard and
       the big-endian twin union are not-taken preprocessor text on x86-64 and
       were dropped; the INNER `#ifdef __LP64__ int padh:32; #endif` is kept
       VERBATIM.
     - u_int32_t -> uint32_t (the 2 declarations `lsw`, `msw`); <stdint.h> added.
       No memcpy word shim is used anywhere in this slice: at ld80 the union IS
       the word access, and the pass's promoteFp80Union stage owns it.

   src/amd64_fpmath.h
     - union IEEEl2bits (corpus lines 29-44, BOTH the bits and xbits views) plus
       LDBL_NBIT (46) and mask_nbit_l (47) copied byte-for-byte. The license
       header and the trailing LDBL_MANH_SIZE / LDBL_MANL_SIZE /
       LDBL_TO_ARRAY32 (unused here) were dropped.

   src/s_isnan.c
     - deleted: the license header (lines 1-27), the 3 include lines (29,31,32),
       the two SIBLING entry points that are not in the atanhl closure — the
       `#if 1`-guarded `(isnan)(double)` over union IEEEd2bits (34-44) and
       `__isnanf` over union IEEEf2bits (46-53) — the `#ifdef OLM_LONG_DOUBLE` /
       `#endif` guard (55,65), the `OLM_DLLEXPORT int` storage line (56) and the
       trailing `openlibm_weak_reference(__isnanf, isnanf);` (67). The entry
       `__isnanl` is renamed olm_isnanl and marked
       `__attribute__((always_inline)) static inline`. Body lines 58-64 verbatim.

   src/s_frexpl.c
     - deleted: the license header (1-27), the 4 include lines (29,30,32,33),
       the `#if LDBL_MAX_EXP != 0x4000 / #error / #endif` guard (35-37) and
       `OLM_DLLEXPORT` (39). `frexpl` renamed olm_frexpl + always_inline static
       inline. Body lines 41-63 verbatim (the 3-way switch on u.bits.exp with
       the 0x1.0p514 subnormal scale and the 0x3ffe exponent write-back).

   src/polevll.c
     - deleted: the license/SCCS header and the polevll/p1evll prose comment
       (1-61), the 2 include lines (63,65) and the two interior
       "Polynomial evaluator:" comments (67-70 and 86-89).
       `__polevll` -> olm_polevll (body lines 73-84
       verbatim), `__p1evll` -> olm_p1evll (body lines 92-104 verbatim), both
       always_inline static inline. Each body declares a LOCAL `long double *P`
       which shadows the file-scope `P[]` table vendored below it; in the corpus
       these live in separate translation units, and C scoping makes the local
       shadow the file-scope name inside the function, so the behaviour is
       identical.

   ld80/s_log1pl.c
     - deleted: the license header (1-17), the log1pl prose comment (19-60) and
       the 2 include lines (62,64).
     - the coefficient block (corpus lines 66-111: the two comment blocks, P[],
       Q[], R[4], S[4], C1, C2 and `#define SQRTH`) is BYTE-IDENTICAL to the
       corpus — verified by diff, zero edits, no uniquifying rename needed
       (unlike the acoshl closure, this slice vendors only ONE log-family file,
       so nothing collides).
     - `log1pl` renamed olm_log1pl + always_inline static inline; body lines
       115-191 verbatim EXCEPT these declared renames/expansions:
         * `isnan(xm1)` -> `olm_isnanl(xm1)` (1 site) — openlibm_math.h:120's
           sizeof-dispatch macro resolves to __isnanl for `long double`.
         * `frexpl(` -> `olm_frexpl(` (1 site).
         * `__polevll(` -> `olm_polevll(` (2 sites), `__p1evll(` ->
           `olm_p1evll(` (2 sites).
         * `INFINITY` -> `__builtin_inff()` (2 sites, one of them `-INFINITY`)
           and `NAN` -> `__builtin_nanf("")` (1 site): these are the LITERAL
           macro bodies from include/openlibm_math.h:82-83 under
           __MATH_BUILTIN_CONSTANTS (defined unconditionally at line 62), i.e.
           compile-time CONSTANTS — NOT a Rule-18 builtin substitution of a
           library function.

   ld80/e_atanhl.c
     - deleted: the SCCS/license header (1-11), the atanhl Method/Special-cases
       prose comment (13-30) and the 2 include lines (32,33). There is no
       OLM_DLLEXPORT and no trailing weak/strong-reference block in this file.
     - the file-scope constants `one`/`huge` (line 35) and `zero` (line 37) are
       verbatim.
     - `atanhl` renamed olm_atanhl + always_inline static inline; body lines
       41-60 verbatim EXCEPT `u_int32_t se,i0,i1;` -> `uint32_t se,i0,i1;`
       (1 declaration) and `log1pl(` -> `olm_log1pl(` (2 sites).

   KEEP-SET CALLS (Rule 18):
     The atanhl closure calls NO named libm keep. In particular there is no
     fabsl site to fold: e_atanhl.c clears the sign with `SET_LDOUBLE_EXP(x,ix)`
     (a union exponent write-back), not with fabsl. MEASURED on the pre-pass
     IR: 0 @llvm.fabs.f80 and 0 @llvm.sqrt.f80 call sites.
     The one keep present is introduced by clang, not by the corpus text:
     clang -O1's default fp-contract fuses the Horner `y = y*x + *P++` products
     (and log1pl's `e*C1`/`e*C2` accumulations) into 22 @llvm.fmuladd.f80 call
     sites in the pre-pass @slice, which cq-lowering rewrites to
     cq_template_fma_f80_{qql,qlq,qll}. fma/fmuladd is a Rule-18 hardware keep
     (x86-64 SSE/FMA), so that fold is the ship floor, not a body substitution.
     Both frexpl and log1pl are LIBRARY functions and are vendored as source.

   LOWERING EXERCISED (every figure below MEASURED on the lowered IR / the
   golden; trace counts re-counted 2026-10-05; nothing asserted):
     Pre-pass @slice (clang -O1, the whole closure inlined into one function):
     56 basic blocks, 53 br of which 24 conditional, 2 switch, 38 phi, and
     8 NATURAL LOOPS — clang -O1 leaves the four __polevll/__p1evll Horner
     do/while loops ROLLED, once in each of log1pl's two exponent-range halves.
     Lowered @slice: 2 basic blocks, 1 unconditional br, 0 conditional br,
     0 phi, 0 loops — a straight line.
     Trace: 1459 lines, byte-identical across two consecutive runs.
     Exactly 1 cqrt_ry_f80 and exactly 1 cqrt_measure_f80 — the sole user-written
     rotation and the sole user-written measurement (Rule 5: the compiler
     inserted none).
     Rails: 136 cqrt_alloc (90 _i1 flag rails + 32 _f80 + 12 _i32 + 2 _i64) and
     335 cqrt_free.
     Control substrate: 180 cqrt_toffoli flag conjunctions, 80 cqrt_cnot,
     74 cqrt_x (the not-flag brackets), and 74 controlled-copy merges
     (54 cqrt_copy_f80_controlled + 16 cqrt_copy_i32_controlled +
     4 cqrt_copy_i64_controlled). Compares: 90 cq_template_icmp_* with 90
     matching _unc strips, 39 fcmp with 37 (the 2 unstripped olt feed a sext).
     The ld80 union work (GET_LDOUBLE_WORDS / SET_LDOUBLE_EXP / u.bits.exp and
     u.bits.man{l,h} reads and the exponent write-back) lowers through
     promoteFp80Union to 12 bitcast templates (9 f80_to_i80 + 3 i80_to_f80),
     12 lshr, 3 shl, 19 trunc, 11 zext, 2 sext, 22 and, 10 or and
     4 sitofp_i32_to_f80 (the `e * C1` / `e * C2` integer-exponent promotions).
     The 22 pre-pass @llvm.fmuladd.f80 call sites become 46 fma templates
     (28 _qql + 10 _qlq + 8 _qll). That 22 -> 46 growth is the pass UNROLLING
     the 8 Horner loops, NOT arm duplication: every non-loop fp opcode maps 1:1
     — 16 fmul -> 16 cq_template_fmul_f80{,_hl}, 21 fadd -> 21
     cq_template_fadd_f80{,_hl}, 10 fdiv -> 10 cq_template_fdiv_f80{,_hl},
     3 fsub -> 3, 1 fneg -> 1.
     The lowered module has ZERO residual @cq_* intrinsic calls and ZERO @llvm.*
     CALL SITES; 3 now-unused `declare @llvm.*` lines (lifetime.start/end,
     fmuladd.f80) do survive with no uses, so a bare grep for @llvm. is not a
     refutation of that claim. */
#include <stdint.h>

/* src/math_private_openbsd.h — the LP64 little-endian ld80 word union +
   GET_LDOUBLE_WORDS + SET_LDOUBLE_EXP (verbatim; the outer
   __FLOAT_WORD_ORDER__ guard dropped — x86-64 is always little-endian). */
typedef union
{
  long double value;
  struct {
    uint32_t lsw;
    uint32_t msw;
    int exp:16;
    int padl:16;
#ifdef __LP64__
    int padh:32;
#endif
  } parts;
} ieee_extended_shape_type;

/* Get three 32 bit ints from a double.  */

#define GET_LDOUBLE_WORDS(se,ix0,ix1,d)				\
do {								\
  ieee_extended_shape_type ew_u;				\
  ew_u.value = (d);						\
  (se) = ew_u.parts.exp;					\
  (ix0) = ew_u.parts.msw;					\
  (ix1) = ew_u.parts.lsw;					\
} while (0)

/* Set exponent of a long double from an int.  */

#define SET_LDOUBLE_EXP(d,se)					\
do {								\
  ieee_extended_shape_type se_u;				\
  se_u.value = (d);						\
  se_u.parts.exp = (se);					\
  (d) = se_u.value;						\
} while (0)

/* src/amd64_fpmath.h — union IEEEl2bits (verbatim, both views) + LDBL_NBIT +
   mask_nbit_l; the ld80 pass stage promoteFp80Union owns this union. */
union IEEEl2bits {
	long double	e;
	struct {
		unsigned int	manl	:32;
		unsigned int	manh	:32;
		unsigned int	exp	:15;
		unsigned int	sign	:1;
		unsigned int	junkl	:16;
		unsigned int	junkh	:32;
	} bits;
	struct {
		unsigned long	man	:64;
		unsigned int	expsign	:16;
		unsigned long	junk	:48;
	} xbits;
};

#define	LDBL_NBIT	0x80000000
#define	mask_nbit_l(u)	((u).bits.manh &= ~LDBL_NBIT)

/* src/s_isnan.c __isnanl -> olm_isnanl (verbatim body). */
__attribute__((always_inline)) static inline int
olm_isnanl(long double e)
{
	union IEEEl2bits u;

	u.e = e;
	mask_nbit_l(u);
	return (u.bits.exp == 32767 && (u.bits.manl != 0 || u.bits.manh != 0));
}

/* src/s_frexpl.c frexpl -> olm_frexpl (verbatim body). */
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

/* src/polevll.c __polevll -> olm_polevll, __p1evll -> olm_p1evll (verbatim
   bodies, including the do/while Horner loops). */
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

/* ld80/s_log1pl.c — coefficient tables (verbatim) + log1pl -> olm_log1pl. */
/* Coefficients for log(1+x) = x - x^2 / 2 + x^3 P(x)/Q(x)
 * 1/sqrt(2) <= x < sqrt(2)
 * Theoretical peak relative error = 2.32e-20
 */

static long double P[] = {
 4.5270000862445199635215E-5L,
 4.9854102823193375972212E-1L,
 6.5787325942061044846969E0L,
 2.9911919328553073277375E1L,
 6.0949667980987787057556E1L,
 5.7112963590585538103336E1L,
 2.0039553499201281259648E1L,
};
static long double Q[] = {
/* 1.0000000000000000000000E0,*/
 1.5062909083469192043167E1L,
 8.3047565967967209469434E1L,
 2.2176239823732856465394E2L,
 3.0909872225312059774938E2L,
 2.1642788614495947685003E2L,
 6.0118660497603843919306E1L,
};

/* Coefficients for log(x) = z + z^3 P(z^2)/Q(z^2),
 * where z = 2(x-1)/(x+1)
 * 1/sqrt(2) <= x < sqrt(2)
 * Theoretical peak relative error = 6.16e-22
 */

static long double R[4] = {
 1.9757429581415468984296E-3L,
-7.1990767473014147232598E-1L,
 1.0777257190312272158094E1L,
-3.5717684488096787370998E1L,
};
static long double S[4] = {
/* 1.00000000000000000000E0L,*/
-2.6201045551331104417768E1L,
 1.9361891836232102174846E2L,
-4.2861221385716144629696E2L,
};
static const long double C1 = 6.9314575195312500000000E-1L;
static const long double C2 = 1.4286068203094172321215E-6L;

#define SQRTH 0.70710678118654752440L

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
if( x < SQRTH )
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
z = x * ( z * olm_polevll( z, R, 3 ) / olm_p1evll( z, S, 3 ) );
z = z + e * C2;
z = z + x;
z = z + e * C1;
return( z );
}


/* logarithm using log(1+x) = x - .5x**2 + x**3 P(x)/Q(x) */

if( x < SQRTH )
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
y = x * ( z * olm_polevll( x, P, 6 ) / olm_p1evll( x, Q, 6 ) );
y = y + e * C2;
z = y - 0.5 * z;
z = z + x;
z = z + e * C1;
return( z );
}

/* ld80/e_atanhl.c — file-scope constants (verbatim) + atanhl -> olm_atanhl. */
static const long double one = 1.0, huge = 1e4900L;

static const long double zero = 0.0;

__attribute__((always_inline)) static inline long double
olm_atanhl(long double x)
{
	long double t;
	int32_t ix;
	uint32_t se,i0,i1;
	GET_LDOUBLE_WORDS(se,i0,i1,x);
	ix = se&0x7fff;
	if ((ix+((((i0&0x7fffffff)|i1)|(-((i0&0x7fffffff)|i1)))>>31))>0x3fff)
	  /* |x|>1 */
	    return (x-x)/(x-x);
	if(ix==0x3fff)
	    return x/zero;
	if(ix<0x3fe3&&(huge+x)>zero) return x;	/* x<2**-28 */
	SET_LDOUBLE_EXP(x,ix);
	if(ix<0x3ffe) {		/* x < 0.5 */
	    t = x+x;
	    t = 0.5*olm_log1pl(t+t*x/(one-x));
	} else
	    t = 0.5*olm_log1pl((x+x)/(one-x));
	if(se<=0x7fff) return t; else return -t;
}

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);
    return cq_measure_f80(olm_atanhl(q));
}
int main(void) { (void) slice(); return 0; }
