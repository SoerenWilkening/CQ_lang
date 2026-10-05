/* slice_libm_real_lgamma.c — bd 3c6m.60: the REAL openlibm lgamma body over
   its full library closure. Census cell lgamma.f64 — the largest slice in this
   batch by vendored source volume.

   Corpus vendored (from the intact clone /private/tmp/openlibm_reclone):
     src/e_lgamma_r.c — the whole file: the file-scope coefficient table
                        (two52 half one pi a0-a11 tc tf tt t0-t14 u0-u5 v1-v5
                        s0-s6 r1-r6 w0-w6 zero), the static sin_pi helper, and
                        __ieee754_lgamma_r itself.
     src/e_lgamma.c   — the public entry. openlibm mints lgamma(x) as
                        __ieee754_lgamma_r(x, &signgam), so this slice keeps a
                        file-scope `static int signgam;` and olm_lgamma(x)
                        forwards to olm_lgamma_r(x, &signgam). The census probes
                        the public name, so the probe goes through that wrapper.
                        NOTE for reviewers: the wrapper is reproduced faithfully,
                        but its side effect does not survive to the pass. The
                        slice never reads signgam, so at -O1 GlobalOpt deletes
                        the write-only internal global before cq-lowering runs
                        (verified: zero `signgam` occurrences in the -O1 IR).
                        This cell therefore does NOT exercise a store under
                        quantum control; the `*signgamp = -1` under the tainted
                        `hx<0` test is dead by then.
     src/k_sin.c      — __kernel_sin plus its half/S1-S6 table.
     src/k_cos.c      — __kernel_cos plus its one/C1-C6 table.
     src/e_log.c      — __ieee754_log, reused BYTE-IDENTICALLY (both the
                        ln2_hi/ln2_lo/two54/Lg1-Lg7/zero table and the body)
                        from the already-verified sibling slice_libm_real_log.c,
                        per the recipe's "inner body identical to its own
                        standalone verified slice" pattern.
   The two kernels are reached ONLY from sin_pi, which reduces its own argument
   before calling them, so no argument-reduction closure is needed:
   src/e_rem_pio2.c is deliberately NOT vendored.

   KEEP-SET calls (Rule 18): `floor` (twice, in sin_pi) and `fabs` (once, in
   lgamma_r) are HARDWARE keeps. At the ship floor — plain `clang -O1`, builtins
   ON — the named calls fold to @llvm.floor.f64 / @llvm.fabs.f64 before codegen
   and cq-lowering rewrites those to cq_template_floor_f64 /
   cq_template_fabs_f64. A keep has no injectable body by definition, so this
   slice spells them __builtin_floor / __builtin_fabs: the identical IR
   construct, needing no libm declaration. That is NOT a body substitution.
   Everything else reachable — log, __kernel_sin, __kernel_cos, sin_pi — IS a
   library function and is vendored here as real openlibm source, transitively,
   until the closure is closed.

   Mechanical edits ONLY (libm-real-slice-recipe; NO constant, branch or
   expression changed). This list is the faithfulness contract: EVERY
   difference from the corpus is enumerated here.
     - deleted the corpus include lines, the license/FBSDID header blocks, and
       the OLM_DLLEXPORT export macro on each entry point. The slice includes
       only <stdint.h>, for the fixed-width types the word shims below need;
     - deleted e_log.c's trailing
       `#if (LDBL_MANT_DIG == 53) openlibm_weak_reference(log, logl); #endif`
       — an alias directive, not code;
     - every vendored function marked `__attribute__((always_inline)) static
       inline` and renamed to its olm_ name (__ieee754_lgamma_r -> olm_lgamma_r,
       sin_pi -> olm_sin_pi, __kernel_sin -> olm_kernel_sin, __kernel_cos ->
       olm_kernel_cos, __ieee754_log -> olm_log, and __ieee754_lgamma (which
       math_private.h maps to the public name lgamma) -> olm_lgamma), with
       every intra-body call
       renamed to match. Force-inlining reproduces the census inline shape at
       plain -O1 and collapses the closure to one straight-line body (recipe
       lesson, bd 20xt.2);
     - e_lgamma.c's `signgam` is openlibm's extern global (declared in
       openlibm_math.h); the slice supplies a file-scope `static int signgam;`
       instead, and drops the `#ifdef OPENLIBM_ONLY_THREAD_SAFE` local-signgam
       arm, which x86-64 does not take;
     - e_log.c's `u_int32_t lx` respelled `uint32_t lx` — the same 32-bit
       unsigned type; its only use is `((hx&0x7fffffff)|lx)==0`;
     - the math_private.h word macros expanded to the __builtin_memcpy 8-byte
       pun the exemplar uses, at ALL SIX macro sites, plus a local
       `uint64_t bits` scratch in each host function:
         olm_log       EXTRACT_WORDS(hx,lx,x), GET_HIGH_WORD(hx,x),
                       SET_HIGH_WORD(x, hx|(i^0x3ff00000))
         olm_sin_pi    GET_HIGH_WORD(ix,x), GET_LOW_WORD(n,z)
         olm_lgamma_r  EXTRACT_WORDS(hx,lx,x)
       Six macro sites but SEVEN __builtin_memcpy calls: SET_HIGH_WORD expands
       to a reload of x (load-bearing — the preceding GET_HIGH_WORD sits inside
       the conditional subnormal branch), a splice that keeps the low 32 bits
       and writes the high 32, and a store back. The conversion spellings are
       deliberately NOT uniform; each reproduces its own macro's conversion. A
       high word is `(int32_t)(bits >> 32)`. A low word is
       `(int32_t)(uint32_t)bits` where the corpus destination is int-typed
       (olm_sin_pi's `n`, olm_lgamma_r's `lx`) and `(uint32_t)bits` where the
       corpus destination is unsigned (olm_log's `lx`);
     - file-scope static const collisions uniquified across the four vendored
       tables. openlibm's own names are kept on the e_lgamma_r.c side (the cell
       under test) and on the byte-identical e_log.c side; the three real
       collisions move instead: k_sin.c `half` -> `ks_half`, k_cos.c `one` ->
       `kc_one`, and e_lgamma_r.c `zero` -> `lg_zero` (it collides with
       e_log.c's `zero`, which the byte-identical olm_log body reads). Each pair
       holds the identical value; only the spelling moved. Everything else is
       collision-free and keeps its openlibm name — note that k_sin.c's S1-S6 do
       NOT collide with e_lgamma_r.c's s0-s6 (C is case-sensitive) and that
       k_cos.c's C1-C6 collide with nothing here.
   The whole file-scope coefficient table was checked literal-by-literal, in
   order, against the corpus — a body-level diff does not cover it.

   Lowering exercised: a wide multi-band tainted value-region DAG. lgamma_r
   dispatches on the extracted words of the tainted x across the +-inf/NaN,
   +-0, |x|<2**-70, negative, ==1/==2, x<2.0 (SIX sub-bands — three under
   ix<=0x3feccccc and three under its else — feeding a 3-way coefficient
   switch on i), x<8.0 (an (int)x fptosi feeding a fallthrough switch that
   accumulates z), 8.0<=x<2**58, and x>=2**58 exits; sin_pi adds its own
   floor-based mod-2 reduction and a switch over n with cases 0-6 plus a
   default (five distinct arms); olm_log contributes its own 3-deep nest.
   One inlining-context fold, recorded so a later reader need not re-open it:
   lgamma_r returns before ever calling sin_pi when ix>=0x43300000, so inside
   sin_pi the test `ix>=0x43400000` is a dominated false and `ix<0x43300000` a
   dominated true — neither compare survives to the -O1 IR, and two52 appears
   there only as a double constant. That is a correct fold, not a dropped
   branch; every other band threshold is present, with the expected clang -O1
   `>=`->`>` canonicalization (Rule 9). PredMux
   (PredMuxFlatten.cpp) flattens all of it onto the edge-predicated select
   substrate — the lowered module carries cqrt_copy_f64_controlled and
   cqrt_copy_i32_controlled merges over cqrt_alloc_i1 flag rails, with
   cqrt_x/cqrt_cnot/cqrt_toffoli conjunctions and matching compare `_unc`
   strips. The Horner tables ride the arithmetic templates (at -O1 the default
   -ffp-contract=on fuses most of them into @llvm.fmuladd.f64, itself a Rule-18
   keep, which lowers to the cq_template_fma_f64 family); the fdivs, the
   fptosi/sitofp round trip on i, and the integer word twiddling on the
   bitcast-extracted words ride their own templates. The census bucket for this
   cell is COMPILES (spec-clone):
   under the census harness the inner __kernel_cos and log stay OUTLINED and
   lower as Phase-6 specialization clones. At the plain -O1 ship floor the
   always_inline convention instead collapses the whole closure to one
   straight-line body and no spec clone is minted. Both routes reach opt exit 0;
   this golden pins the ship-floor one (the same situation as the
   already-shipped slice_libm_real_sinhl.c).

   This slice is the LINK-layer proof (Rule 2) that every emitted symbol
   resolves and signature-matches and that the trace is stable and
   deterministic. q is theta-tainted, so no guard const-folds away. */
