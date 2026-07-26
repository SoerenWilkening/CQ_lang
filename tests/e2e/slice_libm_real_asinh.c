/* slice_libm_real_asinh.c — bd q2wk (PredMux L6 Inc 5): the REAL openlibm
   asinh body, the LINK-layer proof (Rule 2) for census cell asinh.f64.

   CORPUS VENDORED (three files — the whole closure):
     /private/tmp/openlibm_reclone/src/s_asinh.c   — asinh(x), the entry point:
       the inf/NaN early-out, the |x|<2**-28 inexact-raise arm, and the
       three-way |x| classification (|x|>2**28 -> log(|x|)+ln2 ; 2**28>|x|>2
       -> log(2|x| + 1/(sqrt(x*x+1)+|x|)) ; else -> log1p(|x| + t/(1+
       sqrt(1+t)))), plus the final sign fixup `if(hx>0) return w; else -w`.
     /private/tmp/openlibm_reclone/src/e_log.c     — __ieee754_log, called by
       the two large-|x| arms. Vendored whole (subnormal scale-up, the
       |f|<2**-20 fast path with its own k==0 split, the degree-14 Remez
       polynomial and the i>0 accuracy split).
     /private/tmp/openlibm_reclone/src/s_log1p.c   — log1p, called by the
       small-|x| arm. Vendored whole (the 1+x<sqrt(2) classification, the
       x<=-1 domain arms, the |x|<2**-29 arms, the u=1+x correction term c,
       the u ~< sqrt(2) normalize/renormalize split, and the |f|<2**-20 fast
       path).
     After the keep-set rewrite below the closure is CLOSED: these three
     bodies call nothing but each other and hardware keeps.

   MECHANICAL EDITS (declared, in corpus order; no algorithmic change — every
   constant, branch, comparison operator, declaration order and expression is
   the corpus text):
     Shared, applied to all three files:
       - the math_private.h word macros actually used by the closure
         (EXTRACT_WORDS, GET_HIGH_WORD, SET_HIGH_WORD) are re-#defined at the
         top of this file as the __builtin_memcpy 8-byte-pun shim that clang
         -O1 folds to the same bitcast/shift IR the taint pass lowers (the
         same idiom as the verified acos / log10 / sinh slices). The macro
         CALL SITES in the three bodies are therefore untouched corpus text.
       - the BSD spelling u_int32_t replaced by uint32_t (<stdint.h>); no
         other type changed.
     e_log.c (vendored first, since asinh calls it):
       - deleted: the SCCS/Sun-1993 license header (corpus lines 1-12), the
         `#include "cdefs-compat.h"` (line 14), the //__FBSDID comment (line
         15), the __ieee754_log Method/Special-cases/Accuracy/Constants prose
         comment (lines 17-66), the 3 include lines float.h / openlibm_math.h
         / math_private.h (lines 68-71), the OLM_DLLEXPORT storage marker
         (line 87), and the trailing `#if (LDBL_MANT_DIG == 53)
         openlibm_weak_reference(log, logl)` block (lines 144-146; x86-64
         long double has 64 mantissa bits, so that block is not taken here).
       - entry point __ieee754_log renamed to olm_log and marked
         always_inline static inline.
       - `u_int32_t lx;` -> `uint32_t lx;` (the shared edit above).
     s_log1p.c (vendored second):
       - deleted: the SCCS/Sun-1993 license header (lines 1-11), the
         `#include "cdefs-compat.h"` (line 13), the //__FBSDID comment (line
         14), the log1p Method/Special-cases/Accuracy/Constants prose comment
         (lines 16-79), the 3 include lines float.h / openlibm_math.h /
         math_private.h (lines 81-84), the OLM_DLLEXPORT storage marker (line
         100), and the trailing `#if (LDBL_MANT_DIG == 53)
         openlibm_weak_reference(log1p, log1pl)` block (lines 177-179, not
         taken on x86-64).
       - entry point log1p renamed to olm_log1p, always_inline static inline.
       - NAME-COLLISION UNIQUIFICATION (the only rename inside a body): four
         file-scope `static const double` names in s_log1p.c collide with
         identically-named, identically-valued objects in e_log.c —
         ln2_hi / ln2_lo / two54 / zero. The s_log1p.c copies are renamed
         l1p_ln2_hi / l1p_ln2_lo / l1p_two54 / l1p_zero at their definitions
         and at every use inside olm_log1p; the literal values are the corpus
         values, unchanged. Lp1..Lp7 do not collide and keep their names.
       - `STRICT_ASSIGN(double,u,1.0+x);` (corpus line 128) expanded to
         `u = 1.0+x;`. That is the macro's expansion on this target verbatim:
         math_private.h:206-208 defines STRICT_ASSIGN(type,lval,rval) as
         ((lval) = (rval)) under `#ifndef __FreeBSD__`, and __FreeBSD__ is not
         defined for a darwin clang build — not-taken-preprocessor text.
     s_asinh.c (vendored last, the entry point):
       - deleted: the SCCS/Sun-1993 license header (lines 1-11), the
         `#include "cdefs-compat.h"` (line 13), the //__FBSDID comment (line
         14), the asinh Method prose comment (lines 16-25), the 3 include
         lines float.h / openlibm_math.h / math_private.h (lines 27-30), the
         OLM_DLLEXPORT storage marker (line 37), and the trailing
         `#if (LDBL_MANT_DIG == 53) openlibm_weak_reference(asinh, asinhl)`
         block (lines 60-62, not taken on x86-64).
       - entry point asinh renamed to olm_asinh, always_inline static inline;
         intra-body callee __ieee754_log renamed to the vendored olm_log and
         log1p to the vendored olm_log1p.
       - s_asinh.c's own file-scope statics one / ln2 / huge collide with
         nothing in the other two files and are kept verbatim.

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution):
     s_asinh.c calls fabs (3 sites: one per classification arm) and
     __ieee754_sqrt (2 sites: the 2<|x|<2**28 arm and the small arm). Both are
     HARDWARE KEEPS: at the real ship floor (plain clang -O1, builtins ON) the
     named calls fold to @llvm.fabs.f64 / @llvm.sqrt.f64 before codegen and
     cq-lowering rewrites those to cq_template_fabs_f64 / cq_template_sqrt_f64.
     The __builtin_fabs / __builtin_sqrt spellings emit exactly that construct
     and need no libm declaration. A keep has no injectable body, so vendoring
     openlibm's SOFTWARE e_sqrt.c / s_fabs.c here would misrepresent the ship
     floor (that blanket -fno-builtin resolution is the census bug bd 3c6m.60
     fixed). __ieee754_log and log1p are LIBRARY functions and are therefore
     vendored as source above, never builtin'd.

   FAITHFULNESS CHECK (run 2026-07-26, scripted): each of the three vendored
   regions was comment-stripped and tokenized against its corpus line range
   (e_log.c 73-142, s_log1p.c 86-175, s_asinh.c 32-58) with the declared
   renames reverse-applied. Token counts are equal and the sequences are
   identical: e_log 545/545, s_log1p 594/594, s_asinh 183/183.

   LOWERING EXERCISED (every figure below MEASURED on the lowered IR / the
   trace, not asserted; q is theta-tainted so no guard const-folds away):
     - pre-pass @slice after -O1 inlining: 75 basic blocks, 74 `br` (38 of
       them conditional) and 21 `phi`. Post-pass @slice: 2 basic blocks and
       exactly 1 `br`, an unconditional edge into the measure block (0
       conditional br). PredMux (PredMuxFlatten.cpp) flattened the entire
       three-body nest — the asinh |x| classification, the log
       subnormal/fast-path/i>0 splits and the log1p domain / correction-term /
       normalize splits — onto the select substrate.
     - rails: 969 cqrt_alloc_* in total (906 cqrt_alloc_i1 predicate rails,
       48 cqrt_alloc_f64, 14 cqrt_alloc_i32, 1 cqrt_alloc_i64) against 1787
       cqrt_free. Exactly 1 cqrt_ry_f64 and 1 cqrt_measure_f64 — the one
       user-written rotation and the one user-written measurement; the pass
       inserted no measurement (Rule 5).
     - merge substrate: 80 cqrt_copy_f64_controlled + 18
       cqrt_copy_i32_controlled + 2 cqrt_copy_i64_controlled controlled-copy
       merges, 1812 cqrt_toffoli flag conjunctions, 1348 cqrt_cnot and 100
       cqrt_x. Every fcmp/icmp template is paired 1:1 with its `_inv` strip
       (e.g. 149 cq_template_icmp_ule_i32_hl / 149 ..._inv, 55
       cq_template_fcmp_ule_f64_hl / 55 ..._inv).
     - keeps lowered 1:1, nothing dropped: 3 @llvm.fabs.f64 -> 3
       cq_template_fabs_f64 and 2 @llvm.sqrt.f64 -> 2 cq_template_sqrt_f64.
       Those counts equal the 3 fabs / 2 sqrt SOURCE sites exactly — all three
       classification arms survive -O1 and both sqrt sites are lowered.
       A third keep family comes from clang, not from the corpus text: with
       clang's default fp-contract the two Remez polynomials and the
       correction terms fuse into 48 @llvm.fmuladd.f64, which lower to 48
       fma templates (10 cq_template_fma_f64 + 18 _qlq + 12 _qql + 8 _qll) —
       again exactly 1:1, none dropped. fma/fmuladd is likewise a Rule-18
       keep.
     - 0 residual @cq_theta / @cq_measure calls in the lowered IR, and 0
       @llvm.* CALL SITES — but 3 now-unused `declare @llvm.*` lines do
       survive with no uses, so a bare grep for @llvm. is not a refutation of
       that claim. The trace is 8132 lines over 86 distinct symbols and
       contains cqrt_ry_f64 and cqrt_measure_f64; two consecutive runs of the
       linked binary are byte-identical. This slice is the LINK-layer proof
       (Rule 2) that every emitted symbol resolves, signature-matches, and the
       trace is stable. */
