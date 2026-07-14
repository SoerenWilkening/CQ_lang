/* slice_libm_real_atan2.c — bd 3c6m.53: the REAL openlibm atan2 body
   (census cell atan2.f64). Vendored VERBATIM from openlibm src/e_atan2.c
   (__ieee754_atan2 → olm_atan2) plus its transitive callee atan
   (src/s_atan.c, copied verbatim from the already-verified model slice
   tests/e2e/slice_libm_real_atan.c → olm_atan) and the fabs shim
   (olm_fabs, in the preamble). math_private.h word macros expanded to the
   __builtin_memcpy idiom clang -O1 folds to the same bitcast/shift IR the
   taint pass lowers. atan2(y,x): y=arg0 tainted (cq_theta), x=0.5 classical;
   the body ends in a 4-way sign-quadrant switch on m and calls
   olm_atan(olm_fabs(y/x)). This slice is the LINK-layer proof (Rule 2). */
#include <stdint.h>
typedef uint32_t u_int32_t;
typedef uint64_t u_int64_t;
/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define GET_HIGH_WORD(i,d)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)(__w>>32); }while(0)
#define GET_LOW_WORD(i,d)      do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)__w; }while(0)
#define SET_HIGH_WORD(d,v)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0x00000000ffffffffULL)|((uint64_t)(uint32_t)(v)<<32); __builtin_memcpy(&(d),&__w,8); }while(0)
#define SET_LOW_WORD(d,v)      do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0xffffffff00000000ULL)|(uint32_t)(v); __builtin_memcpy(&(d),&__w,8); }while(0)
#define INSERT_WORDS(d,hi,lo)  do{ uint64_t __w=((uint64_t)(uint32_t)(hi)<<32)|(uint32_t)(lo); __builtin_memcpy(&(d),&__w,8); }while(0)
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)
__attribute__((always_inline)) static inline double olm_fabs(double x){ uint64_t b; __builtin_memcpy(&b,&x,8); b&=0x7fffffffffffffffULL; __builtin_memcpy(&x,&b,8); return x; }
__attribute__((always_inline)) static inline float  olm_fabsf(float x){ uint32_t b; __builtin_memcpy(&b,&x,4); b&=0x7fffffffU; __builtin_memcpy(&x,&b,4); return x; }
__attribute__((always_inline)) static inline double olm_copysign(double x,double y){ uint64_t bx,by; __builtin_memcpy(&bx,&x,8); __builtin_memcpy(&by,&y,8); bx=(bx&0x7fffffffffffffffULL)|(by&0x8000000000000000ULL); __builtin_memcpy(&x,&bx,8); return x; }
__attribute__((always_inline)) static inline float  olm_copysignf(float x,float y){ uint32_t bx,by; __builtin_memcpy(&bx,&x,4); __builtin_memcpy(&by,&y,4); bx=(bx&0x7fffffffU)|(by&0x80000000U); __builtin_memcpy(&x,&bx,4); return x; }

/* ---- atan (openlibm src/s_atan.c, verbatim from verified model slice) ---- */
static const double atanhi[] = {
  4.63647609000806093515e-01, /* atan(0.5)hi 0x3FDDAC67, 0x0561BB4F */
  7.85398163397448278999e-01, /* atan(1.0)hi 0x3FE921FB, 0x54442D18 */
  9.82793723247329054082e-01, /* atan(1.5)hi 0x3FEF730B, 0xD281F69B */
  1.57079632679489655800e+00, /* atan(inf)hi 0x3FF921FB, 0x54442D18 */
};

static const double atanlo[] = {
  2.26987774529616870924e-17, /* atan(0.5)lo 0x3C7A2B7F, 0x222F65E2 */
  3.06161699786838301793e-17, /* atan(1.0)lo 0x3C81A626, 0x33145C07 */
  1.39033110312309984516e-17, /* atan(1.5)lo 0x3C700788, 0x7AF0CBBD */
  6.12323399573676603587e-17, /* atan(inf)lo 0x3C91A626, 0x33145C07 */
};

static const double aT[] = {
  3.33333333333329318027e-01, /* 0x3FD55555, 0x5555550D */
 -1.99999999998764832476e-01, /* 0xBFC99999, 0x9998EBC4 */
  1.42857142725034663711e-01, /* 0x3FC24924, 0x920083FF */
 -1.11111104054623557880e-01, /* 0xBFBC71C6, 0xFE231671 */
  9.09088713343650656196e-02, /* 0x3FB745CD, 0xC54C206E */
 -7.69187620504482999495e-02, /* 0xBFB3B0F2, 0xAF749A6D */
  6.66107313738753120669e-02, /* 0x3FB10D66, 0xA0D03D51 */
 -5.83357013379057348645e-02, /* 0xBFADDE2D, 0x52DEFD9A */
  4.97687799461593236017e-02, /* 0x3FA97B4B, 0x24760DEB */
 -3.65315727442169155270e-02, /* 0xBFA2B444, 0x2C6A6C2F */
  1.62858201153657823623e-02, /* 0x3F90AD3A, 0xE322DA11 */
};

static const double one = 1.0, at_huge = 1.0e300;

