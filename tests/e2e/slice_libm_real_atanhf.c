/* slice_libm_real_atanhf.c — bd q2wk: the REAL openlibm atanhf body.

   CORPUS VENDORED (two files — the whole closure):
     /private/tmp/openlibm_reclone/src/e_atanhf.c — __ieee754_atanhf(x), the
     entire algorithm (the |x|>1 NaN arm, the |x|==1 divide-by-zero arm, the
     x<2**-28 early-out, the SET_FLOAT_WORD absolute value, the x<0.5 vs
     x>=0.5 argument split, and the final sign restore from hx).
     /private/tmp/openlibm_reclone/src/s_log1pf.c — log1pf(x), the sole
     library callee of e_atanhf.c, vendored whole (the sqrt(2) window test,
     the x<=-1 arms, the |x|<2**-15 / 2**-24 arms, the k/u/c argument
     reduction with both the hx<0x5a000000 and the large-x forms, the
     u<sqrt(2) vs u>=sqrt(2) normalization, the hu==0 |f|<2**-20 arms and
     the Lp1..Lp7 polynomial).
     That closes the graph: after those two, the closure calls nothing at
     all — no keep-set builtin and no further library function (see
     KEEP-SET CALLS below).

   MECHANICAL EDITS (declared, per file, in corpus order; no algorithmic
   change — every constant, branch, comparison and expression is the corpus
   text byte-for-byte):
     s_log1pf.c (vendored first, as the dependency):
       - deleted: the "float version of s_log1p.c" attribution comment
         (corpus lines 1-3), the SunPro license block (lines 5-14), the 4
         include lines (cdefs-compat.h line 16, float.h line 19,
         openlibm_math.h line 20, math_private.h line 22), the //__FBSDID
         comment (line 17), and the OLM_DLLEXPORT storage marker (line 38).
         All comment, include or storage-class text; no executable statement
         removed. The coefficient block's hex-value comments (lines 25-34)
         are KEPT verbatim.
       - entry point log1pf renamed to olm_log1pf and marked always_inline
         static inline (forces the census inline shape at plain -O1 so the
         closure collapses into one function — recipe lesson bd 20xt.2).
       - its file-scope `static const float zero = 0.0;` (line 36) keeps the
         corpus name `zero`; the COLLIDING name in e_atanhf.c is the one
         renamed (below).
     e_atanhf.c (the entry file):
       - deleted: the "float version of e_atanh.c" attribution comment
         (corpus lines 1-3), the SunPro license block (lines 5-14), the 3
         include lines (cdefs-compat.h line 16, openlibm_math.h line 19,
         math_private.h line 21), the //__FBSDID comment (line 17), and the
         OLM_DLLEXPORT storage marker (line 27). Same categories as above.
       - entry point __ieee754_atanhf renamed to olm_atanhf, always_inline
         static inline. (In openlibm __ieee754_atanhf IS the public symbol:
         math_private.h line 315 is `#define __ieee754_atanhf atanhf`, so
         there is no separate wrapper file in the closure.)
       - COLLISION UNIQUIFIED: e_atanhf.c line 25 `static const float zero =
         0.0;` collides with s_log1pf.c line 36's `zero`, so this one is
         renamed atanhf_zero (2 uses, both in the body: `x/zero` and
         `(huge+x)>zero`). Its `one` and `huge` (line 23) do NOT collide with
         anything in s_log1pf.c and keep their corpus names.
       - the intra-body call `log1pf(...)` (2 sites, corpus lines 42 and 44)
         renamed to the vendored `olm_log1pf(...)`.
     both files:
       - the math_private.h word macros GET_FLOAT_WORD / SET_FLOAT_WORD are
         supplied at the top of this file as the __builtin_memcpy 4-byte pun
         shim that clang -O1 folds to the same bitcast IR. Defining them as
         macros (rather than expanding each site by hand) leaves both bodies
         byte-identical to the corpus. Both files apply these macros ONLY to
         `float` lvalues — there is no k_expf-style double->float narrowing
         site here, so the plain 4-byte pun is exact (gotcha bd 3c6m.53).
       - STRICT_ASSIGN (1 site, s_log1pf.c line 66) supplied as the plain
         assignment form: math_private.h line 206's `#ifndef __FreeBSD__`
         selects line 207's
         `#define STRICT_ASSIGN(type,lval,rval) ((lval)=(rval))`, and
         __FreeBSD__ is not defined on this target.
       - <stdint.h> added for int32_t/uint32_t. Neither file uses the BSD
         u_int32_t spelling, so no type rename was needed.

   KEEP-SET CALLS (Rule 18): the corpus closure calls NO keep-set function
   BY NAME. The cell note anticipated an fabsf keep, but the real e_atanhf.c
   takes the absolute value in the WORD domain (`ix = hx&0x7fffffff;` then
   `SET_FLOAT_WORD(x,ix);`) and never calls fabsf; s_log1pf.c does not call
   it either. Nothing here was substituted for a software body, and nothing
   was vendored that should have been a keep — there is no sqrt/fabs/rint
   call site in either corpus file to get wrong.
   Two keep-set intrinsic families DO reach the pass, both synthesized by
   clang -O1 out of the source's own stock C, not by a name recognizer:
     - 3 @llvm.fabs.f32 call sites (measured in /tmp/atanhf_s1.ll): clang
       canonicalizes the `& 0x7fffffff` mask of a float's bit pattern into
       fabs-then-bitcast. The 3 sites are e_atanhf.c's `ix = hx&0x7fffffff`
       and the `ax = hx&0x7fffffff` of EACH of the two inlined log1pf copies
       (olm_atanhf calls olm_log1pf at two source sites).
     - 32 @llvm.fmuladd.f32 call sites: clang's default fp-contract=on fuses
       the polynomial and correction-term products. MEASURED distribution:
       all 32 sit inside the two inlined olm_log1pf copies, 16 each (s1
       blocks 44-168 and 228-262); olm_atanhf's OWN arithmetic contributes
       ZERO fmuladd — its `t*x/(one-x)` product is separated from the `t+`
       addend by an fdiv, and `(float)0.5*t` has no addend to fuse with.
   Both are Rule-18 keeps (hardware-folded before codegen, Bennett-backed),
   and both lower 1:1 (counts below).

   LOWERING EXERCISED (every figure below MEASURED on /tmp/atanhf_s1.ll,
   /tmp/atanhf_s2.ll and the golden, re-counted 2026-10-05): a single tainted-x
   atanhf. Pre-pass @slice is NOT straight-line — it carries 64 basic blocks
   and 63 br, 32 of them CONDITIONAL: the fdlibm exponent-word
   classification cascade of e_atanhf.c with two whole inlined copies of
   s_log1pf.c's cascade nested inside it. The pass's PredMux/flatten stage
   collapses that to a straight line: the lowered @slice is 2 blocks with
   exactly 1 br, an unconditional edge into the measure block, and 1 ret.
   That tainted classification chain lowers onto the select substrate as 66
   cqrt_copy_f32_controlled + 24 cqrt_copy_i32_controlled route-merges,
   2496 cqrt_toffoli flag conjunctions, 2248 cqrt_cnot, 90 cqrt_x polarity
   brackets, 1248 cqrt_alloc_i1 flag rails, 42 cqrt_alloc_f32 and 14
   cqrt_alloc_i32 (of the 42 f32 allocs, exactly 1 is the taint source —
   trace line 1, `cqrt_alloc_f32(0x1p-1) -> h0`, immediately followed by
   the single cqrt_ry_f32), and 2528 cqrt_free. There is exactly 1
   cqrt_ry_f32 (the sole taint source) and exactly 1 cqrt_measure_f32 (the
   sole sink, trace line 11377). Every fcmp/icmp template appears paired
   with its _unc strip at equal count (e.g. 225/225 icmp_ult_i32_hl,
   64/64 fcmp_ogt_f32_hl) — no unstripped flag.
   Both keep families lower 1:1, nothing dropped: 3 @llvm.fabs.f32 -> 3
   cq_template_fabs_f32, and 32 @llvm.fmuladd.f32 -> 32 fma templates
   (14 cq_template_fma_f32_qlq + 10 _qql + 4 _qll + 4 plain = 32).
   The lowered module has ZERO residual @cq_* intrinsic calls and ZERO
   @llvm.* CALL SITES — though 2 now-unused `declare @llvm.{fmuladd,fabs}.f32`
   lines do survive with no uses, so a bare grep for @llvm. is not a
   refutation of that claim. The trace is 11377 lines and byte-identical
   across two runs. This slice is the LINK-layer proof (Rule 2) that every
   emitted symbol resolves, signature-matches, and the trace is stable. */
