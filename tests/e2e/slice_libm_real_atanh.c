/* slice_libm_real_atanh.c — bd q2wk: the REAL openlibm atanh body.

   CORPUS VENDORED (two files — the whole closure):
     /private/tmp/openlibm_reclone/src/e_atanh.c — __ieee754_atanh(x), the
     entire algorithm (the EXTRACT_WORDS exponent-word classification, the
     |x|>1 NaN arm, the |x|==1 divide-by-zero arm, the x<2**-28 early-out,
     the SET_HIGH_WORD absolute value, the x<0.5 / x>=0.5 log1p split, and
     the sign restore).
     /private/tmp/openlibm_reclone/src/s_log1p.c — log1p(x), vendored as
     olm_log1p.  log1p is a LIBRARY function, NOT a hardware keep: there is
     no @llvm.log1p fold and no Bennett gate sequence for it, so Rule 18
     requires its SOURCE be injected.  Its whole body is here verbatim —
     the 1+x<sqrt(2) argument reduction, the x<=-1 / |x|<2**-29 / |x|<2**-54
     special arms, the 2**53 threshold split, the hu<0x6a09e normalize-u vs
     normalize-u/2 split, the hu==0 |f|<2**-20 path, and the degree-14
     Lp1..Lp7 Reme polynomial.
     That is the complete closure: after the two renames below, neither file
     calls any function at all — there is no third corpus file and no libm
     call left in the module.

   MECHANICAL EDITS (declared; no algorithmic change — every constant,
   branch, comparison and expression is byte-for-byte the corpus text):
     - e_atanh.c, deleted in corpus order: the SCCS marker + license block
       (lines 2-13), the cdefs-compat.h include (line 15), the //__FBSDID
       comment (line 16), the Method / Special cases prose comment (lines
       18-34), the float.h / openlibm_math.h / math_private.h includes
       (lines 36, 37, 39), the OLM_DLLEXPORT storage marker (line 44), and
       the trailing `#if (LDBL_MANT_DIG == 53) openlibm_weak_reference(atanh,
       atanhl); #endif` block (lines 66-68; x86-64 long double has 64
       mantissa bits so LDBL_MANT_DIG == 64 and that block is not-taken
       preprocessor text).
     - e_atanh.c, entry point __ieee754_atanh renamed to olm_atanh and marked
       always_inline static inline (forces the census inline shape at plain
       -O1, collapsing the closure into ONE FUNCTION — recipe lesson bd
       20xt.2).
     - e_atanh.c, the two intra-body `log1p(...)` calls renamed to
       `olm_log1p(...)` (declared rename to the vendored name; the argument
       expressions `t+t*x/(one-x)` and `(x+x)/(one-x)` are untouched).
     - e_atanh.c, the BSD spelling `u_int32_t lx;` replaced by `uint32_t lx;`
       (stdint.h).  No other type changed; lx stays UNSIGNED, which is
       load-bearing for the `((lx|(-lx))>>31)` logical shift.
     - s_log1p.c, deleted in corpus order: the SCCS marker + license block
       (lines 1-11), the cdefs-compat.h include (line 13), the //__FBSDID
       comment (line 14), the Method / Special cases / Accuracy / Constants
       prose comment (lines 16-79), the float.h / openlibm_math.h /
       math_private.h includes (lines 81, 82, 84), the OLM_DLLEXPORT storage
       marker (line 100), and the trailing `#if (LDBL_MANT_DIG == 53)
       openlibm_weak_reference(log1p, log1pl); #endif` block (lines 177-179;
       same not-taken reason as above).
     - s_log1p.c, entry point log1p renamed to olm_log1p, always_inline
       static inline (same inline-shape reason).
     - s_log1p.c, its file-scope `static const double zero = 0.0;` renamed to
       `l1p_zero` — it COLLIDES with e_atanh.c's own `static const double
       zero = 0.0;` when the two files are concatenated into one TU.  Both
       are the identical value 0.0; the three `zero` uses inside the log1p
       body (`-two54/zero`, `f==zero`, `two54+x>zero`) are renamed with it.
       e_atanh.c's `one` / `huge` / `zero` are untouched; s_log1p.c has no
       other colliding file-scope name (ln2_hi, ln2_lo, two54, Lp1..Lp7 are
       unique to it).
     - the math_private.h word macros EXTRACT_WORDS (line 84), GET_HIGH_WORD
       (line 102) and SET_HIGH_WORD (line 138) are re-#defined at the top of
       this file as the __builtin_memcpy 8-byte pun shim, which clang -O1
       folds to the same bitcast/shift IR the union does.  The macro CALL
       SITES in both bodies are left byte-identical to the corpus — the shim
       is a macro-for-macro substitution of the union temp, not a rewrite of
       the algorithm.  STRICT_ASSIGN is likewise re-#defined as
       `((lval) = (rval))`, which is EXACTLY math_private.h line 207, the
       arm selected on this target (`#ifndef __FreeBSD__`); the one call
       site `STRICT_ASSIGN(double,u,1.0+x)` is verbatim.
     There is no float-word macro anywhere in this closure, so the k_expf.c
     double->float narrowing hazard (Rule-18 gotcha 4) does not arise here.

   KEEP-SET CALLS (Rule 18): the SOURCE calls none — and that is the point.
   Grep the two corpus files: between them they contain exactly one function
   call (log1p, from atanh), and that one is a LIBRARY function vendored as
   source above.  Neither body names fabs, sqrt, copysign or any other
   hardware keep; atanh takes its absolute value with SET_HIGH_WORD(x,ix),
   i.e. by word masking, not by fabs.  So NOTHING in this file is spelled as
   a __builtin_.
   Two keeps nevertheless appear in the lowered module, and BOTH are clang
   canonicalizations of the corpus's own stock C — not a library body swapped
   in by a name recognizer, so the Rule-18 injection rule is not in play for
   them (same situation as the umax/umin in slice_libm_real_hypot.c):
     - 1 @llvm.fabs.f64.  InstCombine recognizes atanh's
       SET_HIGH_WORD(x, hx&0x7fffffff) sign-bit clear as fabs and folds the
       bitcast/and/bitcast triple into the intrinsic.  MEASURED: 1 in the
       pre-pass IR -> 1 cq_template_fabs_f64 in the lowered IR and 1 in the
       trace.
     - 32 @llvm.fmuladd.f64, ALL of them from the log1p body and NONE from
       atanh's own arithmetic.  clang's default -ffp-contract=on fuses 16
       multiply-adds per inlined log1p copy (MEASURED on a standalone -O1 TU
       of the vendored olm_log1p: 16 fmuladd) — 6 of them the Lp1..Lp7 Horner
       chain, the other 10 log1p's remaining multiply-add forms (x - x*x*0.5,
       the 1.0-0.666...*f hfsq correction, and the s*(hfsq+R) / k*ln2_hi /
       k*ln2_lo+c reconstructions).  atanh itself contributes ZERO (MEASURED
       on a standalone -O1 TU of olm_atanh with olm_log1p left opaque: 0
       fmuladd) — in t+t*x/(one-x) the product t*x feeds a DIVIDE, not an
       add, so there is nothing to contract, and (x+x)/(one-x) has no product
       at all.  The 32 is therefore 2 x 16: olm_log1p is inlined at BOTH of
       atanh's call sites (MEASURED in the pre-pass @slice: log1p's Lp1
       0x3FE5555555555593, its Lp7 0x3FC2F112DF3E5244 and its two54
       0x4350000000000000 each appear exactly 2x).  MEASURED: 32 in the
       pre-pass IR -> 32 fma templates in the lowered IR and trace
       (4 cq_template_fma_f64 + 4 _qll + 14 _qlq + 10 _qql, i.e. a 1:1
       lowering with the operand quantum/classical split spelled in the
       suffix).
   MEASURED on the pre-pass -O1 IR of @slice: 35 call instructions total =
   2 @cq_* intrinsics + 1 @llvm.fabs.f64 + 32 @llvm.fmuladd.f64, and NO
   other call of any kind.  There is no libm call left in the module.

   LOWERING EXERCISED (every figure below MEASURED on the lowered IR / the
   trace, not asserted): a tainted-x atanh.  atanh's own word classification
   (`(ix|((lx|(-lx))>>31))>0x3ff00000`, `ix==0x3ff00000`, `ix<0x3e300000 &&
   (huge+x)>zero`, `ix<0x3fe00000`, `hx>=0`) plus log1p's nested
   classification (`hx<0x3FDA827A`, `ax>=0x3ff00000`, `x==-1.0`,
   `ax<0x3e200000`, `two54+x>zero && ax<0x3c900000`, `hx>0 ||
   hx<=0xbfd2bec4`, `hx>=0x7ff00000`, `k!=0`, `hx<0x43400000`, `k>0`,
   `hu<0x6a09e`, `hu==0`, `f==zero`, `k==0`) are all tainted branches on
   values derived from the single Ry rail — exactly the fdlibm
   exponent-word chain the bd q2wk PredMux E6 widening (path-predicated
   branch conditions: an i1 PHI used as a br condition, and a br condition
   the flatten itself taints) was built for.
   MEASURED, pre-pass @slice: 64 basic blocks, 63 br of which 32 are
   conditional, 26 phi, 3 select.  MEASURED, lowered @slice: 2 basic blocks,
   1 br and that br is UNCONDITIONAL (0 conditional br, 0 phi, 0 select) —
   PredMuxFlatten straight-lined the entire 32-way conditional nest onto the
   select substrate.
   MEASURED on the lowered IR; re-counted on the golden 2026-10-05 (straight-
   line body: every call executes once, so the two agree call-for-call):
     1346 cqrt_alloc (44 cqrt_alloc_f64 + 1288 cqrt_alloc_i1 +
       14 cqrt_alloc_i32); of the 44 f64 allocs exactly 1 is the Ry rail,
     1 cqrt_ry_f64, 1 cqrt_measure_f64,
     70 cqrt_copy_f64_controlled + 24 cqrt_copy_i32_controlled route merges,
     2576 cqrt_toffoli flag conjunctions, 2320 cqrt_cnot, 94 cqrt_x,
     2627 cqrt_free,
     16 distinct compare templates totalling 1234 forward compares, each of
       which has an exactly-matching _unc count (e.g. icmp_ult_i32_hl
       231/231, icmp_uge_i32_hl 220/220, fcmp_ogt_f64_hl 66/66). That includes
       cq_template_icmp_ne_i64_hl (1/1), which is DATA, not a control flag:
       clang's canonicalization of atanh's `(lx|(-lx))>>31` nonzero-test into
       `icmp ne i64 %w, 0` + `zext i1 to i32`, whose result is ORed straight
       into `ix`. The golden uncomputes it with its value chain, before any
       controlled copy (lines 12-18: icmp, zext, or, the zext's `_unc`, a free,
       the icmp's `_unc`, a free), not as a flag strip.
   MEASURED, residual intrinsics: 0 @cq_* intrinsic call sites and 0 @llvm.*
   CALL SITES in the lowered module.  2 now-unused `declare @llvm.*` lines
   (llvm.fabs.f64, llvm.fmuladd.f64) do survive with no uses, so a bare grep
   for @llvm. is not a refutation of that claim.
   MEASURED, trace: 11799 lines, byte-identical across two consecutive runs
   (determinism verified by diff), containing cqrt_ry_f64 and cqrt_measure_f64.
   This slice is the LINK-layer proof (Rule 2) that every emitted symbol
   resolves, signature-matches, and the trace is stable. */
