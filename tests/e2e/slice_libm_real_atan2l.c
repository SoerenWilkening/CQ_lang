/* slice_libm_real_atan2l.c — bd 20xt.6 (real-openlibm VERIFIED promotion of the
   ld80 census cell atan2l.f80, which COMPILES(spec-clone) post 20xt.5.2's inner-
   atanl clone-control coherent-escape bypass): the REAL openlibm atan2l body
   (src/e_atan2l.c) over its full inner-atanl closure (ld80/s_atanl.c: olm_atanl +
   ld80/invtrig.c: atanhi[4]/atanlo[4]/aT[13] + pi_lo; ld80/invtrig.h: the
   T_even/T_odd Horner helpers, the pio2_hi/pio2_lo = atanhi[3]/atanlo[3]
   aliases, and the BIAS/ATAN_CONST/ATAN_LINEAR/MANH_SIZE thresholds;
   src/amd64_fpmath.h: union IEEEl2bits + LDBL_NBIT/LDBL_MANH_SIZE;
   FreeBSD/fdlibm-derived, BSD-licensed) over x86_fp80 `long double`.

   This slice is the LINK-layer proof (Rule 2) that atan2l's emitted symbols —
   the i80 extract/field family for the union `xbits.expsign`/`bits.man*`
   decompositions of BOTH operands (ux/uy), the special-case/quadrant control
   ladder over the tainted y (m = 2*sign(x)+sign(y) route, the y=0/x=0/INF
   switch arms — all flattened by PredMux at plain -O1), and — the whole point of
   20xt.3/.4/.5.2 — the inner `olm_atanl(fabsl(y/x))` call lowered as a Phase-6
   spec CLONE with INTERNAL tainted control: atanl's argument-reduction cascade
   flattens under lowerCloneControl and its two data-indexed atanhi[id]/atanlo[id]
   QROM reads (cqrt_qram_*) coherently ESCAPE to the clone's non-main ret via the
   20xt.5.2 Bennett-clone bypass (sound: emitBennettWrap copies-out then reverse-
   plays the whole stream incl. the qram _unc). The probe pins the census cell
   atan2l.f80: y = theta-tainted, x = classical 0.5L (the census cell convention:
   arg0 tainted, other fp args 0.5).

   DE-RISK (bd 20xt.6, 2026-07-23): at plain clang -O1 the inner atanl range-id is
   the SAME multi-block phi with the 4294967295 sentinel (%id = phi i64 [0..],[1..],
   [2..],[3..],[-1..]) -> NeedsMask, which 20xt.5.2's coherent-escape bypass +
   20xt.7's pow2 mask handle; the fcmp-condition-select hazard (a DEFERRED
   lowerCloneSelect widening) was a synthetic 3-way-slice artifact, NOT the real
   5-way atanl, so it does NOT materialize here. This ticket is pure verification:
   opt-exit-0 + LINK + RUN deterministic -> flips atan2l COMPILES(spec-clone) ->
   VERIFIED.

   Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
   changed): includes/license/FBSDID deleted; the `#ifdef __i386__` pi1/pi2 gcc-
   truncation workaround #ifdef-guarded OUT (amd64 target -> the `#else` single
   `pi` const is live, the i386 branch is dead); the vendored macro closure
   inlined as #defines with their real openlibm values (LDBL_NBIT/LDBL_MANH_SIZE
   from src/amd64_fpmath.h, LDBL_MAX_EXP/LDBL_MANT_DIG from <float.h>,
   BIAS/MANH_SIZE/ATAN_CONST/ATAN_LINEAR/pio2_hi/pio2_lo from ld80/invtrig.h); the
   public entries renamed `atanl`->`olm_atanl` / `atan2l`->`olm_atan2l`; the two
   libm builtin calls `fabsl(x)` written `__builtin_fabsl(x)` (the coshl-slice
   convention for a hardware-backed keep-intrinsic — folds to @llvm.fabs.f80); the
   invtrig.h `_ItL_*` table-name #defines resolved so the tables carry their
   body-visible names atanhi/atanlo/aT/pi_lo. The x86_fp80 union is kept VERBATIM —
   the promoteFp80Union pass owns it, never a memcpy word shim (3c6m.51). The
   olm_atanl body is byte-identical to slice_libm_real_atanl.c (same vendored
   ld80/s_atanl.c). */
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
#define LDBL_MANT_DIG  64

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

/* openlibm ld80/invtrig.c pi_lo (verbatim). */
static const long double pi_lo = -5.01655761266833202345e-20L;

