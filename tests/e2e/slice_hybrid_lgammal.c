/* slice_hybrid_lgammal.c — bd 20xt.8 Inc 4: the ld80 (x86_fp80) HYBRID lgammal
   e2e slice that promotes the census cell lgammal.f80 from COMPILES (Inc 2
   re-probe) to VERIFIED (a committed, deterministic, links+runs e2e golden).

   *** HYBRID PROVENANCE — a DISJOINT scoreboard category (owner-approved
   2026-07-23). *** This slice is the REAL openlibm ld80 lgammal_r OUTER ladder
   (src ld80/e_lgammal_r.c: the sin_pi reflection helper + the argument-reduction
   / [1.5,2.5] rational / x≥8 asymptotic / negative-x reflection branches +
   every poly coefficient, VERBATIM) wrapped around THREE AUTHORED branchless
   leaves — bsinl / bcosl / blogl — that stand in for the inner sinl / cosl / logl
   calls. It is NOT a pure real-openlibm slice (that is what slice_libm_real_*.c
   denotes and what the census verified-scoreboard counts): the census cell
   lgammal.f80 STAYS DECLINED because the ld80 census injects the REAL openlibm
   sinl/cosl (whose Payne–Hanek __kernel_rem_pio2 reduction is quantum-indexed
   MUX-EXCH array writes, ROADMAP 7.5 post-freeze) and logl (a 23-block domain
   ladder), none of which lowers today. So there is NO census-number delta, and
   this golden is NEVER quoted alongside the real-openlibm atanl/atan2l/coshl
   goldens (the retired 165/174 overclaim discipline). Verification is
   e2e-golden-only: opt exits 0, the lowered module verifies clean with 0 qram,
   it links + runs, and the trace is byte-deterministic.

   *** WHY A HYBRID AT ALL — the Bennett-parity path. *** openlibm's ld80
   sinl/cosl reduce an arbitrary argument to [-π/4,π/4] with the full
   __kernel_rem_pio2 Payne–Hanek large-argument reduction (alloca [20 x i32] /
   [20 x double] working arrays with tainted DYNAMIC-INDEX stores inside bounded
   loops = Bennett's quantum-indexed memory-write strategy, deferred post-freeze),
   and ld80 logl is a data-dependent isnan/isinf/x≤0 / |e|≶2 branch ladder + a
   frexpl by-ref escape. Under the opaque cq_theta seed those branches are TAINTED
   control flow and do not lower as acyclic clones. Exactly as Bennett.jl ships
   its own register-only branchless SoftFloatLib in place of Payne–Hanek — and
   exactly as CQ's own f64 branchless corpus already does — this
   slice injects register-only, branchless f80 leaves: a 2-term Cody–Waite
   reduction + fdlibm ld80 minimax kernels for sin/cos, and e_logl.c's
   small-exponent path taken unconditionally for log. Each leaf is authored
   static + always_inline so clang -O1 INLINES it into the tainted seed — the
   top-level kjd1 fp-DATA select / register bit-surgery accept shapes lower it,
   whereas an UN-inlined leaf would be Phase-6 spec-CLONED and DECLINE
   ("callee contains tainted control flow", the inline-not-cloned lesson). The
   leaf bodies are TEXTUALLY IDENTICAL to their corpus twins
   tools/library_coverage/branchless/{sinl,cosl,logl}.c and their standalone
   e2e twins tests/e2e/slice_branchless_{sinl,cosl,logl}.c — keep the three in
   sync. Each is faithful (a few ulp, trace-only sanity — the runtime is
   trace-only) over the bounded reduction range; huge-argument accuracy is
   deliberately traded away (the Payne–Hanek path this omits).

   *** MECHANICAL EDITS ONLY to the real lgammal_r/sin_pi body (Rule 18 /
   libm-real-slice-recipe; NO constant / branch / expression changed). ***
     - includes / license / copyright deleted;
     - GET_LDOUBLE_WORDS resolved to the amd64 `union IEEEl2bits` word-read shim
       (the sanctioned ld80 word access — the promoteFp80Union pass owns the
       union; a memcpy shim is for f32/f64 words only, 3c6m.51). se=xbits.expsign
       (the 16-bit exp+sign), i0=bits.manh (msw), i1=bits.manl (lsw) — identical
       values to openlibm's own little-endian ieee_extended_shape_type
       {lsw; msw; exp:16;} that its GET_LDOUBLE_WORDS reads;
     - u_int32_t typedef provided;
     - the public entry lgammal_r → olm_lgammal_r, static sin_pi → olm_sin_pi;
     - the intra-body inner calls renamed to the vendored leaves:
       sinl→bsinl, cosl→bcosl, logl→blogl;
     - the keep-set intrinsics floorl→__builtin_floorl, fabsl→__builtin_fabsl
       (cq-lowering rewrites @llvm.{floor,fabs}.f80 to cq_template_*_f80 before
       codegen — pure-register, no libcall).
   The `union IEEEl2bits` is kept VERBATIM (both bits + xbits views, exactly as
   slice_libm_real_atan2l.c). The static const coefficient block, every threshold
   hex compare, the sin_pi switch, and the lgammal_r branch ladder are UNCHANGED.

   *** THE SEED MAKES EVERY BRANCH REACHABLE. *** cq_theta(&q,·) on q = 0.5L is an OPAQUE
   f80 the pass cannot constant-fold, so the sign/reflection branch (se & 0x8000),
   the |x|<2 / <8 / <2^66 magnitude ladder, and the sin_pi reduction switch are
   all TAINTED control flow — flattened at plain clang -O1 (PredMux) so sin_pi
   (→ bsinl/bcosl) AND the blogl calls are all genuinely exercised and lowered.
   signgam is a dead local (never read); clang -O1 DSE-eliminates the *signgamp
   stores before cq-lowering, so there is no tainted-store escape. */
