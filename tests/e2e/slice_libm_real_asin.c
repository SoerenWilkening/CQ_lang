/* slice_libm_real_asin.c — bd 3c6m.60: the REAL openlibm asin body.

   Vendored corpus file (the ONLY one; the closure is closed by it):
     /private/tmp/openlibm_reclone/src/e_asin.c — __ieee754_asin, its file-scope
     static coefficient block (one, huge, pio2_hi, pio2_lo, pio4_hi, pS0..pS5,
     qS1..qS4), and nothing else. e_asin.c calls exactly two other functions,
     fabs and sqrt, and BOTH are Rule-18 hardware keeps, so no further openlibm
     source needs vendoring.

   Declared mechanical edits (algorithm, constants, branches and expressions are
   otherwise byte-faithful to the corpus):
     - deleted the four include lines (cdefs-compat.h, float.h, openlibm_math.h,
       math_private.h), the Sun/fdlibm license header, the FBSDID comment, the
       Method comment block, the OLM_DLLEXPORT marker, and the trailing
       LDBL_MANT_DIG == 53 block with its asinl weak-reference line (x86-64 long
       double has 64 mantissa bits, so that block does not apply). <stdint.h> is
       included in their place, for the int32_t / uint32_t / uint64_t spellings.
     - entry point __ieee754_asin renamed to
       __attribute__((always_inline)) static inline double olm_asin. The
       force-inline reproduces the census inline shape at plain -O1 and collapses
       the cell to one straight-line body (the standing real-slice recipe rule,
       recorded in the libm-real-slice-recipe memory under bd 3c6m.53).
     - the math_private.h word macros expanded to the __builtin_memcpy 8-byte pun
       clang -O1 folds to the same bitcast IR: GET_HIGH_WORD(hx,x),
       GET_LOW_WORD(lx,x), SET_LOW_WORD(w,0). The shim's uint64_t bits local is
       the only declaration this vendoring adds to the body; t, w, p, q, c, r, s
       and int32_t hx, ix are the corpus declarations verbatim.
     - the BSD spelling u_int32_t (which came from the deleted math_private.h
       include chain) written as the stdint.h spelling uint32_t.
     - openlibm's static names are kept as-is: this is a single-file cell, so
       nothing collides and no uniquifying rename was needed. pio2_lo here is a
       plain static const double, exactly as e_asin.c declares it (unlike
       e_acos.c, where it is static volatile) — no qualifier was added or removed.

   KEEP-SET calls rewritten to their __builtin_ spelling:
     fabs -> __builtin_fabs, sqrt -> __builtin_sqrt.
   Both are Rule-18 hardware keeps: at the real ship floor (plain clang -O1,
   builtins ON) the named calls fold to @llvm.fabs.f64 / @llvm.sqrt.f64 before
   codegen, and cq-lowering rewrites those to cq_template_fabs_f64 /
   cq_template_sqrt_f64. __builtin_fabs / __builtin_sqrt emit that SAME construct
   with no libm declaration needed. This is NOT a body substitution — a keep has
   no injectable body by definition (Rule 18). It is also the exact reason the
   old census misfiled this family: the corpus was built with a blanket
   -fno-builtin, so the inner sqrt resolved to openlibm's SOFTWARE
   __ieee754_sqrt and dragged that body's subnormal-normalize loop into the cell.

   Lowering exercised: the tainted-exponent classification cascade
   (|x|>=1 / |x|<0.5 / the |x|>0.975 split of the [0.5,1) tail) flattens onto the
   select substrate; the shared pS/qS Horner polynomials ride the arithmetic
   templates; SET_LOW_WORD(w,0) becomes a register bit-mask after SROA; the two
   keeps lower to cq_template_fabs_f64 / cq_template_sqrt_f64 rather than to any
   vendored software body. This slice is the LINK-layer proof (Rule 2) that every
   emitted symbol resolves, signature-matches, and the trace is stable. */
#include <stdint.h>

static const double
one =  1.00000000000000000000e+00, /* 0x3FF00000, 0x00000000 */
huge =  1.000e+300,
pio2_hi =  1.57079632679489655800e+00, /* 0x3FF921FB, 0x54442D18 */
pio2_lo =  6.12323399573676603587e-17, /* 0x3C91A626, 0x33145C07 */
pio4_hi =  7.85398163397448278999e-01, /* 0x3FE921FB, 0x54442D18 */
	/* coefficient for R(x^2) */