#include <stdint.h>

/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define GET_HIGH_WORD(i,d)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)(__w>>32); }while(0)
#define SET_HIGH_WORD(d,v)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0x00000000ffffffffULL)|((uint64_t)(uint32_t)(v)<<32); __builtin_memcpy(&(d),&__w,8); }while(0)

/* ---- vendored from openlibm/src/e_log.c ---- */
static const double
ln2_hi  =  6.93147180369123816490e-01,	/* 3fe62e42 fee00000 */
ln2_lo  =  1.90821492927058770002e-10,	/* 3dea39ef 35793c76 */
two54   =  1.80143985094819840000e+16,  /* 43500000 00000000 */
Lg1 = 6.666666666666735130e-01,  /* 3FE55555 55555593 */
Lg2 = 3.999999999940941908e-01,  /* 3FD99999 9997FA04 */
Lg3 = 2.857142874366239149e-01,  /* 3FD24924 94229359 */
Lg4 = 2.222219843214978396e-01,  /* 3FCC71C5 1D8E78AF */
Lg5 = 1.818357216161805012e-01,  /* 3FC74664 96CB03DE */
Lg6 = 1.531383769920937332e-01,  /* 3FC39A09 D078C69F */
Lg7 = 1.479819860511658591e-01;  /* 3FC2F112 DF3E5244 */

