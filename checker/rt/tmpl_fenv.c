/* Checker template family: rounding-mode and exception forms (cq-w0-tmpl-fenv).
 *
 * Evaluator semantics, on basis values, of every fp template that carries `_rm`, `_rmq` or `_exc`,
 * and of `fcmps`. Semantics: CONSTRUCTION_RULES §1.2 (_rm/_rmq, _exc), §2 (wins), BACKEND_ABI §2.1,
 * §2.4, §2.9:
 *   - rounding mode: the x86-64 FE_* value of the last argument, bits 10-11: 0 nearest-even,
 *     1 down, 2 up, 3 toward zero; every other bit ignored. Without _rm/_rmq: nearest-even.
 *   - exception bits (the fresh i32 result of _exc): INVALID 1, DIVBYZERO 4, OVERFLOW 8,
 *     UNDERFLOW 16, INEXACT 32; no DENORMAL; tininess after rounding; UNDERFLOW only together with
 *     INEXACT (x86, masked); a quiet NaN operand raises INVALID only in fcmps, conversions to
 *     integer and invalid arithmetic; a signaling NaN operand raises INVALID everywhere.
 *   - NaN results: the first NaN operand in IR order, quieted; an invalid operation gives the
 *     default NaN (sign 1, quiet bit, zero payload: f32 0xFFC00000, f64 0xFFF8..., f80 real
 *     indefinite) (CR §2).
 *   - f80 non-canonical encodings (pseudo-NaN, pseudo-Inf, unnormal) are invalid operands: real
 *     indefinite and INVALID; pseudo-denormals read as denormals (CR §2).
 *
 * Generic over the format: f16 and f32 (IEEE binary16/32), bf16 (8 exponent, 7 fraction bits),
 * f80 (x87 extended, explicit integer bit), and f<N> for N >= 64, N a multiple of 32 (IEEE interchange: exponent bits
 * round(4 log2 N) - 13). Integer operands and results have any width i<N>. All arithmetic is
 * exact on a small bignum and rounded once.
 *
 * Registration (cq-arch M1, cq-mgi): under the exact op names fadd fsub fmul fdiv fma sqrt frem
 * fcmp fcmps fptrunc fpext sitofp uitofp fptosi fptoui rint floor ceil trunc round fmax fmin.
 * Several families serve one op; this one claims a template iff its name carries _rm, _rmq or
 * _exc, or its op is fcmps (every fcmps form), and no width is f80 (tmpl-f80 claims every f80
 * template, fenv forms included; the f80 format code here is kept generic but unclaimed). Any
 * other template returns CQE_OP_NOT_MINE without cqe_fail and without touching out.
 *
 * Calling convention (cq-arch M1): args are every forward-call argument in signature order,
 * literals included, resolved to values, the mode last when t->rm != 0; the _unc form's leading
 * out handle is not passed. The core owns out: out->w is non-NULL with out->nw = ceil(bits/64)
 * zeroed words and out->bits preset to the result width (W; i1 for compares; W2 for casts; i32
 * for _exc). The op writes every word (bits above out->bits zero) and returns 0; a malformed
 * call is cqe_fail and returns -1. The op computes the forward value whatever t->unc says; the
 * core XORs it in.
 *
 * Conversions to integer (only as _exc; their value template is the plain one): the x86-64
 * LLVM 19 -O1 code of CR §2's fptosi/fptoui row, which the strict lowering keeps:
 *   from f16 via f32 (fpext first); from f32/f64 (cvtt, indefinite on NaN or out of range):
 *   fptosi to i<=32: cvtt32, i<=64: cvtt64; fptoui to i<=16: cvtt32, i<=32: cvtt64,
 *   i<=64: cvtt64(x - (x >= 2^63 ? 2^63 : 0)); from f80 the same with fist16/32/64
 *   (fptosi to i<=16 fist16, i<=32 fist32, i<=64 fist64; fptoui to i<=16 fist32, i<=32 fist64,
 *   i<=64 fist64(x - (x >= 2^63 ? 2^63 : 0))). cvtt/fist raise INVALID (only) on NaN or a
 *   truncated value outside the signed range of their width, else INEXACT iff x is not integral.
 *   Wider than 64 bits: IEEE at the destination width; likewise sitofp/uitofp from wider than 64
 *   bits round per the mode (native compiler-rt ignores the mode and raises nothing: bead cq-qx1).
 *
 * CR §2 at CQ_spec 2f894fd: what LLVM 19 code generation fixes inline is adopted for the VALUE, a
 * vendor library's result is IEEE in the template's mode, and the exception bits are IEEE at the
 * operation's width (in the template's mode) wherever native raises none. So the _exc bits of
 * every conversion stay the IEEE ones above, and only these values differ from one IEEE rounding:
 *   - sitofp/uitofp from more than 128 bits: ExpandLargeFpConvert (nearest-even whatever the mode,
 *     exponent wraps past the range); to f16 through its f32 and the library fptrunc (in the mode);
 *   - to bf16 through f32 (two roundings), the second step being fptrunc f32 -> bf16.
 * CQ_spec e46f5e3 bf16 row: fptrunc f32/f64 -> bf16 are compiler-rt calls (__truncsfbf2,
 * __truncdfbf2), so IEEE in the template's mode, one rounding from the source width, a NaN quiet
 * with the high payload bits. rint rounds in the template's mode (rint row). fpext has no rounding
 * operand and so no value form here (its bare-shift value is the plain family's).
 */
#include <math.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"
#include "libm_next.h"

CQE_LIBM_NEXT(double, log2, (double x), (x))
CQE_LIBM_NEXT(long, lround, (double x), (x))

#ifndef CQE_OP_NOT_MINE
#define CQE_OP_NOT_MINE 1
#endif

enum { X_INVALID = 1, X_DIVBYZERO = 4, X_OVERFLOW = 8, X_UNDERFLOW = 16, X_INEXACT = 32 };
enum { RM_NE = 0, RM_DN = 1, RM_UP = 2, RM_TZ = 3 };

static _Noreturn void fe_unimplemented(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  fprintf(stderr, "cq: unimplemented: tmpl-fenv: ");
  vfprintf(stderr, fmt, ap);
  fprintf(stderr, "\n");
  va_end(ap);
  abort();
}

/* ---------------------------------------------------------------------------------------------
 * Bignum: unsigned, little-endian 64-bit words, n significant words. */

#define BN_N 48 /* 3072 bits: formats up to p = 900 and every int width (compressed) */

typedef struct {
  int n;
  uint64_t w[BN_N];
} bn_t;

