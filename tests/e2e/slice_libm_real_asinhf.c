/* slice_libm_real_asinhf.c — bd q2wk (PredMux L6 Inc 5): the REAL openlibm asinhf body.

   Cell: asinhf.f32. THE WHOLE CLOSURE, three corpus files, all from the FLOAT
   corpus (never a retyped double body):
     /private/tmp/openlibm_reclone/src/s_asinhf.c  — asinhf(x), the public entry.
     /private/tmp/openlibm_reclone/src/e_logf.c    — __ieee754_logf, called at 2
       sites in asinhf (the |x|>2**28 arm and the 2**28>|x|>2.0 arm).
     /private/tmp/openlibm_reclone/src/s_log1pf.c  — log1pf, called at 1 site in
       asinhf (the 2.0>|x|>2**-28 arm).
   Both e_logf.c and s_log1pf.c are self-contained: neither body contains a call
   to ANY function — no openlibm callee and no keep-set name; their only
   math_private.h dependencies are the GET_/SET_FLOAT_WORD macros and (in
   s_log1pf.c) STRICT_ASSIGN. So the closure terminates at three files, and the
   keep-set rewrite below touches only s_asinhf.c. fabsf and __ieee754_sqrtf are
   Rule-18 HARDWARE KEEPS and are NOT vendored (see KEEP-SET CALLS).

   ATTRIBUTION — the SunPro notice, preserved HERE because the vendored bodies
   below no longer carry it (it is identical in all three corpus files): "Copyright
   (C) 1993 by Sun Microsystems, Inc. All rights reserved. Developed at SunPro, a
   Sun Microsystems, Inc. business. Permission to use, copy, modify, and distribute
   this software is freely granted, provided that this notice is preserved." All
   three files also carry the Ian Lance Taylor float-conversion attribution line.
   Deleting those blocks from the bodies is a LICENSING / owner call, NOT a
   mechanical edit; they are listed in the edit list only so the diff-vs-corpus
   contract stays complete.

   MECHANICAL EDITS (declared, in corpus order, per file; no algorithmic change —
   every constant, branch, comparison and expression is byte-for-byte the corpus
   text):

   s_asinhf.c:
     - DELETED the Ian Lance Taylor conversion comment (lines 1-3), the SunPro
       copyright block (lines 5-14), the 3 include lines (cdefs-compat.h line 16,
       openlibm_math.h line 19, math_private.h line 21) and the //__FBSDID comment
       (line 17), and the OLM_DLLEXPORT storage marker (line 28). All comment,
       include or storage-class text; no executable statement removed.
     - RENAMED the entry point asinhf -> olm_asinhf, marked
       __attribute__((always_inline)) static inline (forces the census inline
       shape at plain -O1, collapsing the closure into one body).
     - RENAMED the intra-body calls to the vendored names: __ieee754_logf ->
       olm_logf (2 sites, corpus lines 40 and 43), log1pf -> olm_log1pf (1 site,
       corpus line 46).
     - REWROTE the keep-set names as builtins: fabsf -> __builtin_fabsf (3 sites,
       corpus lines 40, 42, 46), __ieee754_sqrtf -> __builtin_sqrtf (2 sites,
       corpus lines 43 and 46). See KEEP-SET CALLS below.
     - File-scope `static const float one/ln2/huge` (lines 23-26) kept verbatim;
       none of those three names collides with the other two files.

   e_logf.c:
     - DELETED the Ian Lance Taylor conversion comment (lines 1-3), the SunPro
       copyright block (lines 5-14), the 3 include lines (lines 16, 19, 21), the
       //__FBSDID comment (line 17), and the OLM_DLLEXPORT storage marker (line
       35). No executable statement removed. The `|(log(1+s)-log(1-s))/s - Lg(s)|`
       accuracy comment inside the constant table is KEPT (it documents the
       coefficients and is retained verbatim).
     - RENAMED __ieee754_logf -> olm_logf, marked always_inline static inline.
     - The file-scope table (ln2_hi, ln2_lo, two25, Lg1..Lg4, zero) is verbatim.
       ln2_hi / ln2_lo / two25 / zero COLLIDE with s_log1pf.c's file-scope table;
       the four colliding definitions agree in both corpus files (same type
       `static const float`, same literals 6.9313812256e-01 / 9.0580006145e-06 /
       3.355443200e+07 / 0.0). The ln2_hi/ln2_lo/two25 rows are byte-identical
       (e_logf.c:24-26 vs s_log1pf.c:25-27); the `zero` rows differ ONLY in
       intra-line whitespace (`zero   =  0.0;` at e_logf.c:33 vs `zero = 0.0;` at
       s_log1pf.c:36) — same token sequence, same value. All four are therefore
       DEDUPLICATED to one definition each; the e_logf.c spelling of `zero` is the
       one retained. Deduplication (rather
       than prefix-uniquifying) leaves BOTH function bodies textually unchanged,
       which is the stronger faithfulness property. Lg1..Lg4 are unique to
       e_logf.c and Lp1..Lp7 to s_log1pf.c; no other name collides.

   s_log1pf.c:
     - DELETED the Ian Lance Taylor conversion comment (lines 1-3), the SunPro
       copyright block (lines 5-14), the 4 include lines (cdefs-compat.h line 16,
       float.h line 19, openlibm_math.h line 20, math_private.h line 22), the
       //__FBSDID comment (line 17), and the OLM_DLLEXPORT storage marker (line
       38). No executable statement removed. The long "The approximation to
       sqrt(2) used in thresholds..." in-body comment is KEPT verbatim.
     - RENAMED log1pf -> olm_log1pf, marked always_inline static inline.
     - Its ln2_hi/ln2_lo/two25/zero definitions are the deduplicated ones above
       (declared once, in the e_logf.c block); Lp1..Lp7 are verbatim.
     - EXPANDED the one math_private.h STRICT_ASSIGN site (corpus line 66,
       `STRICT_ASSIGN(float,u,(float)1.0+x);`) to `u = (float)1.0+x;`. That is the
       macro's own expansion on this target: math_private.h:206-208 selects
       `#define STRICT_ASSIGN(type, lval, rval) ((lval) = (rval))` under
       `#ifndef __FreeBSD__`, and this is macOS/x86-64. Not-taken preprocessor
       text; the corpus source line is retained as a trailing comment.

   shared (all three files):
     - The math_private.h float word macros GET_FLOAT_WORD / SET_FLOAT_WORD are
       expanded to the __builtin_memcpy pun shim that clang -O1 folds to the same
       bitcast IR the taint pass lowers. They are redefined as MACROS at the top
       of this file, so the three function bodies below carry the corpus macro
       call text unchanged. Every punned object in this closure (asinhf's x;
       logf's x; log1pf's x and u) is declared `float` in the corpus source, so no
       double ever reaches these macros here — but the shim still routes through a
       `float` temp, which is exactly openlibm's ieee_float_shape_type union
       semantics (`gf_u.value = (d)` is a float lvalue). That is the bd 3c6m.53
       k_expf.c hazard guard; it is a no-op for the float operands in this file.
       Sites: 1 GET_FLOAT_WORD in s_asinhf.c; 2 GET + 1 SET in e_logf.c; 3 GET +
       2 SET in s_log1pf.c.
     - The BSD type spelling u_int32_t is not used by any of the three bodies;
       `#include <stdint.h>` is ADDED because int32_t reaches the corpus bodies
       transitively through math_private.h, which is not vendored.
     - ADDED: this header, the per-file banner comments, and the slice()/main()
       driver at the end.

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution):
     s_asinhf.c calls fabsf (3 sites) and __ieee754_sqrtf (2 sites). Both are
     HARDWARE KEEPS: at the real ship floor (plain `clang -O1`, builtins ON) the
     named calls fold to @llvm.fabs.f32 / @llvm.sqrt.f32 before codegen, and
     cq-lowering rewrites those to cq_template_fabs_f32 / cq_template_sqrt_f32.
     The __builtin_fabsf / __builtin_sqrtf spellings emit exactly that construct
     and need no libm declaration. By definition a keep has no injectable body, so
     vendoring openlibm's software e_sqrtf.c / s_fabsf.c here would MISREPRESENT
     the ship floor — that blanket -fno-builtin resolution is the census bug bd
     3c6m.60 fixed. No other keep-set name appears anywhere in this closure.

   LOWERING EXERCISED (every figure below MEASURED on /tmp/asinhf_s1.ll,
   /tmp/asinhf_s2.ll and the golden (re-counted 2026-10-05) — none asserted):
     - Pre-pass @slice, after -O1 has inlined the whole 3-file closure into one
       function: 70 basic blocks, 69 `br`, 35 of them conditional. That is the
       fdlibm exponent-word classification chain bd q2wk widened the PredMux E6
       claim gate for (i1 PHIs used as conditional-branch conditions inside the
       claimed region, plus branch conditions the flatten itself taints).
       Post-pass @slice: 2 basic blocks and 1 `br`, an unconditional edge into
       the measure block — PredMuxFlatten straight-lined all 35 conditionals.
     - ALL THREE asinhf arms survive -O1 and are lowered; none was folded away.
       The two arm-selecting compares are both still in the pre-pass IR
       (`icmp ugt i32 %4, 1300234240` = 0x4d800000 and `icmp ugt i32 %4,
       1073741824` = 0x40000000), each with a live successor: the |x|>2**28
       logf arm, the 2**28>|x|>2.0 logf arm, and the log1pf arm.
     - Merge substrate on the trace: 72 cqrt_copy_f32_controlled +
       16 cqrt_copy_i32_controlled controlled-copy merges; 1628 cqrt_toffoli
       flag conjunctions, 1248 cqrt_cnot, 88 cqrt_x, 1753 cqrt_free;
       868 allocations (814 cqrt_alloc_i1 flag rails + 43 cqrt_alloc_f32 +
       11 cqrt_alloc_i32); 1 cqrt_ry_f32 and 1 cqrt_measure_f32 (the single
       tainted theta rail in, the single measurement out).
       Every compare template is paired 1:1 with its `_unc` strip (e.g. 140
       cq_template_icmp_ule_i32_hl against 140 ..._unc; the same holds for each
       of the 14 predicate families present — 10 icmp (eq ne sge sgt sle slt uge
       ugt ule ult) and 4 fcmp (oeq ogt ule une)).
     - KEEPS actually lowered, counted on the trace: 2 cq_template_fabs_f32 and
       2 cq_template_sqrt_f32. The sqrt count is 1:1 with the two source
       __ieee754_sqrtf sites (arm 2 and arm 3), NOT tail-merged. The fabs count
       is 2 rather than the 3 source fabsf sites, and NEITHER shortfall is an arm
       the pass dropped:
         * all three source `fabsf(x)` sites compute the identical expression on
           the identical value, so -O1 CSEs them into ONE `@llvm.fabs.f32(%1)`
           hoisted into the entry block, and all three arms consume that one
           value (measured: the single %3 is used by the arm-1 word bitcast, by
           arm 2's `sqrt(x*x+one)+t`, and by arm 3's `fabsf(x)+t/...`);
         * that same %3 is simultaneously what clang -O1 canonicalizes asinhf's
           own `ix = hx&0x7fffffff` magnitude test into — a canonicalization of a
           stock C bit-and, not a library body swapped in by a name recognizer;
         * the SECOND @llvm.fabs.f32 is the same canonicalization applied to
           log1pf's own `ax = hx&0x7fffffff`, inside arm 3.
       fabs is itself a Rule-18 keep, so both canonicalizations stay inside the
       keep set.
     - 42 cq_template_fma_f32* (10 all-handle + 18 _qlq + 8 _qll + 6 _qql) come
       from clang's default fp-contract fusing the Lg1..Lg4 / Lp1..Lp7 Horner
       chains and `x*x+one`; fma/fmuladd is likewise a Rule-18 keep.
     - Total trace: 7621 lines. The lowered module has ZERO residual @cq_*
       intrinsic call sites (call.*@cq_theta / call.*@cq_measure both 0) and ZERO
       @llvm.* CALL sites — but 3 now-unused `declare @llvm.*` lines do survive
       with no uses, so a bare grep for @llvm. is not a refutation of that claim.
       Two runs of the binary byte-diff identical (determinism verified).
   This slice is the LINK-layer proof (Rule 2) that every emitted symbol resolves,
   signature-matches, and the trace is stable. */