static const double zero   =  0.0;

__attribute__((always_inline)) static inline double
olm_log(double x)
{
	double hfsq,f,s,z,R,w,t1,t2,dk;
	int32_t k,hx,i,j;
	uint32_t lx;

	EXTRACT_WORDS(hx,lx,x);

	k=0;
	if (hx < 0x00100000) {			/* x < 2**-1022  */
	    if (((hx&0x7fffffff)|lx)==0)
		return -two54/zero;		/* log(+-0)=-inf */
	    if (hx<0) return (x-x)/zero;	/* log(-#) = NaN */
	    k -= 54; x *= two54; /* subnormal number, scale up x */
	    GET_HIGH_WORD(hx,x);
	}
	if (hx >= 0x7ff00000) return x+x;
	k += (hx>>20)-1023;
	hx &= 0x000fffff;
	i = (hx+0x95f64)&0x100000;
	SET_HIGH_WORD(x,hx|(i^0x3ff00000));	/* normalize x or x/2 */
	k += (i>>20);
	f = x-1.0;
	if((0x000fffff&(2+hx))<3) {	/* -2**-20 <= f < 2**-20 */
	    if(f==zero) {
		if(k==0) {
		    return zero;
		} else {
		    dk=(double)k;
		    return dk*ln2_hi+dk*ln2_lo;
		}
	    }
	    R = f*f*(0.5-0.33333333333333333*f);
	    if(k==0) return f-R; else {dk=(double)k;
	    	     return dk*ln2_hi-((R-dk*ln2_lo)-f);}
	}
 	s = f/(2.0+f);
	dk = (double)k;
	z = s*s;
	i = hx-0x6147a;
	w = z*z;
	j = 0x6b851-hx;
	t1= w*(Lg2+w*(Lg4+w*Lg6));
	t2= z*(Lg1+w*(Lg3+w*(Lg5+w*Lg7)));
	i |= j;
	R = t2+t1;
	if(i>0) {
	    hfsq=0.5*f*f;
	    if(k==0) return f-(hfsq-s*(hfsq+R)); else
		     return dk*ln2_hi-((hfsq-(s*(hfsq+R)+dk*ln2_lo))-f);
	} else {
	    if(k==0) return f-s*(f-R); else
		     return dk*ln2_hi-((s*(f-R)-dk*ln2_lo)-f);
	}
}

