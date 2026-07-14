/* slice_libm_real_coshf.c — REAL openlibm coshf (f32) end-to-end verification slice.
 * Cell: coshf.f32. Sources: openlibm src/e_coshf.c (public entry) → expm1f
 * (s_expm1f.c) → __ieee754_expf (e_expf.c) → __ldexp_expf/__frexp_expf
 * (k_expf.c) → fabsf (shim). fdlibm-derived, BSD-licensed; verbatim algorithms
 * with the math_private.h word macros expanded to the __builtin_memcpy idiom
 * clang -O1 folds to the same bitcast/shift IR the taint pass lowers. Promotes
 * the census cell coshf.f32 from injection-covered → VERIFIED (Rule 2 link-layer
 * proof, Rule 18 real-source injection). All bodies come from the FLOAT corpus
 * (e_*f.c / s_*f.c / k_*f.c) — never a retyped double body. File-scope `one`
 * (1.0) and `huge` (1.0e30) are identical across e_coshf.c / e_expf.c /
 * s_expm1f.c and deduplicated to one definition each (same name, same value);
 * `o_threshold`/`invln2` (shared value between expm1f and expf) and the k_expf
 * `k`/`kln2` are uniquified by owning-fn prefix (NAME only, never the value).
 * bd 3c6m.53. */
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
/* Route through a `float` temp so a `double` operand narrows exactly like
   openlibm's ieee_float_shape_type union (gf_u.value=(d) is a float lvalue =>
   double->float conversion); for a float operand this folds to the same bitcast
   IR. k_expf.c __frexp_expf uses `double exp_x` with these macros, so a raw
   4-byte memcpy of the double would be unfaithful (bd 3c6m.53 audit). */
#define GET_FLOAT_WORD(i,d)    do{ float __f=(float)(d); uint32_t __w; __builtin_memcpy(&__w,&__f,4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); float __f; __builtin_memcpy(&__f,&__w,4); (d)=__f; }while(0)
__attribute__((always_inline)) static inline double olm_fabs(double x){ uint64_t b; __builtin_memcpy(&b,&x,8); b&=0x7fffffffffffffffULL; __builtin_memcpy(&x,&b,8); return x; }
__attribute__((always_inline)) static inline float  olm_fabsf(float x){ uint32_t b; __builtin_memcpy(&b,&x,4); b&=0x7fffffffU; __builtin_memcpy(&x,&b,4); return x; }
__attribute__((always_inline)) static inline double olm_copysign(double x,double y){ uint64_t bx,by; __builtin_memcpy(&bx,&x,8); __builtin_memcpy(&by,&y,8); bx=(bx&0x7fffffffffffffffULL)|(by&0x8000000000000000ULL); __builtin_memcpy(&x,&bx,8); return x; }
__attribute__((always_inline)) static inline float  olm_copysignf(float x,float y){ uint32_t bx,by; __builtin_memcpy(&bx,&x,4); __builtin_memcpy(&by,&y,4); bx=(bx&0x7fffffffU)|(by&0x80000000U); __builtin_memcpy(&x,&bx,4); return x; }

/* ---- shared file-scope constants (identical across e_coshf / e_expf / s_expm1f) ---- */
static const float one = 1.0, huge = 1.0e30;

/* ---- e_coshf.c constant ---- */
static const float half = 0.5;

/* ---- s_expm1f.c constants ---- */
static const float
tiny		= 1.0e-30,
expm1_o_threshold = 8.8721679688e+01,/* 0x42b17180 */
ln2_hi		= 6.9313812256e-01,/* 0x3f317180 */
ln2_lo		= 9.0580006145e-06,/* 0x3717f7d1 */
expm1_invln2	= 1.4426950216e+00,/* 0x3fb8aa3b */
Q1 = -3.3333212137e-2,		/* -0x888868.0p-28 */
Q2 =  1.5807170421e-3;		/*  0xcf3010.0p-33 */

/* ---- e_expf.c constants ---- */
static const float
halF[2]	= {0.5,-0.5,},
exp_o_threshold=  8.8721679688e+01,  /* 0x42b17180 */
u_threshold= -1.0397208405e+02,  /* 0xc2cff1b5 */
ln2HI[2]   ={ 6.9314575195e-01,		/* 0x3f317200 */
	     -6.9314575195e-01,},	/* 0xbf317200 */
ln2LO[2]   ={ 1.4286067653e-06,  	/* 0x35bfbe8e */
	     -1.4286067653e-06,},	/* 0xb5bfbe8e */
