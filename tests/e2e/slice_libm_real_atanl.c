/* slice_libm_real_atanl.c — bd 3c6m.53 (real-openlibm VERIFIED promotion of the
   ld80 census cell atanl.f80, which COMPILES post the 20xt data-symbol closure):
   the REAL openlibm atanl body (ld80/s_atanl.c) over its full coefficient-table
   closure (ld80/invtrig.c: atanhi[4]/atanlo[4]/aT[13]; ld80/invtrig.h: the
   T_even/T_odd Horner helpers + the BIAS/ATAN_CONST/ATAN_LINEAR/MANH_SIZE
   thresholds; src/amd64_fpmath.h: union IEEEl2bits + LDBL_NBIT/LDBL_MANH_SIZE;
   FreeBSD/fdlibm-derived, BSD-licensed) over x86_fp80 `long double`.

   This slice is the LINK-layer proof (Rule 2) that atanl's emitted symbols —
   the i80 extract/field family for the union `xbits.expsign`/`bits.man*`
   decompositions, the cqrt_qram_* QROM reads of the two data-indexed coefficient
   tables (atanhi[id]/atanlo[id]; the whole point of the 20xt DATA-symbol closure
   — with the tables linked+initialized the tainted-index reads classify as QROM,
   the constant-index reads const-fold), the fp80 data selects of the argument-
   reduction ladder, the T_even/T_odd polynomial evaluation, and cq_template_fabs_f80
   (fabsl folds to @llvm.fabs.f80, a curated reversible intrinsic) — all resolve
   and the trace is stable+deterministic. The probe pins the census cell atanl.f80:
   x = theta-tainted. Data closure history: bd memory ld80-census-data-closure.

   NOTE (adia lesson): the plain -O1 ship floor DIFFERS from the census O2 model —
   the census force-inlines (always-inline + inline-threshold 2M) so T_even/T_odd
   and the reduction fold into one straight-line body; at plain -O1 the leaves may
   stay OUTLINED (Phase-6 spec-clone candidates, like coshl's expl). This is the
   authoritative floor per run_slice.sh (Rule 9); the census O2 measure is not.

   Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
   changed): includes/license deleted; the vendored macro closure inlined as
   #defines with their real openlibm values (LDBL_NBIT/LDBL_MANH_SIZE from
   src/amd64_fpmath.h, LDBL_MAX_EXP from <float.h>, BIAS/MANH_SIZE/ATAN_CONST/
   ATAN_LINEAR from ld80/invtrig.h); the public `atanl` entry renamed
   `olm_atanl`; the one libm builtin call `fabsl(x)` written `__builtin_fabsl(x)`
   (the coshl-slice convention for a hardware-backed keep-intrinsic — folds to
   the identical @llvm.fabs.f80); the invtrig.h `_ItL_*` table-name #defines
   resolved so the tables carry their body-visible names atanhi/atanlo/aT. The
   x86_fp80 union is kept VERBATIM — the promoteFp80Union pass owns it, never a
   memcpy word shim (3c6m.51 ld80 convention). */
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
#define LDBL_NBIT      0x80000000
#define LDBL_MANH_SIZE 32
#define LDBL_MAX_EXP   16384

/* openlibm ld80/invtrig.h thresholds (verbatim values). */
#define BIAS        (LDBL_MAX_EXP - 1)
#define MANH_SIZE   LDBL_MANH_SIZE
#define ATAN_CONST  (BIAS + 65)    /* 2**65  */
#define ATAN_LINEAR (BIAS - 32)    /* 2**-32 */

/* openlibm ld80/invtrig.c atanl() coefficient tables (verbatim ld80 values). */
static const long double atanhi[] = {
     4.63647609000806116202e-01L,
     7.85398163397448309628e-01L,
     9.82793723247329067960e-01L,
     1.57079632679489661926e+00L,
};