#include <stdint.h>

/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast IR the taint pass lowers. Routed through a `float`
   temp so the narrowing matches openlibm's ieee_float_shape_type union exactly
   (bd 3c6m.53 k_expf.c hazard); every operand in THIS closure is already a
   float, so the temp is a no-op copy here. */
#define GET_FLOAT_WORD(i,d)    do{ float __f=(float)(d); uint32_t __w; __builtin_memcpy(&__w,&__f,4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); float __f; __builtin_memcpy(&__f,&__w,4); (d)=__f; }while(0)

/* ---- vendored from openlibm src/e_logf.c (file-scope table).
   ln2_hi / ln2_lo / two25 / zero are byte-identical in src/s_log1pf.c and are
   deduplicated here to one definition each (same name, same type, same value),
   so both vendored bodies below reference them unchanged. ---- */
static const float
ln2_hi =   6.9313812256e-01,	/* 0x3f317180 */
ln2_lo =   9.0580006145e-06,	/* 0x3717f7d1 */
two25 =    3.355443200e+07,	/* 0x4c000000 */
/* |(log(1+s)-log(1-s))/s - Lg(s)| < 2**-34.24 (~[-4.95e-11, 4.97e-11]). */
Lg1 =      0xaaaaaa.0p-24,	/* 0.66666662693 */
Lg2 =      0xccce13.0p-25,	/* 0.40000972152 */
Lg3 =      0x91e9ee.0p-25,	/* 0.28498786688 */
Lg4 =      0xf89e26.0p-26;	/* 0.24279078841 */

