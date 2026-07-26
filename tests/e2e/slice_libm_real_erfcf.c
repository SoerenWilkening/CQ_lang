/* slice_libm_real_erfcf.c — census cell erfcf.f32 (VERIFIED slice, bd 3c6m.53)
 * Vendored REAL openlibm source:
 *   - olm_erfcf : src/s_erff.c  (erfcf body + shared float R/S constants)
 *   - olm_expf  : src/e_expf.c  (__ieee754_expf, called by erfcf)
 * Mechanical edits only (Rule 18 real-source injection): renamed public/alias
 * entries to olm_-prefixed always_inline statics, deleted #include/license/
 * trailer blocks, word macros via the __builtin_memcpy shim, uniquified the
 * duplicate file-scope `one` (expf_one), fabsf spelled __builtin_fabsf.
 *
 * KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution; bd tkju):
 * s_erff.c's 2 fabsf sites are a HARDWARE KEEP — at the ship floor (plain
 * clang -O1, builtins ON) __builtin_fabsf folds to @llvm.fabs.f32 before
 * codegen, which cq-lowering rewrites to cq_template_fabs_f32. A keep has no
 * injectable body, so the four vendored olm_fabs/olm_fabsf/olm_copysign/
 * olm_copysignf software shims are deleted and the golden is byte-identical
 * across the rewrite (8843 lines). Its 3 cq_template_fabs_f32 are NOT those 2
 * sites — both CSE into the |x| value clang already folds out of
 * `ix = hx&0x7fffffff`; the 3 are that fold plus the same idiom in the two
 * expf inlines.
 */
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
#define STRICT_ASSIGN(type, lval, rval) ((lval) = (rval))

/* ===================== vendored from src/e_expf.c ===================== */
static const float
expf_one	= 1.0,
halF[2]	= {0.5,-0.5,},
huge	= 1.0e+30,
o_threshold=  8.8721679688e+01,  /* 0x42b17180 */
u_threshold= -1.0397208405e+02,  /* 0xc2cff1b5 */
ln2HI[2]   ={ 6.9314575195e-01,		/* 0x3f317200 */
	     -6.9314575195e-01,},	/* 0xbf317200 */
ln2LO[2]   ={ 1.4286067653e-06,  	/* 0x35bfbe8e */
	     -1.4286067653e-06,},	/* 0xb5bfbe8e */
invln2 =  1.4426950216e+00, 		/* 0x3fb8aa3b */
P1 =  1.6666625440e-1,		/*  0xaaaa8f.0p-26 */
P2 = -2.7667332906e-3;		/* -0xb55215.0p-32 */

static volatile float twom100 = 7.8886090522e-31;      /* 2**-100=0x0d800000 */

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
	    if(x > o_threshold) return huge*huge; /* overflow */
	    if(x < u_threshold) return twom100*twom100; /* underflow */
	}

    /* argument reduction */
	if(hx > 0x3eb17218) {		/* if  |x| > 0.5 ln2 */
	    if(hx < 0x3F851592) {	/* and |x| < 1.5 ln2 */
		hi = x-ln2HI[xsb]; lo=ln2LO[xsb]; k = 1-xsb-xsb;
	    } else {
		k  = invln2*x+halF[xsb];
		t  = k;
		hi = x - t*ln2HI[0];	/* t*ln2HI is exact here */
		lo = t*ln2LO[0];
	    }
	    STRICT_ASSIGN(float, x, hi - lo);
	}
	else if(hx < 0x39000000)  {	/* when |x|<2**-14 */
	    if(huge+x>expf_one) return expf_one+x;/* trigger inexact */
	}
	else k = 0;

    /* x is now in primary range */
	t  = x*x;
	if(k >= -125)
	    SET_FLOAT_WORD(twopk,0x3f800000+(k<<23));
	else
	    SET_FLOAT_WORD(twopk,0x3f800000+((k+100)<<23));
	c  = x - t*(P1+t*P2);
	if(k==0) 	return expf_one-((x*c)/(c-(float)2.0)-x);
	else 		y = expf_one-((lo-(x*c)/((float)2.0-c))-hi);
	if(k >= -125) {
	    if(k==128) return y*2.0F*0x1p127F;
	    return y*twopk;
	} else {
	    return y*twopk*twom100;
	}
}