#include <stdint.h>

typedef uint32_t u_int32_t;

/* openlibm src/amd64_fpmath.h (verbatim — both views; the fp80 pass owns the
   union, never a memcpy word shim). */
union IEEEl2bits {
    long double e;
    struct {
        unsigned int manl : 32;
        unsigned int manh : 32;
        unsigned int exp  : 15;
        unsigned int sign : 1;
        unsigned int junkl : 16;
        unsigned int junkh : 32;
    } bits;
    struct {
        unsigned long man     : 64;
        unsigned int  expsign : 16;
        unsigned long junk    : 48;
    } xbits;
};

/* openlibm GET_LDOUBLE_WORDS via IEEEl2bits (the sanctioned ld80 word read).
   se = 16-bit exp+sign, ix0 = high 32 mantissa (msw), ix1 = low 32 (lsw). */
#define GET_LDOUBLE_WORDS(se, ix0, ix1, d)                      \
do {                                                            \
  union IEEEl2bits ew_u;                                        \
  ew_u.e = (d);                                                 \
  (se)  = ew_u.xbits.expsign;                                   \
  (ix0) = ew_u.bits.manh;                                       \
  (ix1) = ew_u.bits.manl;                                       \
} while (0)

/* ===================================================================== */
/* AUTHORED branchless f80 leaves — textually identical to the corpus     */
/* twins tools/library_coverage/branchless/{sinl,cosl,logl}.c and the     */
/* standalone e2e twins slice_branchless_{sinl,cosl,logl}.c. always_inline */
/* so clang -O1 inlines them into the tainted seed (never spec-cloned).    */
/* ===================================================================== */