#include <stdint.h>

/* math_private.h word macros re-#defined as the __builtin_memcpy pun shim
   (clang -O1 folds these to the same bitcast/shift IR as the corpus union);
   STRICT_ASSIGN is math_private.h line 207 verbatim, the non-__FreeBSD arm. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define GET_HIGH_WORD(i,d)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)(__w>>32); }while(0)
#define SET_HIGH_WORD(d,v)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0x00000000ffffffffULL)|((uint64_t)(uint32_t)(v)<<32); __builtin_memcpy(&(d),&__w,8); }while(0)
#define STRICT_ASSIGN(type, lval, rval) ((lval) = (rval))

/* ---- openlibm src/s_log1p.c (verbatim; `zero` -> `l1p_zero`, entry point
   log1p -> olm_log1p) ---- */
static const double
ln2_hi  =  6.93147180369123816490e-01,	/* 3fe62e42 fee00000 */
ln2_lo  =  1.90821492927058770002e-10,	/* 3dea39ef 35793c76 */
two54   =  1.80143985094819840000e+16,  /* 43500000 00000000 */
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
		if(x==-1.0) return -two54/l1p_zero; /* log1p(-1)=+inf */
		else return (x-x)/(x-x);	/* log1p(x<-1)=NaN */
	    }
	    if(ax<0x3e200000) {			/* |x| < 2**-29 */
		if(two54+x>l1p_zero			/* raise inexact */
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
		STRICT_ASSIGN(double,u,1.0+x);
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
		    c += k*ln2_lo;
		    return k*ln2_hi+c;
		}
	    }
	    R = hfsq*(1.0-0.66666666666666666*f);
	    if(k==0) return f-R; else
	    	     return k*ln2_hi-((R-(k*ln2_lo+c))-f);
	}
 	s = f/(2.0+f);
	z = s*s;
	R = z*(Lp1+z*(Lp2+z*(Lp3+z*(Lp4+z*(Lp5+z*(Lp6+z*Lp7))))));
	if(k==0) return f-(hfsq-s*(hfsq+R)); else
		 return k*ln2_hi-((hfsq-(s*(hfsq+R)+(k*ln2_lo+c)))-f);
}

/* ---- openlibm src/e_atanh.c (verbatim; entry point __ieee754_atanh ->
   olm_atanh, the two log1p call sites -> olm_log1p) ---- */
static const double one = 1.0, huge = 1e300;
static const double zero = 0.0;

__attribute__((always_inline)) static inline double
olm_atanh(double x)
{
	double t;
	int32_t hx,ix;
	uint32_t lx;
	EXTRACT_WORDS(hx,lx,x);
	ix = hx&0x7fffffff;
	if ((ix|((lx|(-lx))>>31))>0x3ff00000) /* |x|>1 */
	    return (x-x)/(x-x);
	if(ix==0x3ff00000) 
	    return x/zero;
	if(ix<0x3e300000&&(huge+x)>zero) return x;	/* x<2**-28 */
	SET_HIGH_WORD(x,ix);
	if(ix<0x3fe00000) {		/* x < 0.5 */
	    t = x+x;
	    t = 0.5*olm_log1p(t+t*x/(one-x));
	} else 
	    t = 0.5*olm_log1p((x+x)/(one-x));
	if(hx>=0) return t; else return -t;
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_atanh(q));
}
int main(void) { (void) slice(); return 0; }