#include <stdint.h>

/* ---- openlibm src/e_log.c: __ieee754_log, vendored BYTE-IDENTICALLY
   (table + body) from the already-verified sibling slice_libm_real_log.c. */
static const double
ln2_hi  =  6.93147180369123816490e-01,  /* 3fe62e42 fee00000 */
ln2_lo  =  1.90821492927058770002e-10,  /* 3dea39ef 35793c76 */
two54   =  1.80143985094819840000e+16,  /* 43500000 00000000 */
Lg1 = 6.666666666666735130e-01,  /* 3FE55555 55555593 */
Lg2 = 3.999999999940941908e-01,  /* 3FD99999 9997FA04 */
Lg3 = 2.857142874366239149e-01,  /* 3FD24924 94229359 */
Lg4 = 2.222219843214978396e-01,  /* 3FCC71C5 1D8E78AF */
Lg5 = 1.818357216161805012e-01,  /* 3FC74664 96CB03DE */
Lg6 = 1.531383769920937332e-01,  /* 3FC39A09 D078C69F */
Lg7 = 1.479819860511658591e-01;  /* 3FC2F112 DF3E5244 */

static const double zero = 0.0;

__attribute__((always_inline)) static inline double olm_log(double x) {
    double hfsq, f, s, z, R, w, t1, t2, dk;
    int32_t k, hx, i, j;
    uint32_t lx;
    uint64_t bits;

    __builtin_memcpy(&bits, &x, 8);                      /* EXTRACT_WORDS */
    hx = (int32_t)(bits >> 32);
    lx = (uint32_t)bits;

    k = 0;
    if (hx < 0x00100000) {                               /* x < 2**-1022 */
        if (((hx & 0x7fffffff) | lx) == 0)
            return -two54 / zero;                        /* log(+-0)=-inf */
        if (hx < 0) return (x - x) / zero;               /* log(-#) = NaN */
        k -= 54; x *= two54;             /* subnormal number, scale up x */
        __builtin_memcpy(&bits, &x, 8);                  /* GET_HIGH_WORD */
        hx = (int32_t)(bits >> 32);
    }
    if (hx >= 0x7ff00000) return x + x;
    k += (hx >> 20) - 1023;
    hx &= 0x000fffff;
    i = (hx + 0x95f64) & 0x100000;
    __builtin_memcpy(&bits, &x, 8);                      /* SET_HIGH_WORD */
    bits = (bits & 0xffffffffULL) |
           ((uint64_t)(uint32_t)(hx | (i ^ 0x3ff00000)) << 32);
    __builtin_memcpy(&x, &bits, 8);                      /* normalize x or x/2 */
    k += (i >> 20);
    f = x - 1.0;
    if ((0x000fffff & (2 + hx)) < 3) {   /* -2**-20 <= f < 2**-20 */
        if (f == zero) {
            if (k == 0) {
                return zero;
            } else {
                dk = (double)k;
                return dk * ln2_hi + dk * ln2_lo;
            }
        }
        R = f * f * (0.5 - 0.33333333333333333 * f);
        if (k == 0) return f - R;
        else { dk = (double)k;
               return dk * ln2_hi - ((R - dk * ln2_lo) - f); }
    }
    s = f / (2.0 + f);
    dk = (double)k;
    z = s * s;
    i = hx - 0x6147a;
    w = z * z;
    j = 0x6b851 - hx;
    t1 = w * (Lg2 + w * (Lg4 + w * Lg6));
    t2 = z * (Lg1 + w * (Lg3 + w * (Lg5 + w * Lg7)));
    i |= j;
    R = t2 + t1;
    if (i > 0) {
        hfsq = 0.5 * f * f;
        if (k == 0) return f - (hfsq - s * (hfsq + R));
        else return dk * ln2_hi - ((hfsq - (s * (hfsq + R) + dk * ln2_lo)) - f);
    } else {
        if (k == 0) return f - s * (f - R);
        else return dk * ln2_hi - ((s * (f - R) - dk * ln2_lo) - f);
    }
}

