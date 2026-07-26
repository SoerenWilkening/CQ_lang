/* slice_libm_real_scalbln.c — bd 3c6m.53: the REAL openlibm scalbln body
   (s_scalbln.c) over the REAL openlibm scalbn body (s_scalbn.c). scalbln is a
   thin `long n` wrapper that clamps n to INT_MAX/INT_MIN when it does not fit in
   an int, then defers to scalbn. The vendored olm_scalbn is copied VERBATIM from
   the already-verified slice_libm_real_scalbn.c (a REAL openlibm body). This
   slice is the LINK-layer proof (Rule 2) + Rule-18 real-source injection that
   promotes census cell scalbln.f64 injection-covered → VERIFIED.

   Cell: scalbln  width: f64  return: double
   Entry corpus file: /private/tmp/openlibm/src/s_scalbln.c
   Dep corpus file:   /private/tmp/openlibm/src/s_scalbn.c
   Probe: x = theta-tainted, n = 2 (classical).

   KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution — bd tkju):
   olm_scalbn's overflow/underflow arms call copysign, a HARDWARE KEEP. At the
   ship floor (plain clang -O1, builtins ON) the named call folds to
   @llvm.copysign.f64 before codegen and cq-lowering rewrites that to
   cq_template_copysign_f64_lh (the literal `huge` + the tainted handle). A
   keep has no injectable body, so the s_copysign.c bit-op shim vendored here
   before (olm_copysign, plus the unused olm_fabs/olm_fabsf/olm_copysignf
   siblings) misrepresented the ship floor and is deleted. MEASURED: the shim's
   4 template calls (one each of bitcast_f64_to_i64 / and_i64_hl / or_i64_hl /
   bitcast_i64_to_f64) collapse to the single copysign template — trace
   253 -> 250 lines. */
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
/* INT_MAX / INT_MIN (from <limits.h> in the corpus) */
#define INT_MAX 2147483647
#define INT_MIN (-2147483647 - 1)

/* ---- vendored VERBATIM from slice_libm_real_scalbn.c (REAL openlibm s_scalbn.c) ---- */
static const double two54  = 1.80143985094819840000e+16; /* 0x43500000, 0x00000000 */
static const double twom54 = 5.55111512312578270212e-17; /* 0x3C900000, 0x00000000 */
static const double huge   = 1.0e+300;
static const double tiny   = 1.0e-300;

__attribute__((always_inline)) static inline double olm_scalbn(double x, int n) {
    int32_t k, hx, lx;
    uint64_t bits;
    __builtin_memcpy(&bits, &x, 8);                      /* EXTRACT_WORDS */
    hx = (int32_t)(bits >> 32);
    lx = (int32_t)bits;
    k = (hx & 0x7ff00000) >> 20;                         /* extract exponent */
    if (k == 0) {                                        /* 0 or subnormal x */
        if ((lx | (hx & 0x7fffffff)) == 0) return x;     /* +-0 */
        x *= two54;
        __builtin_memcpy(&bits, &x, 8);                  /* GET_HIGH_WORD */
        hx = (int32_t)(bits >> 32);
        k = ((hx & 0x7ff00000) >> 20) - 54;
        if (n < -50000) return tiny * x;                 /* underflow */
    }
    if (k == 0x7ff) return x + x;                        /* NaN or Inf */
    k = k + n;
    if (k > 0x7fe) return huge * __builtin_copysign(huge, x);  /* overflow */
    if (k > 0) {                                         /* normal result */
        __builtin_memcpy(&bits, &x, 8);                  /* SET_HIGH_WORD */
        bits = (bits & 0xffffffffULL) |
               ((uint64_t)(uint32_t)((hx & 0x800fffff) | (k << 20)) << 32);
        __builtin_memcpy(&x, &bits, 8);
        return x;
    }
    if (k <= -54) {
        if (n > 50000)                                   /* n+k overflowed */
            return huge * __builtin_copysign(huge, x);         /* overflow */
        else
            return tiny * __builtin_copysign(tiny, x);         /* underflow */
    }
    k += 54;                                             /* subnormal result */
    __builtin_memcpy(&bits, &x, 8);                      /* SET_HIGH_WORD */
    bits = (bits & 0xffffffffULL) |
           ((uint64_t)(uint32_t)((hx & 0x800fffff) | (k << 20)) << 32);
    __builtin_memcpy(&x, &bits, 8);
    return x * twom54;
}

/* ---- vendored from s_scalbln.c (REAL openlibm scalbln) ---- */
__attribute__((always_inline)) static inline double olm_scalbln (double x, long n)
{
	int in;

	in = (int)n;
	if (in != n) {
		if (n > 0)
			in = INT_MAX;
		else
			in = INT_MIN;
	}
	return (olm_scalbn(x, in));
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_scalbln(q, 2));
}
int main(void) { (void) slice(); return 0; }
