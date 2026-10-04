/* slice_libm_real_acosh.c — bd q2wk / PredMux L6 Inc 5: the REAL openlibm
   acosh body (f64), with its whole library closure vendored as source.

   CORPUS VENDORED (three files; this IS the whole closure):
     /private/tmp/openlibm_reclone/src/e_acosh.c   — __ieee754_acosh(x), the entire
       algorithm: the EXTRACT_WORDS exponent-word classification chain
       (x<1 NaN arm, x>2**28 arm with its inf/NaN sub-arm, the acosh(1)==0
       exact arm, the 2<x<2**28 arm, the 1<x<2 arm) — 5 arms, 6 `return`
       statements, all present verbatim.
     /private/tmp/openlibm_reclone/src/e_log.c     — __ieee754_log(x), called from
       two of acosh's arms. LIBRARY function, so Rule 18 requires the source:
       vendored whole (subnormal scale-up, the |f|<2**-20 fast path with its
       own k==0 split, the i>0 polynomial split, Lg1..Lg7).
     /private/tmp/openlibm_reclone/src/s_log1p.c   — log1p(x), called from acosh's
       1<x<2 arm. LIBRARY function, vendored whole (the sqrt(2)/2 window
       classification, the |x|<2**-29 and |x|<2**-54 arms, the 2**53 split,
       the u-normalization pair, Lp1..Lp7).
     After the keep-set rewrite below, those three bodies call nothing but
     hardware keeps, so the closure is closed.  DEFINITION ORDER: e_log.c,
     then s_log1p.c, then e_acosh.c — the corpus files are three separate
     translation units; concatenating them into one requires callees first.
     No statement was reordered inside any body.

   MECHANICAL EDITS (declared per file, in corpus order; no algorithmic
   change — every constant, branch, comparison and expression is the corpus
   text):

     src/e_log.c
       - deleted: the SCCS/license header block (lines 1-12), #include
         "cdefs-compat.h" (14), the //__FBSDID comment (15), the Method /
         Special cases / Accuracy / Constants prose (17-66), #include
         <float.h> (68), #include <openlibm_math.h> (69), #include
         "math_private.h" (71), the OLM_DLLEXPORT storage marker (87), and the
         trailing `#if (LDBL_MANT_DIG == 53) openlibm_weak_reference(log,logl)`
         block (144-146; x86-64 long double has 64 mantissa bits, so that
         block is not taken here). All comment / include / storage-class /
         not-taken-preprocessor text; no executable statement removed.
       - entry point __ieee754_log renamed olm_log, marked always_inline
         static inline (forces the census inline shape at plain -O1).
       - COLLIDING FILE-SCOPE STATICS UNIQUIFIED: e_log.c and s_log1p.c both
         define file-scope `static const double ln2_hi, ln2_lo, two54, zero`
         with identical values. Concatenating the two TUs collides on all
         four, so e_log.c's copies are suffixed _log and s_log1p.c's _log1p.
         Rename only — the four literals are unchanged and each body still
         reads its own file's constants. Lg1..Lg7 (e_log.c) and Lp1..Lp7
         (s_log1p.c) do not collide and are untouched.
       - math_private.h word macros expanded to the __builtin_memcpy 8-byte
         pun shim that clang -O1 folds to the same bitcast IR: 1
         EXTRACT_WORDS, 1 GET_HIGH_WORD, 1 SET_HIGH_WORD (a SET expansion is
         the macro's read-modify-write pair, so 2 memcpys). The macro-local
         union temp becomes one function-scope `uint64_t bits`; every
         expansion is a self-contained read-then-write with no intervening
         use, so the sharing is semantically identical.
       - BSD spelling u_int32_t -> uint32_t (stdint.h). No other type changed.

     src/s_log1p.c
       - deleted: the SCCS/license header block (lines 1-11), #include
         "cdefs-compat.h" (13), the //__FBSDID comment (14), the Method /
         Special cases / Accuracy / Constants / HP-15C prose (16-79),
         #include <float.h> (81), #include <openlibm_math.h> (82), #include
         "math_private.h" (84), the OLM_DLLEXPORT storage marker (100), and
         the trailing `#if (LDBL_MANT_DIG == 53) openlibm_weak_reference(
         log1p,log1pl)` block (177-179; not taken on x86-64). All comment /
         include / storage-class / not-taken-preprocessor text.
       - entry point log1p renamed olm_log1p, marked always_inline static
         inline.
       - ln2_hi / ln2_lo / two54 / zero suffixed _log1p (the collision
         declared above).
       - math_private.h word macros expanded to the same __builtin_memcpy
         shim: 3 GET_HIGH_WORD, 2 SET_HIGH_WORD.
       - STRICT_ASSIGN(double,u,1.0+x) expanded to `u = 1.0+x`. That is the
         literal expansion selected here: math_private.h line 206-207 defines
         STRICT_ASSIGN(type,lval,rval) as ((lval) = (rval)) under
         `#ifndef __FreeBSD__`, which is the branch taken on this darwin
         target. Macro expansion, not a semantic edit.

     src/e_acosh.c
       - deleted: the SCCS/license header block (lines 1-13), #include
         "cdefs-compat.h" (15), the //__FBSDID comment (16), the Method /
         Special cases prose (18-30), #include <float.h> (32), #include
         <openlibm_math.h> (33), #include "math_private.h" (35), the
         OLM_DLLEXPORT storage marker (41), and the trailing
         `#if (LDBL_MANT_DIG == 53) openlibm_weak_reference(acosh,acoshl)`
         block (66-68; not taken on x86-64).
       - entry point __ieee754_acosh renamed olm_acosh, marked always_inline
         static inline; the two intra-body __ieee754_log calls renamed
         olm_log and the one log1p call renamed olm_log1p (the vendored
         names). e_acosh.c's own file-scope statics `one` and `ln2` collide
         with nothing and are verbatim.
       - EXTRACT_WORDS(hx,lx,x) expanded to the __builtin_memcpy shim (1
         site).
       - u_int32_t -> uint32_t.

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution):
     e_acosh.c calls sqrt at 2 sites (the 2<x<2**28 arm's sqrt(t-one) and the
     1<x<2 arm's sqrt(2.0*t+t*t)). sqrt is a HARDWARE KEEP: at the real ship
     floor (plain clang -O1, builtins ON) the named call folds to
     @llvm.sqrt.f64 before codegen and cq-lowering rewrites that to
     cq_template_sqrt_f64. The __builtin_sqrt spelling emits exactly that
     construct and needs no libm declaration. By definition a keep has no
     injectable body, so vendoring openlibm's software e_sqrt.c here would
     MISREPRESENT the ship floor (that is the census bug bd 3c6m.60 fixed).
     log / log1p are NOT keeps — they are library functions with no hardware
     instruction and no @llvm intrinsic at -O1, which is exactly why both are
     vendored as source above.

   LOWERING EXERCISED (every figure below MEASURED — the IR counts by
   grepping call sites in the lowered /tmp/acosh_s2.ll, the trace counts by
   grepping the emitted trace; none is asserted):
     Pre-pass @slice (after clang -O1, always_inline having collapsed the
     3-function closure into one body) has 72 basic blocks and 71 br, 37 of
     them conditional — this is the fdlibm exponent-word classification chain
     that bd q2wk's E6 widening (an i1 PHI used as a conditional-branch
     condition, and a branch condition the flatten itself taints) unblocked.
     The lowered @slice has 2 basic blocks and retains exactly 1 br, an
     unconditional edge into the block holding cqrt_measure_f64/ret:
     PredMuxFlatten straight-lined the whole nest onto the select substrate.
     Rails and merges on the lowered IR: 47 cqrt_alloc_f64 + 11
     cqrt_alloc_i32 + 763 cqrt_alloc_i1 allocations (the one theta rail plus
     the flatten's work rails and edge-predicate flags), 76
     cqrt_copy_f64_controlled + 16 cqrt_copy_i32_controlled controlled-copy
     merges, 1526 cqrt_toffoli flag conjunctions, 1088 cqrt_cnot, 92 cqrt_x
     (the !flag brackets), 1508 cqrt_free, 0 cqrt_cswap. Exactly 1 cqrt_ry_f64
     and 1 cqrt_measure_f64 (and 0 cqrt_rz_f64 — acosh writes no phase).
     Every compare template is emitted paired with its _inv strip (e.g. 115
     cq_template_icmp_sge_i32_hl and 115 cq_template_icmp_sge_i32_hl_inv).
     Rule-18 keeps: clang -O1 hands the pass 2 @llvm.sqrt.f64 call sites and
     48 @llvm.fmuladd.f64 call sites (its default fp-contract fuses the
     fdlibm polynomial products). Both families lower 1:1 and nothing is
     dropped: 2 -> 2 cq_template_sqrt_f64, and 48 -> 48 fma templates (10
     cq_template_fma_f64, 19 _qlq, 11 _qql, 8 _qll). BOTH source sqrt sites
     survive -O1 and both are lowered; neither was folded nor tail-merged
     away. The lowered module has ZERO @llvm.* CALL SITES, but 2 now-unused
     `declare @llvm.*` lines (sqrt.f64, fmuladd.f64) do survive with no uses,
     so a bare grep for @llvm. is not a refutation of that claim.
     The lowered module has ZERO residual @cq_* intrinsic calls. The trace is
     6860 lines over 75 distinct symbols (5129 cqrt_* + 1731 cq_template_*)
     and is byte-identical across two runs (determinism checked). Every
     cqrt_ and cq_template_ IR call-site count above equals its trace line
     count, as it must for a straight-line function. This slice is the
     LINK-layer proof (Rule 2) that every emitted symbol resolves,
     signature-matches, and the trace is stable. */