exp_invln2 =  1.4426950216e+00, 		/* 0x3fb8aa3b */
P1 =  1.6666625440e-1,		/*  0xaaaa8f.0p-26 */
P2 = -2.7667332906e-3;		/* -0xb55215.0p-32 */

static volatile float twom100 = 7.8886090522e-31;      /* 2**-100=0x0d800000 */

/* ---- k_expf.c constants ---- */
static const u_int32_t kexp_k = 235;			/* constant for reduction */
static const float kexp_kln2 =  162.88958740F;	/* k * ln2 */

/* ======== e_expf.c : __ieee754_expf ======== */
__attribute__((always_inline)) static inline float
olm_expf(float x)
{
	float y,hi=0.0,lo=0.0,c,t,twopk;
	int32_t k=0,xsb;
	u_int32_t hx;

	GET_FLOAT_WORD(hx,x);
	xsb = (hx>>31)&1;		/* sign bit of x */
	hx &= 0x7fffffff;		/* high word of |x| */

    /* filter out non-finite argument */
	if(hx >= 0x42b17218) {			/* if |x|>=88.721... */
	    if(hx>0x7f800000)
		 return x+x;	 		/* NaN */
            if(hx==0x7f800000)
		return (xsb==0)? x:0.0;		/* exp(+-inf)={inf,0} */
	    if(x > exp_o_threshold) return huge*huge; /* overflow */
	    if(x < u_threshold) return twom100*twom100; /* underflow */
	}

    /* argument reduction */
	if(hx > 0x3eb17218) {		/* if  |x| > 0.5 ln2 */
	    if(hx < 0x3F851592) {	/* and |x| < 1.5 ln2 */
		hi = x-ln2HI[xsb]; lo=ln2LO[xsb]; k = 1-xsb-xsb;
	    } else {
		k  = exp_invln2*x+halF[xsb];
		t  = k;
		hi = x - t*ln2HI[0];	/* t*ln2HI is exact here */
		lo = t*ln2LO[0];
	    }
	    x = hi - lo;	/* STRICT_ASSIGN */
	}
	else if(hx < 0x39000000)  {	/* when |x|<2**-14 */
	    if(huge+x>one) return one+x;/* trigger inexact */
	}
	else k = 0;

    /* x is now in primary range */
	t  = x*x;
	if(k >= -125)
	    SET_FLOAT_WORD(twopk,0x3f800000+(k<<23));
	else
	    SET_FLOAT_WORD(twopk,0x3f800000+((k+100)<<23));
	c  = x - t*(P1+t*P2);
	if(k==0) 	return one-((x*c)/(c-(float)2.0)-x);
	else 		y = one-((lo-(x*c)/((float)2.0-c))-hi);
	if(k >= -125) {
	    if(k==128) return y*2.0F*0x1p127F;
	    return y*twopk;
	} else {
	    return y*twopk*twom100;
	}
}

/* ======== k_expf.c : __frexp_expf / __ldexp_expf ======== */
__attribute__((always_inline)) static inline float
olm_frexp_expf(float x, int *expt)
{
	double exp_x;
	u_int32_t hx;

	exp_x = olm_expf(x - kexp_kln2);
	GET_FLOAT_WORD(hx, exp_x);
	*expt = (hx >> 23) - (0x7f + 127) + kexp_k;
	SET_FLOAT_WORD(exp_x, (hx & 0x7fffff) | ((0x7f + 127) << 23));
	return (exp_x);
}

__attribute__((always_inline)) static inline float
olm_ldexp_expf(float x, int expt)
{
	float exp_x, scale;
	int ex_expt;

	exp_x = olm_frexp_expf(x, &ex_expt);
	expt += ex_expt;
	SET_FLOAT_WORD(scale, (0x7f + expt) << 23);
	return (exp_x * scale);
}

