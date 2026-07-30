/* slice_libm_real_log10l.c — bd 0rwu (PredMux W7, the CONST-FALLTHROUGH integer
   sole-phi diamond): the REAL openlibm log10l body over x86_fp80 `long double` —
   census cell log10l.f80. The LINK-layer proof (Rule 2) for one of the two cells
   the W7 witness unblocked; slice_libm_real_expl.c is the other.

   WHY THIS CELL WAS BLOCKED. `isnan(x)` (ld80/e_log10l.c:128) inlines __isnanl,
   whose `&&` (src/s_isnan.c:63, col 30) `clang -O1` spells as a 2-block DIAMOND
   whose merge takes a CONSTANT on the entry edge:
       %isnan = phi i32 [ 0, %entry ], [ %zext, %arm ]
   That is a sole 2-incoming INTEGER merge phi, which W5 deliberately left to the
   4.2 value emitter — and the 4.2 emitter cannot take it either, because
   `ArmClassify` sets `Routed = StraightThrough` = the folded `0` and no accept
   path can match a `ConstantInt`. So the region declined
   `value-arm swap-route under quantum control` at ArmClassify.cpp:1171 with no
   owner anywhere. MEASURED (2026-07-30): log10l.f80 and expl.f80 are the ONLY
   two of the census's 123 cells that decline-anchor there. W7 claims the diamond
   for PredMux; the flatten reduces it to exactly the tainted `select` the
   4.4/kjd1 controlled-XOR copy merge has lowered all along.

   WHY THIS CELL AND NOT ITS SIBLING log2l. log2l.f80 has compiled since bd oudq
   (W6) and its slice is committed. The two bodies are the SAME Moshier log kernel
   and their P/Q/R/S tables are IDENTICAL values (verified byte-for-byte against
   the log2l slice). What differs — and an earlier draft under-stated this, which
   the Rule-13 round corrected, since this slice is entirely about control-flow
   shape — is FOUR things, not two:
     (1) prose/ACCURACY blocks;
     (2) the tail scaling constants (log10l's L102A/L102B/L10EA/L10EB and its
         6-term `done:` tail vs log2l's single LOG2EA and 5-term tail);
     (3) the domain-error SPELLINGS (log10l returns `-1.0L/(x-x)` and
         `(x-x)/(x-x)`; log2l returns the `-INFINITY`/`NAN` literals); AND
     (4) THE POSITION OF THE `x == INFINITY` EARLY RETURN IN THE CONTROL FLOW —
         e_log2l.c:125 puts it BEFORE the `x <= 0` domain test (:128) and returns
         `x`; e_log10l.c:138 puts it AFTER (`x <= 0` at :131) and returns
         `INFINITY`. The `volatile long double z` declaration also moves (:119 vs
         :125).
   What decides the two witnesses, though, is the shape of the ISNAN CONSUMER, and
   that is the whole story here. In log2l the
   merge phi is an i1 OR-ed into its own block's tainted branch, so it strands a
   downstream cond tree and W6 claims it. In log10l `isnan(x)` stands ALONE as
   `if (isnan(x)) return x;` — the domain test `x <= 0` is a separate downstream
   block, so nothing is stranded, W6 correctly does not fire, and the diamond sat
   ownerless until W7. Same source idiom, same file, two different witnesses:
   this pair is the clearest demonstration in the suite that the W witnesses
   partition by CONSUMER shape, not by function.

   CORPUS VENDORED (6 regions; the WHOLE closure — after the vendoring the slice
   calls no libm name at all, only clang-synthesized keeps). The five SHARED
   regions are copied BYTE-FOR-BYTE from the committed, Rule-13-cleared
   slice_libm_real_log2l.c, so its per-file mechanical-edit ledger applies to them
   unchanged:
     /private/tmp/openlibm/src/polevll.c      — __polevll and __p1evll.
     /private/tmp/openlibm/src/s_frexpl.c     — frexpl (a BY-REF library
       function: Rule 18 requires it be vendored as SOURCE).
     /private/tmp/openlibm/src/s_scalbnl.c    — scalbnl, which is what log10l's
       two `ldexpl(x,1)` / `ldexpl(z,-1)` sites resolve to (openlibm ships ldexpl
       ONLY as the assembler alias `.set ldexpl, scalbnl`). Its tiny/huge statics
       stay uniquified `scb_*`.
     /private/tmp/openlibm/src/s_isnan.c      — __isnanl (the sizeof dispatch of
       `isnan(x)` for a long double). THE CELL'S BLOCKER LIVES HERE.
     /private/tmp/openlibm/src/amd64_fpmath.h — union IEEEl2bits + LDBL_NBIT +
       mask_nbit_l, driven by __isnanl, frexpl and scalbnl.
   The SIXTH region is new to this slice and was vendored directly from the
   corpus (verified at 82e90ae, byte-identical to the openlibm_reclone the earlier
   ld80 slices were vendored from), diff-verified line by line against it:
     /private/tmp/openlibm/ld80/e_log10l.c    — log10l + its OWN P/Q/R/S tables
       and its OWN tail constants L102A/L102B/L10EA/L10EB (log2l has a single
       LOG2EA instead, and a 5-term `done:` tail where log10l has 6).
       MECHANICAL EDITS (no algorithmic change): the license header and the
       log10l.c prose/ACCURACY/ERROR-MESSAGES comment block, the two `#include`
       lines and the `OLM_DLLEXPORT` storage line are deleted; the entry `log10l`
       is renamed `olm_log10l` and marked
       `__attribute__((always_inline)) static inline`; the file-scope
       P/Q/R/S/SQRTH names are uniquified `*_log10l` (the log2l model's
       convention); `isnan` -> `olm_isnanl`, `frexpl` -> `olm_frexpl`,
       `__polevll`/`__p1evll` -> `olm_polevll`/`olm_p1evll`, `ldexpl` ->
       `olm_scalbnl` (the strong-reference alias, per the ldexpl slice
       precedent); `INFINITY` is written as the `__builtin_inff()` it expands to.
       Every constant, branch, comparison, expression and the `goto done` control
       flow are the corpus text. NOTE the domain arms are log10l's OWN
       `-1.0L / (x - x)` and `(x - x) / (x - x)` — NOT log2l's `-INFINITY`/`NAN`
       literals. They are kept verbatim; substituting log2l's spelling here would
       model a different program.

   VOLATILE: e_log10l.c declares `volatile long double z` (the Moshier
   "***CAUTION***" anti-reassociation idiom) and this slice keeps it VERBATIM —
   it is what bd zco4's promoteVolatileScalarLocals stage exists to promote, and
   removing it would model a different program.

   KEEP-SET CALLS (bd tkju — Rule 18 ship-floor fold): copysignl/copysign
   (scalbnl's overflow/underflow arms) are HARDWARE KEEPS, spelled
   __builtin_<fn> so the intrinsic is named without a libm declaration.

   (`#include <stdint.h>` is inherited verbatim from the log2l model, where the
   dropped math_private_openbsd.h word union needs it; nothing in THIS closure
   uses a fixed-width integer type, so it is vestigial — kept only to hold the
   shared regions byte-identical to their source slice.)

   The probe pins the census cell log10l.f80: the single argument is
   theta-tainted (`cq_theta_f80(0.5L, 0.5)`), matching the census cell convention
   exactly. */
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