static const long double atanlo[] = {
     1.18469937025062860669e-20L,
    -1.25413940316708300586e-20L,
     2.55232234165405176172e-20L,
    -2.50827880633416601173e-20L,
};

static const long double aT[] = {
     3.33333333333333333017e-01L,
    -1.99999999999999632011e-01L,
     1.42857142857046531280e-01L,
    -1.11111111100562372733e-01L,
     9.09090902935647302252e-02L,
    -7.69230552476207730353e-02L,
     6.66661718042406260546e-02L,
    -5.88158892835030888692e-02L,
     5.25499891539726639379e-02L,
    -4.70119845393155721494e-02L,
     4.03539201366454414072e-02L,
    -2.91303858419364158725e-02L,
     1.24822046299269234080e-02L,
};

/* openlibm ld80/invtrig.h T_even/T_odd (verbatim). */
static inline long double
T_even(long double x)
{

	return (aT[0] + x * (aT[2] + x * (aT[4] + x * (aT[6] + x * \
		(aT[8] + x * (aT[10] + x * aT[12]))))));
}

static inline long double
T_odd(long double x)
{

	return (aT[1] + x * (aT[3] + x * (aT[5] + x * (aT[7] + x * \
		(aT[9] + x * aT[11])))));
}

/* openlibm ld80/s_atanl.c atanl (verbatim; fabsl -> __builtin_fabsl). */
static const long double
one   = 1.0,
huge   = 1.0e300;

static long double
olm_atanl(long double x)
{
	union IEEEl2bits u;
	long double w,s1,s2,z;
	int id;
	int16_t expsign, expt;
	int32_t expman;

	u.e = x;
	expsign = u.xbits.expsign;
	expt = expsign & 0x7fff;
	if(expt >= ATAN_CONST) {	/* if |x| is large, atan(x)~=pi/2 */
	    if(expt == BIAS + LDBL_MAX_EXP &&
	       ((u.bits.manh&~LDBL_NBIT)|u.bits.manl)!=0)
		return x+x;		/* NaN */
	    if(expsign>0) return  atanhi[3]+atanlo[3];
	    else     return -atanhi[3]-atanlo[3];
	}
	/* Extract the exponent and the first few bits of the mantissa. */
	/* XXX There should be a more convenient way to do this. */
	expman = (expt << 8) | ((u.bits.manh >> (MANH_SIZE - 9)) & 0xff);
	if (expman < ((BIAS - 2) << 8) + 0xc0) {	/* |x| < 0.4375 */
	    if (expt < ATAN_LINEAR) {	/* if |x| is small, atanl(x)~=x */
		if(huge+x>one) return x;	/* raise inexact */
	    }
	    id = -1;
	} else {
	x = __builtin_fabsl(x);
	if (expman < (BIAS << 8) + 0x30) {		/* |x| < 1.1875 */
	    if (expman < ((BIAS - 1) << 8) + 0x60) {	/* 7/16 <=|x|<11/16 */
		id = 0; x = (2.0*x-one)/(2.0+x);
	    } else {			/* 11/16<=|x|< 19/16 */
		id = 1; x  = (x-one)/(x+one);
	    }
	} else {
	    if (expman < ((BIAS + 1) << 8) + 0x38) {	/* |x| < 2.4375 */
		id = 2; x  = (x-1.5)/(one+1.5*x);
	    } else {			/* 2.4375 <= |x| < 2^ATAN_CONST */
		id = 3; x  = -1.0/x;
	    }
	}}
    /* end of argument reduction */
	z = x*x;
	w = z*z;
    /* break sum aT[i]z**(i+1) into odd and even poly */
	s1 = z*T_even(w);
	s2 = w*T_odd(w);
	if (id<0) return x - x*(s1+s2);
	else {
	    z = atanhi[id] - ((x*(s1+s2) - atanlo[id]) - x);
	    return (expsign<0)? -z:z;
	}
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_atanl(q));
}

int main(void) {
    (void) slice();
    return 0;
}