/* ===================== vendored from src/s_erff.c ===================== */
static const float
tiny	    = 1e-30,
half=  5.0000000000e-01, /* 0x3F000000 */
one =  1.0000000000e+00, /* 0x3F800000 */
two =  2.0000000000e+00, /* 0x40000000 */
efx =  1.2837916613e-01, /* 0x3e0375d4 */
efx8=  1.0270333290e+00, /* 0x3f8375d4 */
pp0  =  1.28379166e-01F, /*  0x1.06eba8p-3 */
pp1  = -3.36030394e-01F, /* -0x1.58185ap-2 */
pp2  = -1.86260219e-03F, /* -0x1.e8451ep-10 */
qq1  =  3.12324286e-01F, /*  0x1.3fd1f0p-2 */
qq2  =  2.16070302e-02F, /*  0x1.620274p-6 */
qq3  = -1.98859419e-03F, /* -0x1.04a626p-9 */
erx  =  8.42697144e-01F, /*  0x1.af7600p-1.  erf(1) rounded to 16 bits. */
pa0  =  3.64939137e-06F, /*  0x1.e9d022p-19 */
pa1  =  4.15109694e-01F, /*  0x1.a91284p-2 */
pa2  = -1.65179938e-01F, /* -0x1.5249dcp-3 */
pa3  =  1.10914491e-01F, /*  0x1.c64e46p-4 */
qa1  =  6.02074385e-01F, /*  0x1.344318p-1 */
qa2  =  5.35934687e-01F, /*  0x1.126608p-1 */
qa3  =  1.68576106e-01F, /*  0x1.593e6ep-3 */
qa4  =  5.62181212e-02F, /*  0x1.cc89f2p-5 */
ra0  = -9.87132732e-03F, /* -0x1.4376b2p-7 */
ra1  = -5.53605914e-01F, /* -0x1.1b723cp-1 */
ra2  = -2.17589188e+00F, /* -0x1.1683a0p+1 */
ra3  = -1.43268085e+00F, /* -0x1.6ec42cp+0 */
sa1  =  5.45995426e+00F, /*  0x1.5d6fe4p+2 */
sa2  =  6.69798088e+00F, /*  0x1.acabb8p+2 */
sa3  =  1.43113089e+00F, /*  0x1.6e5e98p+0 */
sa4  = -5.77397496e-02F, /* -0x1.d90108p-5 */
rb0  = -9.86494310e-03F, /* -0x1.434124p-7 */
rb1  = -6.25171244e-01F, /* -0x1.401672p-1 */
rb2  = -6.16498327e+00F, /* -0x1.8a8f16p+2 */
rb3  = -1.66696873e+01F, /* -0x1.0ab70ap+4 */
rb4  = -9.53764343e+00F, /* -0x1.313460p+3 */
sb1  =  1.26884899e+01F, /*  0x1.96081cp+3 */
sb2  =  4.51839523e+01F, /*  0x1.6978bcp+5 */
sb3  =  4.72810211e+01F, /*  0x1.7a3f88p+5 */
sb4  =  8.93033314e+00F; /*  0x1.1dc54ap+3 */

__attribute__((always_inline)) static inline float
olm_erfcf(float x)
{
	int32_t hx,ix;
	float R,S,P,Q,s,y,z,r;
	GET_FLOAT_WORD(hx,x);
	ix = hx&0x7fffffff;
	if(ix>=0x7f800000) {			/* erfc(nan)=nan */
						/* erfc(+-inf)=0,2 */
	    return (float)(((u_int32_t)hx>>31)<<1)+one/x;
	}

	if(ix < 0x3f580000) {		/* |x|<0.84375 */
	    if(ix < 0x33800000)  	/* |x|<2**-56 */
		return one-x;
	    z = x*x;
            r = pp0+z*(pp1+z*pp2);
            s = one+z*(qq1+z*(qq2+z*qq3));
	    y = r/s;
	    if(hx < 0x3e800000) {  	/* x<1/4 */
		return one-(x+x*y);
	    } else {
		r = x*y;
		r += (x-half);
	        return half - r ;
	    }
	}
	if(ix < 0x3fa00000) {		/* 0.84375 <= |x| < 1.25 */
	    s = __builtin_fabsf(x)-one;
            P = pa0+s*(pa1+s*(pa2+s*pa3));
            Q = one+s*(qa1+s*(qa2+s*(qa3+s*qa4)));
	    if(hx>=0) {
	        z  = one-erx; return z - P/Q;
	    } else {
		z = erx+P/Q; return one+z;
	    }
	}
	if (ix < 0x41300000) {		/* |x|<28 */
	    x = __builtin_fabsf(x);
 	    s = one/(x*x);
	    if(ix< 0x4036DB6D) {	/* |x| < 1/.35 ~ 2.857143*/
                R=ra0+s*(ra1+s*(ra2+s*ra3));
                S=one+s*(sa1+s*(sa2+s*(sa3+s*sa4)));
	    } else {			/* |x| >= 1/.35 ~ 2.857143 */
                if(hx<0&&ix>=0x40a00000) return two-tiny;/* x < -5 */
                R=rb0+s*(rb1+s*(rb2+s*(rb3+s*rb4)));
                S=one+s*(sb1+s*(sb2+s*(sb3+s*sb4)));
	    }
            SET_FLOAT_WORD(z,hx&0xffffe000);
            r  = olm_expf(-z*z-0.5625F)*olm_expf((z-x)*(z+x)+R/S);
	    if(hx>0) return r/x; else return two-r/x;
	} else {
	    if(hx>0) return tiny*tiny; else return two-tiny;
	}
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_erfcf(q));
}
int main(void) { (void) slice(); return 0; }