/* ld80/e_log10l.c log10l + its coefficient tables (verbatim; the file-scope
   P/Q/R/S/SQRTH names uniquified _log10l, matching the log2l model's
   convention). */
/* Coefficients for log(1+x) = x - x**2/2 + x**3 P(x)/Q(x)
 * 1/sqrt(2) <= x < sqrt(2)
 * Theoretical peak relative error = 6.2e-22
 */
static long double P_log10l[] = {
 4.9962495940332550844739E-1L,
 1.0767376367209449010438E1L,
 7.7671073698359539859595E1L,
 2.5620629828144409632571E2L,
 4.2401812743503691187826E2L,
 3.4258224542413922935104E2L,
 1.0747524399916215149070E2L,
};
static long double Q_log10l[] = {
/* 1.0000000000000000000000E0,*/
 2.3479774160285863271658E1L,
 1.9444210022760132894510E2L,
 7.7952888181207260646090E2L,
 1.6911722418503949084863E3L,
 2.0307734695595183428202E3L,
 1.2695660352705325274404E3L,
 3.2242573199748645407652E2L,
};

/* Coefficients for log(x) = z + z^3 P(z^2)/Q(z^2),
 * where z = 2(x-1)/(x+1)
 * 1/sqrt(2) <= x < sqrt(2)
 * Theoretical peak relative error = 6.16e-22
 */
static long double R_log10l[4] = {
 1.9757429581415468984296E-3L,
-7.1990767473014147232598E-1L,
 1.0777257190312272158094E1L,
-3.5717684488096787370998E1L,
};
static long double S_log10l[4] = {
/* 1.00000000000000000000E0L,*/
-2.6201045551331104417768E1L,
 1.9361891836232102174846E2L,
-4.2861221385716144629696E2L,
};
/* log10(2) */
#define L102A 0.3125L
#define L102B -1.1470004336018804786261e-2L
/* log10(e) */
#define L10EA 0.5L
#define L10EB -6.5705518096748172348871e-2L

#define SQRTH_log10l 0.70710678118654752440L

__attribute__((always_inline)) static inline long double
olm_log10l(long double x)
{
long double y;
volatile long double z;
int e;

if( olm_isnanl(x) )
	return(x);
/* Test for domain */
if( x <= 0.0L )
	{
	if( x == 0.0L )
		return (-1.0L / (x - x));
	else
		return (x - x) / (x - x);
	}
if( x == __builtin_inff() )
	return(__builtin_inff());
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
if( x < SQRTH_log10l )
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
y = x * ( z * olm_polevll( z, R_log10l, 3 ) / olm_p1evll( z, S_log10l, 3 ) );
goto done;
}


/* logarithm using log(1+x) = x - .5x**2 + x**3 P(x)/Q(x) */

if( x < SQRTH_log10l )
	{
	e -= 1;
	x = olm_scalbnl( x, 1 ) - 1.0L; /*  2x - 1  */
	}	
else
	{
	x = x - 1.0L;
	}
z = x*x;
y = x * ( z * olm_polevll( x, P_log10l, 6 ) / olm_p1evll( x, Q_log10l, 7 ) );
y = y - olm_scalbnl( z, -1 );   /* -0.5x^2 + ... */

done:

/* Multiply log of fraction by log10(e)
 * and base 2 exponent by log10(2).
 *
 * ***CAUTION***
 *
 * This sequence of operations is critical and it may
 * be horribly defeated by some compiler optimizers.
 */
z = y * (L10EB);
z += x * (L10EB);
z += e * (L102B);
z += y * (L10EA);
z += x * (L10EA);
z += e * (L102A);

return( z );
}

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);
    return cq_measure_f80(olm_log10l(q));
}
int main(void) { (void) slice(); return 0; }