#include <stdint.h>

/* ---- openlibm src/e_log.c (verbatim; word macros -> memcpy shim, the four
   colliding file-scope constants suffixed _log) ---------------------------- */

static const double
ln2_hi_log  =  6.93147180369123816490e-01,	/* 3fe62e42 fee00000 */
ln2_lo_log  =  1.90821492927058770002e-10,	/* 3dea39ef 35793c76 */
two54_log   =  1.80143985094819840000e+16,  /* 43500000 00000000 */
Lg1 = 6.666666666666735130e-01,  /* 3FE55555 55555593 */
Lg2 = 3.999999999940941908e-01,  /* 3FD99999 9997FA04 */
Lg3 = 2.857142874366239149e-01,  /* 3FD24924 94229359 */
Lg4 = 2.222219843214978396e-01,  /* 3FCC71C5 1D8E78AF */
Lg5 = 1.818357216161805012e-01,  /* 3FC74664 96CB03DE */
Lg6 = 1.531383769920937332e-01,  /* 3FC39A09 D078C69F */
Lg7 = 1.479819860511658591e-01;  /* 3FC2F112 DF3E5244 */

static const double zero_log   =  0.0;

__attribute__((always_inline)) static inline double
olm_log(double x)
{
	double hfsq,f,s,z,R,w,t1,t2,dk;
	int32_t k,hx,i,j;
	uint32_t lx;
	uint64_t bits;

	__builtin_memcpy(&bits, &x, 8);			/* EXTRACT_WORDS(hx,lx,x) */
	hx = (int32_t)(bits >> 32);
	lx = (uint32_t)bits;

	k=0;
	if (hx < 0x00100000) {			/* x < 2**-1022  */
	    if (((hx&0x7fffffff)|lx)==0)
		return -two54_log/zero_log;		/* log(+-0)=-inf */
	    if (hx<0) return (x-x)/zero_log;	/* log(-#) = NaN */
	    k -= 54; x *= two54_log; /* subnormal number, scale up x */
	    __builtin_memcpy(&bits, &x, 8);		/* GET_HIGH_WORD(hx,x) */
	    hx = (int32_t)(bits >> 32);
	}
	if (hx >= 0x7ff00000) return x+x;
	k += (hx>>20)-1023;
	hx &= 0x000fffff;
	i = (hx+0x95f64)&0x100000;
	__builtin_memcpy(&bits, &x, 8);		/* SET_HIGH_WORD(x,hx|(i^0x3ff00000)) */
	bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)(hx|(i^0x3ff00000)) << 32);
	__builtin_memcpy(&x, &bits, 8);		/* normalize x or x/2 */
	k += (i>>20);
	f = x-1.0;
	if((0x000fffff&(2+hx))<3) {	/* -2**-20 <= f < 2**-20 */
	    if(f==zero_log) {
		if(k==0) {
		    return zero_log;
		} else {
		    dk=(double)k;
		    return dk*ln2_hi_log+dk*ln2_lo_log;
		}
	    }
	    R = f*f*(0.5-0.33333333333333333*f);
	    if(k==0) return f-R; else {dk=(double)k;
	    	     return dk*ln2_hi_log-((R-dk*ln2_lo_log)-f);}
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
		     return dk*ln2_hi_log-((hfsq-(s*(hfsq+R)+dk*ln2_lo_log))-f);
	} else {
	    if(k==0) return f-s*(f-R); else
		     return dk*ln2_hi_log-((s*(f-R)-dk*ln2_lo_log)-f);
	}
}