static inline __attribute__((always_inline)) long double bsinl(long double x) {
    const long double invpio2 = 6.36619772367581343076e-01L;
    const double      pio2_1  = 1.57079632679597125389e+00;
    const long double pio2_1t = -1.07463465549719416346e-12L;
    const long double PIO4    = 0.78539816339744830962L;
    const long double S1 = -0.166666666666666666671L;
    const double      S2 =  0.0083333333333333332,       S3 = -0.00019841269841269427,
                      S4 =  0.0000027557319223597490,    S5 = -0.000000025052108218074604,
                      S6 =  1.6059006598854211e-10,       S7 = -7.6429779983024564e-13,
                      S8 =  2.6174587166648325e-15;
    const long double C1 =  0.0416666666666666666136L;
    const double      C2 = -0.0013888888888888874,       C3 =  0.000024801587301571716,
                      C4 = -0.00000027557319215507120,   C5 =  0.0000000020876754400407278,
                      C6 = -1.1470297442401303e-11,       C7 =  4.7383039476436467e-14;

    long double fn = __builtin_rintl(x * invpio2);
    long double y  = (x - fn * pio2_1) - fn * pio2_1t;
    long double yc = __builtin_fmaxl(-PIO4, __builtin_fminl(y, PIO4));

    long double z  = yc * yc;
    long double rs = S2 + z*(S3 + z*(S4 + z*(S5 + z*(S6 + z*(S7 + z*S8)))));
    long double v  = z * yc;
    long double S  = yc + v*(S1 + z*rs);
    long double rc = z*(C1 + z*(C2 + z*(C3 + z*(C4 + z*(C5 + z*(C6 + z*C7))))));
    long double hz = 0.5L * z, wc = 1.0L - hz;
    long double C  = wc + (((1.0L - wc) - hz) + z * rc);

    long double qf   = fn - 4.0L * __builtin_floorl(fn * 0.25L);
    long double half = __builtin_floorl(qf * 0.5L);
    long double par  = qf - 2.0L * half;
    long double useS = (par  < 0.5L) ? 1.0L : 0.0L;
    long double sgn  = (half < 0.5L) ? 1.0L : -1.0L;
    long double mag  = useS * S + (1.0L - useS) * C;
    return sgn * mag;
}

static inline __attribute__((always_inline)) long double bcosl(long double x) {
    const long double invpio2 = 6.36619772367581343076e-01L;
    const double      pio2_1  = 1.57079632679597125389e+00;
    const long double pio2_1t = -1.07463465549719416346e-12L;
    const long double PIO4    = 0.78539816339744830962L;
    const long double S1 = -0.166666666666666666671L;
    const double      S2 =  0.0083333333333333332,       S3 = -0.00019841269841269427,
                      S4 =  0.0000027557319223597490,    S5 = -0.000000025052108218074604,
                      S6 =  1.6059006598854211e-10,       S7 = -7.6429779983024564e-13,
                      S8 =  2.6174587166648325e-15;
    const long double C1 =  0.0416666666666666666136L;
    const double      C2 = -0.0013888888888888874,       C3 =  0.000024801587301571716,
                      C4 = -0.00000027557319215507120,   C5 =  0.0000000020876754400407278,
                      C6 = -1.1470297442401303e-11,       C7 =  4.7383039476436467e-14;

    long double fn = __builtin_rintl(x * invpio2);
    long double y  = (x - fn * pio2_1) - fn * pio2_1t;
    long double yc = __builtin_fmaxl(-PIO4, __builtin_fminl(y, PIO4));

    long double z  = yc * yc;
    long double rs = S2 + z*(S3 + z*(S4 + z*(S5 + z*(S6 + z*(S7 + z*S8)))));
    long double v  = z * yc;
    long double S  = yc + v*(S1 + z*rs);
    long double rc = z*(C1 + z*(C2 + z*(C3 + z*(C4 + z*(C5 + z*(C6 + z*C7))))));
    long double hz = 0.5L * z, wc = 1.0L - hz;
    long double C  = wc + (((1.0L - wc) - hz) + z * rc);

    long double fq   = fn + 1.0L;
    long double qf   = fq - 4.0L * __builtin_floorl(fq * 0.25L);
    long double half = __builtin_floorl(qf * 0.5L);
    long double par  = qf - 2.0L * half;
    long double useS = (par  < 0.5L) ? 1.0L : 0.0L;
    long double sgn  = (half < 0.5L) ? 1.0L : -1.0L;
    long double mag  = useS * S + (1.0L - useS) * C;
    return sgn * mag;
}