static void bn_norm(bn_t *a) {
  while (a->n > 0 && a->w[a->n - 1] == 0)
    a->n--;
}
static void bn_zero(bn_t *a) { a->n = 0; }
static void bn_u64(bn_t *a, uint64_t v) {
  a->n = v ? 1 : 0;
  a->w[0] = v;
}
static int bn_is0(const bn_t *a) { return a->n == 0; }
static int bn_len(const bn_t *a) {
  if (!a->n)
    return 0;
  return (a->n - 1) * 64 + 64 - __builtin_clzll(a->w[a->n - 1]);
}
static int bn_bit(const bn_t *a, int i) {
  if (i < 0 || i / 64 >= a->n)
    return 0;
  return (int)((a->w[i / 64] >> (i % 64)) & 1u);
}
/* any bit set in [0, i) */
static int bn_below(const bn_t *a, int i) {
  if (i <= 0)
    return 0;
  int k = i / 64;
  for (int j = 0; j < k && j < a->n; ++j)
    if (a->w[j])
      return 1;
  if (k < a->n && (i % 64) && (a->w[k] & ((UINT64_C(1) << (i % 64)) - 1)))
    return 1;
  return 0;
}
static void bn_setbit(bn_t *a, int i) {
  int k = i / 64;
  if (k >= BN_N)
    fe_unimplemented("bignum capacity (%d bits)", BN_N * 64);
  while (a->n <= k)
    a->w[a->n++] = 0;
  a->w[k] |= UINT64_C(1) << (i % 64);
}
static void bn_shl(bn_t *r, const bn_t *a, int s) {
  if (bn_is0(a)) {
    r->n = 0;
    return;
  }
  int ws = s / 64, bs = s % 64, n = a->n + ws + 1;
  if (n > BN_N) {
    if (bn_len(a) + s > BN_N * 64)
      fe_unimplemented("bignum capacity (%d bits)", BN_N * 64);
    n = BN_N;
  }
  uint64_t t[BN_N];
  for (int i = 0; i < n; ++i) {
    int j = i - ws;
    uint64_t lo = (j >= 0 && j < a->n) ? a->w[j] : 0;
    uint64_t lo1 = (j - 1 >= 0 && j - 1 < a->n) ? a->w[j - 1] : 0;
    t[i] = bs ? (lo << bs) | (lo1 >> (64 - bs)) : lo;
  }
  memcpy(r->w, t, (size_t)n * sizeof t[0]);
  r->n = n;
  bn_norm(r);
}
static void bn_shr(bn_t *r, const bn_t *a, int s) {
  int ws = s / 64, bs = s % 64, n = a->n - ws;
  if (n <= 0) {
    r->n = 0;
    return;
  }
  uint64_t t[BN_N];
  for (int i = 0; i < n; ++i) {
    uint64_t lo = a->w[i + ws];
    uint64_t hi = (i + ws + 1 < a->n) ? a->w[i + ws + 1] : 0;
    t[i] = bs ? (lo >> bs) | (hi << (64 - bs)) : lo;
  }
  memcpy(r->w, t, (size_t)n * sizeof t[0]);
  r->n = n;
  bn_norm(r);
}
static int bn_cmp(const bn_t *a, const bn_t *b) {
  if (a->n != b->n)
    return a->n < b->n ? -1 : 1;
  for (int i = a->n - 1; i >= 0; --i)
    if (a->w[i] != b->w[i])
      return a->w[i] < b->w[i] ? -1 : 1;
  return 0;
}
static void bn_add(bn_t *r, const bn_t *a, const bn_t *b) {
  int n = a->n > b->n ? a->n : b->n;
  uint64_t t[BN_N + 1], c = 0;
  for (int i = 0; i < n; ++i) {
    uint64_t x = i < a->n ? a->w[i] : 0, y = i < b->n ? b->w[i] : 0;
    unsigned __int128 s = (unsigned __int128)x + y + c;
    t[i] = (uint64_t)s;
    c = (uint64_t)(s >> 64);
  }
  if (c) {
    if (n >= BN_N)
      fe_unimplemented("bignum capacity (%d bits)", BN_N * 64);
    t[n++] = c;
  }
  memcpy(r->w, t, (size_t)n * sizeof t[0]);
  r->n = n;
  bn_norm(r);
}
static void bn_sub(bn_t *r, const bn_t *a, const bn_t *b) { /* a >= b */
  uint64_t t[BN_N], br = 0;
  int n = a->n;
  for (int i = 0; i < n; ++i) {
    uint64_t x = a->w[i], y = i < b->n ? b->w[i] : 0;
    uint64_t d = x - y - br;
    br = (x < y) || (x - y < br);
    t[i] = d;
  }
  memcpy(r->w, t, (size_t)n * sizeof t[0]);
  r->n = n;
  bn_norm(r);
}
static void bn_mul(bn_t *r, const bn_t *a, const bn_t *b) {
  int n = a->n + b->n;
  if (n > BN_N)
    fe_unimplemented("bignum capacity (%d bits)", BN_N * 64);
  uint64_t t[BN_N];
  memset(t, 0, sizeof t);
  for (int i = 0; i < a->n; ++i) {
    uint64_t c = 0;
    for (int j = 0; j < b->n; ++j) {
      unsigned __int128 p = (unsigned __int128)a->w[i] * b->w[j] + t[i + j] + c;
      t[i + j] = (uint64_t)p;
      c = (uint64_t)(p >> 64);
    }
    t[i + b->n] = c;
  }
  memcpy(r->w, t, (size_t)n * sizeof t[0]);
  r->n = n;
  bn_norm(r);
}
/* q = a / b, rem = a mod b; b != 0 */
static void bn_divmod(bn_t *q, bn_t *rem, const bn_t *a, const bn_t *b) {
  bn_t r, qq;
  bn_zero(&r);
  bn_zero(&qq);
  for (int i = bn_len(a) - 1; i >= 0; --i) {
    bn_shl(&r, &r, 1);
    if (bn_bit(a, i))
      bn_setbit(&r, 0);
    if (bn_cmp(&r, b) >= 0) {
      bn_sub(&r, &r, b);
      bn_setbit(&qq, i);
    }
  }
  if (q)
    *q = qq;
  if (rem)
    *rem = r;
}
/* root = floor(sqrt(a)); *exact = root^2 == a */
static void bn_isqrt(bn_t *root, int *exact, const bn_t *a) {
  bn_t x = *a, res, bit, t;
  bn_zero(&res);
  bn_zero(&bit);
  int l = bn_len(a);
  if (l == 0) {
    bn_zero(root);
    *exact = 1;
    return;
  }
  bn_setbit(&bit, (l - 1) & ~1);
  while (!bn_is0(&bit)) {
    bn_add(&t, &res, &bit);
    if (bn_cmp(&x, &t) >= 0) {
      bn_sub(&x, &x, &t);
      bn_shr(&res, &res, 1);
      bn_add(&res, &res, &bit);
    } else {
      bn_shr(&res, &res, 1);
    }
    bn_shr(&bit, &bit, 2);
  }
  *root = res;
  *exact = bn_is0(&x);
}
static void bn_low(bn_t *r, const bn_t *a, int bits) { /* r = a mod 2^bits */
  *r = *a;
  int k = bits / 64;
  if (r->n > k) {
    if (bits % 64) {
      r->w[k] &= (UINT64_C(1) << (bits % 64)) - 1;
      r->n = k + 1;
    } else {
      r->n = k;
    }
  }
  bn_norm(r);
}
static void bn_or(bn_t *r, const bn_t *a, const bn_t *b) {
  int n = a->n > b->n ? a->n : b->n;
  for (int i = 0; i < n; ++i)
    r->w[i] = (i < a->n ? a->w[i] : 0) | (i < b->n ? b->w[i] : 0);
  r->n = n;
  bn_norm(r);
}

/* ---------------------------------------------------------------------------------------------
 * Formats and numbers. */

typedef struct {
  int W, ebits, fbits, jbit, p;
  int64_t bias, emin, emax;
} fmt_t;

