/* Differential test of checker/rt/tmpl_f80.c (cq-w0-tmpl-f80).
 *
 * For every case of cases.inc (generated with native.ll by gen_native.py) and every form
 * (plain, _exc, _rm x4, _rm_exc x4, _rmq x4, _rmq_exc x4), every sample is evaluated by the
 * family's registered cqe_op_fn and by the native code (the same LLVM IR operation, clang-19 -O1,
 * corpus CPU penryn): the plain function at the default mode, the strictfp function under
 * fesetround(mode) with fetestexcept around it. The two must agree bit for bit (80-bit patterns,
 * NaN payloads included; the low W2 bits of an integer; the exception bits).
 *
 * Where a CONSTRUCTION_RULES §2 row fixes a result the native code does not give, the sample is
 * checked against the table instead, computed here by code written independently of tmpl_f80.c.
 * Each such row is named and counted in the report ("table" column), and the number of those
 * samples where native also differs is shown, so every deviation from native is visible:
 *   T-noncanon   pseudo-NaN/pseudo-Inf/unnormal operand: real indefinite + INVALID (fp result);
 *                compares and conversions read the real indefinite with INVALID
 *   T-u8         fptoui f80 -> i8 = trunc(fist16) (CQ_spec 2f894fd), flags of fist16
 *   T-fmax       fmax/fmin value: isnan(a) ? b : isnan(b) ? a : (b > a ? b : a), equal gives a;
 *                exception bits INVALID iff an operand is a signaling NaN (or non-canonical,
 *                T-noncanon), else none (cq-qx1 ruling, IEEE maxNum, over libm's choice)
 *   T-fpclass    is_fpclass: pseudo-denormal is subnormal; non-canonical is the real indefinite
 *   T-itofp      sitofp/uitofp above 64 bits: correctly rounded in the template's mode, INEXACT
 *   T-narrow     fptrunc f80 -> f16 in a directed mode and its exception bits; f80 -> bf16 in
 *                every form (LLVM 19 cannot lower fptrunc x86_fp80 to bfloat: no native code)
 *   T-nan        NaN result of fp arithmetic: the first NaN operand quieted, else the real
 *                indefinite; INVALID for a signaling NaN operand
 *   T-fix        fptosi/fptoui above 64 bits: exception bits of an x87 conversion
 * Also checked: a template with no f80 operand returns CQE_OP_NOT_MINE and leaves out untouched;
 * a malformed call returns -1 and reports cqe_fail; the corpus symbols listed in CORPUS parse
 * into the forms tested here.
 */
#pragma STDC FENV_ACCESS ON

#include <fenv.h>
#include <math.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

#ifndef CQE_OP_NOT_MINE
#define CQE_OP_NOT_MINE 1
#endif

/* ------------------------------------------------------------------ the core shim */

static cqe_op_fn g_fn;
static int g_nreg, g_fails;
static char g_ops[64][24];

void cqe_register_op(const char *op, cqe_op_fn fn) {
  if (g_fn && g_fn != fn) {
    fprintf(stderr, "harness: two different handlers\n");
    exit(2);
  }
  g_fn = fn;
  snprintf(g_ops[g_nreg++], 24, "%s", op);
}
void cqe_fail(const char *fmt, ...) {
  (void)fmt;
  ++g_fails;
}
int cqe_parse_template(const char *s, cqe_tname *o) { (void)s; (void)o; abort(); }
int32_t cqe_new_rail(const char *w, const cqe_val *i, int k) { (void)w; (void)i; (void)k; abort(); }
const cqe_val *cqe_rail(int32_t h) { (void)h; abort(); }
void cqe_xor_into(int32_t h, const cqe_val *v) { (void)h; (void)v; abort(); }
void cqe_set_known(int32_t h, int k) { (void)h; (void)k; abort(); }
void cqe_log(const char *j) { (void)j; abort(); }

/* ------------------------------------------------------------------ cases */

typedef enum { K_BIN, K_UN, K_FMA, K_SIGN, K_MINMAX, K_CMP, K_CLASS, K_FPEXT, K_FPTRUNC, K_ITOFP, K_FPTOI } kind_t;
typedef void (*nfn)(void *, const void *, const void *, const void *);

#define CASE(i, k, op, pr, w, to, n, x) void nv_##i(void *, const void *, const void *, const void *); \
  void ns_##i(void *, const void *, const void *, const void *);
#include "cases.inc"
#undef CASE

static const struct tcase {
  kind_t k;
  const char *op, *pred, *w, *to;
  int nargs;
  unsigned extra;
  nfn nv, ns;
} CASES[] = {
#define CASE(i, k, op, pr, w, to, n, x) {k, op, pr, w, to, n, x, nv_##i, ns_##i},
#include "cases.inc"
#undef CASE
};
#define NCASES (sizeof CASES / sizeof CASES[0])

/* ------------------------------------------------------------------ values */

typedef struct {
  uint64_t w[4]; /* little-endian; enough for i200 */
} val;

static uint64_t rng = 0x9E3779B97F4A7C15ull; /* seeded: the run is reproducible */
static uint64_t rnd(void) {
  rng ^= rng << 13;
  rng ^= rng >> 7;
  rng ^= rng << 17;
  return rng;
}

static val f80v(uint16_t se, uint64_t m) {
  val v = {{m, se, 0, 0}};
  return v;
}
static long double ldv(val v) {
  long double x;
  memset(&x, 0, sizeof x);
  memcpy(&x, v.w, 10);
  return x;
}
static val vld(long double x) {
  val v = {{0, 0, 0, 0}};
  memcpy(v.w, &x, 10);
  v.w[1] &= 0xFFFF;
  return v;
}
static int noncanon(val v) { return (v.w[1] & 0x7FFF) != 0 && !(v.w[0] >> 63); }
static int is_nan80(val v) { return noncanon(v) || ((v.w[1] & 0x7FFF) == 0x7FFF && (v.w[0] << 1)); }
static const uint64_t INDEF_M = 0xC000000000000000ull;

