/* slice_libm_real_erfl.c — bd 20xt.2 (real-openlibm VERIFIED promotion of the
   ld80 census cell erfl.f80, which COMPILES at the plain -O1 ship floor post the
   20xt.1 general funnel-shift 7.1 axis): the REAL openlibm erfl body
   (ld80/s_erfl.c) over its full transcendental closure — the pp/qq/pa/qa/ra/sa/
   rb/sb/rc/sc coefficient tables, the inner expl (ld80/e_expl.c, called TWICE in
   the asymptotic arm), and expl's own closure __isnanl (src/s_isnan.c) /
   __polevll (src/polevll.c) / ldexpl==scalbnl (src/s_scalbnl.c) / floorl+fabsl
   (hardware-backed keep-intrinsics) — over x86_fp80 `long double`.
   FreeBSD/OpenBSD/fdlibm-derived, BSD-licensed.

   This slice is the LINK-layer proof (Rule 2) that erfl's emitted symbols all
   resolve and the trace is stable+deterministic: the funnel-shift word extract
   `ix = (ix<<16)|(i0>>16)` → @llvm.fshl.i32 → cq_template_fshl_i32_qql (the
   20xt.1 payoff), the ieee_extended_shape_type GET/SET_LDOUBLE_WORDS fp80 union
   RMW (the SET_LDOUBLE_WORDS(z,...) low-word truncation is the multi-block
   3c6m.51 Shadow store), the fp80 data selects of the |x| range-band dispatch
   flattened by PredMux + carried by the kjd1 fp-select controlled-copy family,
   the const-index coefficient reads (all const-fold — NO QROM, unlike atanl/
   exp2l), and the two full expl inlines (each with its own floorl round /
   __polevll bounded-loop Horner / ldexpl exponent-pack union RMW). fabsl/floorl
   fold to @llvm.fabs.f80 / @llvm.floor.f80 (curated reversible keep-intrinsics,
   Rule 18); fmuladd rides @llvm.fmuladd.f80. The probe pins the census cell
   erfl.f80: x = theta-tainted. Data-closure/funnel history: bd memories
   ld80-census-data-closure, ld80-fshl-funnel-erfl-erfcl.

   Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
   changed): includes/license/OLM_* deleted; the vendored math_private closure
   inlined (the ieee_extended_shape_type LP64/little-endian union + GET/SET_
   LDOUBLE_WORDS verbatim from src/math_private_openbsd.h; union IEEEl2bits +
   LDBL_NBIT/mask_nbit_l verbatim from src/amd64_fpmath.h; u_int32_t typedef);
   every vendored function marked `__attribute__((always_inline)) static inline`
   with its public/`__`-prefixed entry renamed `olm_<name>` (the tanh/cosh/erf
   model convention — clang -O1 force-inlines the closure into one straight-line
   body, matching the census hand-verify); the libm keep-intrinsic calls
   fabsl/floorl written `__builtin_fabsl`/`__builtin_floorl` and INFINITY written
   `__builtin_infl()`; intra-body calls renamed to their olm_ vendored names
   (ldexpl→olm_scalbnl per openlibm_strong_reference(scalbnl,ldexpl); isnan→
   olm_isnanl; __polevll→olm_polevll); s_scalbnl.c's colliding file-scope
   `tiny`/`huge` uniquified `scb_tiny`/`scb_huge`. Both fp80 unions are kept
   VERBATIM — the promoteFp80Union pass owns them, never a memcpy word shim
   (3c6m.51 ld80 convention). */
#include <stdint.h>

typedef unsigned int u_int32_t;

/* src/math_private_openbsd.h — the LP64 little-endian ld80 word union +
   GET/SET_LDOUBLE_WORDS (verbatim; x86-64 is always little-endian). */
typedef union
{
  long double value;
  struct {
    u_int32_t lsw;
    u_int32_t msw;
    int exp:16;
    int padl:16;
    int padh:32;
  } parts;
} ieee_extended_shape_type;

#define GET_LDOUBLE_WORDS(se,ix0,ix1,d)				\
do {								\
  ieee_extended_shape_type ew_u;				\
  ew_u.value = (d);						\
  (se) = ew_u.parts.exp;					\
  (ix0) = ew_u.parts.msw;					\
  (ix1) = ew_u.parts.lsw;					\
} while (0)

#define SET_LDOUBLE_WORDS(d,se,ix0,ix1)				\
do {								\
  ieee_extended_shape_type iw_u;				\
  iw_u.parts.exp = (se);					\
  iw_u.parts.msw = (ix0);					\
  iw_u.parts.lsw = (ix1);					\
  (d) = iw_u.value;						\
} while (0)