static int fmt_of(const char *w, fmt_t *f) {
  if (!strcmp(w, "bf16")) { /* bfloat16 (CR §1.1): 8 exponent bits, 7 fraction bits */
    memset(f, 0, sizeof *f);
    f->W = 16;
    f->ebits = 8;
    goto derived;
  }
  if (w[0] != 'f')
    return 0;
  long n = 0;
  for (const char *c = w + 1; *c; ++c) {
    if (*c < '0' || *c > '9' || n > 100000)
      return 0;
    n = n * 10 + (*c - '0');
  }
  memset(f, 0, sizeof *f);
  f->W = (int)n;
  if (n == 16)
    f->ebits = 5;
  else if (n == 32)
    f->ebits = 8;
  else if (n == 80) {
    f->ebits = 15;
    f->jbit = 1;
  } else if (n >= 64 && n % 32 == 0) {
    /* IEEE 754-2008 interchange formats: round(4 log2 N) - 13. 4 log2 N is never a half
     * integer (that needs N^8 = 2^odd), and double log2 is far more precise than the distance
     * to one for N < 100000. */
    f->ebits = (int)cqe_next_lround(4.0 * cqe_next_log2((double)n)) - 13;
  } else
    return 0;
derived:
  f->fbits = f->W - 1 - f->ebits - f->jbit;
  f->p = f->fbits + 1;
  f->bias = (INT64_C(1) << (f->ebits - 1)) - 1;
  f->emin = 1 - f->bias;
  f->emax = f->bias;
  if (f->p + 8 > BN_N * 64 / 4)
    fe_unimplemented("format %s exceeds the bignum capacity", w);
  return 1;
}

enum { C_ZERO, C_FIN, C_INF, C_NAN, C_BAD };

typedef struct {
  int cls, sign, quiet; /* quiet: NaN only */
  bn_t m;               /* C_FIN: value = m * 2^e; C_NAN: the fraction field (payload) */
  int64_t e;
} num_t;

static void val_to_bn(bn_t *r, const cqe_val *v, int bits) {
  int nw = (bits + 63) / 64;
  if (nw > BN_N)
    fe_unimplemented("value width %d", bits);
  for (int i = 0; i < nw; ++i)
    r->w[i] = (i < (int)v->nw && v->w) ? v->w[i] : 0;
  r->n = nw;
  bn_norm(r);
  bn_low(r, r, bits);
}

static void unpack(const fmt_t *f, const bn_t *raw, num_t *x) {
  memset(x, 0, sizeof *x);
  x->sign = bn_bit(raw, f->W - 1);
  bn_t t;
  bn_shr(&t, raw, f->fbits + f->jbit);
  bn_low(&t, &t, f->ebits);
  int64_t ex = t.n ? (int64_t)t.w[0] : 0;
  int64_t exmax = (INT64_C(1) << f->ebits) - 1;
  bn_t frac;
  bn_low(&frac, raw, f->fbits);
  int J = f->jbit ? bn_bit(raw, f->fbits) : (ex != 0);
  if (ex == exmax) {
    if (f->jbit && !J) {
      x->cls = C_BAD;
      return;
    }
    if (bn_is0(&frac)) {
      x->cls = C_INF;
    } else {
      x->cls = C_NAN;
      x->quiet = bn_bit(&frac, f->fbits - 1);
      x->m = frac;
    }
    return;
  }
  if (ex == 0) {
    bn_low(&x->m, raw, f->fbits + f->jbit); /* f80: J:frac (pseudo-denormal reads as denormal) */
    x->cls = bn_is0(&x->m) ? C_ZERO : C_FIN;
    x->e = f->emin - (f->p - 1);
    return;
  }
  if (f->jbit && !J) {
    x->cls = C_BAD; /* unnormal */
    return;
  }
  x->m = frac;
  bn_setbit(&x->m, f->fbits);
  x->cls = C_FIN;
  x->e = ex - f->bias - (f->p - 1);
}

static void pack_fields(const fmt_t *f, bn_t *raw, int sign, int64_t biased, const bn_t *low) {
  /* low: fraction field (with J for f80) */
  bn_t e;
  bn_u64(&e, (uint64_t)biased);
  bn_shl(&e, &e, f->fbits + f->jbit);
  bn_or(raw, &e, low);
  if (sign)
    bn_setbit(raw, f->W - 1);
}
static void pack_zero(const fmt_t *f, bn_t *raw, int sign) {
  bn_t z;
  bn_zero(&z);
  pack_fields(f, raw, sign, 0, &z);
}
static void pack_inf(const fmt_t *f, bn_t *raw, int sign) {
  bn_t z;
  bn_zero(&z);
  if (f->jbit)
    bn_setbit(&z, f->fbits);
  pack_fields(f, raw, sign, (INT64_C(1) << f->ebits) - 1, &z);
}
/* payload: a fraction field of pbits bits; left-aligned into this format's fraction, quieted */
static void pack_nan(const fmt_t *f, bn_t *raw, int sign, const bn_t *payload, int pbits) {
  bn_t fr;
  if (pbits <= f->fbits)
    bn_shl(&fr, payload, f->fbits - pbits);
  else
    bn_shr(&fr, payload, pbits - f->fbits);
  bn_setbit(&fr, f->fbits - 1);
  if (f->jbit)
    bn_setbit(&fr, f->fbits);
  pack_fields(f, raw, sign, (INT64_C(1) << f->ebits) - 1, &fr);
}
static void pack_default_nan(const fmt_t *f, bn_t *raw) {
  bn_t z;
  bn_zero(&z);
  pack_nan(f, raw, 1, &z, f->fbits);
}
/* finite: |value| = mant * 2^q, mant < 2^p, already on the format's grid */
static void pack_fin(const fmt_t *f, bn_t *raw, int sign, const bn_t *mant, int64_t q) {
  if (bn_len(mant) == f->p) {
    int64_t biased = q + (f->p - 1) + f->bias;
    bn_t low;
    bn_low(&low, mant, f->fbits + f->jbit);
    pack_fields(f, raw, sign, biased, &low);
  } else {
    pack_fields(f, raw, sign, 0, mant);
  }
}

/* ---------------------------------------------------------------------------------------------
 * Rounding. */

/* kept = M >> s rounded per mode; sticky_in: a nonzero tail below M's lsb. s >= 1 when sticky_in. */
static void round_shift(bn_t *kept, const bn_t *M, int64_t s, int sticky_in, int mode, int sign,
                        int *inexact) {
  if (s <= 0) {
    if (sticky_in)
      fe_unimplemented("round_shift: sticky without guard bits");
    bn_shl(kept, M, (int)-s);
    *inexact = 0;
    return;
  }
  int rb = 0, st = sticky_in;
  if (s > bn_len(M) + 1) {
    bn_zero(kept);
    st = st || !bn_is0(M);
  } else {
    rb = bn_bit(M, (int)s - 1);
    st = st || bn_below(M, (int)s - 1);
    bn_shr(kept, M, (int)s);
  }
  *inexact = rb || st;
  int inc = 0;
  switch (mode) {
  case RM_NE: inc = rb && (st || bn_bit(kept, 0)); break;
  case RM_TZ: inc = 0; break;
  case RM_UP: inc = *inexact && !sign; break;
  case RM_DN: inc = *inexact && sign; break;
  }
  if (inc) {
    bn_t one;
    bn_u64(&one, 1);
    bn_add(kept, kept, &one);
  }
}