static val mask_to(val v, unsigned bits) {
  for (unsigned i = 0; i < 4; ++i) {
    unsigned lo = 64 * i;
    if (lo >= bits)
      v.w[i] = 0;
    else if (bits - lo < 64)
      v.w[i] &= (1ull << (bits - lo)) - 1;
  }
  return v;
}

static unsigned width_bits(const char *w) { return (unsigned)atoi(w + (w[0] == 'b' ? 2 : 1)); }

/* f80 operand samples */
static val F80S[512];
static int nf80;
static void addf(uint16_t se, uint64_t m) { F80S[nf80++] = f80v(se, m); }
static void addld(long double x) {
  F80S[nf80++] = vld(x);
  F80S[nf80++] = vld(-x);
}

static void build_f80_samples(void) {
  const uint64_t J = 1ull << 63;
  addld(0.0L); addld(1.0L); addld(0.5L); addld(1.5L); addld(2.5L); addld(3.5L); addld(0.25L);
  addld(1.0L / 3.0L); addld(3.14159265358979323846264338327950288L); addld(0.1L);
  addld(127.9L); addld(128.0L); addld(255.0L); addld(255.5L); addld(256.0L); addld(129.0L);
  addld(32767.5L); addld(32768.0L); addld(32769.0L); addld(65535.5L); addld(65536.0L);
  addld(2147483647.0L); addld(2147483648.0L); addld(2147483648.5L); addld(4294967295.0L); addld(4294967296.0L);
  addld(9223372036854775807.0L); addld(9223372036854775808.0L); addld(18446744073709551615.0L);
  addld(18446744073709551616.0L); addld(ldexpl(1, 79)); addld(ldexpl(1, 99)); addld(ldexpl(1, 100));
  addld(ldexpl(1, 127)); addld(ldexpl(1.5L, 127)); addld(ldexpl(1, 128)); addld(ldexpl(1, 199));
  addld(ldexpl(1, 200)); addld(ldexpl(1, 100) + ldexpl(1, 37)); addld(ldexpl(0xFFFFFFFFFFFFFFFFull, 40));
  addld(65504.0L); addld(65520.0L); addld(65519.99L); addld(ldexpl(1, -14)); addld(ldexpl(1, -24));
  addld(ldexpl(1, -25)); addld(ldexpl(3, -26)); addld(ldexpl(1, -26)); addld(ldexpl(1023, -24) + ldexpl(1, -35));
  addld(3.4028234663852886e38L); addld(3.4028235677973366e38L); addld(ldexpl(1, -149)); addld(ldexpl(1, -150));
  /* just below the smallest normal of f16 / bf16: tiny before rounding, not after (tininess
   * after rounding, CR §1.2 _exc) in some modes */
  addld(ldexpl(1, -14) * (1 - ldexpl(1, -12))); addld(ldexpl(1, -14) * (1 - ldexpl(1, -13)));
  addld(ldexpl(1, -14) * (1 - ldexpl(1, -11)));
  addld(ldexpl(1, -126) * (1 - ldexpl(1, -9))); addld(ldexpl(1, -126) * (1 - ldexpl(1, -10)));
  addld(1.7976931348623157e308L); addld(ldexpl(1, 1024)); addld(ldexpl(1, -1074)); addld(ldexpl(1, -1075));
  addld(ldexpl(1, -1022) * 0.75L); addld(1e4000L); addld(1e-4000L);
  for (int s = 0; s < 2; ++s) {
    uint16_t S = s ? 0x8000 : 0;
    addf(S | 0, 1);                        /* min subnormal */
    addf(S | 0, J - 1);                    /* max subnormal */
    addf(S | 1, J);                        /* min normal */
    addf(S | 0x7FFE, ~0ull);               /* max finite */
    addf(S | 0x7FFF, J);                   /* Inf */
    addf(S | 0x7FFF, INDEF_M);             /* qNaN (real indefinite when negative) */
    addf(S | 0x7FFF, INDEF_M | 1);         /* qNaN payload */
    addf(S | 0x7FFF, 0xE000000000000123ull);
    addf(S | 0x7FFF, ~0ull);
    addf(S | 0x7FFF, J | 1);               /* sNaN */
    addf(S | 0x7FFF, 0xA000000000000000ull);
    addf(S | 0x7FFF, 0x4000000000000000ull); /* pseudo-NaN (quiet pattern) */
    addf(S | 0x7FFF, 0x0000000000000001ull); /* pseudo-NaN */
    addf(S | 0x7FFF, 0);                     /* pseudo-Inf */
    addf(S | 0x3FFF, 0x4000000000000000ull); /* unnormal */
    addf(S | 0x0001, 0);                     /* unnormal, zero significand */
    addf(S | 0x403E, 0x7FFFFFFFFFFFFFFFull); /* unnormal near 2^63 */
    addf(S | 0, J);                          /* pseudo-denormal */
    addf(S | 0, J | 12345);
  }
}

static val rand_f80(void) {
  uint64_t r = rnd() % 4;
  if (r == 0) return f80v((uint16_t)rnd(), rnd()); /* any pattern */
  uint16_t s = (rnd() & 1) ? 0x8000 : 0;
  if (r == 1) return f80v(s | (uint16_t)(16383 - 70 + rnd() % 140), rnd() | (1ull << 63));
  if (r == 2) return f80v(s | (uint16_t)(16383 - 3 + rnd() % 140), rnd() | (1ull << 63));
  long double x = (long double)(int64_t)(rnd() % 100000 - 50000) / (long double)(1 + rnd() % 8);
  return vld(x);
}