/* ---- openlibm src/k_sin.c: __kernel_sin. `half` -> `ks_half`
   (collides with e_lgamma_r.c's `half`; same value). */
static const double
ks_half =  5.00000000000000000000e-01, /* 0x3FE00000, 0x00000000 */
S1  = -1.66666666666666324348e-01, /* 0xBFC55555, 0x55555549 */
S2  =  8.33333333332248946124e-03, /* 0x3F811111, 0x1110F8A6 */
S3  = -1.98412698298579493134e-04, /* 0xBF2A01A0, 0x19C161D5 */
S4  =  2.75573137070700676789e-06, /* 0x3EC71DE3, 0x57B1FE7D */
S5  = -2.50507602534068634195e-08, /* 0xBE5AE5E6, 0x8A2B9CEB */
S6  =  1.58969099521155010221e-10; /* 0x3DE5D93A, 0x5ACFD57C */

__attribute__((always_inline)) static inline double
olm_kernel_sin(double x, double y, int iy)
{
	double z,r,v,w;

	z	=  x*x;
	w	=  z*z;
	r	=  S2+z*(S3+z*S4) + z*w*(S5+z*S6);
	v	=  z*x;
	if(iy==0) return x+v*(S1+z*r);
	else      return x-((z*(ks_half*y-v*r)-y)-v*S1);
}