static void pack_overflow(const fmt_t *f, bn_t *raw, int sign, int mode) {
  int toinf = mode == RM_NE || (mode == RM_UP && !sign) || (mode == RM_DN && sign);
  if (toinf) {
    pack_inf(f, raw, sign);
  } else {
    bn_t m;
    bn_zero(&m);
    for (int i = 0; i < f->p; ++i)
      bn_setbit(&m, i);
    pack_fin(f, raw, sign, &m, f->emax - f->p + 1);
  }
}

/* Round sign * (M + tail) * 2^E, M != 0, tail in (0, 1) iff sticky; M must carry at least p + 2
 * bits when sticky. */
static void fe_round(const fmt_t *f, bn_t *raw, int sign, const bn_t *M, int64_t E, int sticky,
                     int mode, int *flags) {
  int L = bn_len(M);
  int64_t lead = E + L - 1;
  int inex;
  bn_t mu;
  /* tininess after rounding: round to p bits with unbounded exponent */
  round_shift(&mu, M, (lead - f->p + 1) - E, sticky, mode, sign, &inex);
  int64_t lead_u = lead + (bn_len(&mu) > f->p ? 1 : 0);
  int tiny = lead_u < f->emin;
  int64_t q = (lead > f->emin ? lead : f->emin) - f->p + 1;
  bn_t mr;
  round_shift(&mr, M, q - E, sticky, mode, sign, &inex);
  if (bn_len(&mr) > f->p) {
    bn_shr(&mr, &mr, 1);
    q++;
  }
  if (!bn_is0(&mr) && q + bn_len(&mr) - 1 > f->emax) {
    *flags |= X_OVERFLOW | X_INEXACT;
    pack_overflow(f, raw, sign, mode);
    return;
  }
  if (inex) {
    *flags |= X_INEXACT;
    if (tiny)
      *flags |= X_UNDERFLOW;
  }
  if (bn_is0(&mr))
    pack_zero(f, raw, sign);
  else
    pack_fin(f, raw, sign, &mr, q);
}

/* ---------------------------------------------------------------------------------------------
 * Operations. Each returns the result bits in raw and ORs exception bits into *fl. */

static int64_t lead_of(const num_t *x) { return x->e + bn_len(&x->m) - 1; }

/* NaN / invalid-operand prelude over n operands. Returns 1 when the result is decided. */
static int nan_prelude(const fmt_t *f, const fmt_t *const *af, const num_t *a, int n, bn_t *raw,
                       int *fl) {
  int anynan = 0, bad = 0;
  for (int i = 0; i < n; ++i) {
    if (a[i].cls == C_BAD)
      bad = 1;
    if (a[i].cls == C_NAN) {
      anynan = 1;
      if (!a[i].quiet)
        *fl |= X_INVALID;
    }
  }
  if (bad) {
    *fl |= X_INVALID;
    pack_default_nan(f, raw);
    return 1;
  }
  if (!anynan)
    return 0;
  for (int i = 0; i < n; ++i)
    if (a[i].cls == C_NAN) {
      pack_nan(f, raw, a[i].sign, &a[i].m, af[i]->fbits);
      return 1;
    }
  return 0;
}

static void invalid_nan(const fmt_t *f, bn_t *raw, int *fl) {
  *fl |= X_INVALID;
  pack_default_nan(f, raw);
}

/* exact a + b (finite, nonzero), result as (sign, M, E); M == 0 is an exact zero. p: precision
 * of the destination. Let a have the larger leading exponent la and g = min(Ea, la - p - 1).
 * a is a multiple of 2^g, and so is every rounding boundary of the result (grid points and
 * midpoints, normal, subnormal or unbounded-exponent): the result's leading exponent is at
 * least la - 1, and it is subnormal only when la <= emin. So when |b| < 2^g, a + b lies strictly
 * between a and the next multiple of 2^g toward b's sign, and b may be replaced by
 * sign(b) * 2^(g-1) without changing the rounded value, inexactness or tininess. */
static void exact_add(int sa, const bn_t *Ma, int64_t Ea, int sb, const bn_t *Mb, int64_t Eb,
                      int p, int *sr, bn_t *Mr, int64_t *Er) {
  int64_t la = Ea + bn_len(Ma) - 1, lb = Eb + bn_len(Mb) - 1;
  if (lb > la) {
    const bn_t *tm = Ma;
    Ma = Mb;
    Mb = tm;
    int64_t te = Ea;
    Ea = Eb;
    Eb = te;
    int ts = sa;
    sa = sb;
    sb = ts;
    te = la;
    la = lb;
    lb = te;
  }
  bn_t one;
  int64_t g = Ea < la - p - 1 ? Ea : la - p - 1;
  if (lb < g) {
    bn_u64(&one, 1);
    Mb = &one;
    Eb = g - 1;
  }
  int64_t E = Ea < Eb ? Ea : Eb;
  bn_t A, B;
  bn_shl(&A, Ma, (int)(Ea - E));
  bn_shl(&B, Mb, (int)(Eb - E));
  *Er = E;
  if (sa == sb) {
    bn_add(Mr, &A, &B);
    *sr = sa;
  } else {
    int c = bn_cmp(&A, &B);
    if (c >= 0) {
      bn_sub(Mr, &A, &B);
      *sr = sa;
    } else {
      bn_sub(Mr, &B, &A);
      *sr = sb;
    }
  }
}

static void op_add(const fmt_t *f, const fmt_t *const *af, num_t a, num_t b, int negb, int mode,
                   bn_t *raw, int *fl) {
  num_t ab[2] = {a, b};
  if (nan_prelude(f, af, ab, 2, raw, fl))
    return;
  if (negb)
    b.sign ^= 1;
  if (a.cls == C_INF || b.cls == C_INF) {
    if (a.cls == C_INF && b.cls == C_INF && a.sign != b.sign) {
      invalid_nan(f, raw, fl);
      return;
    }
    pack_inf(f, raw, a.cls == C_INF ? a.sign : b.sign);
    return;
  }
  if (a.cls == C_ZERO && b.cls == C_ZERO) {
    pack_zero(f, raw, a.sign == b.sign ? a.sign : mode == RM_DN);
    return;
  }
  if (a.cls == C_ZERO || b.cls == C_ZERO) {
    const num_t *x = a.cls == C_ZERO ? &b : &a;
    fe_round(f, raw, x->sign, &x->m, x->e, 0, mode, fl);
    return;
  }
  int s;
  bn_t M;
  int64_t E;
  exact_add(a.sign, &a.m, a.e, b.sign, &b.m, b.e, f->p, &s, &M, &E);
  if (bn_is0(&M)) {
    pack_zero(f, raw, mode == RM_DN);
    return;
  }
  fe_round(f, raw, s, &M, E, 0, mode, fl);
}

static void op_mul(const fmt_t *f, const fmt_t *const *af, num_t a, num_t b, int mode, bn_t *raw,
                   int *fl) {
  num_t ab[2] = {a, b};
  if (nan_prelude(f, af, ab, 2, raw, fl))
    return;
  int s = a.sign ^ b.sign;
  if (a.cls == C_INF || b.cls == C_INF) {
    if (a.cls == C_ZERO || b.cls == C_ZERO) {
      invalid_nan(f, raw, fl);
      return;
    }
    pack_inf(f, raw, s);
    return;
  }
  if (a.cls == C_ZERO || b.cls == C_ZERO) {
    pack_zero(f, raw, s);
    return;
  }
  bn_t M;
  bn_mul(&M, &a.m, &b.m);
  fe_round(f, raw, s, &M, a.e + b.e, 0, mode, fl);
}

