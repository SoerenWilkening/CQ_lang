/* slice_libm_real_acosf.c — bd 3c6m.60: the REAL openlibm acosf body.

   Cell: acosf.f32. Corpus file vendored: /private/tmp/openlibm_reclone/src/e_acosf.c
   (defines __ieee754_acosf, which math_private.h:312 maps to the public name
   acosf; fdlibm-derived, BSD-licensed). Its closure is a single distinct inner
   callee, sqrtf, called at TWO sites (corpus e_acosf.c:60 and :67), so e_acosf.c
   is the ONLY corpus file this closure needs — nothing else is vendored.

   ATTRIBUTION — the SunPro notice, preserved HERE because the vendored body
   below no longer carries it: "Copyright (C) 1993 by Sun Microsystems, Inc. All
   rights reserved. Developed at SunPro, a Sun Microsystems, Inc. business.
   Permission to use, copy, modify, and distribute this software is freely
   granted, provided that this notice is preserved." Deleting that block from the
   body is a LICENSING / owner call, NOT a mechanical edit; it is listed in the
   edit list below only so the diff-vs-corpus contract stays complete.

   This is the f32 sibling of slice_libm_real_acos.c and it pins the same
   KEEP-SET HARNESS FIX. e_acosf.c contains ZERO loops, yet the census reported
   acosf.f32 as a loop-carried decline: the corpus recipe built every openlibm .c
   with a blanket -fno-builtin, so the inner sqrtf(z) resolved to openlibm's
   SOFTWARE __ieee754_sqrtf and dragged in ITS normalize loop. At the real ship
   floor — plain `clang -O1`, builtins ON — sqrtf is a Rule-18 HARDWARE KEEP: it
   folds to @llvm.sqrt.f32 before codegen and cq-lowering rewrites it to
   cq_template_sqrt_f32. So `__builtin_sqrtf` here is the deliberate spelling of
   exactly the construct the ship floor emits for the named call (no libm
   declaration needed, and no body substitution — a keep has no injectable body
   by definition, Rule 18).

   Declared edits, and no others (this list is the faithfulness contract: every
   difference from the corpus file is declared here):
     - DELETED the three include lines, the SunPro copyright block (a licensing
       call, see ATTRIBUTION above — the notice lives in this header) and the
       commented FreeBSD id line, and the OLM_DLLEXPORT export decoration on the
       entry point;
     - ADDED `#include <stdint.h>`: int32_t / uint32_t reach the corpus body
       transitively through math_private.h, which is not vendored;
     - renamed __ieee754_acosf -> olm_acosf and marked it always_inline static
       inline (force-inlining reproduces the census inline shape at plain -O1 and
       collapses the closure to one straight-line body);
     - expanded the two math_private.h float word macros in place to the
       __builtin_memcpy idiom clang -O1 folds to the same bitcast IR, and ADDED
       the `uint32_t word;` local that shim needs as its punning slot (the corpus
       macros declare their own union internally, so the corpus body has no such
       declaration; nothing else here reads or writes `word`). Both punned
       objects (x and df) are declared `float` in the corpus source, so each pun
       is a 4-byte copy in and out of a float — no double is involved anywhere in
       this body (the bd 3c6m.53 f32 double/float shim hazard does not arise);
     - rewrote the inner sqrtf(z) as __builtin_sqrtf(z) at BOTH call sites, per
       the keep-set rule above. sqrtf is the only keep-set name in this body;
     - ADDED the slice-only comment block above olm_acosf, this header, and the
       slice()/main() driver at the end of the file.
   Every algorithm expression, branch, cast and literal — including the file-scope
   static const coefficient table (one, pi, pio2_hi, pS0..pS2, qS1) and the
   `static volatile float pio2_lo` qualifier — is verbatim in the SOURCE. (What
   the PASS then does with that volatile qualifier is a separate matter — see the
   SCOPE CAVEAT below.)

   Lowering exercised: the classification cascade over the tainted float word
   (|x|>=1 / |x|<0.5 / x<-0.5 / x>0.5) flattens through PredMux onto the
   controlled-copy merge substrate (12 cqrt_copy_f32_controlled over 11 i1 flag
   rails); the degree-2 pS Horner numerator and the one-term qS denominator ride
   the arithmetic templates, largely as contracted fma — the trace carries 14
   cq_template_fma_f32* (2 QQQ + 5 _qql + 7 _qll) against 7 fmul, 5 fadd and 3
   fsub; __builtin_sqrtf lowers as the f32 sqrt keep, twice (2
   cq_template_sqrt_f32, one per call site);
   SET_FLOAT_WORD(df, idf&0xfffff000) is the register bit-mask
   cq_template_and_i32_hl(h7, -4096) between two bitcast templates after SROA.
   NOTE: clang -O1 canonicalizes part of the `hx & 0x7fffffff` magnitude test into
   @llvm.fabs.f32, so the trace also contains exactly one cq_template_fabs_f32 —
   fabs is itself a Rule-18 keep, so that canonicalization stays inside the keep
   set.

   SCOPE CAVEAT — this golden does NOT exercise volatile memory traffic; it
   exercises the fold that REMOVES it. The source keeps fdlibm's anti-const-fold
   `volatile` on pio2_lo verbatim, but the pass deliberately folds it away:
   pre-pass IR has 4 `load volatile float, ptr @pio2_lo`; the post-pass module has
   ZERO loads and ZERO occurrences of the token `volatile` (@pio2_lo survives only
   as an unused internal global). The mechanism is foldVolatileConstGlobalLoads
   (ir-pass/src/QramLowering.cpp, "3c6m.14 Inc 3" — the const-GLOBAL sibling of bd
   etiq's alloca fold, run at both CQLoweringPass entry points). It is NOT bd
   zco4: that ticket is promoteVolatileScalarLocals, for volatile scalar ALLOCAS,
   and it explicitly declines volatile globals. Each load is replaced by the exact
   initializer, and two whole return expressions const-fold to a single alloc
   (pio2_hi+pio2_lo -> cqrt_alloc_f32 0x3FF921FB60000000, pi+2.0*pio2_lo ->
   cqrt_alloc_f32 0x400921FB60000000), so the unitary is unaffected — but nothing
   downstream of this golden should be read as evidence that CQ preserves the
   volatile idiom as a real memory access. It does not.

   This slice is the LINK-layer proof (Rule 2) that every emitted symbol resolves
   and the trace is stable. */
