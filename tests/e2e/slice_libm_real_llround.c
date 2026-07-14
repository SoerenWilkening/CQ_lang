/* slice_libm_real_llround.c — bd 3c6m.53: the REAL openlibm llround body.
   s_llround.c is s_lround.c re-instantiated with dtype=long long
   (roundit=round, type=double). INRANGE() is compile-time TRUE for the
   double/long-long instantiation exactly as for lround, so
   llround(x) = (long long)round(x) with no fenv path — the census cell
   llround.f64. round (s_round.c) inlines floor (s_floor.c); the olm_round /
   olm_floor bodies are copied VERBATIM from the already-verified
   slice_libm_real_lround.c model slice. This slice is the LINK-layer proof
   (Rule 2). Sources: openlibm src/s_llround.c → s_lround.c → s_round.c →
   s_floor.c (fdlibm-derived, BSD-licensed; word macros expanded to the
   __builtin_memcpy idiom). */
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

static const double fl_huge = 1.0e300;

__attribute__((always_inline)) static inline double olm_floor(double x) {
    int32_t i0, i1, j0;
    uint32_t i, j;
    uint64_t bits;
    __builtin_memcpy(&bits, &x, 8);                      /* EXTRACT_WORDS */
    i0 = (int32_t)(bits >> 32);
    i1 = (int32_t)bits;
    j0 = ((i0 >> 20) & 0x7ff) - 0x3ff;
    if (j0 < 20) {
        if (j0 < 0) {                                    /* |x| < 1 */
            if (fl_huge + x > 0.0) {                     /* raise inexact */
                if (i0 >= 0) { i0 = i1 = 0; }
                else if (((i0 & 0x7fffffff) | i1) != 0) { i0 = 0xbff00000; i1 = 0; }
            }
        } else {
            i = (0x000fffff) >> j0;
            if (((i0 & i) | i1) == 0) return x;          /* x is integral */
            if (fl_huge + x > 0.0) {                     /* raise inexact */
                if (i0 < 0) i0 += (0x00100000) >> j0;
                i0 &= (~i); i1 = 0;
            }
        }
    } else if (j0 > 51) {
        if (j0 == 0x400) return x + x;                   /* inf or NaN */
        else return x;                                   /* x is integral */
    } else {
        i = ((uint32_t)(0xffffffff)) >> (j0 - 20);
        if ((i1 & i) == 0) return x;                     /* x is integral */
        if (fl_huge + x > 0.0) {                         /* raise inexact */
            if (i0 < 0) {
                if (j0 == 20) i0 += 1;
                else {
                    j = i1 + (1 << (52 - j0));
                    if (j < (uint32_t)i1) i0 += 1;       /* got a carry */
                    i1 = j;
                }
            }
            i1 &= (~i);
        }
    }
    bits = ((uint64_t)(uint32_t)i0 << 32) | (uint32_t)i1; /* INSERT_WORDS */
    __builtin_memcpy(&x, &bits, 8);
    return x;
}

__attribute__((always_inline)) static inline double olm_round(double x) {
    double t;
    uint32_t hx;
    uint64_t bits;
    __builtin_memcpy(&bits, &x, 8);                      /* GET_HIGH_WORD */
    hx = (uint32_t)(bits >> 32);
    if ((hx & 0x7fffffff) == 0x7ff00000)
        return (x + x);
    if (!(hx & 0x80000000)) {
        t = olm_floor(x);
        if (t - x <= -0.5)
            t += 1;
        return (t);
    } else {
        t = olm_floor(-x);
        if (t + x <= -0.5)
            t += 1;
        return (-t);
    }
}

__attribute__((always_inline)) static inline long long olm_llround(double x) {
    /* openlibm s_llround.c = s_lround.c with dtype=long long. INRANGE(x)
       short-circuits to compile-time TRUE for the double/long-long
       instantiation (dtype_max - DTYPE_MAX == 0.0 != 0.5), so the
       feraiseexcept/saturate branch is dead: llround(x) = (long long)round(x),
       round + fptosi only. */
    return (long long)olm_round(x);
}

long long slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_llround(q));
}
int main(void) { (void) slice(); return 0; }