/* ---- openlibm src/s_log1p.c (verbatim; word macros -> memcpy shim,
   STRICT_ASSIGN expanded, the four colliding constants suffixed _log1p) ---- */

static const double
ln2_hi_log1p  =  6.93147180369123816490e-01,	/* 3fe62e42 fee00000 */
ln2_lo_log1p  =  1.90821492927058770002e-10,	/* 3dea39ef 35793c76 */
two54_log1p   =  1.80143985094819840000e+16,  /* 43500000 00000000 */
Lp1 = 6.666666666666735130e-01,  /* 3FE55555 55555593 */
Lp2 = 3.999999999940941908e-01,  /* 3FD99999 9997FA04 */
Lp3 = 2.857142874366239149e-01,  /* 3FD24924 94229359 */
Lp4 = 2.222219843214978396e-01,  /* 3FCC71C5 1D8E78AF */
Lp5 = 1.818357216161805012e-01,  /* 3FC74664 96CB03DE */
Lp6 = 1.531383769920937332e-01,  /* 3FC39A09 D078C69F */
Lp7 = 1.479819860511658591e-01;  /* 3FC2F112 DF3E5244 */

static const double zero_log1p = 0.0;

__attribute__((always_inline)) static inline double
olm_log1p(double x)
{
	double hfsq,f,c,s,z,R,u;
	int32_t k,hx,hu,ax;
	uint64_t bits;

	__builtin_memcpy(&bits, &x, 8);		/* GET_HIGH_WORD(hx,x) */
	hx = (int32_t)(bits >> 32);
	ax = hx&0x7fffffff;

	k = 1;
	if (hx < 0x3FDA827A) {			/* 1+x < sqrt(2)+ */
	    if(ax>=0x3ff00000) {		/* x <= -1.0 */
		if(x==-1.0) return -two54_log1p/zero_log1p; /* log1p(-1)=+inf */
		else return (x-x)/(x-x);	/* log1p(x<-1)=NaN */
	    }
	    if(ax<0x3e200000) {			/* |x| < 2**-29 */
		if(two54_log1p+x>zero_log1p	/* raise inexact */
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
		u = 1.0+x;			/* STRICT_ASSIGN(double,u,1.0+x) */
		__builtin_memcpy(&bits, &u, 8);	/* GET_HIGH_WORD(hu,u) */
		hu = (int32_t)(bits >> 32);
	        k  = (hu>>20)-1023;
	        c  = (k>0)? 1.0-(u-x):x-(u-1.0);/* correction term */
		c /= u;
	    } else {
		u  = x;
		__builtin_memcpy(&bits, &u, 8);	/* GET_HIGH_WORD(hu,u) */
		hu = (int32_t)(bits >> 32);
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
		__builtin_memcpy(&bits, &u, 8);	/* SET_HIGH_WORD(u,hu|0x3ff00000) */
		bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)(hu|0x3ff00000) << 32);
		__builtin_memcpy(&u, &bits, 8);	/* normalize u */
	    } else {
	        k += 1;
		__builtin_memcpy(&bits, &u, 8);	/* SET_HIGH_WORD(u,hu|0x3fe00000) */
		bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)(hu|0x3fe00000) << 32);
		__builtin_memcpy(&u, &bits, 8);	/* normalize u/2 */
	        hu = (0x00100000-hu)>>2;
	    }
	    f = u-1.0;
	}
	hfsq=0.5*f*f;
	if(hu==0) {	/* |f| < 2**-20 */
	    if(f==zero_log1p) {
		if(k==0) {
		    return zero_log1p;
		} else {
		    c += k*ln2_lo_log1p;
		    return k*ln2_hi_log1p+c;
		}
	    }
	    R = hfsq*(1.0-0.66666666666666666*f);
	    if(k==0) return f-R; else
	    	     return k*ln2_hi_log1p-((R-(k*ln2_lo_log1p+c))-f);
	}
 	s = f/(2.0+f);
	z = s*s;
	R = z*(Lp1+z*(Lp2+z*(Lp3+z*(Lp4+z*(Lp5+z*(Lp6+z*Lp7))))));
	if(k==0) return f-(hfsq-s*(hfsq+R)); else
		 return k*ln2_hi_log1p-((hfsq-(s*(hfsq+R)+(k*ln2_lo_log1p+c)))-f);
}