/* ======== s_expm1f.c : expm1f ======== */
__attribute__((always_inline)) static inline float
olm_expm1f(float x)
{
	float y,hi,lo,c,t,e,hxs,hfx,r1,twopk;
	int32_t k,xsb;
	u_int32_t hx;

	GET_FLOAT_WORD(hx,x);
	xsb = hx&0x80000000;		/* sign bit of x */
	hx &= 0x7fffffff;		/* high word of |x| */

    /* filter out huge and non-finite argument */
	if(hx >= 0x4195b844) {			/* if |x|>=27*ln2 */
	    if(hx >= 0x42b17218) {		/* if |x|>=88.721... */
                if(hx>0x7f800000)
		    return x+x; 	 /* NaN */
		if(hx==0x7f800000)
		    return (xsb==0)? x:-1.0;/* exp(+-inf)={inf,-1} */
	        if(x > expm1_o_threshold) return huge*huge; /* overflow */
	    }
	    if(xsb!=0) { /* x < -27*ln2, return -1.0 with inexact */
		if(x+tiny<(float)0.0)	/* raise inexact */
		return tiny-one;	/* return -1 */
	    }
	}

    /* argument reduction */
	if(hx > 0x3eb17218) {		/* if  |x| > 0.5 ln2 */
	    if(hx < 0x3F851592) {	/* and |x| < 1.5 ln2 */
		if(xsb==0)
		    {hi = x - ln2_hi; lo =  ln2_lo;  k =  1;}
		else
		    {hi = x + ln2_hi; lo = -ln2_lo;  k = -1;}
	    } else {
		k  = expm1_invln2*x+((xsb==0)?(float)0.5:(float)-0.5);
		t  = k;
		hi = x - t*ln2_hi;	/* t*ln2_hi is exact here */
		lo = t*ln2_lo;
	    }
	    x = hi - lo;	/* STRICT_ASSIGN */
	    c  = (hi-x)-lo;
	}
	else if(hx < 0x33000000) {  	/* when |x|<2**-25, return x */
	    t = huge+x;	/* return x with inexact flags when x!=0 */
	    return x - (t-(huge+x));
	}
	else k = 0;

    /* x is now in primary range */
	hfx = (float)0.5*x;
	hxs = x*hfx;
	r1 = one+hxs*(Q1+hxs*Q2);
	t  = (float)3.0-r1*hfx;
	e  = hxs*((r1-t)/((float)6.0 - x*t));
	if(k==0) return x - (x*e-hxs);		/* c is 0 */
	else {
	    SET_FLOAT_WORD(twopk,0x3f800000+(k<<23));	/* 2^k */
	    e  = (x*(e-c)-c);
	    e -= hxs;
	    if(k== -1) return (float)0.5*(x-e)-(float)0.5;
	    if(k==1) {
	       	if(x < (float)-0.25) return -(float)2.0*(e-(x+(float)0.5));
	       	else 	      return  one+(float)2.0*(x-e);
	    }
	    if (k <= -2 || k>56) {   /* suffice to return exp(x)-1 */
	        y = one-(e-x);
		if (k == 128) y = y*2.0F*0x1p127F;
		else y = y*twopk;
	        return y-one;
	    }
	    t = one;
	    if(k<23) {
	        SET_FLOAT_WORD(t,0x3f800000 - (0x1000000>>k)); /* t=1-2^-k */
	       	y = t-(e-x);
		y = y*twopk;
	   } else {
		SET_FLOAT_WORD(t,((0x7f-k)<<23));	/* 2^-k */
	       	y = x-(e+t);
	       	y += one;
		y = y*twopk;
	    }
	}
	return y;
}

/* ======== e_coshf.c : __ieee754_coshf ======== */
__attribute__((always_inline)) static inline float
olm_coshf(float x)
{
	float t,w;
	int32_t ix;

	GET_FLOAT_WORD(ix,x);
	ix &= 0x7fffffff;

    /* x is INF or NaN */
	if(ix>=0x7f800000) return x*x;

    /* |x| in [0,0.5*ln2], return 1+expm1(|x|)^2/(2*exp(|x|)) */
	if(ix<0x3eb17218) {
	    t = olm_expm1f(olm_fabsf(x));
	    w = one+t;
	    if (ix<0x39800000) return one;	/* cosh(tiny) = 1 */
	    return one+(t*t)/(w+w);
	}

    /* |x| in [0.5*ln2,9], return (exp(|x|)+1/exp(|x|))/2; */
	if (ix < 0x41100000) {
		t = olm_expf(olm_fabsf(x));
		return half*t+half/t;
	}

    /* |x| in [9, log(maxfloat)] return half*exp(|x|) */
	if (ix < 0x42b17217)  return half*olm_expf(olm_fabsf(x));

    /* |x| in [log(maxfloat), overflowthresold] */
	if (ix<=0x42b2d4fc)
	    return olm_ldexp_expf(olm_fabsf(x), -1);

    /* |x| > overflowthresold, cosh(x) overflow */
	return huge*huge;
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_coshf(q));
}
int main(void) { (void) slice(); return 0; }