/* ---- vendored from openlibm/src/s_log1p.c ----
   (ln2_hi/ln2_lo/two54/zero uniquified to l1p_* — they collide with the
   identically-valued e_log.c objects above; values unchanged.) */
static const double
l1p_ln2_hi  =  6.93147180369123816490e-01,	/* 3fe62e42 fee00000 */
l1p_ln2_lo  =  1.90821492927058770002e-10,	/* 3dea39ef 35793c76 */
l1p_two54   =  1.80143985094819840000e+16,  /* 43500000 00000000 */
Lp1 = 6.666666666666735130e-01,  /* 3FE55555 55555593 */
Lp2 = 3.999999999940941908e-01,  /* 3FD99999 9997FA04 */
Lp3 = 2.857142874366239149e-01,  /* 3FD24924 94229359 */
Lp4 = 2.222219843214978396e-01,  /* 3FCC71C5 1D8E78AF */
Lp5 = 1.818357216161805012e-01,  /* 3FC74664 96CB03DE */
Lp6 = 1.531383769920937332e-01,  /* 3FC39A09 D078C69F */
Lp7 = 1.479819860511658591e-01;  /* 3FC2F112 DF3E5244 */

static const double l1p_zero = 0.0;

__attribute__((always_inline)) static inline double
olm_log1p(double x)
{
	double hfsq,f,c,s,z,R,u;
	int32_t k,hx,hu,ax;

	GET_HIGH_WORD(hx,x);
	ax = hx&0x7fffffff;

	k = 1;
	if (hx < 0x3FDA827A) {			/* 1+x < sqrt(2)+ */
	    if(ax>=0x3ff00000) {		/* x <= -1.0 */
		if(x==-1.0) return -l1p_two54/l1p_zero; /* log1p(-1)=+inf */
		else return (x-x)/(x-x);	/* log1p(x<-1)=NaN */
	    }
	    if(ax<0x3e200000) {			/* |x| < 2**-29 */
		if(l1p_two54+x>l1p_zero		/* raise inexact */
	            &&ax<0x3c900000) 		/* |x| < 2**-54 */
		    return x;
		else
		    return x - x*x*0.5;
	    }
	    if(hx>0||hx<=((int32_t)0xbfd2bec4)) {
		k=0;f=x;hu=1;}		/* sqrt(2)/2- <= 1+x < sqrt(2)+ */
	}
	if (hx >= 0x7ff00000) return x+x;
	if(k!=0) {
	    if(hx<0x43400000) {
		u = 1.0+x;
		GET_HIGH_WORD(hu,u);
	        k  = (hu>>20)-1023;
	        c  = (k>0)? 1.0-(u-x):x-(u-1.0);/* correction term */
		c /= u;
	    } else {
		u  = x;
		GET_HIGH_WORD(hu,u);
	        k  = (hu>>20)-1023;
		c  = 0;
	    }
	    hu &= 0x000fffff;
	    /*
	     * The approximation to sqrt(2) used in thresholds is not
	     * critical.  However, the ones used above must give less
	     * strict bounds than the one here so that the k==0 case is
	     * never reached from here, since here we have committed to
	     * using the correction term but don't use it if k==0.
	     */
	    if(hu<0x6a09e) {			/* u ~< sqrt(2) */
	        SET_HIGH_WORD(u,hu|0x3ff00000);	/* normalize u */
	    } else {
	        k += 1;
		SET_HIGH_WORD(u,hu|0x3fe00000);	/* normalize u/2 */
	        hu = (0x00100000-hu)>>2;
	    }
	    f = u-1.0;
	}
	hfsq=0.5*f*f;
	if(hu==0) {	/* |f| < 2**-20 */
	    if(f==l1p_zero) {
		if(k==0) {
		    return l1p_zero;
		} else {
		    c += k*l1p_ln2_lo;
		    return k*l1p_ln2_hi+c;
		}
	    }
	    R = hfsq*(1.0-0.66666666666666666*f);
	    if(k==0) return f-R; else
	    	     return k*l1p_ln2_hi-((R-(k*l1p_ln2_lo+c))-f);
	}
 	s = f/(2.0+f);
	z = s*s;
	R = z*(Lp1+z*(Lp2+z*(Lp3+z*(Lp4+z*(Lp5+z*(Lp6+z*Lp7))))));
	if(k==0) return f-(hfsq-s*(hfsq+R)); else
		 return k*l1p_ln2_hi-((hfsq-(s*(hfsq+R)+(k*l1p_ln2_lo+c)))-f);
}

