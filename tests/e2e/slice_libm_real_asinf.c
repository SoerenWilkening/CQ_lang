/* slice_libm_real_asinf.c — bd 3c6m.60: the REAL openlibm asinf body.

   Cell: asinf.f32.
   Corpus vendored (intact clone at /private/tmp/openlibm_reclone, pinned at
   upstream 82e90ae, working tree clean):
     src/e_asinf.c — the whole cell: the `one` / `huge` / `pS0..pS2` / `qS1`
       float coefficient block, the `pio2` double, and __ieee754_asinf verbatim.
       (math_private.h:316 is `#define __ieee754_asinf asinf`, so this body IS
       the public asinf — there is no separate wrapper file to vendor.)
   No other corpus file is vendored: the closure of e_asinf.c is exactly
   { fabsf, sqrt }, and BOTH are Rule-18 hardware keeps (see below), so there is
   no library body left to inject.

   Declared mechanical edits (and no others):
     - deleted the include lines (cdefs-compat.h, openlibm_math.h,
       math_private.h), the SunPro license header block, the FBSDID comment,
       and the OLM_DLLEXPORT storage-class marker.
     - added `#include <stdint.h>`: the corpus obtained int32_t / uint32_t
       transitively through math_private.h, which is deleted above.
     - entry point __ieee754_asinf renamed to olm_asinf and given
       __attribute__((always_inline)) static inline, so plain -O1 collapses the
       cell to one straight-line body (the census inline shape; bd 20xt.2).
     - the math_private.h GET_FLOAT_WORD macro expanded to the __builtin_memcpy
       shim, routed through a float temp per the bd 3c6m.53 f32 hazard note
       (here the operand `x` is already a float, so the temp is a no-op, but the
       shim is written defensively). SET_FLOAT_WORD is not used by this cell.
     - added, outside the vendored body: this header block, the two provenance
       comments below, and the slice()/main() trace harness at the bottom.
     - no constant, branch, expression, or declaration was altered; the
       coefficient block and the body are byte-faithful to src/e_asinf.c modulo
       the renames above (verified by mechanically un-applying the renames and
       byte-comparing: 1030 bytes on each side, identical, tabs included).

   Keep-set calls rewritten to their __builtin_ spelling (Rule 18):
     - fabsf(x)  ->  __builtin_fabsf(x)
     - sqrt(t)   ->  __builtin_sqrt(t)   [NOTE: the corpus really does call the
       DOUBLE sqrt here — `s` is declared `double` and the float `t` promotes —
       so the f64 spelling is the faithful one, not sqrtf.]
   This is the census harness fix made honest. The corpus census used to build
   openlibm with a blanket -fno-builtin, so these inner names resolved to
   openlibm's SOFTWARE bodies and dragged e_sqrt.c's subnormal-normalize loop
   into the cell — e_asinf.c itself contains ZERO loops. At the real ship floor
   (plain `clang -O1`, builtins ON) fabsf and sqrt fold to @llvm.fabs.f32 /
   @llvm.sqrt.f64 BEFORE codegen and cq-lowering rewrites them to
   cq_template_fabs_f32 / cq_template_sqrt_f64. __builtin_ is the same IR
   construct the ship floor emits for the named call and needs no libm
   declaration; it is NOT a body substitution (a keep has no injectable body).

   Lowering exercised (each item read back out of the emitted trace / lowered
   IR of this exact slice, not asserted from the source):
     - the f32 exponent-word classification cascade (|x|>=1 / |x|==1 / |x|<0.5 /
       |x|<2**-12 / else) flattens to a BRANCH-FREE body. Measured on @slice:
       clang -O1 leaves 9 basic blocks and 8 `br` instructions, of which 4 are
       CONDITIONAL (`br i1`) and 4 are `br label`; after cq-lowering @slice is
       2 blocks with 0 `br i1` (one unconditional `br label` + the `ret`
       survive). The five arm values are merged by the controlled-XOR copy
       substrate: 5 `cqrt_copy_f32_controlled` PAIRS, each pair `cqrt_x`-
       bracketed on its control, each control un-minted and its compare `_unc`-
       stripped and freed afterwards. The control is NOT uniformly a toffoli
       conjunction rail — two of the five deviate: the `hx>0` sign merge drives
       its copy pair from the BARE `icmp_sgt_i32_hl` flag (no `cqrt_alloc_i1`,
       no toffoli at all), and the polynomial-arm merge mints one of its two
       conjunction inputs with a cnot/cnot/toffoli OR-network rather than a
       conjunction. Golden-trace totals: 8 `cqrt_alloc_i1` control rails (all 8
       freed), 16 `cqrt_toffoli` (each rail minted and un-minted once), 4
       `cqrt_cnot` (the OR-network, minted and un-minted), 10 `cqrt_x`, 13
       compare `_unc` strips, 43 `cqrt_free` on 43 DISTINCT handles (8 rails,
       13 flags, 22 `_unc`'d template rails); the 6 `cqrt_alloc_f32` (theta rail
       + 5 merge destinations) stay allocated, never freed dirty (Rule 6). The
       `huge+x>one` raise-inexact guard is in that set (it lowers to
       cq_template_fadd_f32_hl(h0, 1e30) then fcmp_ogt/fcmp_ule_f32_hl vs 1.0);
     - a MIXED-WIDTH Rule-18 keep pair on one tainted rail:
       cq_template_fabs_f32 (from @llvm.fabs.f32) AND cq_template_sqrt_f64
       (from @llvm.sqrt.f64), both on values derived from the single f32 theta;
       no @llvm.* call survives in the lowered body (0 in @slice; 4 orphan,
       uncalled `declare @llvm.*` lines remain module-wide);
     - the f32<->f64 conversion templates that straddle that width split: THREE
       fpext_f32_to_f64 — on the sqrt argument `t`, on `w`, and on `x` for the
       |x|==1 `x*pio2` arm — and TWO fptrunc_f64_to_f32 — on the
       `t = pio2-2.0*(s+s*w)` tail (whose f64 arithmetic fuses to
       fma_f64 / fma_f64_qll) and on that same `x*pio2` arm;
     - the sign fixup `if(hx>0) return t; else return -t` as a tainted-condition
       merge over cq_template_fneg_f32.
   This slice is the LINK-layer proof (Rule 2) that every emitted symbol
   resolves, signature-matches, and produces a stable trace. */
