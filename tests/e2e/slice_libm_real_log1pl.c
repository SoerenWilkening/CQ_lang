/* slice_libm_real_log1pl.c — bd oudq (PredMux L6 Inc 6, the W6 stranded-merge
   claim witness): the REAL openlibm log1pl body over x86_fp80 `long double` —
   census cell log1pl.f80. This is the LINK-layer proof (Rule 2) for one of the
   three cells the W6 witness unblocked.

   WHY THIS CELL WAS BLOCKED. Its `__isnanl` early-exit inlines to a 2-block
   diamond whose MERGE hosts `%isnan = phi i1 [ false, %entry ], [ %nan, %chk ]`
   OR-ed into that same block's own tainted branch (`isnan(x) || x == INFINITY ||
   x == 0`, s_log1pl.c:119-123 through s_isnan.c:63). The downstream claim rooted
   at that merge left at `E6-condtree` — a phi in the region ENTRY is never
   converted (q2wk rule (A) condition 2) — and the upstream diamond that defines
   the phi left at `W-witness` (a sole 2-incoming NON-fp merge phi). W6 claims
   the upstream diamond, `convertPhis` rewrites the phi to the Inc-2 boolean
   algebra, and the whole body flattens on the next fixpoint round.

   CORPUS VENDORED (5 regions; this is the WHOLE closure — after the vendoring
   below the slice calls no libm name at all). Every region is copied
   BYTE-FOR-BYTE from the committed, Rule-13-cleared slice_libm_real_atanhl.c,
   which vendored exactly this closure from the corpus and whose per-file
   mechanical-edit ledger applies here unchanged:
     /private/tmp/openlibm_reclone/ld80/s_log1pl.c    — log1pl + its P/Q/R/S/C1/
       C2/SQRTH coefficient tables (both exponent-range halves, including the
       e!=0 fallbacks to the raw xm1).
     /private/tmp/openlibm_reclone/src/polevll.c      — __polevll and __p1evll,
       the two Horner do/while evaluators log1pl drives.
     /private/tmp/openlibm_reclone/src/s_frexpl.c     — frexpl (log1pl's
       mantissa/exponent split; a BY-REF library function, so Rule 18 requires
       it be vendored as SOURCE, never spelled as a builtin).
     /private/tmp/openlibm_reclone/src/s_isnan.c      — __isnanl, which is what
       openlibm_math.h's sizeof-dispatch `isnan(x)` macro selects for a
       long double argument. THE CELL'S BLOCKER LIVES HERE.
     /private/tmp/openlibm_reclone/src/amd64_fpmath.h — union IEEEl2bits (both
       views) + LDBL_NBIT + mask_nbit_l, driven by __isnanl and frexpl.
   atanhl's two extra regions (ld80/e_atanhl.c and the
   src/math_private_openbsd.h word union + GET_LDOUBLE_WORDS/SET_LDOUBLE_EXP)
   are NOT in log1pl's closure and are dropped.

   MECHANICAL EDITS: exactly those declared in slice_libm_real_atanhl.c for the
   five shared regions — includes/license/weak_reference dropped, entry points
   renamed `olm_*` and marked `__attribute__((always_inline)) static inline`,
   `INFINITY`/`NAN` written as the `__builtin_inff()`/`__builtin_nanf("")` they
   expand to. NO constant, branch or expression is changed. (atanhl's
   `u_int32_t` -> `uint32_t` edit belongs to its math_private_openbsd.h word
   union, which is NOT in this closure.) The ld80 union is kept VERBATIM (never memcpy-shimmed): the pass's
   promoteFp80Union stage owns it (bd 3c6m.51).

   The probe pins the census cell log1pl.f80: the single argument is
   theta-tainted (`cq_theta_f80(0.5L, 0.5)`), matching the census cell
   convention exactly. */
#include <stdint.h>

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

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);
    return cq_measure_f80(olm_log1pl(q));
}
int main(void) { (void) slice(); return 0; }
