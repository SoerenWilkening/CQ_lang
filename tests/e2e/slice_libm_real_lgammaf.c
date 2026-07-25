/* slice_libm_real_lgammaf.c — bd 3c6m.60: the REAL openlibm lgammaf body over
   its full float closure. Census cell lgammaf.f32.

   SCOPE LIMIT — READ THIS BEFORE CITING THIS GOLDEN AS COVERAGE.
   This slice gives the public wrapper's `signgam` global INTERNAL linkage
   (`static int signgam;`, just above olm_lgammaf). openlibm does not: it declares
   `OLM_DLLEXPORT extern int signgam;` (include/openlibm_math.h:177) and defines
   it `int signgam = 0;` (src/s_signgam.c:6) — EXTERNAL linkage. That one word is
   outcome-determining, not cosmetic:
     - As shipped (`static`, never read): clang -O1 GlobalOpt/DSE deletes the
       global and all three `*signgamp` stores before cq-lowering runs. MEASURED:
       the stage-1 .ll contains 0 `signgam` occurrences and 0 `store`
       instructions. opt exits 0 and this golden is produced.
     - With the corpus linkage (A/B measured, only textual change = drop
       `static`; same clang, same plugin, same flags): 3 stores survive into the
       stage-1 .ll and opt exits 1 with
         error: <unknown>:0:0: in function slice float (): cq controlled lowering: nested control flow under quantum control
   So: this golden does NOT exercise a store under quantum control. The
   `*signgamp = -1` under the tainted `hx<0` test — the hardest construct in this
   function — is dead before the pass sees the module. What is proven here is
   "the real lgammaf body WITH ITS signgam SIDE EFFECT DEAD-STRIPPED lowers",
   not "the real lgammaf lowers". The decline in the A/B is a SAFE decline
   (Prime Directive), not a miscompile — but it is the ship-floor outcome for the
   corpus-linkage spelling, and this cell's evidence must not be read as
   covering it. (The f64 sibling slice_libm_real_lgamma.c carries the same
   caveat.)

   CORPUS FILES VENDORED (from /private/tmp/openlibm_reclone):
     src/e_lgammaf_r.c  — the whole computational body: the 65-entry float
                          coefficient block (two23 half one pi a0..a11 tc tf tt
                          t0..t14 u0..u5 v1..v5 s0..s6 r1..r6 w0..w6), the file
                          static `zero`, the static helper sin_pif, and
                          __ieee754_lgammaf_r itself.
     src/e_logf.c       — __ieee754_logf, the inner log, reached from SEVEN
                          call sites in olm_lgammaf_r (the two |x|<2**-21
                          tails, the negative-x reflection nadj, the
                          ix<=0x3f666666 (x<=0.9) branch, the i=3..7
                          rising-factorial tail, and both x>=8.0 bands, one of
                          which is 8.0<=x<2**58 and the other x>=2**58). Taken
                          BYTE-IDENTICALLY from the
                          already-verified sibling slice
                          tests/e2e/slice_libm_real_logf.c (bd 3c6m.53), which
                          is itself the verbatim src/e_logf.c body.
     src/k_sinf.c       — __kernel_sindf, reached from FOUR call sites in
                          sin_pif: the pre-switch |x|<0.25 early return, plus
                          the n = 0, the n = 3/4, and the default switch arms.
     src/k_cosf.c       — __kernel_cosdf, reached from TWO call sites in
                          sin_pif: the n = 1/2 and the n = 5/6 switch arms.
                          sin_pif pre-reduces its argument itself, so NO
                          rem_pio2f closure is pulled in.
     src/e_lgammaf.c    — the public non-reentrant wrapper shape
                          lgammaf(x) = lgammaf_r(x, &signgam). The corpus body
                          resolves `signgam` to the external global (its
                          function-local `int signgam;` is behind
                          `#ifdef OPENLIBM_ONLY_THREAD_SAFE`, off by default);
                          this slice substitutes a file-scope
                          `static int signgam;` instead. The census harness does
                          NOT spell it this way either — it uses external
                          linkage, `int signgam;`
                          (tools/library_coverage/full_surface/README.md:472).
                          This is the one edit that is not semantics-neutral:
                          see SCOPE LIMIT above and mechanical edit (e) below.

   MECHANICAL EDITS — no constant, branch, or expression was changed (every
   rename below was applied by a word-boundary perl substitution over the
   extracted corpus text, and the result was diffed back against the corpus with
   the substitutions reversed). This list is the faithfulness contract: it
   enumerates EVERY difference from the corpus text. Edits (a)-(d) are
   semantics-neutral; edit (e) is NOT — see SCOPE LIMIT above.
     a) deleted the include lines, the Sun/FreeBSD license and FBSDID header
        blocks, and the OLM_ export-macro decoration on each entry point.
     b) renamed each entry point to its olm_ vendored name and marked it
        `__attribute__((always_inline)) static inline`:
        __ieee754_lgammaf_r -> olm_lgammaf_r, sin_pif -> olm_sin_pif,
        __ieee754_logf -> olm_logf, __kernel_sindf -> olm_kernel_sindf,
        __kernel_cosdf -> olm_kernel_cosdf, __ieee754_lgammaf -> olm_lgammaf;
        every intra-body call was renamed to match. Force-inlining collapses the
        closure to one straight-line body at plain -O1 (recipe lesson from bd
        20xt.2). It does NOT reproduce the census inline shape: under the census
        harness the inner logf stays OUTLINED (full_census_O1.json records
        lgammaf.f32 as `"diag": "surv:['logf']"`), whereas the always_inline
        convention here inlines it.
     c) uniquified two file-scope static-const name collisions across the four
        vendored translation units; VALUES AND TYPES UNCHANGED:
          e_lgammaf_r.c `zero` (float 0.0) -> `lgammaf_zero`, because
          e_logf.c already contributes a `zero` and the logf body is kept
          byte-identical with the verified sibling slice;
          k_cosf.c `one` (double 1.0) -> `cosdf_one`, because e_lgammaf_r.c
          already contributes a float `one`.
        No other name collides (S1..S4 vs s0..s6 differ in case; two23 vs
        two25, half, pi, tc, tf, tt, C0..C3, Lg1..Lg4 are unique).
     d) replaced the math_private.h word macros with the __builtin_memcpy shim
        block used by every sibling slice. Only GET_FLOAT_WORD is actually
        exercised here (in olm_sin_pif and olm_lgammaf_r on `float` lvalues)
        plus GET_FLOAT_WORD/SET_FLOAT_WORD inside olm_logf; the f32 hazard of
        bd 3c6m.53 does not arise because every argument of a *_FLOAT_WORD use
        in this closure is declared `float`, never `double` — the two `double`
        parameters in this file (olm_kernel_sindf / olm_kernel_cosdf) do no word
        access at all.
     e) LINKAGE CHANGE, NOT SEMANTICS-NEUTRAL: the corpus `signgam` (external
        linkage, openlibm_math.h:177 + s_signgam.c:6) was replaced by a
        file-scope `static int signgam;`. This is the only edit that changes what
        the compiler is allowed to do to the source: it lets -O1 dead-strip the
        wrapper's side effect, and the corpus-linkage spelling declines at the
        ship floor. Read SCOPE LIMIT at the top before using this cell as
        coverage evidence.

   KEEP-SET CALLS REWRITTEN TO __builtin_ (Rule 18): `floorf` (twice, in the
   sin_pif argument reduction) -> `__builtin_floorf`, and `fabsf` (once, in the
   negative-x reflection nadj) -> `__builtin_fabsf`. Both are x86-64 hardware
   keeps: at the ship floor plain `clang -O1` folds the named call to
   @llvm.floor.f32 / @llvm.fabs.f32 before codegen, which is exactly the
   construct `__builtin_` emits, and cq-lowering rewrites it to
   cq_template_floor_f32 / cq_template_fabs_f32. This is NOT a body
   substitution: a keep has no injectable body by definition. Everything else in
   the closure (logf, the two sin/cos kernels) is a LIBRARY function and IS
   vendored from real source.

   LOWERING EXERCISED: a deeply branch-dense value-region chain. The tainted
   float word `hx`/`ix` drives the outer band ladder (ix>=0x7f800000 NaN/inf,
   ix==0, ix<0x35000000, hx<0, then 0x3f800000/0x40000000, 0x41000000,
   0x5c800000); the negative-x arm calls olm_sin_pif, which itself contains a
   nested if/else argument reduction over __builtin_floorf plus an 8-LABEL
   `switch (n)` (cases 0..6 + default, 5 distinct bodies) on a tainted
   scrutinee; the x<2.0 arm has a 3-arm `switch (i)` of Horner polynomials; and
   the 2.0<=x<8.0 arm has a FALLTHROUGH `switch (i)` rising-factorial chain
   (cases 7..3). All of it flattens onto the PredMux select substrate — the
   lowered module calls cqrt_copy_f32_controlled 218x and cqrt_copy_i32_-
   controlled 38x (the kjd1 fp / 4.4 integer controlled-copy merges) — and the
   whole-DAG LIFO uncompute spine reverses the dead arithmetic: all 14 compare
   families have their `_inv` twin with matching call counts and zero orphan
   `_inv`, and the trace carries 3267 cqrt_free lines on 3267 distinct
   operands, interleaved from trace line 29 onward (not a terminal block — the
   trace's last line is the cqrt_measure_f32). What this region chain does NOT
   contain is a store under quantum control: see SCOPE LIMIT at the top.

   This slice is the LINK-layer proof (Rule 2) that every emitted symbol
   resolves and signature-matches and that the trace is stable and
   deterministic; census bucket for this cell is COMPILES (spec-clone) because
   the inner logf stays outlined under the census harness, whereas the
   always_inline convention here collapses it. Both routes reach opt exit 0;
   this golden pins the ship-floor one (precedent: slice_libm_real_sinhl.c).

   MEASURED AT MINT (bd 3c6m.60 gate), all re-measured 2026-07-25: opt exit 0
   with an empty stderr; s2.ll has 0 residual @cq_theta / @cq_phi / @cq_measure
   calls, and @slice and @main are the only defined functions. Four vestigial
   `declare`s outside the cqrt_ / cq_template_ families survive — @llvm.fabs.f32,
   @llvm.fmuladd.f32, @llvm.floor.f32, @llvm.fmuladd.f64 — each with ZERO
   remaining call sites (LLVM does not strip unused declarations); nothing
   unlowered escapes and the link is clean. 1891 cqrt_alloc call sites (1719
   i1 + 134 f32 + 38 i32); the trace is 14135 lines with EXACTLY one
   cqrt_ry_f32 and EXACTLY one cqrt_measure_f32; all 3267 cqrt_free operands
   are distinct and the measured handle h5626 is never among them; two runs are
   byte-identical. */
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