__attribute__((always_inline)) static inline double olm_atan(double x) {
    double w, s1, s2, z;
    int32_t ix, hx, id;
    uint64_t bits;

    __builtin_memcpy(&bits, &x, 8);                      /* GET_HIGH_WORD */
    hx = (int32_t)(bits >> 32);
    ix = hx & 0x7fffffff;
    if (ix >= 0x44100000) {     /* if |x| >= 2^66 */
        uint32_t low;
        __builtin_memcpy(&bits, &x, 8);                  /* GET_LOW_WORD */
        low = (uint32_t)bits;
        if (ix > 0x7ff00000 ||
            (ix == 0x7ff00000 && (low != 0)))
            return x + x;       /* NaN */
        if (hx > 0) return  atanhi[3] + *(volatile double *)&atanlo[3];
        else        return -atanhi[3] - *(volatile double *)&atanlo[3];
    } if (ix < 0x3fdc0000) {    /* |x| < 0.4375 */
        if (ix < 0x3e400000) {  /* |x| < 2^-27 */
            if (at_huge + x > one) return x;  /* raise inexact */
        }
        id = -1;
    } else {
    x = olm_fabs(x);
    if (ix < 0x3ff30000) {          /* |x| < 1.1875 */
        if (ix < 0x3fe60000) {      /* 7/16 <=|x|<11/16 */
            id = 0; x = (2.0 * x - one) / (2.0 + x);
        } else {                    /* 11/16<=|x|< 19/16 */
            id = 1; x = (x - one) / (x + one);
        }
    } else {
        if (ix < 0x40038000) {      /* |x| < 2.4375 */
            id = 2; x = (x - 1.5) / (one + 1.5 * x);
        } else {                    /* 2.4375 <= |x| < 2^66 */
            id = 3; x = -1.0 / x;
        }
    }}
    /* end of argument reduction */
    z = x * x;
    w = z * z;
    /* break sum from i=0 to 10 aT[i]z**(i+1) into odd and even poly */
    s1 = z * (aT[0] + w * (aT[2] + w * (aT[4] + w * (aT[6] + w * (aT[8] + w * aT[10])))));
    s2 = w * (aT[1] + w * (aT[3] + w * (aT[5] + w * (aT[7] + w * aT[9]))));
    if (id < 0) return x - x * (s1 + s2);
    else {
        z = atanhi[id] - ((x * (s1 + s2) - atanlo[id]) - x);
        return (hx < 0) ? -z : z;
    }
}

/* ---- atan2 (openlibm src/e_atan2.c, verbatim → olm_atan2) ---- */
static volatile double
tiny  = 1.0e-300;
static const double
zero  = 0.0,
pi_o_4  = 7.8539816339744827900E-01, /* 0x3FE921FB, 0x54442D18 */
pi_o_2  = 1.5707963267948965580E+00, /* 0x3FF921FB, 0x54442D18 */
pi      = 3.1415926535897931160E+00; /* 0x400921FB, 0x54442D18 */
static volatile double
pi_lo   = 1.2246467991473531772E-16; /* 0x3CA1A626, 0x33145C07 */

__attribute__((always_inline)) static inline double
olm_atan2(double y, double x)
{
	double z;
	int32_t k,m,hx,hy,ix,iy;
	u_int32_t lx,ly;

	EXTRACT_WORDS(hx,lx,x);
	ix = hx&0x7fffffff;
	EXTRACT_WORDS(hy,ly,y);
	iy = hy&0x7fffffff;
	if(((ix|((lx|-lx)>>31))>0x7ff00000)||
	   ((iy|((ly|-ly)>>31))>0x7ff00000))	/* x or y is NaN */
	   return x+y;
	if(hx==0x3ff00000&&lx==0) return olm_atan(y);   /* x=1.0 */
	m = ((hy>>31)&1)|((hx>>30)&2);	/* 2*sign(x)+sign(y) */

    /* when y = 0 */
	if((iy|ly)==0) {
	    switch(m) {
		case 0:
		case 1: return y; 	/* atan(+-0,+anything)=+-0 */
		case 2: return  pi+tiny;/* atan(+0,-anything) = pi */
		case 3: return -pi-tiny;/* atan(-0,-anything) =-pi */
	    }
	}
    /* when x = 0 */
	if((ix|lx)==0) return (hy<0)?  -pi_o_2-tiny: pi_o_2+tiny;

    /* when x is INF */
	if(ix==0x7ff00000) {
	    if(iy==0x7ff00000) {
		switch(m) {
		    case 0: return  pi_o_4+tiny;/* atan(+INF,+INF) */
		    case 1: return -pi_o_4-tiny;/* atan(-INF,+INF) */
		    case 2: return  3.0*pi_o_4+tiny;/*atan(+INF,-INF)*/
		    case 3: return -3.0*pi_o_4-tiny;/*atan(-INF,-INF)*/
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
	if(iy==0x7ff00000) return (hy<0)? -pi_o_2-tiny: pi_o_2+tiny;

    /* compute y/x */
	k = (iy-ix)>>20;
	if(k > 60) {		 	/* |y/x| >  2**60 */
	    z=pi_o_2+0.5*pi_lo;
	    m&=1;
	}
	else if(hx<0&&k<-60) z=0.0; 	/* 0 > |y|/x > -2**-60 */
	else z=olm_atan(olm_fabs(y/x));		/* safe to do y/x */
	switch (m) {
	    case 0: return       z  ;	/* atan(+,+) */
	    case 1: return      -z  ;	/* atan(-,+) */
	    case 2: return  pi-(z-pi_lo);/* atan(+,-) */
	    default: /* case 3 */
	    	    return  (z-pi_lo)-pi;/* atan(-,-) */
	}
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_atan2(q, 0.5));
}
int main(void) { (void) slice(); return 0; }