#include <stdint.h>

/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. f32 words only. */
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)
/* not-__FreeBSD__ selection of math_private.h's STRICT_ASSIGN. */
#define STRICT_ASSIGN(type,lval,rval) ((lval)=(rval))

/* ---- dependency: openlibm src/s_log1pf.c (verbatim) ---- */
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

/* ---- entry: openlibm src/e_atanhf.c (verbatim; `zero` -> `atanhf_zero`,
   `log1pf` -> `olm_log1pf`) ---- */
static const float one = 1.0, huge = 1e30;

static const float atanhf_zero = 0.0;

__attribute__((always_inline)) static inline float
olm_atanhf(float x)
{
	float t;
	int32_t hx,ix;
	GET_FLOAT_WORD(hx,x);
	ix = hx&0x7fffffff;
	if (ix>0x3f800000) 		/* |x|>1 */
	    return (x-x)/(x-x);
	if(ix==0x3f800000)
	    return x/atanhf_zero;
	if(ix<0x31800000&&(huge+x)>atanhf_zero) return x;	/* x<2**-28 */
	SET_FLOAT_WORD(x,ix);
	if(ix<0x3f000000) {		/* x < 0.5 */
	    t = x+x;
	    t = (float)0.5*olm_log1pf(t+t*x/(one-x));
	} else
	    t = (float)0.5*olm_log1pf((x+x)/(one-x));
	if(hx>=0) return t; else return -t;
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_atanhf(q));
}
int main(void) { (void) slice(); return 0; }
