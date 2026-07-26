/* slice_libm_real_logl.c — bd oudq (PredMux L6 Inc 6, the W6 stranded-merge
   claim witness): the REAL openlibm logl body over x86_fp80 `long double` —
   census cell logl.f80. This is the LINK-layer proof (Rule 2) for one of the
   three cells the W6 witness unblocked.

   WHY THIS CELL WAS BLOCKED — identical to log1pl.f80 and log2l.f80: `isnan(x)`
   (e_logl.c:122) inlines __isnanl to a 2-block diamond whose MERGE hosts
   `%isnan = phi i1 [ false, %entry ], [ %nan, %chk ]` OR-ed into that same
   block's own tainted branch (`isnan(x) || x == INFINITY`; the `x <= 0` domain
   test stays a SEPARATE downstream block). The
   downstream claim rooted at that merge left at `E6-condtree` (a phi in the
   region ENTRY is never converted — q2wk rule (A) condition 2) and the upstream
   diamond defining the phi left at `W-witness` (a sole 2-incoming NON-fp merge
   phi). W6 claims the upstream diamond, `convertPhis` rewrites the phi to the
   Inc-2 boolean algebra, and the body flattens on the next fixpoint round.

   CORPUS VENDORED (6 regions; the WHOLE closure — after the vendoring the slice
   calls no libm name at all, only clang-synthesized keeps). Every region is
   copied BYTE-FOR-BYTE from the committed, Rule-13-cleared
   slice_libm_real_acoshl.c — which vendored exactly this closure (acoshl calls
   logl) and is the tkju worked model for the copysign keep — so its per-file
   mechanical-edit ledger applies here unchanged:
     /private/tmp/openlibm_reclone/ld80/e_logl.c      — logl + its P/Q/R/S/C1/C2/
       SQRTH coefficient tables (names kept uniquified `*_logl` exactly as in the
       acoshl model, so the two files stay diff-identical region for region).
     /private/tmp/openlibm_reclone/src/polevll.c      — __polevll and __p1evll.
     /private/tmp/openlibm_reclone/src/s_frexpl.c     — frexpl (a BY-REF library
       function: Rule 18 requires it be vendored as SOURCE).
     /private/tmp/openlibm_reclone/src/s_scalbnl.c    — scalbnl, which is what
       logl's two `ldexpl(x,1)` / `ldexpl(z,-1)` sites resolve to (openlibm ships
       ldexpl ONLY as the assembler alias `.set ldexpl, scalbnl`). Its
       tiny/huge statics stay uniquified `scb_*`.
     /private/tmp/openlibm_reclone/src/s_isnan.c      — __isnanl (the sizeof
       dispatch of `isnan(x)` for a long double). THE CELL'S BLOCKER LIVES HERE.
     /private/tmp/openlibm_reclone/src/amd64_fpmath.h — union IEEEl2bits +
       LDBL_NBIT + mask_nbit_l, driven by __isnanl, frexpl and scalbnl.
   acoshl's two extra regions (ld80/e_acoshl.c and ld80/s_log1pl.c) are NOT in
   logl's closure and are dropped.

   (`#include <stdint.h>` is inherited verbatim from the acoshl model, where the
   dropped math_private_openbsd.h word union needs it; nothing in THIS closure uses
   a fixed-width integer type, so it is vestigial — kept only to hold the shared
   regions byte-identical to their source slice.)

   RULE 18 / bd tkju: copysignl and copysign are HARDWARE KEEPS on this target,
   so scalbnl's three call sites are spelled `__builtin_copysignl` /
   `__builtin_copysign` and openlibm's software s_copysignl.c / s_copysign.c
   bodies are NOT vendored — the acoshl model's fixed spelling, carried in from
   the start here rather than inherited and fixed later.

   The probe pins the census cell logl.f80: the single argument is theta-tainted
   (`cq_theta_f80(0.5L, 0.5)`), matching the census cell convention exactly. */
#include <stdint.h>

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
   P/Q/R/S/C1/C2/SQRTH names kept uniquified _logl to stay diff-identical with the
   acoshl model, where s_log1pl.c declares an identically-named set). */
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

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);
    return cq_measure_f80(olm_logl(q));
}
int main(void) { (void) slice(); return 0; }