/* ---- openlibm src/k_cos.c: __kernel_cos. `one` -> `kc_one`
   (collides with e_lgamma_r.c's `one`; same value). */
static const double
kc_one =  1.00000000000000000000e+00, /* 0x3FF00000, 0x00000000 */
C1  =  4.16666666666666019037e-02, /* 0x3FA55555, 0x5555554C */
C2  = -1.38888888888741095749e-03, /* 0xBF56C16C, 0x16C15177 */
C3  =  2.48015872894767294178e-05, /* 0x3EFA01A0, 0x19CB1590 */
C4  = -2.75573143513906633035e-07, /* 0xBE927E4F, 0x809C52AD */
C5  =  2.08757232129817482790e-09, /* 0x3E21EE9E, 0xBDB4B1C4 */
C6  = -1.13596475577881948265e-11; /* 0xBDA8FAE9, 0xBE8838D4 */

__attribute__((always_inline)) static inline double
olm_kernel_cos(double x, double y)
{
	double hz,z,r,w;

	z  = x*x;
	w  = z*z;
	r  = z*(C1+z*(C2+z*C3)) + w*w*(C4+z*(C5+z*C6));
	hz = 0.5*z;
	w  = kc_one-hz;
	return w + (((kc_one-w)-hz) + (z*r-x*y));
}

/* ---- openlibm src/e_lgamma_r.c: the coefficient table, sin_pi and
   __ieee754_lgamma_r. `zero` -> `lg_zero` (collides with e_log.c's
   `zero`, which the byte-identical olm_log body above reads). */