static void op_div(const fmt_t *f, const fmt_t *const *af, num_t a, num_t b, int mode, bn_t *raw,
                   int *fl) {
  num_t ab[2] = {a, b};
  if (nan_prelude(f, af, ab, 2, raw, fl))
    return;
  int s = a.sign ^ b.sign;
  if (a.cls == C_INF) {
    if (b.cls == C_INF)
      invalid_nan(f, raw, fl);
    else
      pack_inf(f, raw, s);
    return;
  }
  if (b.cls == C_INF) {
    pack_zero(f, raw, s);
    return;
  }
  if (b.cls == C_ZERO) {
    if (a.cls == C_ZERO) {
      invalid_nan(f, raw, fl);
      return;
    }
    *fl |= X_DIVBYZERO;
    pack_inf(f, raw, s);
    return;
  }
  if (a.cls == C_ZERO) {
    pack_zero(f, raw, s);
    return;
  }
  int sh = bn_len(&b.m) - bn_len(&a.m) + f->p + 3;
  if (sh < 0)
    sh = 0;
  bn_t A, Q, R;
  bn_shl(&A, &a.m, sh);
  bn_divmod(&Q, &R, &A, &b.m);
  fe_round(f, raw, s, &Q, a.e - b.e - sh, !bn_is0(&R), mode, fl);
}

static void op_sqrt(const fmt_t *f, const fmt_t *const *af, num_t a, int mode, bn_t *raw,
                    int *fl) {
  if (nan_prelude(f, af, &a, 1, raw, fl))
    return;
  if (a.cls == C_ZERO) {
    pack_zero(f, raw, a.sign);
    return;
  }
  if (a.sign) {
    invalid_nan(f, raw, fl);
    return;
  }
  if (a.cls == C_INF) {
    pack_inf(f, raw, 0);
    return;
  }
  int sh = 2 * f->p + 5 - bn_len(&a.m);
  if (sh < 0)
    sh = 0;
  if ((a.e - sh) & 1)
    sh++;
  bn_t A, Rt;
  int exact;
  bn_shl(&A, &a.m, sh);
  bn_isqrt(&Rt, &exact, &A);
  int64_t ee = a.e - sh; /* even */
  fe_round(f, raw, 0, &Rt, ee / 2, !exact, mode, fl);
}

static void op_fma(const fmt_t *f, const fmt_t *const *af, num_t a, num_t b, num_t c, int mode,
                   bn_t *raw, int *fl) {
  num_t abc[3] = {a, b, c};
  if (nan_prelude(f, af, abc, 3, raw, fl))
    return;
  int sp = a.sign ^ b.sign;
  int pinf = a.cls == C_INF || b.cls == C_INF;
  int pzero = a.cls == C_ZERO || b.cls == C_ZERO;
  if (pinf && pzero) {
    invalid_nan(f, raw, fl);
    return;
  }
  if (pinf) {
    if (c.cls == C_INF && c.sign != sp) {
      invalid_nan(f, raw, fl);
      return;
    }
    pack_inf(f, raw, sp);
    return;
  }
  if (c.cls == C_INF) {
    pack_inf(f, raw, c.sign);
    return;
  }
  if (pzero) {
    if (c.cls == C_ZERO)
      pack_zero(f, raw, sp == c.sign ? sp : mode == RM_DN);
    else
      fe_round(f, raw, c.sign, &c.m, c.e, 0, mode, fl);
    return;
  }
  bn_t P;
  bn_mul(&P, &a.m, &b.m);
  int64_t Ep = a.e + b.e;
  if (c.cls == C_ZERO) {
    fe_round(f, raw, sp, &P, Ep, 0, mode, fl);
    return;
  }
  int s;
  bn_t M;
  int64_t E;
  exact_add(sp, &P, Ep, c.sign, &c.m, c.e, f->p, &s, &M, &E);
  if (bn_is0(&M)) {
    pack_zero(f, raw, mode == RM_DN);
    return;
  }
  fe_round(f, raw, s, &M, E, 0, mode, fl);
}

/* IEEE fmod: exact */
static void op_frem(const fmt_t *f, const fmt_t *const *af, num_t a, num_t b, bn_t *raw,
                    int *fl) {
  num_t ab[2] = {a, b};
  if (nan_prelude(f, af, ab, 2, raw, fl))
    return;
  if (a.cls == C_INF || b.cls == C_ZERO) {
    invalid_nan(f, raw, fl);
    return;
  }
  if (b.cls == C_INF || a.cls == C_ZERO) {
    if (a.cls == C_ZERO)
      pack_zero(f, raw, a.sign);
    else
      fe_round(f, raw, a.sign, &a.m, a.e, 0, RM_NE, fl);
    return;
  }
  if (lead_of(&a) < lead_of(&b)) {
    fe_round(f, raw, a.sign, &a.m, a.e, 0, RM_NE, fl);
    return;
  }
  bn_t R;
  int64_t E;
  if (a.e >= b.e) {
    bn_divmod(NULL, &R, &a.m, &b.m);
    for (int64_t d = a.e - b.e; d > 0; --d) {
      bn_shl(&R, &R, 1);
      if (bn_cmp(&R, &b.m) >= 0)
        bn_sub(&R, &R, &b.m);
    }
    E = b.e;
  } else {
    bn_t Bs;
    bn_shl(&Bs, &b.m, (int)(b.e - a.e));
    bn_divmod(NULL, &R, &a.m, &Bs);
    E = a.e;
  }
  if (bn_is0(&R))
    pack_zero(f, raw, a.sign);
  else
    fe_round(f, raw, a.sign, &R, E, 0, RM_NE, fl);
}

/* -1, 0, 1 for ordered; 2 unordered. Raises INVALID per signaling. */
static int op_cmp(num_t a, num_t b, int signaling, int *fl) {
  if (a.cls == C_BAD || b.cls == C_BAD) {
    *fl |= X_INVALID;
    return 2;
  }
  if (a.cls == C_NAN || b.cls == C_NAN) {
    if (signaling || (a.cls == C_NAN && !a.quiet) || (b.cls == C_NAN && !b.quiet))
      *fl |= X_INVALID;
    return 2;
  }
  if (a.cls == C_ZERO && b.cls == C_ZERO)
    return 0;
  /* magnitude order: zero < finite < inf */
  int sa = a.cls == C_ZERO ? 0 : (a.sign ? -1 : 1);
  int sb = b.cls == C_ZERO ? 0 : (b.sign ? -1 : 1);
  if (sa != sb)
    return sa < sb ? -1 : 1;
  /* same nonzero sign */
  int mag; /* |a| vs |b| */
  if (a.cls == C_INF || b.cls == C_INF)
    mag = (a.cls == C_INF) - (b.cls == C_INF);
  else {
    int64_t la = lead_of(&a), lb = lead_of(&b);
    if (la != lb)
      mag = la < lb ? -1 : 1;
    else {
      int64_t E = a.e < b.e ? a.e : b.e;
      bn_t A, B;
      bn_shl(&A, &a.m, (int)(a.e - E));
      bn_shl(&B, &b.m, (int)(b.e - E));
      mag = bn_cmp(&A, &B);
    }
  }
  return sa > 0 ? mag : -mag;
}