static const float zero   =  0.0;

/* ---- vendored from openlibm src/s_log1pf.c (file-scope table; the
   ln2_hi/ln2_lo/two25/zero rows are the deduplicated ones above) ---- */
static const float
Lp1 = 6.6666668653e-01,	/* 3F2AAAAB */
Lp2 = 4.0000000596e-01,	/* 3ECCCCCD */
Lp3 = 2.8571429849e-01, /* 3E924925 */
Lp4 = 2.2222198546e-01, /* 3E638E29 */
Lp5 = 1.8183572590e-01, /* 3E3A3325 */
Lp6 = 1.5313838422e-01, /* 3E1CD04F */
Lp7 = 1.4798198640e-01; /* 3E178897 */

/* ---- vendored from openlibm src/s_asinhf.c (file-scope table) ---- */
static const float
one =  1.0000000000e+00, /* 0x3F800000 */
ln2 =  6.9314718246e-01, /* 0x3f317218 */
huge=  1.0000000000e+30;

/* ======== e_logf.c : __ieee754_logf ======== */
__attribute__((always_inline)) static inline float
olm_logf(float x)
{
	float hfsq,f,s,z,R,w,t1,t2,dk;
	int32_t k,ix,i,j;

	GET_FLOAT_WORD(ix,x);

	k=0;
	if (ix < 0x00800000) {			/* x < 2**-126  */
	    if ((ix&0x7fffffff)==0)
		return -two25/zero;		/* log(+-0)=-inf */
	    if (ix<0) return (x-x)/zero;	/* log(-#) = NaN */
	    k -= 25; x *= two25; /* subnormal number, scale up x */
	    GET_FLOAT_WORD(ix,x);
	}
	if (ix >= 0x7f800000) return x+x;
	k += (ix>>23)-127;
	ix &= 0x007fffff;
	i = (ix+(0x95f64<<3))&0x800000;
	SET_FLOAT_WORD(x,ix|(i^0x3f800000));	/* normalize x or x/2 */
	k += (i>>23);
	f = x-(float)1.0;
	if((0x007fffff&(0x8000+ix))<0xc000) {	/* -2**-9 <= f < 2**-9 */
	    if(f==zero) {
		if(k==0) {
		    return zero;
		} else {
		    dk=(float)k;
		    return dk*ln2_hi+dk*ln2_lo;
		}
	    }
	    R = f*f*((float)0.5-(float)0.33333333333333333*f);
	    if(k==0) return f-R; else {dk=(float)k;
	    	     return dk*ln2_hi-((R-dk*ln2_lo)-f);}
	}
 	s = f/((float)2.0+f);
	dk = (float)k;
	z = s*s;
	i = ix-(0x6147a<<3);
	w = z*z;
	j = (0x6b851<<3)-ix;
	t1= w*(Lg2+w*Lg4);
	t2= z*(Lg1+w*Lg3);
	i |= j;
	R = t2+t1;
	if(i>0) {
	    hfsq=(float)0.5*f*f;
	    if(k==0) return f-(hfsq-s*(hfsq+R)); else
		     return dk*ln2_hi-((hfsq-(s*(hfsq+R)+dk*ln2_lo))-f);
	} else {
	    if(k==0) return f-s*(f-R); else
		     return dk*ln2_hi-((s*(f-R)-dk*ln2_lo)-f);
	}
}