/* ---- openlibm src/e_acosh.c (verbatim; EXTRACT_WORDS -> memcpy shim, sqrt
   spelled as the hardware-keep builtin, callees renamed to the vendored
   olm_ names) -------------------------------------------------------------- */

static const double
one	= 1.0,
ln2	= 6.93147180559945286227e-01;  /* 0x3FE62E42, 0xFEFA39EF */

__attribute__((always_inline)) static inline double
olm_acosh(double x)
{
	double t;
	int32_t hx;
	uint32_t lx;
	uint64_t bits;

	__builtin_memcpy(&bits, &x, 8);		/* EXTRACT_WORDS(hx,lx,x) */
	hx = (int32_t)(bits >> 32);
	lx = (uint32_t)bits;
	if(hx<0x3ff00000) {		/* x < 1 */
	    return (x-x)/(x-x);
	} else if(hx >=0x41b00000) {	/* x > 2**28 */
	    if(hx >=0x7ff00000) {	/* x is inf of NaN */
	        return x+x;
	    } else
		return olm_log(x)+ln2;	/* acosh(huge)=log(2x) */
	} else if(((hx-0x3ff00000)|lx)==0) {
	    return 0.0;			/* acosh(1) = 0 */
	} else if (hx > 0x40000000) {	/* 2**28 > x > 2 */
	    t=x*x;
	    return olm_log(2.0*x-one/(x+__builtin_sqrt(t-one)));
	} else {			/* 1<x<2 */
	    t = x-one;
	    return olm_log1p(t+__builtin_sqrt(2.0*t+t*t));
	}
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_acosh(q));
}
int main(void) { (void) slice(); return 0; }