static int pred_holds(const char *pred, int r, int *ok) {
  int lt = r == -1, eq = r == 0, gt = r == 1, un = r == 2;
  *ok = 1;
  if (!strcmp(pred, "false")) return 0;
  if (!strcmp(pred, "oeq")) return eq;
  if (!strcmp(pred, "ogt")) return gt;
  if (!strcmp(pred, "oge")) return gt || eq;
  if (!strcmp(pred, "olt")) return lt;
  if (!strcmp(pred, "ole")) return lt || eq;
  if (!strcmp(pred, "one")) return lt || gt;
  if (!strcmp(pred, "ord")) return !un;
  if (!strcmp(pred, "ueq")) return un || eq;
  if (!strcmp(pred, "ugt")) return un || gt;
  if (!strcmp(pred, "uge")) return un || gt || eq;
  if (!strcmp(pred, "ult")) return un || lt;
  if (!strcmp(pred, "ule")) return un || lt || eq;
  if (!strcmp(pred, "une")) return un || lt || gt;
  if (!strcmp(pred, "uno")) return un;
  if (!strcmp(pred, "true")) return 1;
  *ok = 0;
  return 0;
}

/* fp -> fp conversion (fptrunc, fpext) */
static void op_fpconv(const fmt_t *to, const fmt_t *from, num_t a, int mode, bn_t *raw, int *fl) {
  const fmt_t *af[1] = {from};
  if (nan_prelude(to, af, &a, 1, raw, fl))
    return;
  if (a.cls == C_INF)
    pack_inf(to, raw, a.sign);
  else if (a.cls == C_ZERO)
    pack_zero(to, raw, a.sign);
  else
    fe_round(to, raw, a.sign, &a.m, a.e, 0, mode, fl);
}

/* integer i<N> -> fp */
static void op_itofp(const fmt_t *to, const bn_t *raw_int, int N, int is_signed, int mode,
                     bn_t *raw, int *fl) {
  bn_t M = *raw_int;
  int sign = 0;
  if (is_signed && bn_bit(&M, N - 1)) {
    /* magnitude = 2^N - v */
    bn_t full;
    bn_zero(&full);
    bn_setbit(&full, N);
    bn_sub(&M, &full, &M);
    sign = 1;
  }
  if (bn_is0(&M)) {
    pack_zero(to, raw, 0);
    return;
  }
  fe_round(to, raw, sign, &M, 0, 0, mode, fl);
}

/* The VALUE of sitofp/uitofp i<N> -> to for N > 128: LLVM 19 ExpandLargeFpConvert (expandIToFP),
 * integer code that ignores the rounding mode and raises nothing (CR §2 line: inline codegen is
 * adopted for the value). |v| is rounded to p bits, nearest-even, with an unbounded exponent e;
 * the bits are ((e + bias) << fbits) + fraction, kept to W bits, OR the sign: an exponent past the
 * format's range wraps (2^150 -> f32 0x8a800000, measured). Formats without an explicit integer
 * bit only; f16 and bf16 go through f32 (the caller). */
static void itofp_expand(const fmt_t *to, const bn_t *raw_int, int N, int is_signed, bn_t *raw) {
  bn_t M = *raw_int;
  int sign = 0;
  if (is_signed && bn_bit(&M, N - 1)) {
    bn_t full;
    bn_zero(&full);
    bn_setbit(&full, N);
    bn_sub(&M, &full, &M);
    sign = 1;
  }
  if (bn_is0(&M)) {
    pack_zero(to, raw, 0);
    return;
  }
  int L = bn_len(&M);
  int64_t e = L - 1;
  bn_t kept;
  if (L > to->p) {
    int inex;
    round_shift(&kept, &M, L - to->p, 0, RM_NE, sign, &inex);
    if (bn_len(&kept) > to->p) {
      bn_shr(&kept, &kept, 1);
      e++;
    }
  } else {
    bn_shl(&kept, &M, to->p - L);
  }
  bn_t frac, ex;
  bn_low(&frac, &kept, to->fbits);
  bn_u64(&ex, (uint64_t)(e + to->bias));
  bn_shl(&ex, &ex, to->fbits);
  bn_or(raw, &ex, &frac);
  bn_low(raw, raw, to->W);
  if (sign)
    bn_setbit(raw, to->W - 1);
}

static int is_bf16(const fmt_t *f) { return f->W == 16 && f->ebits == 8; }

/* The VALUE of sitofp/uitofp i<N> -> to when it is not one IEEE rounding in the template's mode
 * (CR §2): bf16 goes through f32 (cvtsi2ss or the compiler-rt call in the mode for N <= 128,
 * ExpandLargeFpConvert above), then the compiler-rt fptrunc f32 -> bf16, IEEE in the mode (two
 * roundings; a wrapped NaN comes back quiet); for N > 128, f16 is ExpandLargeFpConvert's f32 then
 * the library fptrunc f32 -> f16 (IEEE, in the mode) and every other format is
 * ExpandLargeFpConvert's own value. Returns 0 when the IEEE value stands. */
static int itofp_value(const fmt_t *to, const bn_t *raw_int, int N, int is_signed, int mode,
                       bn_t *raw) {
  if (N <= 128 && !is_bf16(to))
    return 0;
  if (to->W != 16) {
    itofp_expand(to, raw_int, N, is_signed, raw);
    return 1;
  }
  fmt_t f32;
  fmt_of("f32", &f32);
  bn_t r32;
  int dummy = 0;
  if (N > 128)
    itofp_expand(&f32, raw_int, N, is_signed, &r32);
  else
    op_itofp(&f32, raw_int, N, is_signed, mode, &r32, &dummy);
  num_t y;
  unpack(&f32, &r32, &y);
  op_fpconv(to, &f32, y, mode, raw, &dummy);
  return 1;
}

/* cvtt / fist at width n (signed range): INVALID on NaN, Inf or trunc(x) out of range; else
 * INEXACT iff x is fractional. */
static void cvtt_flags(num_t x, int n, int *fl) {
  if (x.cls == C_NAN || x.cls == C_BAD || x.cls == C_INF) {
    *fl |= X_INVALID;
    return;
  }
  if (x.cls == C_ZERO)
    return;
  bn_t I;
  int frac = 0;
  if (x.e >= 0) {
    if (lead_of(&x) >= n) { /* |trunc| >= 2^n */
      *fl |= X_INVALID;
      return;
    }
    bn_shl(&I, &x.m, (int)x.e);
  } else {
    int64_t s = -x.e;
    if (s > bn_len(&x.m)) {
      bn_zero(&I);
      frac = 1;
    } else {
      frac = bn_below(&x.m, (int)s);
      bn_shr(&I, &x.m, (int)s);
    }
  }
  /* range: -2^(n-1) <= v <= 2^(n-1) - 1 */
  int L = bn_len(&I);
  int inrange;
  if (!x.sign)
    inrange = L <= n - 1;
  else {
    bn_t lim;
    bn_zero(&lim);
    bn_setbit(&lim, n - 1);
    inrange = bn_cmp(&I, &lim) <= 0;
  }
  if (!inrange)
    *fl |= X_INVALID;
  else if (frac)
    *fl |= X_INEXACT;
}

/* IEEE conversion to an n-bit integer, signed or unsigned: INVALID on NaN, Inf or out of range,
 * else INEXACT iff fractional (destinations wider than 64 bits). */
