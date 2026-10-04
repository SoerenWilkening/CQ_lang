/* slice_libm_real_log1p.c — bd q2wk (PredMux L6 Inc 5): the REAL openlibm
   log1p body. This is the MECHANISM CELL for the E6 path-predicated
   branch-condition widening: the short-circuit
   `if(hx>0||hx<=((int32_t)0xbfd2bec4))` is exactly the i1-PHI-used-as-a-
   conditional-branch-condition shape that increment 5 unblocked.

   CORPUS VENDORED (one file, the whole closure):
     /private/tmp/openlibm_reclone/src/s_log1p.c — log1p(x), the entire
     algorithm: the exponent-word classification (`hx < 0x3FDA827A`), the
     x<=-1.0 / |x|<2**-29 / |x|<2**-54 special-case ladder, the
     sqrt(2)/2 <= 1+x < sqrt(2) short-circuit above, the Inf/NaN arm, the
     1+x argument reduction with its correction term c/u and the two
     SET_HIGH_WORD normalizations, the |f|<2**-20 fast path, and the
     degree-14 Lp1..Lp7 Remez polynomial. s_log1p.c calls NO other function
     at all — no libm call, no keep-set call — so the closure is this one
     file and nothing else.

   MECHANICAL EDITS (declared in corpus order; no algorithmic change — every
   constant, branch, comparison and expression is byte-for-byte the corpus
   text):
     - deleted, in corpus order: the SCCS marker comment (corpus line 1),
       the Sun/SunPro copyright block (lines 2-11), `#include
       "cdefs-compat.h"` (line 13), the //__FBSDID comment (line 14), the
       Method / Special cases / Accuracy / Constants algorithm prose
       (lines 16-79), `#include <float.h>` (line 81), `#include
       <openlibm_math.h>` (line 82), `#include "math_private.h"` (line 84),
       the OLM_DLLEXPORT storage marker (line 100), and the trailing
       `#if (LDBL_MANT_DIG == 53) openlibm_weak_reference(log1p, log1pl);`
       block (lines 177-179; x86-64 long double has LDBL_MANT_DIG == 64, so
       that block is not taken here). Every one of these is comment,
       include, storage-class or not-taken-preprocessor text; none removes
       an executable statement.
     - KEPT VERBATIM: the file-scope `static const double` coefficient table
       ln2_hi / ln2_lo / two54 / Lp1..Lp7 (corpus lines 86-96) and
       `static const double zero = 0.0;` (line 98), including their hex
       comments. Only one corpus file is vendored, so no name collision and
       no uniquifying rename was needed.
     - entry point `log1p` (line 101) renamed to `olm_log1p` and marked
       `__attribute__((always_inline)) static inline` (forces the census
       inline shape at plain -O1, collapsing the closure into ONE FUNCTION).
       The in-body algorithm comment at corpus lines 140-146 (the note about
       the sqrt(2) threshold) is KEPT verbatim.
     - line 106 GET_HIGH_WORD(hx,x) expanded to the __builtin_memcpy 8-byte
       pun shim that clang -O1 folds to the same bitcast IR (same idiom as
       the log / acos / hypot slices).
     - line 128 STRICT_ASSIGN(double,u,1.0+x) expanded to the plain
       assignment `u = 1.0+x;`. This is the macro's own expansion on this
       target, not a simplification: math_private.h line 206 selects
       `#define STRICT_ASSIGN(type, lval, rval) ((lval) = (rval))` under
       `#ifndef __FreeBSD__`, and this build is macOS/x86-64, so
       __FreeBSD__ is undefined and that is the branch the preprocessor
       takes. The volatile-temp FreeBSD variant is not-taken text.
     - lines 129 and 135 GET_HIGH_WORD(hu,u) expanded to the same
       memcpy pun shim (2 sites). The corpus assigns the union's
       `uint32_t parts.msw` into the `int32_t hu`; `(int32_t)(bits >> 32)`
       is that same bit pattern, so the later arithmetic `(hu>>20)-1023`
       and `hu &= 0x000fffff` are unchanged.
     - lines 148 and 151 SET_HIGH_WORD(u, ...) expanded to the macro's
       read-modify-write pair, so each site is 2 memcpys (4 total). The
       macro-local union temp is replaced by one function-scope
       `uint64_t bits`; every expansion is a self-contained read-then-write
       with no intervening use, so that sharing is semantically identical.
     - `#include <stdint.h>` added for the int32_t/uint32_t/uint64_t
       spellings that reached the corpus file through openlibm_math.h /
       math_private.h. There is no u_int32_t in s_log1p.c, so no BSD type
       respelling was needed.

   KEEP-SET CALLS (Rule 18): the corpus SOURCE has none — s_log1p.c contains
   no call of any kind, so nothing here is spelled as a __builtin_ and
   nothing is vendored in substitution for a keep. But clang -O1 SYNTHESIZES
   keeps out of the source's own arithmetic: default fp-contract fuses the
   Lp1..Lp7 Horner chain and the k*ln2_hi / hfsq products into
   @llvm.fmuladd.f64. MEASURED: /tmp/log1p_s1.ll has exactly 16
   `call ... @llvm.fmuladd.f64` sites and no other llvm.* call site at all
   (no fabs/sqrt/umax/umin); the lowered /tmp/log1p_s2.ll has 16
   cq_template_fma_f64* call sites (2 fma_f64 + 2 _qll + 7 _qlq + 5 _qql)
   and ZERO llvm.* call sites — a 1:1 lowering with nothing dropped.
   fma/fmuladd is a Rule-18 hardware keep, and these are clang
   canonicalizations of stock C expressions, NOT a library body swapped in
   by a name recognizer. (The 2 cq_template_trunc_i64_to_i32 in the trace
   are the CAST grammar `<op>_<from>_to_<to>`, i.e. integer truncation of
   the punned word — they are not the `trunc` rounding keep.)

   LOWERING EXERCISED (every figure below MEASURED on /tmp/log1p_s1.ll,
   /tmp/log1p_s2.ll and the emitted trace, not asserted): tainted
   x = cq_theta(0.5, 0.5), so no guard const-folds away and the full nest
   survives clang -O1.
     Pre-pass @slice (after -O1 inlining): 29 basic blocks (the unlabeled
     entry + 28 labeled), 28 br of which 14 are conditional, 13 phi, 1 ret.
     TWO of those phi are `phi i1`, and BOTH are consumed as
     conditional-branch conditions — but at DIFFERENT distances from their
     own block, and the gate must accept both. %29 (the
     `hx>0||hx<=(int32_t)0xbfd2bec4` short-circuit, which clang -O1
     canonicalized into the range test `add i32 %hx, -1; icmp ult ...,
     -1076707644` phi'd against `false`) is phi'd in block %28 and consumed
     by the `br i1 %29` terminating a LATER block, %33 — the phi's own
     block %28 ends on an unrelated condition (`icmp sgt i32 %hx,
     2146435071`, the Inf/NaN arm). %82 (the `hu==0` fast-path flag) is
     phi'd in block %78 and consumed by the `br i1 %82` terminating that
     SAME block %78.
     That is exactly the E6 path-predicated branch-condition shape
     bd q2wk widened the claim gate to accept; this cell is its mechanism
     proof.
     Lowered @slice: 2 basic blocks, 1 br (unconditional, into the measure
     block), 0 conditional br, 0 phi — PredMuxFlatten straight-lined the
     whole nest onto the select substrate.
   Lowered-IR call-site counts (each equals its trace-line count exactly,
   because the lowered body is straight-line and every site executes once):
     - cqrt_alloc_f64 : 20   (the FIRST is the cq_theta rail — it is the
                              operand of the single cqrt_ry_f64; the other
                              19 are PredMux f64 work rails)
     - cqrt_alloc_i32 : 7
     - cqrt_alloc_i1  : 315  (predicate/flag rails)
     - cqrt_ry_f64    : 1
     - cqrt_measure_f64 : 1
     - cqrt_copy_f64_controlled : 30
     - cqrt_copy_i32_controlled : 12
     - cqrt_toffoli   : 630  (flag conjunctions for the predicated merges)
     - cqrt_cnot      : 528
     - cqrt_x         : 42
     - cqrt_free      : 619
     - cq_template_*  : 681 call sites total, 16 of them the fma keep-folds
                        above; the bulk is 594 icmp_*_i32_hl — 297 forward
                        compares paired one-for-one with 297 _inv strips
     - trace lines    : 2886  (= 2205 cqrt + 681 cq_template, exactly)
   AUDITOR NOTE: the corpus's `c` is conditionally uninitialized by design
   (it is written only on the k!=0 path and read only under k!=0), and
   clang materializes that as one `undef` merge-phi incoming in the
   pre-pass @slice (%79). MEASURED: the lowered @slice has ZERO undef and
   ZERO poison operands — the flatten did not propagate it into a gate.
   The trace was produced twice and byte-diffed identical (determinism), the
   lowered module has ZERO residual @cq_* intrinsic call sites, and the
   trace contains both a cqrt_ry_f64 and a cqrt_measure_f64 line. This slice
   is the LINK-layer proof (Rule 2) that every emitted symbol resolves,
   signature-matches, and the trace is stable. */