static inline __attribute__((always_inline)) long double blogl(long double x) {
    const long double P0 = 4.5270000862445199635215E-5L;
    const long double P1 = 4.9854102823193375972212E-1L;
    const long double P2 = 6.5787325942061044846969E0L;
    const long double P3 = 2.9911919328553073277375E1L;
    const long double P4 = 6.0949667980987787057556E1L;
    const long double P5 = 5.7112963590585538103336E1L;
    const long double P6 = 2.0039553499201281259648E1L;
    const long double Q0 = 1.5062909083469192043167E1L;
    const long double Q1 = 8.3047565967967209469434E1L;
    const long double Q2 = 2.2176239823732856465394E2L;
    const long double Q3 = 3.0909872225312059774938E2L;
    const long double Q4 = 2.1642788614495947685003E2L;
    const long double Q5 = 6.0118660497603843919306E1L;
    const long double C1 = 6.9314575195312500000000E-1L;
    const long double C2 = 1.4286068203094172321215E-6L;
    const long double SQRTH = 0.70710678118654752440L;

    union { long double e; struct { unsigned int manl : 32; unsigned int manh : 32;
            unsigned int exp : 15; unsigned int sign : 1; unsigned int junkl : 16;
            unsigned int junkh : 32; } bits; } u;
    u.e = x;
    int e = (int)u.bits.exp - 16382;
    u.bits.exp = 16382;
    long double m = u.e;

    long double hi = (m < SQRTH) ? 1.0L : 0.0L;
    long double ef = (long double)e - hi;
    long double f  = hi * (2.0L * m - 1.0L) + (1.0L - hi) * (m - 1.0L);

    long double z  = f * f;
    long double Pf = ((((((P0 * f + P1) * f + P2) * f + P3) * f + P4) * f + P5) * f + P6);
    long double Qf = ((((((f + Q0) * f + Q1) * f + Q2) * f + Q3) * f + Q4) * f + Q5);
    long double y  = f * (z * Pf / Qf);
    y = y + ef * C2;
    long double r = y - 0.5L * z;
    r = r + f;
    r = r + ef * C1;
    return r;
}

/* ===================================================================== */
/* REAL openlibm ld80/e_lgammal_r.c outer ladder (verbatim; mechanical    */
/* renames per the header note). Static const coefficient block first.    */
/* ===================================================================== */


static const long double
  half = 0.5L,
  one = 1.0L,
  pi = 3.14159265358979323846264L,
  two63 = 9.223372036854775808e18L,

  /* lgam(1+x) = 0.5 x + x a(x)/b(x)
     -0.268402099609375 <= x <= 0
     peak relative error 6.6e-22 */
  a0 = -6.343246574721079391729402781192128239938E2L,
  a1 =  1.856560238672465796768677717168371401378E3L,
  a2 =  2.404733102163746263689288466865843408429E3L,
  a3 =  8.804188795790383497379532868917517596322E2L,
  a4 =  1.135361354097447729740103745999661157426E2L,
  a5 =  3.766956539107615557608581581190400021285E0L,

  b0 =  8.214973713960928795704317259806842490498E3L,
  b1 =  1.026343508841367384879065363925870888012E4L,
  b2 =  4.553337477045763320522762343132210919277E3L,
  b3 =  8.506975785032585797446253359230031874803E2L,
  b4 =  6.042447899703295436820744186992189445813E1L,
  /* b5 =  1.000000000000000000000000000000000000000E0 */


  tc =  1.4616321449683623412626595423257213284682E0L,
  tf = -1.2148629053584961146050602565082954242826E-1,/* double precision */
