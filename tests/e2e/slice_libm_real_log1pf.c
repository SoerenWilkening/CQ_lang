/* slice_libm_real_log1pf.c — bd q2wk (PredMux L6 inc 5): the REAL openlibm
   log1pf body.

   CORPUS VENDORED (one file, the whole closure):
     /private/tmp/openlibm_reclone/src/s_log1pf.c — log1pf(x), the entire
     algorithm: the 10 file-scope `static const float` values
     (ln2_hi/ln2_lo/two25/Lp1..Lp7) plus `zero`, the sqrt(2)+ exponent-word
     classification chain (hx < 0x3ed413d0 / ax >= 0x3f800000 / ax < 0x38000000
     / ax < 0x33800000 / hx>0 || hx<=(int32_t)0xbe95f619), the Inf/NaN arm, the
     k!=0 reduction (hx<0x5a000000 correction-term arm vs the u=x arm), the
     hu<0x3504f4 mantissa normalize / else k+=1 normalize-u/2 arm, the |f|<2**-20
     hfsq arm, and the two final s-polynomial returns.
     There is no other openlibm .c in the closure: s_log1pf.c calls NO function
     at all — not even a hardware keep. Its whole body is stock C arithmetic,
     comparisons, shifts and the two float word macros.

   MECHANICAL EDITS (declared; no algorithmic change — every constant, branch,
   comparison and expression is byte-for-byte the corpus text):
     - deleted, in corpus order: the "float version of s_log1p.c" attribution
       comment (corpus lines 1-3), the SunPro copyright block (lines 5-14), the
       cdefs-compat.h include (line 16), the //__FBSDID comment (line 17), the
       float.h include (line 19), the openlibm_math.h include (line 20), the
       math_private.h include (line 22), and the OLM_DLLEXPORT storage marker
       (line 38). Every one of these is comment, include or storage-class text;
       none removes an executable statement. s_log1pf.c has NO trailing
       openlibm_weak_reference / LDBL_MANT_DIG block to drop.
     - entry point log1pf renamed to olm_log1pf and marked always_inline static
       inline (forces the census inline shape at plain -O1, collapsing the
       closure into ONE FUNCTION). It is NOT straight-line at that point:
       pre-pass @slice has 29 basic blocks and 28 br, 14 of them conditional.
       The straight line is produced later, by the pass's PredMux flatten stage;
       the lowered @slice is 2 blocks with exactly 1 br, an unconditional edge
       into the measure block (0 conditional br remain).
     - the math_private.h word macros GET_FLOAT_WORD / SET_FLOAT_WORD replaced
       by the __builtin_memcpy 4-byte-pun shim that clang -O1 folds to the same
       bitcast IR (same idiom as the logf / expm1f slices). The BODY TEXT keeps
       the macro CALLS verbatim — only the two macro DEFINITIONS are supplied
       here instead of by math_private.h. Gotcha check performed on this file:
       all 5 word-macro sites — 3 GET_FLOAT_WORD (hx from the parameter `float
       x`; hu from `u` in each of the two k!=0 arms) and 2 SET_FLOAT_WORD (both
       writing `u`) — take a FLOAT operand, since `u` is declared in the body's
       `float hfsq,f,c,s,z,R,u;`. None takes a double, so the 4-byte memcpy is
       the correct pun and the k_expf.c double->float narrowing hazard does NOT
       apply here.
     - STRICT_ASSIGN supplied verbatim from math_private.h line 207, i.e. the
       `#ifndef __FreeBSD__` arm `((lval) = (rval))`, which is the arm actually
       taken on this (Darwin/x86-64) target. No other spelling of the macro is
       reachable here, so this is not-taken-preprocessor elimination, not an
       algorithm change.
     - u_int32_t -> uint32_t: not needed. s_log1pf.c uses only int32_t (from
       math_private.h's stdint pull-in); <stdint.h> is included directly.
     - no static-const name uniquification needed: exactly one corpus file is
       vendored, so ln2_hi / ln2_lo / two25 / Lp1..Lp7 / zero cannot collide.

   KEEP-SET CALLS (Rule 18 ship-floor fold):
     NO SOURCE-LEVEL KEEP CALLS. s_log1pf.c contains zero call expressions — no
     fabs, no sqrt, no kernel helper, no library function. Nothing here was
     spelled as a builtin in place of a vendored body, and nothing was vendored
     in place of a hardware keep; the Rule-18 keep/cut line is not exercised by
     the corpus text of this cell.
     Two llvm.* constructs nevertheless reach the pass, and BOTH are clang
     canonicalizations of the source's own stock C — NOT a library body swapped
     in by a name recognizer (same category as the umax/umin note on the hypot
     slice):
       - 1 @llvm.fabs.f32 — instcombine rewrites the source's own
         `ax = hx&0x7fffffff` (a mask on the bitcast float word) into
         `bitcast(fabs(x))`. Measured: 1 call site in the pre-pass IR, lowered
         1:1 to 1 cq_template_fabs_f32.
       - 16 @llvm.fmuladd.f32 — clang's default -ffp-contract=on fuses the
         source's own mul+add expressions (the c-correction terms, the
         hfsq/(1-2/3 f) form, and the Lp1..Lp7 Horner chain). Measured: 16 call
         sites in the pre-pass IR, lowered 1:1 to 16 fma templates
         (7 cq_template_fma_f32_qlq + 5 _qql + 2 _qll + 2 plain).
     Both fabs and fma/fmuladd are themselves Rule-18 hardware keeps, so the
     ship floor lowers them as templates rather than requiring an injected body.

   LOWERING EXERCISED (all figures below MEASURED on the lowered IR / trace,
   not asserted): a single-tainted-argument f32 cell. The fdlibm exponent-word
   classification chain is exactly the PATH-PREDICATED BRANCH CONDITION shape
   bd q2wk widened the PredMux E6 claim gate for, and BOTH widened sub-shapes
   are present in the pre-pass IR (verified by inspection of /tmp/log1pf_s1.ll):
     - shape A, an i1 PHI used directly as a conditional-branch condition:
       pre-pass @slice has 12 phi nodes (2 i1 + 6 i32 + 4 float), and BOTH i1
       phis are branch conditions — `%28 = phi i1 [false,%0],[%26,%24]` (the
       source's `k` flag, k=1 by default vs the `hx>0||hx<=0xbe95f619` arm's
       k=0) feeds `br i1 %28`, and `%70 = phi i1 [%68,%62],[false,%32]` feeds
       `br i1 %70`.
     - shape B, a branch condition untainted at detection that the flatten
       itself taints: the source's `if(k==0)` is `%79 = icmp eq i32 %71, 0`
       where `%71 = phi i32 [%64,%62],[0,%32]` is the region-internal phi
       carrying `k`.
   All 12 phis are consumed by the flatten: 0 phi nodes survive in the lowered
   @slice. Measured on the lowered IR (call sites, declarations excluded), and
   identically on the trace (the runtime prints exactly one line per call):
       332 cqrt_alloc_*  = 306 cqrt_alloc_i1 + 19 cqrt_alloc_f32
                           + 7 cqrt_alloc_i32
       1 cqrt_ry_f32, 1 cqrt_measure_f32   (the sole rotation and the sole
                                            measurement; the compiler inserted
                                            no measurement — Rule 5)
       612 cqrt_toffoli flag conjunctions, 512 cqrt_cnot, 40 cqrt_x,
       600 cqrt_free
       28 cqrt_copy_f32_controlled + 12 cqrt_copy_i32_controlled route-merges
       653 cq_template_* calls total
       0 residual @cq_* intrinsic call sites, 0 @llvm.* CALL SITES
   Every compare that mints a flag is paired 1:1 with its _inv strip (measured:
   294 forward compare templates — 287 icmp + 7 fcmp — against exactly 294
   cq_template_*_inv calls).
   Golden trace: 2791 lines, byte-identical across two runs of the linked
   binary. Note that 2 now-unused `declare @llvm.*` lines (fabs.f32,
   fmuladd.f32) do survive in the lowered module with no uses, so a bare grep
   for @llvm. is not a refutation of the zero-call-site claim above.
   This slice is the LINK-layer proof (Rule 2) that every emitted symbol
   resolves, signature-matches, and the trace is byte-stable across runs. */