static int nsrc_samples(unsigned bits, val *out, int max);

/* ------------------------------------------------------------------ table references */

static int fe_bits(int r) {
  int x = 0;
  if (r & FE_INVALID) x |= 1;
  if (r & FE_DIVBYZERO) x |= 4;
  if (r & FE_OVERFLOW) x |= 8;
  if (r & FE_UNDERFLOW) x |= 16;
  if (r & FE_INEXACT) x |= 32;
  return x;
}
static const int RC[4] = {FE_TONEAREST, FE_DOWNWARD, FE_UPWARD, FE_TOWARDZERO};

/* x87-style conversion flags to a C-bit integer: INVALID for NaN/Inf/out of range, else
 * INEXACT for a fraction (written with long double arithmetic). */
static int ref_conv_flags(val v, unsigned C, int sgn) {
  if (is_nan80(v)) return 1;
  long double x = ldv(v);
  if (isinf(x)) return 1;
  long double t = truncl(x);
  long double lo = sgn ? -ldexpl(1, (int)C - 1) : 0.0L;
  long double hi = sgn ? ldexpl(1, (int)C - 1) : ldexpl(1, (int)C); /* exclusive */
  if (C >= 16384) hi = INFINITY;
  if (t < lo || t >= hi) return (sgn || t != 0) ? 1 : (t == x ? 0 : 32);
  return t == x ? 0 : 32;
}

/* trunc(fist16) */
static uint16_t ref_fist16(val v, int *fl) {
  *fl = ref_conv_flags(v, 16, 1);
  if (*fl & 1) return 0x8000u;
  return (uint16_t)(int16_t)truncl(ldv(v));
}

/* Round a nonnegative integer magnitude (words, up to 256 bits) to f80 per rc and sign. */
static val ref_int_to_f80(const uint64_t *M, int neg, int rc, int *fl) {
  int top = -1;
  for (int i = 255; i >= 0; --i)
    if ((M[i / 64] >> (i % 64)) & 1) { top = i; break; }
  *fl = 0;
  if (top < 0) return f80v(0, 0);
  uint64_t q = 0;
  int rest_half = 0, rest_low = 0;
  for (int i = 0; i < 64; ++i) {
    int b = top - i;
    q = (q << 1) | (b >= 0 ? ((M[b / 64] >> (b % 64)) & 1) : 0);
  }
  int g = top - 64;
  if (g >= 0) {
    rest_half = (M[g / 64] >> (g % 64)) & 1;
    for (int i = 0; i < g; ++i) rest_low |= (int)((M[i / 64] >> (i % 64)) & 1);
  }
  int exp = top; /* value of bit 63 of q */
  int inexact = rest_half || rest_low, up = 0;
  if (rc == FE_TONEAREST) up = rest_half && (rest_low || (q & 1));
  else if (rc == FE_UPWARD) up = !neg && inexact;
  else if (rc == FE_DOWNWARD) up = neg && inexact;
  if (up) {
    q++;
    if (q == 0) { q = 1ull << 63; exp++; }
  }
  if (inexact) *fl = 32;
  return f80v((uint16_t)((neg ? 0x8000 : 0) | (exp + 16383)), q);
}

/* f80 -> f16/bf16 by enumeration of the 65536 patterns (each finite one exactly representable in
 * f80). fb = stored fraction bits (10 or 7), eb = exponent bits (5 or 8). */
static long double narrow_ld(uint16_t h, int fb, int eb) {
  int emax = (1 << eb) - 1, bias = (1 << (eb - 1)) - 1;
  int e = (h >> fb) & emax, m = h & ((1 << fb) - 1);
  long double v = e == 0 ? ldexpl(m, 1 - bias - fb) : e == emax ? (m ? NAN : INFINITY) : ldexpl((1 << fb) + m, e - bias - fb);
  return (h >> 15) ? -v : v;
}
static uint16_t ref_narrow(val v, int fb, int eb, int rc, int *fl) {
  long double x = ldv(v);
  uint16_t inf = (uint16_t)(((1 << eb) - 1) << fb), maxf = (uint16_t)(inf - 1);
  int neg = (v.w[1] >> 15) & 1;
  *fl = 0;
  if (is_nan80(v)) { /* quiet, sign kept, payload = the fraction bits below the quiet bit */
    if (noncanon(v)) { *fl = 1; return (uint16_t)(0x8000 | inf | (1 << (fb - 1))); }
    if (!((v.w[0] >> 62) & 1)) *fl = 1;
    uint16_t pay = (uint16_t)((v.w[0] >> (62 - (fb - 1))) & ((1u << (fb - 1)) - 1));
    return (uint16_t)((neg ? 0x8000 : 0) | inf | (1 << (fb - 1)) | pay);
  }
  long double a = fabsl(x);
  if (isinf(a)) return (uint16_t)((neg ? 0x8000 : 0) | inf);
  /* largest finite pattern lo with value <= a (positive patterns are ordered by value) */
  unsigned l = 0, h = inf; /* narrow_ld(l) <= a < narrow_ld(h) (h may be inf) */
  while (h - l > 1) {
    unsigned mid = (l + h) / 2;
    if (narrow_ld((uint16_t)mid, fb, eb) <= a) l = mid; else h = mid;
  }
  uint16_t lo = (uint16_t)l;
  if (narrow_ld(lo, fb, eb) == a) return (uint16_t)(lo | (neg ? 0x8000 : 0));
  uint16_t hi = (uint16_t)(lo + 1); /* = inf when lo is the largest finite */
  long double hiv = lo == maxf ? ldexpl(1, (1 << (eb - 1))) : narrow_ld(hi, fb, eb); /* 2^(emax+1) */
  int up;
  if (rc == FE_TOWARDZERO) up = 0;
  else if (rc == FE_UPWARD) up = !neg;
  else if (rc == FE_DOWNWARD) up = neg;
  else {
    long double mid = (narrow_ld(lo, fb, eb) + hiv) / 2; /* exact in f80 */
    up = a > mid || (a == mid && (hi & 1) == 0);
  }
  uint16_t r = up ? hi : lo;
  *fl = 32;
  /* overflow: the result rounded with an unbounded exponent is >= 2^(emax+1) */
  if (r == inf || (lo == maxf && a >= hiv)) *fl |= 8;
  /* tininess after rounding: a rounded to fb+1 bits with unbounded exponent < 2^emin */
  int emin = 2 - (1 << (eb - 1));
  if (a < ldexpl(1, emin)) {
    int e;
    frexpl(a, &e);
    long double sc = ldexpl(a, fb + 1 - e), ri;
    fesetround(rc == FE_UPWARD && neg ? FE_DOWNWARD : rc == FE_DOWNWARD && neg ? FE_UPWARD : rc);
    ri = rintl(sc);
    fesetround(FE_TONEAREST);
    if (ldexpl(ri, e - fb - 1) < ldexpl(1, emin)) *fl |= 16;
  }
  return (uint16_t)(r | (neg ? 0x8000 : 0));
}