static void ieee_toint_flags(num_t x, int n, int is_signed, int *fl) {
  if (x.cls == C_NAN || x.cls == C_BAD || x.cls == C_INF) {
    *fl |= X_INVALID;
    return;
  }
  if (x.cls == C_ZERO)
    return;
  bn_t I;
  int frac = 0;
  if (x.e >= 0) {
    if (lead_of(&x) >= n) {
      *fl |= X_INVALID;
      return;
    }
    bn_shl(&I, &x.m, (int)x.e);
  } else {
    int64_t s = -x.e;
    if (s > bn_len(&x.m)) {
      bn_zero(&I);
      frac = 1;
    } else {
      frac = bn_below(&x.m, (int)s);
      bn_shr(&I, &x.m, (int)s);
    }
  }
  int L = bn_len(&I), inrange;
  if (is_signed) {
    if (!x.sign)
      inrange = L <= n - 1;
    else {
      bn_t lim;
      bn_zero(&lim);
      bn_setbit(&lim, n - 1);
      inrange = bn_cmp(&I, &lim) <= 0;
    }
  } else {
    inrange = x.sign ? bn_is0(&I) : L <= n;
  }
  if (!inrange)
    *fl |= X_INVALID;
  else if (frac)
    *fl |= X_INEXACT;
}

/* x - (x >= 2^63 ? 2^63 : 0) in format f, then cvtt/fist 64; flags of both. */
static void u64_flags(const fmt_t *f, num_t x, int mode, int *fl) {
  if (x.cls == C_NAN || x.cls == C_BAD) {
    *fl |= X_INVALID; /* the compare and the conversion */
    return;
  }
  num_t two63;
  memset(&two63, 0, sizeof two63);
  two63.cls = C_FIN;
  bn_u64(&two63.m, 1);
  two63.e = 63;
  int dummy = 0;
  int c = op_cmp(x, two63, 0, &dummy);
  if (c >= 0) {
    const fmt_t *af[2] = {f, f};
    bn_t raw;
    op_add(f, af, x, two63, 1, mode, &raw, fl);
    num_t y;
    unpack(f, &raw, &y);
    cvtt_flags(y, 64, fl);
  } else {
    cvtt_flags(x, 64, fl);
  }
}

static void op_toint_exc(const fmt_t *from, num_t x, int N, int is_signed, int mode, int *fl) {
  fmt_t f32;
  if (from->W == 16) { /* f16, bf16: via f32, fpext first */
    fmt_of("f32", &f32);
    bn_t raw;
    op_fpconv(&f32, from, x, mode, &raw, fl);
    unpack(&f32, &raw, &x);
    from = &f32;
  }
  if (N > 64) {
    ieee_toint_flags(x, N, is_signed, fl);
    return;
  }
  int x87 = from->W == 80;
  if (is_signed) {
    int w = N <= (x87 ? 16 : 32) ? (x87 ? 16 : 32) : N <= 32 ? 32 : 64;
    cvtt_flags(x, w, fl);
  } else {
    if (N <= 16)
      cvtt_flags(x, 32, fl);
    else if (N <= 32)
      cvtt_flags(x, 64, fl);
    else
      u64_flags(from, x, mode, fl);
  }
}

/* roundToIntegral: kind 0 floor, 1 ceil, 2 trunc, 3 round (ties away), 4 rint (per mode) */
static void op_rint(const fmt_t *f, const fmt_t *const *af, num_t a, int kind, int mode, bn_t *raw,
                    int *fl) {
  if (nan_prelude(f, af, &a, 1, raw, fl))
    return;
  if (a.cls == C_INF) {
    pack_inf(f, raw, a.sign);
    return;
  }
  if (a.cls == C_ZERO || a.e >= 0) {
    if (a.cls == C_ZERO)
      pack_zero(f, raw, a.sign);
    else
      fe_round(f, raw, a.sign, &a.m, a.e, 0, RM_NE, fl);
    return;
  }
  int m;
  switch (kind) {
  case 0: m = RM_DN; break;
  case 1: m = RM_UP; break;
  case 2: m = RM_TZ; break;
  case 4: m = mode; break;
  default: m = -1; break;
  }
  bn_t I;
  int inex = 0;
  if (m >= 0) {
    round_shift(&I, &a.m, -a.e, 0, m, a.sign, &inex);
  } else { /* ties away: floor(|x| + 1/2) */
    int64_t s = -a.e;
    if (s > bn_len(&a.m) + 1) {
      bn_zero(&I);
      inex = 1;
    } else {
      int rb = bn_bit(&a.m, (int)s - 1);
      inex = rb || bn_below(&a.m, (int)s - 1);
      bn_shr(&I, &a.m, (int)s);
      if (rb) {
        bn_t one;
        bn_u64(&one, 1);
        bn_add(&I, &I, &one);
      }
    }
  }
  if (kind == 4 && inex)
    *fl |= X_INEXACT;
  int dummy = 0;
  if (bn_is0(&I))
    pack_zero(f, raw, a.sign);
  else
    fe_round(f, raw, a.sign, &I, 0, 0, RM_NE, &dummy);
}

/* ---------------------------------------------------------------------------------------------
 * The cqe_op_fn entry point. */

static int read_width_int(const char *w) { /* "i<N>" -> N, 0 if not */
  if (w[0] != 'i' || !w[1])
    return 0;
  long n = 0;
  for (const char *c = w + 1; *c; ++c) {
    if (*c < '0' || *c > '9' || n > (1L << 24))
      return 0;
    n = n * 10 + (*c - '0');
  }
  return (int)n;
}

static void write_out(cqe_val *out, const bn_t *r, int bits) {
  for (uint32_t i = 0; i < out->nw; ++i)
    out->w[i] = (int)i < r->n ? r->w[i] : 0;
  (void)bits;
}

typedef enum {
  K_ADD, K_SUB, K_MUL, K_DIV, K_FMA, K_SQRT, K_FREM, K_FCMP, K_FCMPS, K_FPTRUNC, K_FPEXT,
  K_SITOFP, K_UITOFP, K_FPTOSI, K_FPTOUI, K_FLOOR, K_CEIL, K_TRUNC, K_ROUND, K_RINT, K_FMAX,
  K_FMIN
} kind_t;

static const struct {
  const char *name;
  kind_t k;
  int arity;
} fe_ops[] = {
    {"fadd", K_ADD, 2},       {"fsub", K_SUB, 2},       {"fmul", K_MUL, 2},
    {"fdiv", K_DIV, 2},       {"fma", K_FMA, 3},        {"sqrt", K_SQRT, 1},
    {"frem", K_FREM, 2},      {"fcmp", K_FCMP, 2},      {"fcmps", K_FCMPS, 2},
    {"fptrunc", K_FPTRUNC, 1}, {"fpext", K_FPEXT, 1},   {"sitofp", K_SITOFP, 1},
    {"uitofp", K_UITOFP, 1},  {"fptosi", K_FPTOSI, 1},  {"fptoui", K_FPTOUI, 1},
    {"floor", K_FLOOR, 1},    {"ceil", K_CEIL, 1},      {"trunc", K_TRUNC, 1},
    {"round", K_ROUND, 1},    {"rint", K_RINT, 1},      {"fmax", K_FMAX, 2},
    {"fmin", K_FMIN, 2},
};