#include <stdint.h>

/* math_private.h GET_FLOAT_WORD / SET_FLOAT_WORD expanded to the
   __builtin_memcpy idiom clang -O1 folds to the same bitcast IR the taint pass
   lowers; all 5 sites in this body take a float operand (see header). */
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)
/* math_private.h line 207, the #ifndef __FreeBSD__ arm (the one taken here). */
#define	STRICT_ASSIGN(type, lval, rval)	((lval) = (rval))

/* ---- vendored from openlibm src/s_log1pf.c (verbatim) ---- */
static const float
ln2_hi =   6.9313812256e-01,	/* 0x3f317180 */
ln2_lo =   9.0580006145e-06,	/* 0x3717f7d1 */
two25 =    3.355443200e+07,	/* 0x4c000000 */
Lp1 = 6.6666668653e-01,	/* 3F2AAAAB */
Lp2 = 4.0000000596e-01,	/* 3ECCCCCD */
Lp3 = 2.8571429849e-01, /* 3E924925 */
Lp4 = 2.2222198546e-01, /* 3E638E29 */
Lp5 = 1.8183572590e-01, /* 3E3A3325 */
Lp6 = 1.5313838422e-01, /* 3E1CD04F */
Lp7 = 1.4798198640e-01; /* 3E178897 */

static const float zero = 0.0;

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
		STRICT_ASSIGN(float,u,(float)1.0+x);
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

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_log1pf(q));
}
int main(void) { (void) slice(); return 0; }