/* fptosi/fptoui above 128 bits, LLVM 19 ExpandLargeFpConvert (the same code for both, through an
 * exact fp128): |x| < 1 -> 0; unbiased exponent >= N -> signed N-bit extreme by the sign bit (NaN,
 * Inf included); else +-floor(|x|) mod 2^N. Computed with long double: floor(|x|) < 2^N. */
static val ref_fix_large(val v, unsigned N) {
  val r = {{0, 0, 0, 0}};
  int neg = (v.w[1] >> 15) & 1;
  int e = (int)(v.w[1] & 0x7FFF) - 16383;
  if ((v.w[1] & 0x7FFF) == 0 || e < 0) return r;
  if (e >= (int)N) {
    if (neg) {
      r.w[(N - 1) / 64] = 1ull << ((N - 1) % 64);
    } else {
      val m = {{~0ull, ~0ull, ~0ull, ~0ull}};
      r = mask_to(m, N - 1);
    }
    return r;
  }
  long double t = truncl(fabsl(ldv(v)));
  for (int i = 3; i >= 0; --i) { /* peel 64-bit digits, exact */
    long double d = ldexpl(1, 64 * i);
    long double q = truncl(t / d);
    r.w[i] = (uint64_t)q;
    t -= q * d;
  }
  if (neg) {
    unsigned carry = 1;
    for (int i = 0; i < 4; ++i) { uint64_t x = ~r.w[i] + carry; carry = carry && x == 0; r.w[i] = x; }
  }
  return mask_to(r, N);
}

static int ref_class(val v, unsigned mask) {
  unsigned e = v.w[1] & 0x7FFF, neg = (v.w[1] >> 15) & 1;
  uint64_t m = v.w[0];
  int c;
  if (noncanon(v)) c = 1;
  else if (e == 0x7FFF) c = (m << 1) == 0 ? (neg ? 2 : 9) : ((m >> 62) & 1) ? 1 : 0;
  else if (e == 0) c = m == 0 ? (neg ? 5 : 6) : (neg ? 4 : 7);
  else c = neg ? 3 : 8;
  return (mask >> c) & 1;
}

/* ------------------------------------------------------------------ running one sample */

typedef struct {
  val v;
  int exc;
} res_t;

static void run_native(const struct tcase *c, int strict, int rc, const val *a, res_t *r) {
  uint64_t o[8] = {0};
  uint64_t in[3][8];
  memset(in, 0, sizeof in);
  for (int i = 0; i < c->nargs && i < 3; ++i) memcpy(in[i], a[i].w, sizeof a[i].w);
  fenv_t env;
  fegetenv(&env);
  fesetround(rc);
  feclearexcept(FE_ALL_EXCEPT);
  (strict ? c->ns : c->nv)(o, in[0], in[1], in[2]);
  int fl = fetestexcept(FE_ALL_EXCEPT);
  fesetenv(&env);
  memcpy(r->v.w, o, sizeof r->v.w);
  r->exc = fe_bits(fl);
}

static unsigned result_bits(const struct tcase *c) {
  if (c->k == K_CMP || c->k == K_CLASS) return 1;
  if (c->to[0]) return width_bits(c->to);
  return 80;
}

/* the form being tested */
typedef struct {
  int rm;   /* 0 none, 1 _rm, 2 _rmq */
  int mode; /* 0..3 */
  int exc;
} form_t;