#include <stdint.h>

/* math_private.h GET_FLOAT_WORD, expanded to the __builtin_memcpy idiom
   clang -O1 folds to the same bitcast IR (float temp per bd 3c6m.53). */
#define GET_FLOAT_WORD(i,d)    do{ float __f=(float)(d); uint32_t __w; __builtin_memcpy(&__w,&__f,4); (i)=(int32_t)__w; }while(0)

static const float
one =  1.0000000000e+00, /* 0x3F800000 */
huge =  1.000e+30,
	/* coefficient for R(x^2) */
pS0 =  1.6666586697e-01,
pS1 = -4.2743422091e-02,
pS2 = -8.6563630030e-03,
qS1 = -7.0662963390e-01;

static const double
pio2 =  1.570796326794896558e+00;

/* openlibm src/e_asinf.c __ieee754_asinf (verbatim). */
__attribute__((always_inline)) static inline float
olm_asinf(float x)
{
	double s;
	float t,w,p,q;
	int32_t hx,ix;
	GET_FLOAT_WORD(hx,x);
	ix = hx&0x7fffffff;
	if(ix>=0x3f800000) {		/* |x| >= 1 */
	    if(ix==0x3f800000)		/* |x| == 1 */
		return x*pio2;		/* asin(+-1) = +-pi/2 with inexact */
	    return (x-x)/(x-x);		/* asin(|x|>1) is NaN */
	} else if (ix<0x3f000000) {	/* |x|<0.5 */
	    if(ix<0x39800000) {		/* |x| < 2**-12 */
		if(huge+x>one) return x;/* return x with inexact if x!=0*/
	    }
	    t = x*x;
	    p = t*(pS0+t*(pS1+t*pS2));
	    q = one+t*qS1;
	    w = p/q;
	    return x+x*w;
	}
	/* 1> |x|>= 0.5 */
	w = one-__builtin_fabsf(x);
	t = w*(float)0.5;
	p = t*(pS0+t*(pS1+t*pS2));
	q = one+t*qS1;
	s = __builtin_sqrt(t);
	w = p/q;
	t = pio2-2.0*(s+s*w);
	if(hx>0) return t; else return -t;
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_asinf(q));
}
int main(void) { (void) slice(); return 0; }