/* ---- vendored from openlibm/src/s_asinh.c ---- */
static const double
one =  1.00000000000000000000e+00, /* 0x3FF00000, 0x00000000 */
ln2 =  6.93147180559945286227e-01, /* 0x3FE62E42, 0xFEFA39EF */
huge=  1.00000000000000000000e+300;

__attribute__((always_inline)) static inline double
olm_asinh(double x)
{
	double t,w;
	int32_t hx,ix;
	GET_HIGH_WORD(hx,x);
	ix = hx&0x7fffffff;
	if(ix>=0x7ff00000) return x+x;	/* x is inf or NaN */
	if(ix< 0x3e300000) {	/* |x|<2**-28 */
	    if(huge+x>one) return x;	/* return x inexact except 0 */
	}
	if(ix>0x41b00000) {	/* |x| > 2**28 */
	    w = olm_log(__builtin_fabs(x))+ln2;
	} else if (ix>0x40000000) {	/* 2**28 > |x| > 2.0 */
	    t = __builtin_fabs(x);
	    w = olm_log(2.0*t+one/(__builtin_sqrt(x*x+one)+t));
	} else {		/* 2.0 > |x| > 2**-28 */
	    t = x*x;
	    w =olm_log1p(__builtin_fabs(x)+t/(one+__builtin_sqrt(one+t)));
	}
	if(hx>0) return w; else return -w;
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_asinh(q));
}
int main(void) { (void) slice(); return 0; }