#include <stdint.h>

static const float
one =  1.0000000000e+00, /* 0x3F800000 */
pi =  3.1415925026e+00, /* 0x40490fda */
pio2_hi =  1.5707962513e+00; /* 0x3fc90fda */
static volatile float
pio2_lo =  7.5497894159e-08; /* 0x33a22168 */
static const float
pS0 =  1.6666586697e-01,
pS1 = -4.2743422091e-02,
pS2 = -8.6563630030e-03,
qS1 = -7.0662963390e-01;

/* openlibm src/e_acosf.c __ieee754_acosf (verbatim; GET_FLOAT_WORD /
   SET_FLOAT_WORD expanded to the __builtin_memcpy shim, sqrtf -> __builtin_sqrtf
   which is the SAME @llvm.sqrt.f32 the ship floor emits for the named call). */
__attribute__((always_inline)) static inline float
olm_acosf(float x)
{
	float z,p,q,r,w,s,c,df;
	int32_t hx,ix;
	uint32_t word;
	__builtin_memcpy(&word,&x,4); hx = (int32_t)word;	/* GET_FLOAT_WORD(hx,x) */
	ix = hx&0x7fffffff;
	if(ix>=0x3f800000) {		/* |x| >= 1 */
	    if(ix==0x3f800000) {	/* |x| == 1 */
		if(hx>0) return 0.0;	/* acos(1) = 0 */
		else return pi+(float)2.0*pio2_lo;	/* acos(-1)= pi */
	    }
	    return (x-x)/(x-x);		/* acos(|x|>1) is NaN */
	}
	if(ix<0x3f000000) {	/* |x| < 0.5 */
	    if(ix<=0x32800000) return pio2_hi+pio2_lo;/*if|x|<2**-26*/
	    z = x*x;
	    p = z*(pS0+z*(pS1+z*pS2));
	    q = one+z*qS1;
	    r = p/q;
	    return pio2_hi - (x - (pio2_lo-x*r));
	} else  if (hx<0) {		/* x < -0.5 */
	    z = (one+x)*(float)0.5;
	    p = z*(pS0+z*(pS1+z*pS2));
	    q = one+z*qS1;
	    s = __builtin_sqrtf(z);
	    r = p/q;
	    w = r*s-pio2_lo;
	    return pi - (float)2.0*(s+w);
	} else {			/* x > 0.5 */
	    int32_t idf;
	    z = (one-x)*(float)0.5;
	    s = __builtin_sqrtf(z);
	    df = s;
	    __builtin_memcpy(&word,&df,4); idf = (int32_t)word;	/* GET_FLOAT_WORD(idf,df) */
	    word = (uint32_t)(idf&0xfffff000);			/* SET_FLOAT_WORD(df,idf&0xfffff000) */
	    __builtin_memcpy(&df,&word,4);
	    c  = (z-df*df)/(s+df);
	    p = z*(pS0+z*(pS1+z*pS2));
	    q = one+z*qS1;
	    r = p/q;
	    w = r*s+c;
	    return (float)2.0*(df+w);
	}
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_acosf(q));
}
int main(void) { (void) slice(); return 0; }