static int ours(const struct tcase *c, form_t f, const val *a, res_t *r) {
  cqe_tname t;
  memset(&t, 0, sizeof t);
  snprintf(t.op, sizeof t.op, "%s", c->op);
  snprintf(t.pred, sizeof t.pred, "%s", c->pred);
  snprintf(t.w, sizeof t.w, "%s", c->w);
  snprintf(t.to, sizeof t.to, "%s", c->to);
  t.rm = (uint8_t)f.rm;
  t.exc = (uint8_t)f.exc;
  cqe_val args[4];
  uint64_t aw[4][4], ow[4] = {0, 0, 0, 0};
  int n = c->nargs;
  for (int i = 0; i < n; ++i) {
    memcpy(aw[i], a[i].w, sizeof aw[i]);
    unsigned b = (c->k == K_CLASS && i == 1) ? 32 : (i == 0 ? width_bits(c->w) : 80);
    if (c->k == K_FPEXT || c->k == K_ITOFP) b = width_bits(c->w);
    args[i].bits = b;
    args[i].kind = c->w[0] == 'i' && i == 0 ? 'i' : 'f';
    args[i].nw = (b + 63) / 64;
    args[i].w = aw[i];
  }
  if (f.rm) {
    aw[n][0] = (uint64_t)(f.mode << 10) | (f.rm == 2 ? 0x37Fu : 0); /* other bits ignored (CR §1.2) */
    args[n].bits = 32;
    args[n].kind = 'i';
    args[n].nw = 1;
    args[n].w = aw[n];
    ++n;
  }
  unsigned rb = f.exc ? 32 : result_bits(c);
  cqe_val out = {rb, (f.exc || c->k == K_CMP || c->k == K_CLASS || c->to[0] == 'i') ? 'i' : 'f', (rb + 63) / 64, ow};
  int rv = g_fn(&t, args, n, &out);
  memset(r, 0, sizeof *r);
  if (f.exc)
    r->exc = (int)ow[0];
  else
    memcpy(r->v.w, ow, sizeof ow);
  return rv;
}

/* ------------------------------------------------------------------ the expected result */

typedef struct {
  const char *row; /* NULL: native */
  int native_differs;
} why_t;

static int fp_result(const struct tcase *c) {
  return c->k == K_BIN || c->k == K_UN || c->k == K_FMA || c->k == K_MINMAX;
}

static void expected(const struct tcase *c, form_t f, const val *a, res_t *e, why_t *why) {
  int rc = RC[f.rm ? f.mode : 0];
  int strict = f.rm || f.exc;
  run_native(c, strict, rc, a, e);
  res_t nat = *e;
  unsigned rb = result_bits(c);
  why->row = NULL;
  int any_nc = 0;
  for (int i = 0; i < c->nargs; ++i) {
    int is_f80_operand = !((c->k == K_CLASS && i == 1) || c->k == K_FPEXT || c->k == K_ITOFP);
    if (is_f80_operand && noncanon(a[i])) any_nc = 1;
  }
  unsigned W2 = c->to[0] == 'i' ? width_bits(c->to) : 0;

  if (any_nc && fp_result(c)) {
    e->v = f80v(0xFFFF, INDEF_M);
    e->exc = 1;
    why->row = "T-noncanon";
  } else if (any_nc && c->k == K_CLASS) {
    e->v = f80v(0, 0);
    e->v.w[0] = (uint64_t)ref_class(a[0], c->extra);
    why->row = "T-fpclass";
  } else if (c->k == K_FPTRUNC && c->extra == 1) { /* no native code for f16, bf16 */
    int bf = !strcmp(c->to, "bf16"), fl;
    e->v = f80v(0, 0);
    e->v.w[0] = ref_narrow(a[0], bf ? 7 : 10, bf ? 8 : 5, rc, &fl);
    e->exc = fl;
    why->row = any_nc ? "T-noncanon" : "T-narrow";
  } else if (c->k == K_FPTOI && W2 > 128) { /* no native code: LLVM's ExpandLargeFpConvert */
    val va = any_nc ? f80v(0xFFFF, INDEF_M) : a[0];
    e->v = ref_fix_large(va, W2);
    e->exc = ref_conv_flags(va, W2, !strcmp(c->op, "fptosi")) | (any_nc ? 1 : 0);
    why->row = any_nc ? "T-noncanon" : "T-fix";
  } else if (any_nc && c->k == K_FPTOI && W2 > 64) {
    val ind = f80v(0xFFFF, INDEF_M);
    res_t r2;
    run_native(c, 0, FE_TONEAREST, &ind, &r2); /* the value of reading the real indefinite */
    e->v = r2.v;
    e->exc = 1;
    why->row = "T-noncanon";
  } else if (c->k == K_FPTOI && !strcmp(c->op, "fptoui") && W2 == 8) {
    val va = any_nc ? f80v(0xFFFF, INDEF_M) : a[0];
    int fl;
    uint16_t r = ref_fist16(va, &fl);
    e->v = f80v(0, 0);
    e->v.w[0] = r & 0xFF;
    e->exc = fl | (any_nc ? 1 : 0);
    why->row = "T-u8";
  } else if (c->k == K_MINMAX) {
    int ismax = c->op[2] == 'a';
    long double x = ldv(a[0]), y = ldv(a[1]);
    val r = is_nan80(a[0]) ? a[1] : is_nan80(a[1]) ? a[0] : ((ismax ? y > x : y < x) ? a[1] : a[0]);
    e->v = r;
    int snan = 0;
    for (int i = 0; i < 2; ++i)
      if (is_nan80(a[i]) && !((a[i].w[0] >> 62) & 1)) snan = 1;
    e->exc = snan ? 1 : 0;
    why->row = "T-fmax";
  } else if (c->k == K_CLASS && (a[0].w[1] & 0x7FFF) == 0 && (a[0].w[0] >> 63)) {
    e->v = f80v(0, 0);
    e->v.w[0] = (uint64_t)ref_class(a[0], c->extra);
    why->row = "T-fpclass";
  } else if (c->k == K_ITOFP && width_bits(c->w) > 64 && (strict || width_bits(c->w) > 128)) {
    unsigned N = width_bits(c->w);
    uint64_t M[4];
    memcpy(M, mask_to(a[0], N).w, sizeof M);
    int neg = c->op[0] == 's' && ((M[(N - 1) / 64] >> ((N - 1) % 64)) & 1);
    if (neg) { /* two's complement magnitude at N bits */
      unsigned carry = 1;
      for (int i = 0; i < 4; ++i) { uint64_t t = ~M[i] + carry; carry = carry && t == 0; M[i] = t; }
      val mv = {{M[0], M[1], M[2], M[3]}};
      mv = mask_to(mv, N);
      memcpy(M, mv.w, sizeof M);
    }
    int fl;
    e->v = ref_int_to_f80(M, neg, rc, &fl);
    e->exc = fl;
    why->row = "T-itofp";
  } else if (c->k == K_FPTOI && W2 > 64 && f.exc) {
    e->exc = ref_conv_flags(a[0], W2 > 128 ? W2 : 128, !strcmp(c->op, "fptosi"));
    why->row = "T-fix";
  }
  if (!any_nc && (c->k == K_BIN || c->k == K_UN || c->k == K_FMA)) {
    /* CR §2 NaN row (normative over the x87 and libm choices): first NaN operand, quieted;
     * an invalid operation gives the real indefinite; a signaling NaN operand raises INVALID. */
    int snan = 0, first = -1;
    for (int i = 0; i < c->nargs; ++i)
      if (is_nan80(a[i])) {
        if (first < 0) first = i;
        if (!((a[i].w[0] >> 62) & 1)) snan = 1;
      }
    res_t base = *e;
    if (is_nan80(e->v)) {
      e->v = first >= 0 ? a[first] : f80v(0xFFFF, INDEF_M);
      e->v.w[0] |= 1ull << 62;
    }
    if (snan) e->exc |= 1;
    if (f.exc ? base.exc != e->exc : memcmp(base.v.w, e->v.w, sizeof base.v.w) != 0) {
      if (!why->row) why->row = "T-nan";
    }
  }
  e->v = mask_to(e->v, rb);
  nat.v = mask_to(nat.v, rb);
  int nonative = c->k != K_CLASS && c->extra == 1;
  why->native_differs = nonative ? -1 : why->row && (f.exc ? nat.exc != e->exc : memcmp(nat.v.w, e->v.w, sizeof nat.v.w) != 0);
}