static const double
two52=  4.50359962737049600000e+15, /* 0x43300000, 0x00000000 */
half=  5.00000000000000000000e-01, /* 0x3FE00000, 0x00000000 */
one =  1.00000000000000000000e+00, /* 0x3FF00000, 0x00000000 */
pi  =  3.14159265358979311600e+00, /* 0x400921FB, 0x54442D18 */
a0  =  7.72156649015328655494e-02, /* 0x3FB3C467, 0xE37DB0C8 */
a1  =  3.22467033424113591611e-01, /* 0x3FD4A34C, 0xC4A60FAD */
a2  =  6.73523010531292681824e-02, /* 0x3FB13E00, 0x1A5562A7 */
a3  =  2.05808084325167332806e-02, /* 0x3F951322, 0xAC92547B */
a4  =  7.38555086081402883957e-03, /* 0x3F7E404F, 0xB68FEFE8 */
a5  =  2.89051383673415629091e-03, /* 0x3F67ADD8, 0xCCB7926B */
a6  =  1.19270763183362067845e-03, /* 0x3F538A94, 0x116F3F5D */
a7  =  5.10069792153511336608e-04, /* 0x3F40B6C6, 0x89B99C00 */
a8  =  2.20862790713908385557e-04, /* 0x3F2CF2EC, 0xED10E54D */
a9  =  1.08011567247583939954e-04, /* 0x3F1C5088, 0x987DFB07 */
a10 =  2.52144565451257326939e-05, /* 0x3EFA7074, 0x428CFA52 */
a11 =  4.48640949618915160150e-05, /* 0x3F07858E, 0x90A45837 */
tc  =  1.46163214496836224576e+00, /* 0x3FF762D8, 0x6356BE3F */
tf  = -1.21486290535849611461e-01, /* 0xBFBF19B9, 0xBCC38A42 */
/* tt = -(tail of tf) */
tt  = -3.63867699703950536541e-18, /* 0xBC50C7CA, 0xA48A971F */
t0  =  4.83836122723810047042e-01, /* 0x3FDEF72B, 0xC8EE38A2 */
t1  = -1.47587722994593911752e-01, /* 0xBFC2E427, 0x8DC6C509 */
t2  =  6.46249402391333854778e-02, /* 0x3FB08B42, 0x94D5419B */
t3  = -3.27885410759859649565e-02, /* 0xBFA0C9A8, 0xDF35B713 */
t4  =  1.79706750811820387126e-02, /* 0x3F9266E7, 0x970AF9EC */
t5  = -1.03142241298341437450e-02, /* 0xBF851F9F, 0xBA91EC6A */
t6  =  6.10053870246291332635e-03, /* 0x3F78FCE0, 0xE370E344 */
t7  = -3.68452016781138256760e-03, /* 0xBF6E2EFF, 0xB3E914D7 */
t8  =  2.25964780900612472250e-03, /* 0x3F6282D3, 0x2E15C915 */
t9  = -1.40346469989232843813e-03, /* 0xBF56FE8E, 0xBF2D1AF1 */
t10 =  8.81081882437654011382e-04, /* 0x3F4CDF0C, 0xEF61A8E9 */
t11 = -5.38595305356740546715e-04, /* 0xBF41A610, 0x9C73E0EC */
t12 =  3.15632070903625950361e-04, /* 0x3F34AF6D, 0x6C0EBBF7 */
t13 = -3.12754168375120860518e-04, /* 0xBF347F24, 0xECC38C38 */
t14 =  3.35529192635519073543e-04, /* 0x3F35FD3E, 0xE8C2D3F4 */
u0  = -7.72156649015328655494e-02, /* 0xBFB3C467, 0xE37DB0C8 */
u1  =  6.32827064025093366517e-01, /* 0x3FE4401E, 0x8B005DFF */
u2  =  1.45492250137234768737e+00, /* 0x3FF7475C, 0xD119BD6F */
u3  =  9.77717527963372745603e-01, /* 0x3FEF4976, 0x44EA8450 */
u4  =  2.28963728064692451092e-01, /* 0x3FCD4EAE, 0xF6010924 */
u5  =  1.33810918536787660377e-02, /* 0x3F8B678B, 0xBF2BAB09 */
v1  =  2.45597793713041134822e+00, /* 0x4003A5D7, 0xC2BD619C */
v2  =  2.12848976379893395361e+00, /* 0x40010725, 0xA42B18F5 */
v3  =  7.69285150456672783825e-01, /* 0x3FE89DFB, 0xE45050AF */
v4  =  1.04222645593369134254e-01, /* 0x3FBAAE55, 0xD6537C88 */
v5  =  3.21709242282423911810e-03, /* 0x3F6A5ABB, 0x57D0CF61 */
s0  = -7.72156649015328655494e-02, /* 0xBFB3C467, 0xE37DB0C8 */
s1  =  2.14982415960608852501e-01, /* 0x3FCB848B, 0x36E20878 */
s2  =  3.25778796408930981787e-01, /* 0x3FD4D98F, 0x4F139F59 */
s3  =  1.46350472652464452805e-01, /* 0x3FC2BB9C, 0xBEE5F2F7 */
s4  =  2.66422703033638609560e-02, /* 0x3F9B481C, 0x7E939961 */
s5  =  1.84028451407337715652e-03, /* 0x3F5E26B6, 0x7368F239 */
s6  =  3.19475326584100867617e-05, /* 0x3F00BFEC, 0xDD17E945 */
r1  =  1.39200533467621045958e+00, /* 0x3FF645A7, 0x62C4AB74 */
r2  =  7.21935547567138069525e-01, /* 0x3FE71A18, 0x93D3DCDC */
r3  =  1.71933865632803078993e-01, /* 0x3FC601ED, 0xCCFBDF27 */
r4  =  1.86459191715652901344e-02, /* 0x3F9317EA, 0x742ED475 */
r5  =  7.77942496381893596434e-04, /* 0x3F497DDA, 0xCA41A95B */
r6  =  7.32668430744625636189e-06, /* 0x3EDEBAF7, 0xA5B38140 */
w0  =  4.18938533204672725052e-01, /* 0x3FDACFE3, 0x90C97D69 */
w1  =  8.33333333333329678849e-02, /* 0x3FB55555, 0x5555553B */
w2  = -2.77777777728775536470e-03, /* 0xBF66C16C, 0x16B02E5C */
w3  =  7.93650558643019558500e-04, /* 0x3F4A019F, 0x98CF38B6 */
w4  = -5.95187557450339963135e-04, /* 0xBF4380CB, 0x8C0FE741 */
w5  =  8.36339918996282139126e-04, /* 0x3F4B67BA, 0x4CDAD5D1 */
w6  = -1.63092934096575273989e-03; /* 0xBF5AB89D, 0x0B9E43E4 */