pS0 =  1.66666666666666657415e-01, /* 0x3FC55555, 0x55555555 */
pS1 = -3.25565818622400915405e-01, /* 0xBFD4D612, 0x03EB6F7D */
pS2 =  2.01212532134862925881e-01, /* 0x3FC9C155, 0x0E884455 */
pS3 = -4.00555345006794114027e-02, /* 0xBFA48228, 0xB5688F3B */
pS4 =  7.91534994289814532176e-04, /* 0x3F49EFE0, 0x7501B288 */
pS5 =  3.47933107596021167570e-05, /* 0x3F023DE1, 0x0DFDF709 */
qS1 = -2.40339491173441421878e+00, /* 0xC0033A27, 0x1C8A2D4B */
qS2 =  2.02094576023350569471e+00, /* 0x40002AE5, 0x9C598AC8 */
qS3 = -6.88283971605453293030e-01, /* 0xBFE6066C, 0x1B8D0159 */
qS4 =  7.70381505559019352791e-02; /* 0x3FB3B8C5, 0xB12E9282 */

/* openlibm src/e_asin.c __ieee754_asin (verbatim; GET_HIGH_WORD / GET_LOW_WORD /
   SET_LOW_WORD expanded to the __builtin_memcpy shim, `fabs` -> `__builtin_fabs`
   and `sqrt` -> `__builtin_sqrt`, which are the SAME @llvm.fabs.f64 /
   @llvm.sqrt.f64 the ship floor emits for the named calls). */
__attribute__((always_inline)) static inline double olm_asin(double x)
{
	double t=0.0,w,p,q,c,r,s;
	int32_t hx,ix;
	uint64_t bits;

	__builtin_memcpy(&bits, &x, 8);                  /* GET_HIGH_WORD(hx,x) */
	hx = (int32_t)(bits >> 32);
	ix = hx&0x7fffffff;
	if(ix>= 0x3ff00000) {		/* |x|>= 1 */
	    uint32_t lx;
	    __builtin_memcpy(&bits, &x, 8);              /* GET_LOW_WORD(lx,x) */
	    lx = (uint32_t)bits;
	    if(((ix-0x3ff00000)|lx)==0)
		    /* asin(1)=+-pi/2 with inexact */
		return x*pio2_hi+x*pio2_lo;
	    return (x-x)/(x-x);		/* asin(|x|>1) is NaN */
	} else if (ix<0x3fe00000) {	/* |x|<0.5 */
	    if(ix<0x3e500000) {		/* if |x| < 2**-26 */
		if(huge+x>one) return x;/* return x with inexact if x!=0*/
	    }
	    t = x*x;
	    p = t*(pS0+t*(pS1+t*(pS2+t*(pS3+t*(pS4+t*pS5)))));
	    q = one+t*(qS1+t*(qS2+t*(qS3+t*qS4)));
	    w = p/q;
	    return x+x*w;
	}
	/* 1> |x|>= 0.5 */
	w = one-__builtin_fabs(x);
	t = w*0.5;
	p = t*(pS0+t*(pS1+t*(pS2+t*(pS3+t*(pS4+t*pS5)))));
	q = one+t*(qS1+t*(qS2+t*(qS3+t*qS4)));
	s = __builtin_sqrt(t);
	if(ix>=0x3FEF3333) { 	/* if |x| > 0.975 */
	    w = p/q;
	    t = pio2_hi-(2.0*(s+s*w)-pio2_lo);
	} else {
	    w  = s;
	    __builtin_memcpy(&bits, &w, 8);              /* SET_LOW_WORD(w,0) */
	    bits &= 0xffffffff00000000ULL;
	    __builtin_memcpy(&w, &bits, 8);
	    c  = (t-w*w)/(s+w);
	    r  = p/q;
	    p  = 2.0*s*r-(pio2_lo-2.0*c);
	    q  = pio4_hi-2.0*w;
	    t  = pio4_hi-(p-q);
	}
	if(hx>0) return t; else return -t;
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_asin(q));
}
int main(void) { (void) slice(); return 0; }