/* ------------------------------------------------------------------ driver */

static int nsrc_samples(unsigned bits, val *out, int max) {
  int n = 0;
  val z = {{0, 0, 0, 0}};
#define PUT(v) do { if (n < max) out[n++] = mask_to((v), bits); } while (0)
  PUT(z);
  val one = z; one.w[0] = 1; PUT(one);
  val m1 = {{~0ull, ~0ull, ~0ull, ~0ull}}; PUT(m1);                  /* -1 / UMAX */
  val mn = z; mn.w[(bits - 1) / 64] = 1ull << ((bits - 1) % 64); PUT(mn); /* MIN / 2^(N-1) */
  val mx = m1; mx = mask_to(mx, bits); mx.w[(bits - 1) / 64] &= ~(1ull << ((bits - 1) % 64)); PUT(mx);
  val mn1 = mn; mn1.w[0] |= 1; PUT(mn1);
  for (unsigned k = 1; k < bits && k < 256; k += (k < 70 ? 1 : 13)) {
    val p = z; p.w[k / 64] = 1ull << (k % 64); PUT(p);
    val pm = p; /* 2^k - 1 */
    for (unsigned i = 0; i < 4; ++i) pm.w[i] = (64 * i + 64 <= k) ? ~0ull : (64 * i < k ? (1ull << (k % 64)) - 1 : 0);
    PUT(pm);
  }
  if (bits > 65) { /* rounding ties at 64 significant bits */
    for (unsigned s = 1; s + 64 <= bits && s < 140; s += 7) {
      val t = z; /* T * 2^s + half: (2^63 + 1) << s, plus 2^(s-1), with and without sticky */
      unsigned b0 = s, b63 = s + 63, bh = s - 1;
      t.w[b0 / 64] |= 1ull << (b0 % 64);
      t.w[b63 / 64] |= 1ull << (b63 % 64);
      t.w[bh / 64] |= 1ull << (bh % 64);
      PUT(t);
      val t2 = t; t2.w[b0 / 64] &= ~(1ull << (b0 % 64)); PUT(t2); /* even: tie stays */
      if (s > 1) { val t3 = t2; t3.w[0] |= 1; PUT(t3); }
    }
  }
  while (n < max) {
    val r = {{rnd(), rnd(), rnd(), rnd()}};
    if (rnd() & 1) r = mask_to(r, 1 + (unsigned)(rnd() % bits));
    PUT(r);
  }
#undef PUT
  return n;
}

static val fsrc(const char *w, int i) {
  unsigned bits = width_bits(w + (w[0] == 'b'));
  /* f16/f32/f64 operand patterns: edges then random */
  static const uint64_t e16[] = {0, 0x8000, 0x3C00, 0xBC00, 1, 0x3FF, 0x400, 0x7BFF, 0x7C00, 0xFC00, 0x7E00, 0x7E01, 0x7C01, 0x7D00, 0xFFFF, 0x3555};
  static const uint64_t e32[] = {0, 0x80000000, 0x3F800000, 1, 0x7FFFFF, 0x800000, 0x7F7FFFFF, 0x7F800000, 0xFF800000, 0x7FC00000, 0x7FC00001, 0x7F800001, 0x7FA00000, 0xFFFFFFFF, 0x3EAAAAAB, 0xC2FF0000};
  static const uint64_t e64[] = {0, 0x8000000000000000ull, 0x3FF0000000000000ull, 1, 0xFFFFFFFFFFFFFull, 0x10000000000000ull, 0x7FEFFFFFFFFFFFFFull, 0x7FF0000000000000ull, 0xFFF0000000000000ull, 0x7FF8000000000000ull, 0x7FF8000000000001ull, 0x7FF0000000000001ull, 0x7FF4000000000000ull, 0xFFFFFFFFFFFFFFFFull, 0x3FD5555555555555ull, 0xC05FE00000000000ull};
  static const uint64_t eb16[] = {0, 0x8000, 0x3F80, 0xBF80, 1, 0x7F, 0x80, 0x7F7F, 0x7F80, 0xFF80, 0x7FC0, 0x7FC1, 0x7F81, 0x7FA0, 0xFFFF, 0x3EAB};
  const uint64_t *e = w[0] == 'b' ? eb16 : bits == 16 ? e16 : bits == 32 ? e32 : e64;
  val v = {{0, 0, 0, 0}};
  v.w[0] = i < 16 ? e[i] : rnd();
  return mask_to(v, bits);
}