/* ---- vendored from openlibm src/e_logf.c ---- */
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

/* ---- vendored from openlibm src/k_sinf.c ---- */
/* |sin(x)/x - s(x)| < 2**-37.5 (~[-4.89e-12, 4.824e-12]). */
static const double
S1 = -0x15555554cbac77.0p-55,	/* -0.166666666416265235595 */
S2 =  0x111110896efbb2.0p-59,	/*  0.0083333293858894631756 */
S3 = -0x1a00f9e2cae774.0p-65,	/* -0.000198393348360966317347 */
S4 =  0x16cd878c3b46a7.0p-71;	/*  0.0000027183114939898219064 */

__attribute__((always_inline)) static inline float
olm_kernel_sindf(double x)
{
	double r, s, w, z;

	/* Try to optimize for parallel evaluation as in k_tanf.c. */
	z = x*x;
	w = z*z;
	r = S3+z*S4;
	s = z*x;
	return (x + s*(S1+z*S2)) + s*w*r;
}

/* ---- vendored from openlibm src/k_cosf.c (`one` -> `cosdf_one`) ---- */
/* |cos(x) - c(x)| < 2**-34.1 (~[-5.37e-11, 5.295e-11]). */
static const double
cosdf_one =  1.0,
C0  = -0x1ffffffd0c5e81.0p-54,	/* -0.499999997251031003120 */
C1  =  0x155553e1053a42.0p-57,	/*  0.0416666233237390631894 */
C2  = -0x16c087e80f1e27.0p-62,	/* -0.00138867637746099294692 */
C3  =  0x199342e0ee5069.0p-68;	/*  0.0000243904487962774090654 */