/* tt = (tail of tf), i.e. tf + tt has extended precision. */
  tt = 3.3649914684731379602768989080467587736363E-18L,
  /* lgam ( 1.4616321449683623412626595423257213284682E0 ) =
-1.2148629053584960809551455717769158215135617312999903886372437313313530E-1 */

  /* lgam (x + tc) = tf + tt + x g(x)/h(x)
     - 0.230003726999612341262659542325721328468 <= x
     <= 0.2699962730003876587373404576742786715318
     peak relative error 2.1e-21 */
  g0 = 3.645529916721223331888305293534095553827E-18L,
  g1 = 5.126654642791082497002594216163574795690E3L,
  g2 = 8.828603575854624811911631336122070070327E3L,
  g3 = 5.464186426932117031234820886525701595203E3L,
  g4 = 1.455427403530884193180776558102868592293E3L,
  g5 = 1.541735456969245924860307497029155838446E2L,
  g6 = 4.335498275274822298341872707453445815118E0L,

  h0 = 1.059584930106085509696730443974495979641E4L,
  h1 =  2.147921653490043010629481226937850618860E4L,
  h2 = 1.643014770044524804175197151958100656728E4L,
  h3 =  5.869021995186925517228323497501767586078E3L,
  h4 =  9.764244777714344488787381271643502742293E2L,
  h5 =  6.442485441570592541741092969581997002349E1L,
  /* h6 = 1.000000000000000000000000000000000000000E0 */


  /* lgam (x+1) = -0.5 x + x u(x)/v(x)
     -0.100006103515625 <= x <= 0.231639862060546875
     peak relative error 1.3e-21 */
  u0 = -8.886217500092090678492242071879342025627E1L,
  u1 =  6.840109978129177639438792958320783599310E2L,
  u2 =  2.042626104514127267855588786511809932433E3L,
  u3 =  1.911723903442667422201651063009856064275E3L,
  u4 =  7.447065275665887457628865263491667767695E2L,
  u5 =  1.132256494121790736268471016493103952637E2L,
  u6 =  4.484398885516614191003094714505960972894E0L,

  v0 =  1.150830924194461522996462401210374632929E3L,
  v1 =  3.399692260848747447377972081399737098610E3L,
  v2 =  3.786631705644460255229513563657226008015E3L,
  v3 =  1.966450123004478374557778781564114347876E3L,
  v4 =  4.741359068914069299837355438370682773122E2L,
  v5 =  4.508989649747184050907206782117647852364E1L,
  /* v6 =  1.000000000000000000000000000000000000000E0 */


  /* lgam (x+2) = .5 x + x s(x)/r(x)
     0 <= x <= 1
     peak relative error 7.2e-22 */
  s0 =  1.454726263410661942989109455292824853344E6L,
  s1 = -3.901428390086348447890408306153378922752E6L,
  s2 = -6.573568698209374121847873064292963089438E6L,
  s3 = -3.319055881485044417245964508099095984643E6L,
  s4 = -7.094891568758439227560184618114707107977E5L,
  s5 = -6.263426646464505837422314539808112478303E4L,
  s6 = -1.684926520999477529949915657519454051529E3L,

  r0 = -1.883978160734303518163008696712983134698E7L,
  r1 = -2.815206082812062064902202753264922306830E7L,
  r2 = -1.600245495251915899081846093343626358398E7L,
  r3 = -4.310526301881305003489257052083370058799E6L,
  r4 = -5.563807682263923279438235987186184968542E5L,
  r5 = -3.027734654434169996032905158145259713083E4L,
  r6 = -4.501995652861105629217250715790764371267E2L,
  /* r6 =  1.000000000000000000000000000000000000000E0 */