typedef struct {
  long checked, table, table_native_differs, fails;
} stat_t;

static int g_print_budget = 40;

static const char *g_only; /* argv[2]: run only cases of this op */

static void check(const struct tcase *c, form_t f, const val *a0, stat_t *st, stat_t *rows, const char **rowname,
                  int *nrows) {
  res_t got, exp;
  why_t why;
  val a[3] = {a0[0], a0[1], a0[2]};
  if (c->k == K_CLASS) a[1] = f80v(0, 0), a[1].w[0] = c->extra; /* the mask literal */
  int rv = ours(c, f, a, &got);
  expected(c, f, a, &exp, &why);
  st->checked++;
  if (why.row) {
    int k;
    for (k = 0; k < *nrows; ++k)
      if (!strcmp(rowname[k], why.row)) break;
    if (k == *nrows) rowname[(*nrows)++] = why.row;
    rows[k].table++;
    st->table++;
    if (why.native_differs < 0) {
      rows[k].fails++; /* reused: samples of cases with no native code */
    } else {
      rows[k].table_native_differs += why.native_differs;
      st->table_native_differs += why.native_differs;
    }
  }
  int bad = rv != 0 || (f.exc ? got.exc != exp.exc : memcmp(got.v.w, exp.v.w, sizeof got.v.w) != 0);
  if (bad) {
    st->fails++;
    if (g_print_budget-- > 0) {
      fprintf(stderr, "FAIL %s%s%s_%s%s%s rm=%d mode=%d exc=%d rv=%d [%s] args:", c->op, c->pred[0] ? "_" : "", c->pred,
              c->w, c->to[0] ? "_to_" : "", c->to, f.rm, f.mode, f.exc, rv, why.row ? why.row : "native");
      for (int i = 0; i < c->nargs; ++i) fprintf(stderr, " %04llx:%016llx", (unsigned long long)a[i].w[1], (unsigned long long)a[i].w[0]);
      if (f.exc)
        fprintf(stderr, " got exc %d want %d\n", got.exc, exp.exc);
      else
        fprintf(stderr, " got %016llx:%016llx want %016llx:%016llx\n", (unsigned long long)got.v.w[1],
                (unsigned long long)got.v.w[0], (unsigned long long)exp.v.w[1], (unsigned long long)exp.v.w[0]);
    }
  }
}

static const form_t FORMS[] = {
    {0, 0, 0}, {0, 0, 1}, {1, 0, 0}, {1, 1, 0}, {1, 2, 0}, {1, 3, 0}, {1, 0, 1}, {1, 1, 1}, {1, 2, 1}, {1, 3, 1},
    {2, 0, 0}, {2, 1, 0}, {2, 2, 0}, {2, 3, 0}, {2, 0, 1}, {2, 1, 1}, {2, 2, 1}, {2, 3, 1},
};
#define NFORMS (sizeof FORMS / sizeof FORMS[0])

/* corpus symbols with f80 (every one this family serves) */
static const char *CORPUS[] = {
    "copysign_f80", "copysign_f80_lh", "fabs_f80", "fadd_f80", "fadd_f80_hl", "fcmp_oeq_f80_hl", "fcmp_ord_f80_hl",
    "fcmp_ueq_f80_hl", "fcmp_une_f80_hl", "fcmp_uno_f80_hl", "fdiv_f80", "fdiv_f80_hl", "fmul_f80", "fmul_f80_hl",
    "fneg_f80", "fpext_f64_to_f80", "frem_f80_hl", "fsub_f80", "fsub_f80_hl", "uitofp_i1_to_f80",
};