__attribute__((always_inline)) static inline float
olm_kernel_cosdf(double x)
{
	double r, w, z;

	/* Try to optimize for parallel evaluation as in k_tanf.c. */
	z = x*x;
	w = z*z;
	r = C2+z*C3;
	return ((cosdf_one+z*C0) + w*C1) + (w*z)*r;
}

/* ---- vendored from openlibm src/e_lgammaf_r.c (`zero` -> `lgammaf_zero`) ---- */
static const float
two23=  8.3886080000e+06, /* 0x4b000000 */
half=  5.0000000000e-01, /* 0x3f000000 */
one =  1.0000000000e+00, /* 0x3f800000 */
pi  =  3.1415927410e+00, /* 0x40490fdb */
a0  =  7.7215664089e-02, /* 0x3d9e233f */
a1  =  3.2246702909e-01, /* 0x3ea51a66 */
a2  =  6.7352302372e-02, /* 0x3d89f001 */
a3  =  2.0580807701e-02, /* 0x3ca89915 */
a4  =  7.3855509982e-03, /* 0x3bf2027e */
a5  =  2.8905137442e-03, /* 0x3b3d6ec6 */
a6  =  1.1927076848e-03, /* 0x3a9c54a1 */
a7  =  5.1006977446e-04, /* 0x3a05b634 */
a8  =  2.2086278477e-04, /* 0x39679767 */
a9  =  1.0801156895e-04, /* 0x38e28445 */
a10 =  2.5214456400e-05, /* 0x37d383a2 */
a11 =  4.4864096708e-05, /* 0x383c2c75 */
tc  =  1.4616321325e+00, /* 0x3fbb16c3 */
tf  = -1.2148628384e-01, /* 0xbdf8cdcd */
/* tt = -(tail of tf) */
tt  =  6.6971006518e-09, /* 0x31e61c52 */
t0  =  4.8383611441e-01, /* 0x3ef7b95e */
t1  = -1.4758771658e-01, /* 0xbe17213c */
t2  =  6.4624942839e-02, /* 0x3d845a15 */
t3  = -3.2788541168e-02, /* 0xbd064d47 */
t4  =  1.7970675603e-02, /* 0x3c93373d */
t5  = -1.0314224288e-02, /* 0xbc28fcfe */
t6  =  6.1005386524e-03, /* 0x3bc7e707 */
t7  = -3.6845202558e-03, /* 0xbb7177fe */
t8  =  2.2596477065e-03, /* 0x3b141699 */
t9  = -1.4034647029e-03, /* 0xbab7f476 */
t10 =  8.8108185446e-04, /* 0x3a66f867 */
t11 = -5.3859531181e-04, /* 0xba0d3085 */
t12 =  3.1563205994e-04, /* 0x39a57b6b */
t13 = -3.1275415677e-04, /* 0xb9a3f927 */
t14 =  3.3552918467e-04, /* 0x39afe9f7 */
u0  = -7.7215664089e-02, /* 0xbd9e233f */
u1  =  6.3282704353e-01, /* 0x3f2200f4 */
u2  =  1.4549225569e+00, /* 0x3fba3ae7 */
u3  =  9.7771751881e-01, /* 0x3f7a4bb2 */
u4  =  2.2896373272e-01, /* 0x3e6a7578 */
u5  =  1.3381091878e-02, /* 0x3c5b3c5e */
v1  =  2.4559779167e+00, /* 0x401d2ebe */
v2  =  2.1284897327e+00, /* 0x4008392d */
v3  =  7.6928514242e-01, /* 0x3f44efdf */
v4  =  1.0422264785e-01, /* 0x3dd572af */
v5  =  3.2170924824e-03, /* 0x3b52d5db */
s0  = -7.7215664089e-02, /* 0xbd9e233f */
s1  =  2.1498242021e-01, /* 0x3e5c245a */
s2  =  3.2577878237e-01, /* 0x3ea6cc7a */
s3  =  1.4635047317e-01, /* 0x3e15dce6 */
s4  =  2.6642270386e-02, /* 0x3cda40e4 */
s5  =  1.8402845599e-03, /* 0x3af135b4 */
s6  =  3.1947532989e-05, /* 0x3805ff67 */
r1  =  1.3920053244e+00, /* 0x3fb22d3b */
r2  =  7.2193557024e-01, /* 0x3f38d0c5 */
r3  =  1.7193385959e-01, /* 0x3e300f6e */
r4  =  1.8645919859e-02, /* 0x3c98bf54 */
r5  =  7.7794247773e-04, /* 0x3a4beed6 */
r6  =  7.3266842264e-06, /* 0x36f5d7bd */
w0  =  4.1893854737e-01, /* 0x3ed67f1d */
w1  =  8.3333335817e-02, /* 0x3daaaaab */
w2  = -2.7777778450e-03, /* 0xbb360b61 */
w3  =  7.9365057172e-04, /* 0x3a500cfd */
w4  = -5.9518753551e-04, /* 0xba1c065c */
w5  =  8.3633989561e-04, /* 0x3a5b3dd2 */
w6  = -1.6309292987e-03; /* 0xbad5c4e8 */