/* src/amd64_fpmath.h — union IEEEl2bits + LDBL_NBIT + mask_nbit_l (verbatim —
   BOTH views; used by olm_isnanl and olm_scalbnl via .bits/.e). */
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
#define LDBL_NBIT       0x80000000
#define mask_nbit_l(u)  ((u).bits.manh &= ~LDBL_NBIT)

/* src/s_isnan.c __isnanl (verbatim). */
__attribute__((always_inline)) static inline int
olm_isnanl(long double e)
{
    union IEEEl2bits u;
    u.e = e;
    mask_nbit_l(u);
    return (u.bits.exp == 32767 && (u.bits.manl != 0 || u.bits.manh != 0));
}

/* src/polevll.c __polevll (verbatim). */
__attribute__((always_inline)) static inline long double
olm_polevll(long double x, void *PP, int n)
{
    long double y;
    long double *P;

    P = (long double *)PP;
    y = *P++;
    do {
        y = y * x + *P++;
    } while (--n);

    return (y);
}

/* src/s_copysignl.c copysignl (verbatim, ld80 IEEEl2bits) + src/s_copysign.c
   copysign (double; the GET/SET_HIGH_WORD f64 word macros expanded to the
   recipe-sanctioned __builtin_memcpy shim — bit-exact, the same body as the
   verified slice_libm_real_scalbn/scalbnl slices). Used only by olm_scalbnl's
   overflow/underflow arms. */
__attribute__((always_inline)) static inline long double
olm_copysignl(long double x, long double y) {
    union IEEEl2bits ux, uy;
    ux.e = x;
    uy.e = y;
    ux.bits.sign = uy.bits.sign;
    return (ux.e);
}
__attribute__((always_inline)) static inline double
olm_copysign(double x, double y) {
    uint64_t bx, by;
    __builtin_memcpy(&bx, &x, 8);
    __builtin_memcpy(&by, &y, 8);
    bx = (bx & 0x7fffffffffffffffULL) | (by & 0x8000000000000000ULL);
    __builtin_memcpy(&x, &bx, 8);
    return x;
}

/* src/s_scalbnl.c scalbnl (verbatim; colliding tiny/huge uniquified scb_*).
   openlibm_strong_reference(scalbnl, ldexpl): ldexpl IS this body. */
static const long double
scb_huge = 0x1p16000L,
scb_tiny = 0x1p-16000L;

__attribute__((always_inline)) static inline long double
olm_scalbnl(long double x, int n) {
    union IEEEl2bits u;
    int k;
    u.e = x;
    k = u.bits.exp;                             /* extract exponent */
    if (k==0) {                                 /* 0 or subnormal x */
        if ((u.bits.manh|u.bits.manl)==0) return x;   /* +-0 */
        u.e *= 0x1p+128;
        k = u.bits.exp - 128;
        if (n< -50000) return scb_tiny*x;       /*underflow*/
    }
    if (k==0x7fff) return x+x;                  /* NaN or Inf */
    k = k+n;
    if (k >= 0x7fff) return scb_huge*olm_copysignl(scb_huge,x); /* overflow  */
    if (k > 0)                                  /* normal result */
        {u.bits.exp = k; return u.e;}
    if (k <= -128) {
        if (n > 50000)                          /* in case integer overflow in n+k */
            return scb_huge*olm_copysign(scb_huge,x);   /*overflow*/
        else return scb_tiny*olm_copysign(scb_tiny,x);  /*underflow*/
    }
    k += 128;                                   /* subnormal result */
    u.bits.exp = k;
    return u.e*0x1p-128;
}

/* ld80/e_expl.c expl (verbatim; floorl→__builtin_floorl, ldexpl→olm_scalbnl,
   isnan→olm_isnanl, __polevll→olm_polevll, INFINITY→__builtin_infl()). */
static long double P[3] = {
 1.2617719307481059087798E-4L,
 3.0299440770744196129956E-2L,
 9.9999999999999999991025E-1L,
};
static long double Q[4] = {
 3.0019850513866445504159E-6L,
 2.5244834034968410419224E-3L,
 2.2726554820815502876593E-1L,
 2.0000000000000000000897E0L,
};
static const long double C1 = 6.9314575195312500000000E-1L;
static const long double C2 = 1.4286068203094172321215E-6L;
static const long double MAXLOGL = 1.1356523406294143949492E4L;
static const long double MINLOGL = -1.13994985314888605586758E4L;
static const long double LOG2EL = 1.4426950408889634073599E0L;