int main(int argc, char **argv) {
  long nrand = argc > 1 ? atol(argv[1]) : 3000;
  g_only = argc > 2 ? argv[2] : NULL;
  build_f80_samples();
  if (!g_fn) {
    fprintf(stderr, "harness: tmpl_f80.c registered nothing\n");
    return 2;
  }
  stat_t total = {0, 0, 0, 0}, rows[16];
  memset(rows, 0, sizeof rows);
  const char *rowname[16];
  int nrows = 0;

  for (size_t ci = 0; ci < NCASES; ++ci) {
    const struct tcase *c = &CASES[ci];
    stat_t st = {0, 0, 0, 0};
    if (g_only && strcmp(g_only, c->op)) continue;
    for (size_t fi = 0; fi < NFORMS; ++fi) {
      form_t f = FORMS[fi];
      if (c->k == K_CMP && !strcmp(c->op, "fcmps") && !f.exc && !f.rm && 0) continue;
      val a[3];
      long reps = 0;
      if (c->k == K_ITOFP) {
        static val src[1200];
        int n = nsrc_samples(width_bits(c->w), src, 400 + (int)(nrand / 10));
        for (int i = 0; i < n; ++i) { a[0] = src[i]; check(c, f, a, &st, rows, rowname, &nrows); }
      } else if (c->k == K_FPEXT) {
        for (long i = 0; i < 16 + nrand; ++i) { a[0] = fsrc(c->w, (int)i); check(c, f, a, &st, rows, rowname, &nrows); }
      } else if (c->nargs == 1 || c->k == K_CLASS) {
        for (int i = 0; i < nf80; ++i) { a[0] = F80S[i]; check(c, f, a, &st, rows, rowname, &nrows); }
        for (long i = 0; i < nrand; ++i) { a[0] = rand_f80(); check(c, f, a, &st, rows, rowname, &nrows); }
        if (c->k == K_CLASS) (void)0;
      } else if (c->nargs == 2) {
        int step = (f.rm || f.exc) && !(fi == 1) ? 3 : 1; /* the full edge cross product in plain and _exc */
        for (int i = 0; i < nf80; i += 1)
          for (int j = (i % step); j < nf80; j += step) {
            a[0] = F80S[i]; a[1] = F80S[j]; check(c, f, a, &st, rows, rowname, &nrows); ++reps;
          }
        for (long i = 0; i < nrand; ++i) {
          a[0] = rand_f80(); a[1] = (i & 3) ? rand_f80() : F80S[rnd() % (uint64_t)nf80];
          check(c, f, a, &st, rows, rowname, &nrows);
        }
      } else { /* fma */
        for (int i = 0; i < nf80; i += 3)
          for (int j = 1; j < nf80; j += 4)
            for (int k = 2; k < nf80; k += 5) {
              a[0] = F80S[i]; a[1] = F80S[j]; a[2] = F80S[k]; check(c, f, a, &st, rows, rowname, &nrows);
            }
        for (long i = 0; i < nrand; ++i) {
          a[0] = rand_f80(); a[1] = rand_f80(); a[2] = rand_f80(); check(c, f, a, &st, rows, rowname, &nrows);
        }
      }
      (void)reps;
    }
    printf("%-12s %-6s %-4s %-5s checked %8ld  table %7ld (native differs %6ld)  FAIL %ld\n", c->op, c->pred, c->w,
           c->to, st.checked, st.table, st.table_native_differs, st.fails);
    total.checked += st.checked;
    total.table += st.table;
    total.table_native_differs += st.table_native_differs;
    total.fails += st.fails;
  }

  /* the dispatch contract */
  long contract_fail = 0;
  {
    cqe_tname t;
    memset(&t, 0, sizeof t);
    strcpy(t.op, "fadd");
    strcpy(t.w, "f64");
    uint64_t w0[1] = {0x1234}, aw[2][1] = {{0}, {0}};
    cqe_val args[2] = {{64, 'f', 1, aw[0]}, {64, 'f', 1, aw[1]}}, out = {64, 'f', 1, w0};
    int before = g_fails;
    if (g_fn(&t, args, 2, &out) != CQE_OP_NOT_MINE || w0[0] != 0x1234 || g_fails != before) ++contract_fail;
    strcpy(t.op, "fptosi"); strcpy(t.w, "f64"); strcpy(t.to, "i32");
    if (g_fn(&t, args, 1, &out) != CQE_OP_NOT_MINE || w0[0] != 0x1234) ++contract_fail;
    strcpy(t.op, "fadd"); strcpy(t.w, "f80"); t.to[0] = 0;
    uint64_t o2[2];
    cqe_val out2 = {80, 'f', 2, o2};
    if (g_fn(&t, args, 1, &out2) != -1 || g_fails != before + 1) ++contract_fail; /* arity */
    strcpy(t.op, "fcmp"); strcpy(t.pred, "zz");
    if (g_fn(&t, args, 2, &out2) != -1 || g_fails != before + 2) ++contract_fail; /* predicate */
    cqe_val shortout = {80, 'f', 1, o2};
    strcpy(t.op, "fadd"); t.pred[0] = 0;
    if (g_fn(&t, args, 2, &shortout) != -1 || g_fails != before + 3) ++contract_fail; /* short out */
    /* every registered op name is one this harness exercised */
    for (int i = 0; i < g_nreg; ++i) {
      int seen = 0;
      for (size_t ci = 0; ci < NCASES; ++ci) seen |= !strcmp(CASES[ci].op, g_ops[i]);
      if (!seen) { fprintf(stderr, "op %s registered but not tested\n", g_ops[i]); ++contract_fail; }
    }
    /* every corpus f80 symbol's op/pred/width form is among the cases */
    for (size_t i = 0; i < sizeof CORPUS / sizeof CORPUS[0]; ++i) {
      int seen = 0;
      for (size_t ci = 0; ci < NCASES; ++ci) {
        char nm[64];
        snprintf(nm, sizeof nm, "%s%s%s_%s%s%s", CASES[ci].op, CASES[ci].pred[0] ? "_" : "", CASES[ci].pred, CASES[ci].w,
                 CASES[ci].to[0] ? "_to_" : "", CASES[ci].to);
        size_t L = strlen(nm);
        seen |= !strncmp(CORPUS[i], nm, L) && (CORPUS[i][L] == 0 || CORPUS[i][L] == '_');
      }
      if (!seen) { fprintf(stderr, "corpus %s not covered\n", CORPUS[i]); ++contract_fail; }
    }
  }

  printf("\nrows checked against the CR §2 table instead of native:\n");
  for (int k = 0; k < nrows; ++k)
    printf("  %-11s %8ld samples (native differs on %ld; %ld in cases with no native code)\n", rowname[k],
           rows[k].table, rows[k].table_native_differs, rows[k].fails);
  printf("\ncases %zu, forms %zu, checked %ld, against table %ld, FAIL %ld, contract FAIL %ld\n", NCASES, NFORMS,
         total.checked, total.table, total.fails, contract_fail);
  return total.fails || contract_fail ? 1 : 0;
}