static const double lg_zero=  0.00000000000000000000e+00;

__attribute__((always_inline)) static inline double olm_sin_pi(double x)
{
	double y,z;
	int n,ix;
	uint64_t bits;

	__builtin_memcpy(&bits,&x,8);		/* GET_HIGH_WORD(ix,x) */
	ix = (int32_t)(bits>>32);
	ix &= 0x7fffffff;

	if(ix<0x3fd00000) return olm_kernel_sin(pi*x,lg_zero,0);
	y = -x;		/* x is assume negative */

    /*
     * argument reduction, make sure inexact flag not raised if input
     * is an integer
     */
	z = __builtin_floor(y);
	if(z!=y) {				/* inexact anyway */
	    y  *= 0.5;
	    y   = 2.0*(y - __builtin_floor(y));		/* y = |x| mod 2.0 */
	    n   = (int) (y*4.0);
	} else {
            if(ix>=0x43400000) {
                y = lg_zero; n = 0;                 /* y must be even */
            } else {
                if(ix<0x43300000) z = y+two52;	/* exact */
		__builtin_memcpy(&bits,&z,8);	/* GET_LOW_WORD(n,z) */
		n = (int32_t)(uint32_t)bits;
		n &= 1;
                y  = n;
                n<<= 2;
            }
        }
	switch (n) {
	    case 0:   y =  olm_kernel_sin(pi*y,lg_zero,0); break;
	    case 1:   
	    case 2:   y =  olm_kernel_cos(pi*(0.5-y),lg_zero); break;
	    case 3:  
	    case 4:   y =  olm_kernel_sin(pi*(one-y),lg_zero,0); break;
	    case 5:
	    case 6:   y = -olm_kernel_cos(pi*(y-1.5),lg_zero); break;
	    default:  y =  olm_kernel_sin(pi*(y-2.0),lg_zero,0); break;
	    }
	return -y;
}