static int fe_eval(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  int idx = -1;
  for (size_t i = 0; i < sizeof fe_ops / sizeof fe_ops[0]; ++i)
    if (!strcmp(t->op, fe_ops[i].name))
      idx = (int)i;
  if (idx < 0)
    return CQE_OP_NOT_MINE;
  kind_t k = fe_ops[idx].k;
  int arity = fe_ops[idx].arity;
  if (!t->rm && !t->exc && k != K_FCMPS)
    return CQE_OP_NOT_MINE; /* the plain form: tmpl-fp, tmpl-fpmisc, tmpl-f80 */
  if (k == K_TRUNC && t->to[0])
    return CQE_OP_NOT_MINE; /* the integer cast (tmpl-int); it has no fenv form */
  if (!strcmp(t->w, "f80") || !strcmp(t->to, "f80"))
    return CQE_OP_NOT_MINE; /* tmpl-f80 claims every f80 template, fenv forms included */
  if (nargs != arity + (t->rm ? 1 : 0)) {
    cqe_fail("tmpl-fenv: %s_%s takes %d arguments, got %d", t->op, t->w, arity + (t->rm ? 1 : 0),
             nargs);
    return -1;
  }
  int mode = RM_NE;
  if (t->rm) {
    const cqe_val *mv = &args[arity];
    uint64_t m = (mv->nw && mv->w) ? mv->w[0] : 0;
    mode = (int)((m >> 10) & 3);
  }
  int fl = 0;
  bn_t raw;
  bn_zero(&raw);
  int resbits;

  int int_src = k == K_SITOFP || k == K_UITOFP;
  int int_dst = k == K_FPTOSI || k == K_FPTOUI;
  int conv = int_src || int_dst || k == K_FPTRUNC || k == K_FPEXT;
  fmt_t fs, fd; /* source, destination formats */
  int Ns = 0, Nd = 0;
  if (int_src) {
    Ns = read_width_int(t->w);
    if (!Ns || !fmt_of(t->to, &fd)) {
      cqe_fail("tmpl-fenv: bad widths %s_to_%s", t->w, t->to);
      return -1;
    }
  } else if (!fmt_of(t->w, &fs)) {
    cqe_fail("tmpl-fenv: %s is not a floating-point width", t->w);
    return -1;
  }
  if (int_dst) {
    Nd = read_width_int(t->to);
    if (!Nd) {
      cqe_fail("tmpl-fenv: bad destination width %s", t->to);
      return -1;
    }
  } else if (conv && !int_src && !fmt_of(t->to, &fd)) {
    cqe_fail("tmpl-fenv: bad destination width %s", t->to);
    return -1;
  }
  if (!conv)
    fd = fs;

  num_t x[3];
  bn_t ibits;
  if (int_src) {
    val_to_bn(&ibits, &args[0], Ns);
  } else {
    for (int i = 0; i < arity; ++i) {
      bn_t r;
      val_to_bn(&r, &args[i], fs.W);
      unpack(&fs, &r, &x[i]);
    }
  }
  const fmt_t *af[3] = {&fs, &fs, &fs};

  int is_cmp = 0, cmpv = 0;
  switch (k) {
  case K_ADD: op_add(&fd, af, x[0], x[1], 0, mode, &raw, &fl); break;
  case K_SUB: op_add(&fd, af, x[0], x[1], 1, mode, &raw, &fl); break;
  case K_MUL: op_mul(&fd, af, x[0], x[1], mode, &raw, &fl); break;
  case K_DIV: op_div(&fd, af, x[0], x[1], mode, &raw, &fl); break;
  case K_FMA: op_fma(&fd, af, x[0], x[1], x[2], mode, &raw, &fl); break;
  case K_SQRT: op_sqrt(&fd, af, x[0], mode, &raw, &fl); break;
  case K_FREM: op_frem(&fd, af, x[0], x[1], &raw, &fl); break;
  case K_FCMP:
  case K_FCMPS: {
    int ok;
    int r = op_cmp(x[0], x[1], k == K_FCMPS, &fl);
    cmpv = pred_holds(t->pred, r, &ok);
    if (!ok) {
      cqe_fail("tmpl-fenv: unknown fcmp predicate '%s'", t->pred);
      return -1;
    }
    is_cmp = 1;
    break;
  }
  case K_FPTRUNC:
  case K_FPEXT:
    op_fpconv(&fd, &fs, x[0], mode, &raw, &fl); /* to bf16: compiler-rt, IEEE (CR §2 bf16 row) */
    break;
  case K_SITOFP:
  case K_UITOFP: {
    op_itofp(&fd, &ibits, Ns, k == K_SITOFP, mode, &raw, &fl); /* flags: IEEE in the mode */
    bn_t v;
    if (itofp_value(&fd, &ibits, Ns, k == K_SITOFP, mode, &v))
      raw = v;
    break;
  }
  case K_FPTOSI:
  case K_FPTOUI:
    if (!t->exc)
      fe_unimplemented("%s value form under a rounding mode (no constrained form has one)", t->op);
    op_toint_exc(&fs, x[0], Nd, k == K_FPTOSI, mode, &fl);
    break;
  case K_FLOOR: op_rint(&fd, af, x[0], 0, mode, &raw, &fl); break;
  case K_CEIL: op_rint(&fd, af, x[0], 1, mode, &raw, &fl); break;
  case K_TRUNC: op_rint(&fd, af, x[0], 2, mode, &raw, &fl); break;
  case K_ROUND: op_rint(&fd, af, x[0], 3, mode, &raw, &fl); break;
  case K_RINT: op_rint(&fd, af, x[0], 4, mode, &raw, &fl); break;
  case K_FMAX:
  case K_FMIN: {
    /* exceptions: INVALID iff a signaling NaN (or an invalid f80 encoding) is an operand.
     * value (CR §2): isnan(a) ? b : isnan(b) ? a : (b > a ? b : a), min with <. */
    for (int i = 0; i < 2; ++i)
      if (x[i].cls == C_BAD || (x[i].cls == C_NAN && !x[i].quiet))
        fl |= X_INVALID;
    int dummy = 0;
    int pick_b;
    if (x[0].cls == C_NAN || x[0].cls == C_BAD)
      pick_b = 1;
    else if (x[1].cls == C_NAN || x[1].cls == C_BAD)
      pick_b = 0;
    else {
      int r = op_cmp(x[1], x[0], 0, &dummy);
      pick_b = k == K_FMAX ? r == 1 : r == -1;
    }
    val_to_bn(&raw, &args[pick_b], fs.W);
    break;
  }
  }

  if (t->exc) {
    resbits = 32;
    bn_u64(&raw, (uint64_t)fl);
  } else if (is_cmp) {
    resbits = 1;
    bn_u64(&raw, (uint64_t)cmpv);
  } else if (int_dst) {
    fe_unimplemented("%s value form", t->op);
  } else {
    resbits = fd.W;
  }
  if (out->bits != (uint32_t)resbits || out->nw * 64 < (uint32_t)resbits) {
    cqe_fail("tmpl-fenv: result width %u, expected %d", out->bits, resbits);
    return -1;
  }
  write_out(out, &raw, resbits);
  return 0;
}

__attribute__((constructor)) static void fe_register(void) {
  for (size_t i = 0; i < sizeof fe_ops / sizeof fe_ops[0]; ++i)
    cqe_register_op(fe_ops[i].name, fe_eval);
}