__attribute__((always_inline)) static inline long double
olm_expl(long double x)
{
long double px, xx;
int n;

if( olm_isnanl(x) )
	return(x);
if( x > MAXLOGL)
	return( __builtin_infl() );

if( x < MINLOGL )
	return(0.0L);

/* Express e**x = e**g 2**n
 *   = e**g e**( n loge(2) )
 *   = e**( g + n loge(2) )
 */
px = __builtin_floorl( LOG2EL * x + 0.5L ); /* floor() truncates toward -infinity. */
n = px;
x -= px * C1;
x -= px * C2;


/* rational approximation for exponential
 * of the fractional part:
 * e**x =  1 + 2x P(x**2)/( Q(x**2) - P(x**2) )
 */
xx = x * x;
px = x * olm_polevll( xx, P, 2 );
x =  px/( olm_polevll( xx, Q, 3 ) - px );
x = 1.0L + olm_scalbnl( x, 1 );

x = olm_scalbnl( x, n );
return(x);
}

/* ld80/s_erfl.c coefficient tables + constants (verbatim). */
static const long double
tiny = 1e-4931L,
  half = 0.5L,
  one = 1.0L,
  two = 2.0L,
  erx = 0.845062911510467529296875L,
  efx = 1.2837916709551257389615890312154517168810E-1L,
  efx8 = 1.0270333367641005911692712249723613735048E0L,

  pp[6] = {
    1.122751350964552113068262337278335028553E6L,
    -2.808533301997696164408397079650699163276E6L,
    -3.314325479115357458197119660818768924100E5L,
    -6.848684465326256109712135497895525446398E4L,
    -2.657817695110739185591505062971929859314E3L,
    -1.655310302737837556654146291646499062882E2L,
  },

  qq[6] = {
    8.745588372054466262548908189000448124232E6L,
    3.746038264792471129367533128637019611485E6L,
    7.066358783162407559861156173539693900031E5L,
    7.448928604824620999413120955705448117056E4L,
    4.511583986730994111992253980546131408924E3L,
    1.368902937933296323345610240009071254014E2L,
  },

  pa[8] = {
    -1.076952146179812072156734957705102256059E0L,
     1.884814957770385593365179835059971587220E2L,
    -5.339153975012804282890066622962070115606E1L,
     4.435910679869176625928504532109635632618E1L,
     1.683219516032328828278557309642929135179E1L,
    -2.360236618396952560064259585299045804293E0L,
     1.852230047861891953244413872297940938041E0L,
     9.394994446747752308256773044667843200719E-2L,
  },

  qa[7] =  {
    4.559263722294508998149925774781887811255E2L,
    3.289248982200800575749795055149780689738E2L,
    2.846070965875643009598627918383314457912E2L,
    1.398715859064535039433275722017479994465E2L,
    6.060190733759793706299079050985358190726E1L,
    2.078695677795422351040502569964299664233E1L,
    4.641271134150895940966798357442234498546E0L,
  },

    ra[] = {
      1.363566591833846324191000679620738857234E-1L,
      1.018203167219873573808450274314658434507E1L,
      1.862359362334248675526472871224778045594E2L,
      1.411622588180721285284945138667933330348E3L,
      5.088538459741511988784440103218342840478E3L,
      8.928251553922176506858267311750789273656E3L,
      7.264436000148052545243018622742770549982E3L,
      2.387492459664548651671894725748959751119E3L,
      2.220916652813908085449221282808458466556E2L,
    },

    sa[] = {
      -1.382234625202480685182526402169222331847E1L,
      -3.315638835627950255832519203687435946482E2L,
      -2.949124863912936259747237164260785326692E3L,
      -1.246622099070875940506391433635999693661E4L,
      -2.673079795851665428695842853070996219632E4L,
      -2.880269786660559337358397106518918220991E4L,
      -1.450600228493968044773354186390390823713E4L,
      -2.874539731125893533960680525192064277816E3L,
      -1.402241261419067750237395034116942296027E2L,
    },

    rb[] = {
      -4.869587348270494309550558460786501252369E-5L,
      -4.030199390527997378549161722412466959403E-3L,
      -9.434425866377037610206443566288917589122E-2L,
      -9.319032754357658601200655161585539404155E-1L,
      -4.273788174307459947350256581445442062291E0L,
      -8.842289940696150508373541814064198259278E0L,
      -7.069215249419887403187988144752613025255E0L,
      -1.401228723639514787920274427443330704764E0L,
    },

    sb[] = {
      4.936254964107175160157544545879293019085E-3L,
      1.583457624037795744377163924895349412015E-1L,
      1.850647991850328356622940552450636420484E0L,
      9.927611557279019463768050710008450625415E0L,
      2.531667257649436709617165336779212114570E1L,
      2.869752886406743386458304052862814690045E1L,
      1.182059497870819562441683560749192539345E1L,
    },

    rc[] = {
      -8.299617545269701963973537248996670806850E-5L,
      -6.243845685115818513578933902532056244108E-3L,
      -1.141667210620380223113693474478394397230E-1L,
      -7.521343797212024245375240432734425789409E-1L,
      -1.765321928311155824664963633786967602934E0L,
      -1.029403473103215800456761180695263439188E0L,
    },

    sc[] = {
      8.413244363014929493035952542677768808601E-3L,
      2.065114333816877479753334599639158060979E-1L,
      1.639064941530797583766364412782135680148E0L,
      4.936788463787115555582319302981666347450E0L,
      5.005177727208955487404729933261347679090E0L,
    };