#include <stdint.h>

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

static const double zero = 0.0;

/* openlibm src/s_log1p.c log1p (verbatim; the math_private.h word macros and
   STRICT_ASSIGN expanded in place as declared above). */
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
		if(x==-1.0) return -two54/zero; /* log1p(-1)=+inf */
		else return (x-x)/(x-x);	/* log1p(x<-1)=NaN */
	    }
	    if(ax<0x3e200000) {			/* |x| < 2**-29 */
		if(two54+x>zero			/* raise inexact */
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
		bits = (bits & 0xffffffffULL) |
		       ((uint64_t)(uint32_t)(hu|0x3ff00000) << 32);
		__builtin_memcpy(&u, &bits, 8);	/* normalize u */
	    } else {
	        k += 1;
		__builtin_memcpy(&bits, &u, 8);	/* SET_HIGH_WORD(u,hu|0x3fe00000) */
		bits = (bits & 0xffffffffULL) |
		       ((uint64_t)(uint32_t)(hu|0x3fe00000) << 32);
		__builtin_memcpy(&u, &bits, 8);	/* normalize u/2 */
	        hu = (0x00100000-hu)>>2;
	    }
	    f = u-1.0;
	}
	hfsq=0.5*f*f;
	if(hu==0) {	/* |f| < 2**-20 */
	    if(f==zero) {
		if(k==0) {
		    return zero;
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

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_log1p(q));
}
int main(void) { (void) slice(); return 0; }