__attribute__((always_inline)) static inline double
olm_lgamma_r(double x, int *signgamp)
{
	double t,y,z,nadj,p,p1,p2,p3,q,r,w;
	int32_t hx;
	int i,lx,ix;
	uint64_t bits;
	nadj = 0;	/* only set & used when hx<0; init silences -Wmaybe-uninitialized */

	__builtin_memcpy(&bits,&x,8);		/* EXTRACT_WORDS(hx,lx,x) */
	hx = (int32_t)(bits>>32);
	lx = (int32_t)(uint32_t)bits;

    /* purge off +-inf, NaN, +-0, tiny and negative arguments */
	*signgamp = 1;
	ix = hx&0x7fffffff;
	if(ix>=0x7ff00000) return x*x;
	if((ix|lx)==0) return one/lg_zero;
	if(ix<0x3b900000) {	/* |x|<2**-70, return -log(|x|) */
	    if(hx<0) {
	        *signgamp = -1;
	        return -olm_log(-x);
	    } else return -olm_log(x);
	}
	if(hx<0) {
	    if(ix>=0x43300000) 	/* |x|>=2**52, must be -integer */
		return one/lg_zero;
	    t = olm_sin_pi(x);
	    if(t==lg_zero) return one/lg_zero; /* -integer */
	    nadj = olm_log(pi/__builtin_fabs(t*x));
	    if(t<lg_zero) *signgamp = -1;
	    x = -x;
	}

    /* purge off 1 and 2 */
	if((((ix-0x3ff00000)|lx)==0)||(((ix-0x40000000)|lx)==0)) r = 0;
    /* for x < 2.0 */
	else if(ix<0x40000000) {
	    if(ix<=0x3feccccc) { 	/* lgamma(x) = lgamma(x+1)-log(x) */
		r = -olm_log(x);
		if(ix>=0x3FE76944) {y = one-x; i= 0;}
		else if(ix>=0x3FCDA661) {y= x-(tc-one); i=1;}
	  	else {y = x; i=2;}
	    } else {
	  	r = lg_zero;
	        if(ix>=0x3FFBB4C3) {y=2.0-x;i=0;} /* [1.7316,2] */
	        else if(ix>=0x3FF3B4C4) {y=x-tc;i=1;} /* [1.23,1.73] */
		else {y=x-one;i=2;}
	    }
	    switch(i) {
	      case 0:
		z = y*y;
		p1 = a0+z*(a2+z*(a4+z*(a6+z*(a8+z*a10))));
		p2 = z*(a1+z*(a3+z*(a5+z*(a7+z*(a9+z*a11)))));
		p  = y*p1+p2;
		r  += (p-0.5*y); break;
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
		r += (-0.5*y + p1/p2);
	    }
	}
	else if(ix<0x40200000) { 			/* x < 8.0 */
	    i = (int)x;
	    y = x-(double)i;
	    p = y*(s0+y*(s1+y*(s2+y*(s3+y*(s4+y*(s5+y*s6))))));
	    q = one+y*(r1+y*(r2+y*(r3+y*(r4+y*(r5+y*r6)))));
	    r = half*y+p/q;
	    z = one;	/* lgamma(1+s) = log(s) + lgamma(s) */
	    switch(i) {
	    case 7: z *= (y+6.0);	/* FALLTHRU */
	    case 6: z *= (y+5.0);	/* FALLTHRU */
	    case 5: z *= (y+4.0);	/* FALLTHRU */
	    case 4: z *= (y+3.0);	/* FALLTHRU */
	    case 3: z *= (y+2.0);	/* FALLTHRU */
		    r += olm_log(z); break;
	    }
    /* 8.0 <= x < 2**58 */
	} else if (ix < 0x43900000) {
	    t = olm_log(x);
	    z = one/x;
	    y = z*z;
	    w = w0+z*(w1+y*(w2+y*(w3+y*(w4+y*(w5+y*w6)))));
	    r = (x-half)*(t-one)+w;
	} else 
    /* 2**58 <= x <= inf */
	    r =  x*(olm_log(x)-one);
	if(hx<0) r = nadj - r;
	return r;
}

/* openlibm src/e_lgamma.c: the public entry forwards to the _r form with the
   global sign cell. `signgam` is file-scope here (openlibm declares it in
   openlibm_math.h); the OPENLIBM_ONLY_THREAD_SAFE variant of the same file
   makes it a local instead. */
static int signgam;

__attribute__((always_inline)) static inline double
olm_lgamma(double x)
{
	return olm_lgamma_r(x,&signgam);
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_lgamma(q));
}
int main(void) { (void) slice(); return 0; }