/* openlibm ld80/invtrig.h shared-constant aliases (verbatim #defines). */
#define pio2_hi atanhi[3]
#define pio2_lo atanlo[3]

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

/* openlibm src/e_atan2l.c atan2l (verbatim; the __i386__ pi1/pi2 workaround
   #ifdef-guarded out on the amd64 target; atanl -> olm_atanl; fabsl ->
   __builtin_fabsl). */
static volatile long double
tiny  = 1.0e-300;
static const long double
zero  = 0.0;
static const long double
pi =  3.14159265358979323846264338327950280e+00L;

static long double
olm_atan2l(long double y, long double x)
{
	union IEEEl2bits ux, uy;
	long double z;
	int32_t k,m;
	int16_t exptx, expsignx, expty, expsigny;

	uy.e = y;
	expsigny = uy.xbits.expsign;
	expty = expsigny & 0x7fff;
	ux.e = x;
	expsignx = ux.xbits.expsign;
	exptx = expsignx & 0x7fff;

	if ((exptx==BIAS+LDBL_MAX_EXP &&
	     ((ux.bits.manh&~LDBL_NBIT)|ux.bits.manl)!=0) ||	/* x is NaN */
	    (expty==BIAS+LDBL_MAX_EXP &&
	     ((uy.bits.manh&~LDBL_NBIT)|uy.bits.manl)!=0))	/* y is NaN */
	    return x+y;
	if (expsignx==BIAS && ((ux.bits.manh&~LDBL_NBIT)|ux.bits.manl)==0)
	    return olm_atanl(y);					/* x=1.0 */
	m = ((expsigny>>15)&1)|((expsignx>>14)&2);	/* 2*sign(x)+sign(y) */

    /* when y = 0 */
	if(expty==0 && ((uy.bits.manh&~LDBL_NBIT)|uy.bits.manl)==0) {
	    switch(m) {
		case 0: 
		case 1: return y; 	/* atan(+-0,+anything)=+-0 */
		case 2: return  pi+tiny;/* atan(+0,-anything) = pi */
		case 3: return -pi-tiny;/* atan(-0,-anything) =-pi */
	    }
	}
    /* when x = 0 */
	if(exptx==0 && ((ux.bits.manh&~LDBL_NBIT)|ux.bits.manl)==0)
	    return (expsigny<0)?  -pio2_hi-tiny: pio2_hi+tiny;

    /* when x is INF */
	if(exptx==BIAS+LDBL_MAX_EXP) {
	    if(expty==BIAS+LDBL_MAX_EXP) {
		switch(m) {
		    case 0: return  pio2_hi*0.5+tiny;/* atan(+INF,+INF) */
		    case 1: return -pio2_hi*0.5-tiny;/* atan(-INF,+INF) */
		    case 2: return  1.5*pio2_hi+tiny;/*atan(+INF,-INF)*/
		    case 3: return -1.5*pio2_hi-tiny;/*atan(-INF,-INF)*/
		}
	    } else {
		switch(m) {
		    case 0: return  zero  ;	/* atan(+...,+INF) */
		    case 1: return -zero  ;	/* atan(-...,+INF) */
		    case 2: return  pi+tiny  ;	/* atan(+...,-INF) */
		    case 3: return -pi-tiny  ;	/* atan(-...,-INF) */
		}
	    }
	}
    /* when y is INF */
	if(expty==BIAS+LDBL_MAX_EXP)
	    return (expsigny<0)? -pio2_hi-tiny: pio2_hi+tiny;

    /* compute y/x */
	k = expty-exptx;
	if(k > LDBL_MANT_DIG+2) {			/* |y/x| huge */
	    z=pio2_hi+pio2_lo;
	    m&=1;
	}
	else if(expsignx<0&&k<-LDBL_MANT_DIG-2) z=0.0; 	/* |y/x| tiny, x<0 */
	else z=olm_atanl(__builtin_fabsl(y/x));		/* safe to do y/x */
	switch (m) {
	    case 0: return       z  ;	/* atan(+,+) */
	    case 1: return      -z  ;	/* atan(-,+) */
	    case 2: return  pi-(z-pi_lo);/* atan(+,-) */
	    default: /* case 3 */
	    	    return  (z-pi_lo)-pi;/* atan(-,-) */
	}
}

long double slice(void) {
    long double q = 0.5L; cq_theta(&q, 0.5);
    return cq_measure(olm_atan2l(q, 0.5L));
}

int main(void) {
    (void) slice();
    return 0;
}