/* lgam(x) = ( x - 0.5 ) * log(x) - x + LS2PI + 1/x w(1/x^2)
   x >= 8
   Peak relative error 1.51e-21
   w0 = LS2PI - 0.5 */
  w0 =  4.189385332046727417803e-1L,
  w1 =  8.333333333333331447505E-2L,
  w2 = -2.777777777750349603440E-3L,
  w3 =  7.936507795855070755671E-4L,
  w4 = -5.952345851765688514613E-4L,
  w5 =  8.412723297322498080632E-4L,
  w6 = -1.880801938119376907179E-3L,
  w7 =  4.885026142432270781165E-3L;

static const long double zero = 0.0L;

static long double
olm_sin_pi(long double x)
{
  long double y, z;
  int n, ix;
  u_int32_t se, i0, i1;

  GET_LDOUBLE_WORDS (se, i0, i1, x);
  ix = se & 0x7fff;
  ix = (ix << 16) | (i0 >> 16);
  if (ix < 0x3ffd8000) /* 0.25 */
    return bsinl (pi * x);
  y = -x;			/* x is assume negative */

  /*
   * argument reduction, make sure inexact flag not raised if input
   * is an integer
   */
  z = __builtin_floorl (y);
  if (z != y)
    {				/* inexact anyway */
      y  *= 0.5;
      y = 2.0*(y - __builtin_floorl(y));		/* y = |x| mod 2.0 */
      n = (int) (y*4.0);
    }
  else
    {
      if (ix >= 0x403f8000)  /* 2^64 */
	{
	  y = zero; n = 0;		/* y must be even */
	}
      else
	{
	if (ix < 0x403e8000)  /* 2^63 */
	  z = y + two63;	/* exact */
	GET_LDOUBLE_WORDS (se, i0, i1, z);
	n = i1 & 1;
	y  = n;
	n <<= 2;
      }
    }

  switch (n)
    {
    case 0:
      y = bsinl (pi * y);
      break;
    case 1:
    case 2:
      y = bcosl (pi * (half - y));
      break;
    case 3:
    case 4:
      y = bsinl (pi * (one - y));
      break;
    case 5:
    case 6:
      y = -bcosl (pi * (y - 1.5));
      break;
    default:
      y = bsinl (pi * (y - 2.0));
      break;
    }
  return -y;
}