/* ======== s_log1pf.c : log1pf ======== */
__attribute__((always_inline)) static inline float
olm_log1pf(float x)
{
	float hfsq,f,c,s,z,R,u;
	int32_t k,hx,hu,ax;

	GET_FLOAT_WORD(hx,x);
	ax = hx&0x7fffffff;

	k = 1;
	if (hx < 0x3ed413d0) {			/* 1+x < sqrt(2)+  */
	    if(ax>=0x3f800000) {		/* x <= -1.0 */
		if(x==(float)-1.0) return -two25/zero; /* log1p(-1)=+inf */
		else return (x-x)/(x-x);	/* log1p(x<-1)=NaN */
	    }
	    if(ax<0x38000000) {			/* |x| < 2**-15 */
		if(two25+x>zero			/* raise inexact */
	            &&ax<0x33800000) 		/* |x| < 2**-24 */
		    return x;
		else
		    return x - x*x*(float)0.5;
	    }
	    if(hx>0||hx<=((int32_t)0xbe95f619)) {
		k=0;f=x;hu=1;}		/* sqrt(2)/2- <= 1+x < sqrt(2)+ */
	}
	if (hx >= 0x7f800000) return x+x;
	if(k!=0) {
	    if(hx<0x5a000000) {
		u = (float)1.0+x;	/* STRICT_ASSIGN(float,u,(float)1.0+x); */
		GET_FLOAT_WORD(hu,u);
	        k  = (hu>>23)-127;
		/* correction term */
	        c  = (k>0)? (float)1.0-(u-x):x-(u-(float)1.0);
		c /= u;
	    } else {
		u  = x;
		GET_FLOAT_WORD(hu,u);
	        k  = (hu>>23)-127;
		c  = 0;
	    }
	    hu &= 0x007fffff;
	    /*
	     * The approximation to sqrt(2) used in thresholds is not
	     * critical.  However, the ones used above must give less
	     * strict bounds than the one here so that the k==0 case is
	     * never reached from here, since here we have committed to
	     * using the correction term but don't use it if k==0.
	     */
	    if(hu<0x3504f4) {			/* u < sqrt(2) */
	        SET_FLOAT_WORD(u,hu|0x3f800000);/* normalize u */
	    } else {
	        k += 1;
		SET_FLOAT_WORD(u,hu|0x3f000000);	/* normalize u/2 */
	        hu = (0x00800000-hu)>>2;
	    }
	    f = u-(float)1.0;
	}
	hfsq=(float)0.5*f*f;
	if(hu==0) {	/* |f| < 2**-20 */
	    if(f==zero) {
		if(k==0) {
		    return zero;
		} else {
		    c += k*ln2_lo;
		    return k*ln2_hi+c;
		}
	    }
	    R = hfsq*((float)1.0-(float)0.66666666666666666*f);
	    if(k==0) return f-R; else
	    	     return k*ln2_hi-((R-(k*ln2_lo+c))-f);
	}
 	s = f/((float)2.0+f);
	z = s*s;
	R = z*(Lp1+z*(Lp2+z*(Lp3+z*(Lp4+z*(Lp5+z*(Lp6+z*Lp7))))));
	if(k==0) return f-(hfsq-s*(hfsq+R)); else
		 return k*ln2_hi-((hfsq-(s*(hfsq+R)+(k*ln2_lo+c)))-f);
}

/* ======== s_asinhf.c : asinhf ======== */
__attribute__((always_inline)) static inline float
olm_asinhf(float x)
{
	float t,w;
	int32_t hx,ix;
	GET_FLOAT_WORD(hx,x);
	ix = hx&0x7fffffff;
	if(ix>=0x7f800000) return x+x;	/* x is inf or NaN */
	if(ix< 0x31800000) {	/* |x|<2**-28 */
	    if(huge+x>one) return x;	/* return x inexact except 0 */
	}
	if(ix>0x4d800000) {	/* |x| > 2**28 */
	    w = olm_logf(__builtin_fabsf(x))+ln2;
	} else if (ix>0x40000000) {	/* 2**28 > |x| > 2.0 */
	    t = __builtin_fabsf(x);
	    w = olm_logf((float)2.0*t+one/(__builtin_sqrtf(x*x+one)+t));
	} else {		/* 2.0 > |x| > 2**-28 */
	    t = x*x;
	    w =olm_log1pf(__builtin_fabsf(x)+t/(one+__builtin_sqrtf(one+t)));
	}
	if(hx>0) return w; else return -w;
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_asinhf(q));
}
int main(void) { (void) slice(); return 0; }