static const float lgammaf_zero=  0.0000000000e+00;
__attribute__((always_inline)) static inline float olm_sin_pif(float x)
{
	float y,z;
	int n,ix;

	GET_FLOAT_WORD(ix,x);
	ix &= 0x7fffffff;

	if(ix<0x3e800000) return olm_kernel_sindf(pi*x);
	y = -x;		/* x is assume negative */

    /*
     * argument reduction, make sure inexact flag not raised if input
     * is an integer
     */
	z = __builtin_floorf(y);
	if(z!=y) {				/* inexact anyway */
	    y  *= (float)0.5;
	    y   = (float)2.0*(y - __builtin_floorf(y));	/* y = |x| mod 2.0 */
	    n   = (int) (y*(float)4.0);
	} else {
            if(ix>=0x4b800000) {
                y = lgammaf_zero; n = 0;                 /* y must be even */
            } else {
                if(ix<0x4b000000) z = y+two23;	/* exact */
		GET_FLOAT_WORD(n,z);
		n &= 1;
                y  = n;
                n<<= 2;
            }
        }
	switch (n) {
	    case 0:   y =  olm_kernel_sindf(pi*y); break;
	    case 1:
	    case 2:   y =  olm_kernel_cosdf(pi*((float)0.5-y)); break;
	    case 3:
	    case 4:   y =  olm_kernel_sindf(pi*(one-y)); break;
	    case 5:
	    case 6:   y = -olm_kernel_cosdf(pi*(y-(float)1.5)); break;
	    default:  y =  olm_kernel_sindf(pi*(y-(float)2.0)); break;
	    }
	return -y;
}
__attribute__((always_inline)) static inline float
olm_lgammaf_r(float x, int *signgamp)
{
	float t,y,z,nadj,p,p1,p2,p3,q,r,w;
	int32_t hx;
	int i,ix;
	nadj = 0;	/* only set & used when hx<0; init silences -Wmaybe-uninitialized */

	GET_FLOAT_WORD(hx,x);

    /* purge off +-inf, NaN, +-0, tiny and negative arguments */
	*signgamp = 1;
	ix = hx&0x7fffffff;
	if(ix>=0x7f800000) return x*x;
	if(ix==0) return one/lgammaf_zero;
	if(ix<0x35000000) {	/* |x|<2**-21, return -log(|x|) */
	    if(hx<0) {
	        *signgamp = -1;
	        return -olm_logf(-x);
	    } else return -olm_logf(x);
	}
	if(hx<0) {
	    if(ix>=0x4b000000) 	/* |x|>=2**23, must be -integer */
		return one/lgammaf_zero;
	    t = olm_sin_pif(x);
	    if(t==lgammaf_zero) return one/lgammaf_zero; /* -integer */
	    nadj = olm_logf(pi/__builtin_fabsf(t*x));
	    if(t<lgammaf_zero) *signgamp = -1;
	    x = -x;
	}

    /* purge off 1 and 2 */
	if (ix==0x3f800000||ix==0x40000000) r = 0;
    /* for x < 2.0 */
	else if(ix<0x40000000) {
	    if(ix<=0x3f666666) { 	/* lgamma(x) = lgamma(x+1)-log(x) */
		r = -olm_logf(x);
		if(ix>=0x3f3b4a20) {y = one-x; i= 0;}
		else if(ix>=0x3e6d3308) {y= x-(tc-one); i=1;}
	  	else {y = x; i=2;}
	    } else {
	  	r = lgammaf_zero;
	        if(ix>=0x3fdda618) {y=(float)2.0-x;i=0;} /* [1.7316,2] */
	        else if(ix>=0x3F9da620) {y=x-tc;i=1;} /* [1.23,1.73] */
		else {y=x-one;i=2;}
	    }
	    switch(i) {
	      case 0:
		z = y*y;
		p1 = a0+z*(a2+z*(a4+z*(a6+z*(a8+z*a10))));
		p2 = z*(a1+z*(a3+z*(a5+z*(a7+z*(a9+z*a11)))));
		p  = y*p1+p2;
		r  += (p-(float)0.5*y); break;
	      case 1:
		z = y*y;
		w = z*y;
		p1 = t0+w*(t3+w*(t6+w*(t9 +w*t12)));	/* parallel comp */
		p2 = t1+w*(t4+w*(t7+w*(t10+w*t13)));
		p3 = t2+w*(t5+w*(t8+w*(t11+w*t14)));
		p  = z*p1-(tt-w*(p2+y*p3));
		r += (tf + p); break;
	      case 2:
		p1 = y*(u0+y*(u1+y*(u2+y*(u3+y*(u4+y*u5)))));
		p2 = one+y*(v1+y*(v2+y*(v3+y*(v4+y*v5))));
		r += (-(float)0.5*y + p1/p2);
	    }
	}
	else if(ix<0x41000000) { 			/* x < 8.0 */
	    i = (int)x;
	    y = x-(float)i;
	    p = y*(s0+y*(s1+y*(s2+y*(s3+y*(s4+y*(s5+y*s6))))));
	    q = one+y*(r1+y*(r2+y*(r3+y*(r4+y*(r5+y*r6)))));
	    r = half*y+p/q;
	    z = one;	/* lgamma(1+s) = log(s) + lgamma(s) */
	    switch(i) {
	    case 7: z *= (y+(float)6.0);	/* FALLTHRU */
	    case 6: z *= (y+(float)5.0);	/* FALLTHRU */
	    case 5: z *= (y+(float)4.0);	/* FALLTHRU */
	    case 4: z *= (y+(float)3.0);	/* FALLTHRU */
	    case 3: z *= (y+(float)2.0);	/* FALLTHRU */
		    r += olm_logf(z); break;
	    }
    /* 8.0 <= x < 2**58 */
	} else if (ix < 0x5c800000) {
	    t = olm_logf(x);
	    z = one/x;
	    y = z*z;
	    w = w0+z*(w1+y*(w2+y*(w3+y*(w4+y*(w5+y*w6)))));
	    r = (x-half)*(t-one)+w;
	} else
    /* 2**58 <= x <= inf */
	    r =  x*(olm_logf(x)-one);
	if(hx<0) r = nadj - r;
	return r;
}

/* ---- vendored from openlibm src/e_lgammaf.c: the public non-reentrant
   wrapper. The `static` below is mechanical edit (e) and is NOT faithful: the
   corpus and the census harness both give signgam EXTERNAL linkage. It is
   outcome-determining — with `int signgam;` this slice declines at the ship
   floor. Read SCOPE LIMIT at the top of this file. ---- */
static int signgam;

__attribute__((always_inline)) static inline float
olm_lgammaf(float x)
{
	return olm_lgammaf_r(x,&signgam);
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_lgammaf(q));
}
int main(void) { (void) slice(); return 0; }