static long double
olm_lgammal_r(long double x, int *signgamp)
{
  long double t, y, z, nadj, p, p1, p2, q, r, w;
  int i, ix;
  u_int32_t se, i0, i1;
  nadj = 0;	/* only set & used when hx<0; init silences -Wmaybe-uninitialized */

  *signgamp = 1;
  GET_LDOUBLE_WORDS (se, i0, i1, x);
  ix = se & 0x7fff;

  if ((ix | i0 | i1) == 0)
    {
      if (se & 0x8000)
	*signgamp = -1;
      return one / __builtin_fabsl (x);
    }

  ix = (ix << 16) | (i0 >> 16);

  /* purge off +-inf, NaN, +-0, and negative arguments */
  if (ix >= 0x7fff0000)
    return x * x;

  if (ix < 0x3fc08000) /* 2^-63 */
    {				/* |x|<2**-63, return -log(|x|) */
      if (se & 0x8000)
	{
	  *signgamp = -1;
	  return -blogl (-x);
	}
      else
	return -blogl (x);
    }
  if (se & 0x8000)
    {
      t = olm_sin_pi (x);
      if (t == zero)
	return one / __builtin_fabsl (t);	/* -integer */
      nadj = blogl (pi / __builtin_fabsl (t * x));
      if (t < zero)
	*signgamp = -1;
      x = -x;
    }

  /* purge off 1 and 2 */
  if ((((ix - 0x3fff8000) | i0 | i1) == 0)
      || (((ix - 0x40008000) | i0 | i1) == 0))
    r = 0;
  else if (ix < 0x40008000) /* 2.0 */
    {
      /* x < 2.0 */
      if (ix <= 0x3ffee666) /* 8.99993896484375e-1 */
	{
	  /* lgamma(x) = lgamma(x+1) - log(x) */
	  r = -blogl (x);
	  if (ix >= 0x3ffebb4a) /* 7.31597900390625e-1 */
	    {
	      y = x - one;
	      i = 0;
	    }
	  else if (ix >= 0x3ffced33)/* 2.31639862060546875e-1 */
	    {
	      y = x - (tc - one);
	      i = 1;
	    }
	  else
	    {
	      /* x < 0.23 */
	      y = x;
	      i = 2;
	    }
	}
      else
	{
	  r = zero;
	  if (ix >= 0x3fffdda6) /* 1.73162841796875 */
	    {
	      /* [1.7316,2] */
	      y = x - 2.0;
	      i = 0;
	    }
	  else if (ix >= 0x3fff9da6)/* 1.23162841796875 */
	    {
	      /* [1.23,1.73] */
	      y = x - tc;
	      i = 1;
	    }
	  else
	    {
	      /* [0.9, 1.23] */
	      y = x - one;
	      i = 2;
	    }
	}
      switch (i)
	{
	case 0:
	  p1 = a0 + y * (a1 + y * (a2 + y * (a3 + y * (a4 + y * a5))));
	  p2 = b0 + y * (b1 + y * (b2 + y * (b3 + y * (b4 + y))));
	  r += half * y + y * p1/p2;
	  break;
	case 1:
    p1 = g0 + y * (g1 + y * (g2 + y * (g3 + y * (g4 + y * (g5 + y * g6)))));
    p2 = h0 + y * (h1 + y * (h2 + y * (h3 + y * (h4 + y * (h5 + y)))));
    p = tt + y * p1/p2;
	  r += (tf + p);
	  break;
	case 2:
 p1 = y * (u0 + y * (u1 + y * (u2 + y * (u3 + y * (u4 + y * (u5 + y * u6))))));
      p2 = v0 + y * (v1 + y * (v2 + y * (v3 + y * (v4 + y * (v5 + y)))));
	  r += (-half * y + p1 / p2);
	}
    }
  else if (ix < 0x40028000) /* 8.0 */
    {
      /* x < 8.0 */
      i = (int) x;
      t = zero;
      y = x - (double) i;
  p = y *
     (s0 + y * (s1 + y * (s2 + y * (s3 + y * (s4 + y * (s5 + y * s6))))));
  q = r0 + y * (r1 + y * (r2 + y * (r3 + y * (r4 + y * (r5 + y * (r6 + y))))));
      r = half * y + p / q;
      z = one;			/* lgamma(1+s) = log(s) + lgamma(s) */
      switch (i)
	{
	case 7:
	  z *= (y + 6.0);	/* FALLTHRU */
	case 6:
	  z *= (y + 5.0);	/* FALLTHRU */
	case 5:
	  z *= (y + 4.0);	/* FALLTHRU */
	case 4:
	  z *= (y + 3.0);	/* FALLTHRU */
	case 3:
	  z *= (y + 2.0);	/* FALLTHRU */
	  r += blogl (z);
	  break;
	}
    }
  else if (ix < 0x40418000) /* 2^66 */
    {
      /* 8.0 <= x < 2**66 */
      t = blogl (x);
      z = one / x;
      y = z * z;
      w = w0 + z * (w1
	  + y * (w2 + y * (w3 + y * (w4 + y * (w5 + y * (w6 + y * w7))))));
      r = (x - half) * (t - one) + w;
    }
  else
    /* 2**66 <= x <= inf */
    r = x * (blogl (x) - one);
  if (se & 0x8000)
    r = nadj - r;
  return r;
}

long double slice(void) {
    int signgam;                       /* dead local: DSE-eliminated pre-lowering */
    long double q = 0.5L; cq_theta(&q, 0.5);
    return cq_measure(olm_lgammal_r(q, &signgam));
}

int main(void) {
    (void) slice();
    return 0;
}