/* ld80/s_erfl.c erfl (verbatim; fabsl→__builtin_fabsl, expl→olm_expl). */
__attribute__((always_inline)) static inline long double
olm_erfl(long double x)
{
  long double R, S, P, Q, s, y, z, r;
  int32_t ix, i;
  u_int32_t se, i0, i1;

  GET_LDOUBLE_WORDS (se, i0, i1, x);
  ix = se & 0x7fff;

  if (ix >= 0x7fff)
    {				/* erf(nan)=nan */
      i = ((se & 0xffff) >> 15) << 1;
      return (long double) (1 - i) + one / x;	/* erf(+-inf)=+-1 */
    }

  ix = (ix << 16) | (i0 >> 16);
  if (ix < 0x3ffed800) /* |x|<0.84375 */
    {
      if (ix < 0x3fde8000) /* |x|<2**-33 */
	{
	  if (ix < 0x00080000)
	    return 0.125 * (8.0 * x + efx8 * x);	/*avoid underflow */
	  return x + efx * x;
	}
      z = x * x;
      r = pp[0] + z * (pp[1]
	+ z * (pp[2] + z * (pp[3] + z * (pp[4] + z * pp[5]))));
      s = qq[0] + z * (qq[1]
	+ z * (qq[2] + z * (qq[3] + z * (qq[4] + z * (qq[5] + z)))));
      y = r / s;
      return x + x * y;
    }
  if (ix < 0x3fffa000) /* 1.25 */
    {				/* 0.84375 <= |x| < 1.25 */
      s = __builtin_fabsl (x) - one;
      P = pa[0] + s * (pa[1] + s * (pa[2]
	+ s * (pa[3] + s * (pa[4] + s * (pa[5] + s * (pa[6] + s * pa[7]))))));
      Q = qa[0] + s * (qa[1] + s * (qa[2]
	+ s * (qa[3] + s * (qa[4] + s * (qa[5] + s * (qa[6] + s))))));
      if ((se & 0x8000) == 0)
	return erx + P / Q;
      else
	return -erx - P / Q;
    }
  if (ix >= 0x4001d555) /* 6.6666259765625 */
    {				/* inf>|x|>=6.666 */
      if ((se & 0x8000) == 0)
	return one - tiny;
      else
	return tiny - one;
    }
  x = __builtin_fabsl (x);
  s = one / (x * x);
  if (ix < 0x4000b6db) /* 2.85711669921875 */
    {
      R = ra[0] + s * (ra[1] + s * (ra[2] + s * (ra[3] + s * (ra[4] +
	s * (ra[5] + s * (ra[6] + s * (ra[7] + s * ra[8])))))));
      S = sa[0] + s * (sa[1] + s * (sa[2] + s * (sa[3] + s * (sa[4] +
	s * (sa[5] + s * (sa[6] + s * (sa[7] + s * (sa[8] + s))))))));
    }
  else
    {				/* |x| >= 1/0.35 */
      R = rb[0] + s * (rb[1] + s * (rb[2] + s * (rb[3] + s * (rb[4] +
	s * (rb[5] + s * (rb[6] + s * rb[7]))))));
      S = sb[0] + s * (sb[1] + s * (sb[2] + s * (sb[3] + s * (sb[4] +
	s * (sb[5] + s * (sb[6] + s))))));
    }
  z = x;
  GET_LDOUBLE_WORDS (i, i0, i1, z);
  i1 = 0;
  SET_LDOUBLE_WORDS (z, i, i0, i1);
  r =
    olm_expl (-z * z - 0.5625) * olm_expl ((z - x) * (z + x) + R / S);
  if ((se & 0x8000) == 0)
    return one - r / x;
  else
    return r / x - one;
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_erfl(q));
}

int main(void) {
    (void) slice();
    return 0;
}
