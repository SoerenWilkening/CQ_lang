/* Checker template family: fp arithmetic at f16/bf16/f32/f64 (cq-w0-tmpl-fp; bf16 cq-jtx).
 *
 * Evaluator semantics of the templates fadd fsub fmul fdiv fneg sqrt fma frem on basis values, per
 * CONSTRUCTION_RULES §2 (wins) and BACKEND_ABI §2.9:
 *   - IEEE 754 binary16/32/64 and bfloat16 (8 exponent bits, 7 fraction bits; CR §1.1 at CQ_spec
 *     3aaafe1: same rounding and NaN rules as the IEEE widths) with subnormals, round to nearest
 *     even, one rounding per operation
 *     (fma fused: one rounding of the exact x*y+z);
 *   - a NaN result follows the x86 SSE rule in IR operand order: the first NaN operand, quieted;
 *     an invalid operation gives the default NaN (sign 1, exponent all ones, top fraction bit:
 *     f64 0xFFF8000000000000, f32 0xFFC00000, f16 0xFE00, bf16 0xFFC0);
 *   - fneg flips bit W-1 and nothing else (no quieting);
 *   - frem is IEEE fmod (exact): sign of x; fmod(x, 0) = fmod(±Inf, y) = default NaN;
 *     fmod(x, ±Inf) = x; NaN propagates by the rule above.
 *
 * The arithmetic is integer soft-float, generic over the format (exponent bits, fraction bits):
 * every operation forms its exact result (or, for fdiv and sqrt, p+2 significant bits plus a
 * sticky bit) and rounds once in tf_round_pack. It never touches the host FPU, so the host
 * rounding mode and exception flags (driven by the fenv family) cannot affect it.
 *
 * Scope: the plain forms at f16/bf16/f32/f64. The _rm/_rmq/_exc forms belong to tmpl-fenv and every
 * f80 form to tmpl-f80; for those the op returns CQE_OP_NOT_MINE, decided from the name alone,
 * without touching out or calling cqe_fail.
 *
 * Calling convention: the M1 handler contract in cqe.h. args are every argument of the forward
 * form in signature order (for these plain forms, the data operands in IR operand order), each
 * resolved to a value. out is the dispatcher's: out->w non-NULL and zeroed, out->nw =
 * ceil(out->bits / 64), out->bits and out->kind preset to the result type. The op writes the
 * value into out->w (tf_store_result, the only place it is touched) and returns 0; on a
 * malformed call it reports cqe_fail and returns -1. It computes the forward value whatever
 * tname->unc says; the dispatcher applies the XOR (BACKEND_ABI §2.1).
 */
#include <stdint.h>
#include <string.h>

#include "cqe.h"

typedef unsigned __int128 tf_u128;

/* ---- formats ------------------------------------------------------------------------------- */

typedef struct {
  unsigned bits;  /* W */
  unsigned eb;    /* exponent bits */
  unsigned mb;    /* stored fraction bits; precision p = mb + 1 */
} tf_fmt;

/* The formats the template grammar names below f80: the IEEE interchange widths and bf16. */
static int tf_format(const char *w, tf_fmt *f) {
  if (!strcmp(w, "f16")) { *f = (tf_fmt){16, 5, 10}; return 1; }
  if (!strcmp(w, "bf16")) { *f = (tf_fmt){16, 8, 7}; return 1; }
  if (!strcmp(w, "f32")) { *f = (tf_fmt){32, 8, 23}; return 1; }
  if (!strcmp(w, "f64")) { *f = (tf_fmt){64, 11, 52}; return 1; }
  return 0;
}

static int tf_bias(const tf_fmt *f) { return (1 << (f->eb - 1)) - 1; }
static int tf_emin(const tf_fmt *f) { return 1 - tf_bias(f); }
static uint64_t tf_mask(const tf_fmt *f) { return f->bits == 64 ? ~(uint64_t)0 : (((uint64_t)1 << f->bits) - 1); }
static uint64_t tf_sign_bit(const tf_fmt *f) { return (uint64_t)1 << (f->bits - 1); }
static uint64_t tf_exp_mask(const tf_fmt *f) { return (((uint64_t)1 << f->eb) - 1) << f->mb; }
static uint64_t tf_frac_mask(const tf_fmt *f) { return ((uint64_t)1 << f->mb) - 1; }
static uint64_t tf_quiet_bit(const tf_fmt *f) { return (uint64_t)1 << (f->mb - 1); }

static uint64_t tf_inf(const tf_fmt *f, int sign) { return (sign ? tf_sign_bit(f) : 0) | tf_exp_mask(f); }
static uint64_t tf_default_nan(const tf_fmt *f) { return tf_sign_bit(f) | tf_exp_mask(f) | tf_quiet_bit(f); }
static uint64_t tf_max_finite(const tf_fmt *f, int sign) {
  return (sign ? tf_sign_bit(f) : 0) | (tf_exp_mask(f) - ((uint64_t)1 << f->mb)) | tf_frac_mask(f);
}

/* ---- unpacked values ----------------------------------------------------------------------- */

enum { TF_ZERO, TF_FINITE, TF_INF, TF_NAN };

typedef struct {
  int cls, sign;
  uint64_t m;  /* finite: value = m * 2^e, m > 0; zero: m = 0 */
  int e;
} tf_val;

static tf_val tf_unpack(const tf_fmt *f, uint64_t x) {
  tf_val v;
  uint64_t ex = (x & tf_exp_mask(f)) >> f->mb, fr = x & tf_frac_mask(f);
  v.sign = (x & tf_sign_bit(f)) != 0;
  v.e = tf_emin(f) - (int)f->mb;
  v.m = 0;
  if (ex == ((uint64_t)1 << f->eb) - 1) {
    v.cls = fr ? TF_NAN : TF_INF;
  } else if (ex == 0) {
    v.cls = fr ? TF_FINITE : TF_ZERO;
    v.m = fr;
  } else {
    v.cls = TF_FINITE;
    v.m = fr | ((uint64_t)1 << f->mb);
    v.e = (int)ex - tf_bias(f) - (int)f->mb;
  }
  return v;
}

static uint64_t tf_quiet(const tf_fmt *f, uint64_t x) { return x | tf_quiet_bit(f); }

static uint64_t tf_zero(const tf_fmt *f, int sign) { return sign ? tf_sign_bit(f) : 0; }

/* ---- a fixed-size unsigned bignum, for the exact aligned sums of fadd/fsub/fma --------------- */

#define TF_NW 72 /* 4608 bits: the widest exact fma sum at f64 spans about 3200 bits */

typedef struct { uint64_t w[TF_NW]; } tf_bn;

static void tf_fatal(const char *what) {
  cqe_fail("tmpl-fp: internal error: %s", what);
}

static void tf_bn_from_u128(tf_bn *a, tf_u128 v) {
  memset(a, 0, sizeof *a);
  a->w[0] = (uint64_t)v;
  a->w[1] = (uint64_t)(v >> 64);
}

static int tf_bn_bitlen(const tf_bn *a) {
  for (int i = TF_NW - 1; i >= 0; --i)
    if (a->w[i])
      return i * 64 + 64 - __builtin_clzll(a->w[i]);
  return 0;
}

static int tf_bn_is_zero(const tf_bn *a) { return tf_bn_bitlen(a) == 0; }

/* a <<= s. Returns 0 if bits would be lost. */
static int tf_bn_shl(tf_bn *a, int s) {
  if (s == 0)
    return 1;
  if (tf_bn_bitlen(a) + s > TF_NW * 64)
    return 0;
  int ws = s / 64, bs = s % 64;
  for (int i = TF_NW - 1; i >= 0; --i) {
    uint64_t hi = i - ws >= 0 ? a->w[i - ws] : 0;
    uint64_t lo = i - ws - 1 >= 0 ? a->w[i - ws - 1] : 0;
    a->w[i] = bs ? (hi << bs) | (lo >> (64 - bs)) : hi;
  }
  return 1;
}

static int tf_bn_cmp(const tf_bn *a, const tf_bn *b) {
  for (int i = TF_NW - 1; i >= 0; --i)
    if (a->w[i] != b->w[i])
      return a->w[i] < b->w[i] ? -1 : 1;
  return 0;
}

/* a += b. Returns 0 on overflow. */
static int tf_bn_add(tf_bn *a, const tf_bn *b) {
  unsigned c = 0;
  for (int i = 0; i < TF_NW; ++i) {
    tf_u128 s = (tf_u128)a->w[i] + b->w[i] + c;
    a->w[i] = (uint64_t)s;
    c = (unsigned)(s >> 64);
  }
  return c == 0;
}

/* a -= b, a >= b. */
static void tf_bn_sub(tf_bn *a, const tf_bn *b) {
  uint64_t br = 0;
  for (int i = 0; i < TF_NW; ++i) {
    uint64_t x = a->w[i], y = b->w[i];
    uint64_t d = x - y - br;
    br = (x < y) || (x == y && br) ? 1 : 0;
    a->w[i] = d;
  }
}

static int tf_bn_bit(const tf_bn *a, int i) { return (int)((a->w[i / 64] >> (i % 64)) & 1u); }

/* any bit below position i set (i >= 0) */
static int tf_bn_any_below(const tf_bn *a, int i) {
  int wi = i / 64, bi = i % 64;
  for (int k = 0; k < wi; ++k)
    if (a->w[k])
      return 1;
  return bi ? (a->w[wi] & (((uint64_t)1 << bi) - 1)) != 0 : 0;
}

/* bits [k, k+64) of a */
static uint64_t tf_bn_extract(const tf_bn *a, int k) {
  int wi = k / 64, bi = k % 64;
  uint64_t lo = wi < TF_NW ? a->w[wi] : 0;
  uint64_t hi = wi + 1 < TF_NW ? a->w[wi + 1] : 0;
  return bi ? (lo >> bi) | (hi << (64 - bi)) : lo;
}

/* ---- rounding ------------------------------------------------------------------------------ */

/* Rounding direction, the CR §1.2 encoding of bits 10-11 (only RNE is reachable from this
 * family's plain forms; the others keep the rounder total). */
enum { TF_RNE = 0, TF_RD = 1, TF_RU = 2, TF_RZ = 3 };

/* The format's bit pattern nearest to (-1)^sign * (M + s) * 2^E, M > 0, where s in [0, 1) is
 * nonzero iff sticky. When sticky is set the caller guarantees bitlen(M) >= p + 2, so the
 * rounding position lies above E. */
static uint64_t tf_round_pack(const tf_fmt *f, int sign, const tf_bn *M, int E, int sticky, int rm) {
  int p = (int)f->mb + 1;
  int L = tf_bn_bitlen(M);
  if (L == 0) {
    tf_fatal("round_pack of zero");
    return 0;
  }
  if (sticky && L < p + 2) {
    tf_fatal("round_pack: sticky with fewer than p+2 bits");
    return 0;
  }
  int e = E + L - 1;               /* exponent of the leading bit */
  int qmin = tf_emin(f) - (p - 1); /* exponent of the least subnormal bit */
  int q = e - (p - 1) > qmin ? e - (p - 1) : qmin;
  uint64_t r;
  int half = 0, rest = sticky;
  if (q <= E) {
    int s = E - q; /* exact, L + s <= p */
    r = tf_bn_extract(M, 0) << s;
  } else {
    int k = q - E;
    if (k > TF_NW * 64) {
      r = 0;
      rest = 1;
    } else {
      r = tf_bn_extract(M, k);
      if (k - 1 < TF_NW * 64) {
        half = tf_bn_bit(M, k - 1);
        rest = rest || tf_bn_any_below(M, k - 1);
      } else {
        rest = 1;
      }
    }
    int up = 0;
    switch (rm) {
    case TF_RNE: up = half && (rest || (r & 1)); break;
    case TF_RZ: up = 0; break;
    case TF_RU: up = (half || rest) && !sign; break;
    case TF_RD: up = (half || rest) && sign; break;
    }
    r += (uint64_t)up;
    if (r == (uint64_t)1 << p) {
      r >>= 1;
      q += 1;
    }
  }
  uint64_t sb = sign ? tf_sign_bit(f) : 0;
  if (r < (uint64_t)1 << (p - 1)) /* subnormal or zero: biased exponent 0 */
    return sb | r;
  int64_t be = (int64_t)q + (p - 1) + tf_bias(f);
  if (be >= ((int64_t)1 << f->eb) - 1) { /* overflow */
    int to_inf = rm == TF_RNE || (rm == TF_RU && !sign) || (rm == TF_RD && sign);
    return to_inf ? tf_inf(f, sign) : tf_max_finite(f, sign);
  }
  return sb | ((uint64_t)be << f->mb) | (r & tf_frac_mask(f));
}

static uint64_t tf_round_u128(const tf_fmt *f, int sign, tf_u128 m, int e, int sticky, int rm) {
  tf_bn M;
  tf_bn_from_u128(&M, m);
  return tf_round_pack(f, sign, &M, e, sticky, rm);
}

/* ---- operations ---------------------------------------------------------------------------- */

/* The x86 SSE NaN rule (CR §2): the first NaN operand in IR order, quieted. 1 if one was found. */
static int tf_first_nan(const tf_fmt *f, const uint64_t *x, const tf_val *v, int n, uint64_t *out) {
  for (int i = 0; i < n; ++i)
    if (v[i].cls == TF_NAN) {
      *out = tf_quiet(f, x[i]);
      return 1;
    }
  return 0;
}

/* Sign of an exact zero sum of two terms with signs sa, sb (IEEE 754 §6.3). */
static int tf_zero_sum_sign(int sa, int sb, int rm) { return sa == sb ? sa : rm == TF_RD; }

/* (-1)^sa ma 2^ea + (-1)^sb mb 2^eb, exact, then one rounding. Either magnitude may be 0. */
static uint64_t tf_exact_sum(const tf_fmt *f, int sa, const tf_bn *ma, int ea, int sb, const tf_bn *mb, int eb,
                             int rm) {
  tf_bn A = *ma, B = *mb;
  int E = ea < eb ? ea : eb;
  if (!tf_bn_shl(&A, ea - E) || !tf_bn_shl(&B, eb - E)) {
    tf_fatal("aligned sum exceeds the bignum");
    return 0;
  }
  int sign;
  if (sa == sb) {
    if (!tf_bn_add(&A, &B)) {
      tf_fatal("aligned sum overflows the bignum");
      return 0;
    }
    sign = sa;
  } else {
    int c = tf_bn_cmp(&A, &B);
    if (c == 0)
      return tf_zero(f, tf_zero_sum_sign(sa, sb, rm));
    if (c > 0) {
      tf_bn_sub(&A, &B);
      sign = sa;
    } else {
      tf_bn_sub(&B, &A);
      A = B;
      sign = sb;
    }
  }
  if (tf_bn_is_zero(&A))
    return tf_zero(f, tf_zero_sum_sign(sa, sb, rm));
  return tf_round_pack(f, sign, &A, E, 0, rm);
}

static uint64_t tf_add(const tf_fmt *f, uint64_t xa, uint64_t xb, int negate_b, int rm) {
  uint64_t x[2] = {xa, xb}, r;
  tf_val v[2] = {tf_unpack(f, xa), tf_unpack(f, xb)};
  if (tf_first_nan(f, x, v, 2, &r))
    return r;
  tf_val a = v[0], b = v[1];
  b.sign ^= negate_b;
  if (a.cls == TF_INF && b.cls == TF_INF)
    return a.sign == b.sign ? tf_inf(f, a.sign) : tf_default_nan(f);
  if (a.cls == TF_INF)
    return tf_inf(f, a.sign);
  if (b.cls == TF_INF)
    return tf_inf(f, b.sign);
  tf_bn A, B;
  tf_bn_from_u128(&A, a.m);
  tf_bn_from_u128(&B, b.m);
  return tf_exact_sum(f, a.sign, &A, a.e, b.sign, &B, b.e, rm);
}

static uint64_t tf_mul(const tf_fmt *f, uint64_t xa, uint64_t xb, int rm) {
  uint64_t x[2] = {xa, xb}, r;
  tf_val v[2] = {tf_unpack(f, xa), tf_unpack(f, xb)};
  if (tf_first_nan(f, x, v, 2, &r))
    return r;
  int s = v[0].sign ^ v[1].sign;
  if (v[0].cls == TF_INF || v[1].cls == TF_INF) {
    if (v[0].cls == TF_ZERO || v[1].cls == TF_ZERO)
      return tf_default_nan(f);
    return tf_inf(f, s);
  }
  if (v[0].cls == TF_ZERO || v[1].cls == TF_ZERO)
    return tf_zero(f, s);
  return tf_round_u128(f, s, (tf_u128)v[0].m * v[1].m, v[0].e + v[1].e, 0, rm);
}

/* Shift a finite m left until its leading bit is at position p-1, adjusting e. */
static void tf_normalize(const tf_fmt *f, tf_val *v) {
  int p = (int)f->mb + 1;
  while (!(v->m >> (p - 1))) {
    v->m <<= 1;
    v->e -= 1;
  }
}

static uint64_t tf_div(const tf_fmt *f, uint64_t xa, uint64_t xb, int rm) {
  uint64_t x[2] = {xa, xb}, r;
  tf_val v[2] = {tf_unpack(f, xa), tf_unpack(f, xb)};
  if (tf_first_nan(f, x, v, 2, &r))
    return r;
  tf_val a = v[0], b = v[1];
  int s = a.sign ^ b.sign;
  if (a.cls == TF_INF)
    return b.cls == TF_INF ? tf_default_nan(f) : tf_inf(f, s);
  if (b.cls == TF_INF)
    return tf_zero(f, s);
  if (b.cls == TF_ZERO)
    return a.cls == TF_ZERO ? tf_default_nan(f) : tf_inf(f, s);
  if (a.cls == TF_ZERO)
    return tf_zero(f, s);
  int p = (int)f->mb + 1;
  tf_normalize(f, &a);
  tf_normalize(f, &b);
  int sh = p + 2; /* quotient in [2^(p+1), 2^(p+3)): at least p+2 bits */
  tf_u128 num = (tf_u128)a.m << sh;
  tf_u128 q = num / b.m, rem = num % b.m;
  return tf_round_u128(f, s, q, a.e - b.e - sh, rem != 0, rm);
}

static tf_u128 tf_isqrt(tf_u128 n) {
  tf_u128 res = 0, bit = (tf_u128)1 << 126;
  while (bit > n)
    bit >>= 2;
  while (bit) {
    if (n >= res + bit) {
      n -= res + bit;
      res = (res >> 1) + bit;
    } else {
      res >>= 1;
    }
    bit >>= 2;
  }
  return res;
}

static uint64_t tf_sqrt(const tf_fmt *f, uint64_t xa, int rm) {
  tf_val a = tf_unpack(f, xa);
  if (a.cls == TF_NAN)
    return tf_quiet(f, xa);
  if (a.cls == TF_ZERO)
    return xa; /* sqrt(±0) = ±0 */
  if (a.sign)
    return tf_default_nan(f); /* negative nonzero, -Inf included */
  if (a.cls == TF_INF)
    return xa;
  int p = (int)f->mb + 1;
  tf_normalize(f, &a);
  int sh = p + 4; /* N = m << sh has 2p+4 bits or more; the root has p+2 or more */
  if ((a.e - sh) & 1)
    sh += 1;
  tf_u128 n = (tf_u128)a.m << sh;
  tf_u128 rt = tf_isqrt(n);
  return tf_round_u128(f, 0, rt, (a.e - sh) / 2, rt * rt != n, rm);
}

static uint64_t tf_fma(const tf_fmt *f, uint64_t xa, uint64_t xb, uint64_t xc, int rm) {
  uint64_t x[3] = {xa, xb, xc}, r;
  tf_val v[3] = {tf_unpack(f, xa), tf_unpack(f, xb), tf_unpack(f, xc)};
  if (tf_first_nan(f, x, v, 3, &r))
    return r;
  int sp = v[0].sign ^ v[1].sign;
  int pinf = v[0].cls == TF_INF || v[1].cls == TF_INF;
  int pzero = v[0].cls == TF_ZERO || v[1].cls == TF_ZERO;
  if (pinf && pzero)
    return tf_default_nan(f);
  if (pinf)
    return v[2].cls == TF_INF && v[2].sign != sp ? tf_default_nan(f) : tf_inf(f, sp);
  if (v[2].cls == TF_INF)
    return tf_inf(f, v[2].sign);
  tf_bn P, C;
  tf_bn_from_u128(&P, (tf_u128)v[0].m * v[1].m);
  tf_bn_from_u128(&C, v[2].m);
  return tf_exact_sum(f, sp, &P, v[0].e + v[1].e, v[2].sign, &C, v[2].e, rm);
}

static uint64_t tf_rem(const tf_fmt *f, uint64_t xa, uint64_t xb) {
  uint64_t x[2] = {xa, xb}, r;
  tf_val v[2] = {tf_unpack(f, xa), tf_unpack(f, xb)};
  if (tf_first_nan(f, x, v, 2, &r))
    return r;
  tf_val a = v[0], b = v[1];
  if (a.cls == TF_INF || b.cls == TF_ZERO)
    return tf_default_nan(f);
  if (b.cls == TF_INF || a.cls == TF_ZERO)
    return xa;
  /* Both finite nonzero; the remainder is exact and smaller than |b|. */
  tf_u128 rm;
  int e;
  if (a.e >= b.e) {
    rm = a.m % b.m;
    for (int i = 0; i < a.e - b.e; ++i)
      rm = (rm << 1) % b.m;
    e = b.e;
  } else {
    int d = b.e - a.e;
    if (d >= (int)f->mb + 1) {
      rm = a.m; /* |b| >= 2^d > a.m */
    } else {
      rm = a.m % ((tf_u128)b.m << d);
    }
    e = a.e;
  }
  if (rm == 0)
    return tf_zero(f, a.sign);
  return tf_round_u128(f, a.sign, rm, e, 0, TF_RNE);
}

/* ---- the cqe_op_fn entry ------------------------------------------------------------------- */

enum { TF_OP_FADD, TF_OP_FSUB, TF_OP_FMUL, TF_OP_FDIV, TF_OP_FNEG, TF_OP_SQRT, TF_OP_FMA, TF_OP_FREM };

static const struct {
  const char *name;
  int arity;
} tf_ops[] = {
    [TF_OP_FADD] = {"fadd", 2}, [TF_OP_FSUB] = {"fsub", 2}, [TF_OP_FMUL] = {"fmul", 2}, [TF_OP_FDIV] = {"fdiv", 2},
    [TF_OP_FNEG] = {"fneg", 1}, [TF_OP_SQRT] = {"sqrt", 1}, [TF_OP_FMA] = {"fma", 3},   [TF_OP_FREM] = {"frem", 2},
};

static int tf_op_index(const char *op) {
  for (int i = 0; i < (int)(sizeof tf_ops / sizeof tf_ops[0]); ++i)
    if (!strcmp(op, tf_ops[i].name))
      return i;
  return -1;
}

/* The one place the result buffer is touched (M1: the dispatcher owns out). Writes word 0 of the
 * zeroed buffer and nothing else: never allocates, and leaves out->w, out->nw, out->bits and
 * out->kind as preset. A preset that does not match the template's result type is reported. */
static int tf_store_result(const cqe_tname *t, const tf_fmt *f, cqe_val *out, uint64_t r) {
  if (!out->w || out->nw < 1 || out->bits != f->bits || out->kind != 'f') {
    cqe_fail("tmpl-fp: %s_%s: result buffer preset to bits %u kind '%c' nw %u, expected %s (%u bits, kind 'f')",
             t->op, t->w, out->bits, out->kind ? out->kind : '?', out->nw, t->w, f->bits);
    return -1;
  }
  out->w[0] = r & tf_mask(f);
  return 0;
}

static int tf_eval(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  int op = tf_op_index(t->op);
  if (op < 0) {
    cqe_fail("tmpl-fp: op '%s' is not an fp arithmetic op", t->op);
    return -1;
  }
  if (t->rm || t->exc || !strcmp(t->w, "f80"))
    return CQE_OP_NOT_MINE; /* tmpl-fenv, tmpl-f80 */
  tf_fmt f;
  if (!tf_format(t->w, &f)) {
    cqe_fail("tmpl-fp: %s at width '%s': not an fp format", t->op, t->w);
    return -1;
  }
  if (t->pred[0] || t->to[0] || t->strided) {
    cqe_fail("tmpl-fp: %s_%s: predicate, _to_ or stride on an fp arithmetic op", t->op, t->w);
    return -1;
  }
  int n = tf_ops[op].arity;
  if (nargs != n) {
    cqe_fail("tmpl-fp: %s_%s takes %d data operands, got %d", t->op, t->w, n, nargs);
    return -1;
  }
  if (t->shape[0]) {
    if ((int)strlen(t->shape) != n) {
      cqe_fail("tmpl-fp: %s_%s: shape '%s' does not cover %d operands", t->op, t->w, t->shape, n);
      return -1;
    }
    for (const char *s = t->shape; *s; ++s)
      if (*s != 'h' && *s != 'q' && *s != 'l') {
        cqe_fail("tmpl-fp: %s_%s: bad shape letter in '%s'", t->op, t->w, t->shape);
        return -1;
      }
  }
  uint64_t x[3] = {0, 0, 0};
  for (int i = 0; i < n; ++i) {
    if (args[i].bits != f.bits || args[i].nw < 1 || !args[i].w) {
      cqe_fail("tmpl-fp: %s_%s operand %d has width %u, expected %u", t->op, t->w, i, args[i].bits, f.bits);
      return -1;
    }
    x[i] = args[i].w[0] & tf_mask(&f);
  }
  uint64_t r = 0;
  switch (op) {
  case TF_OP_FADD: r = tf_add(&f, x[0], x[1], 0, TF_RNE); break;
  case TF_OP_FSUB: r = tf_add(&f, x[0], x[1], 1, TF_RNE); break;
  case TF_OP_FMUL: r = tf_mul(&f, x[0], x[1], TF_RNE); break;
  case TF_OP_FDIV: r = tf_div(&f, x[0], x[1], TF_RNE); break;
  case TF_OP_FNEG: r = x[0] ^ tf_sign_bit(&f); break;
  case TF_OP_SQRT: r = tf_sqrt(&f, x[0], TF_RNE); break;
  case TF_OP_FMA: r = tf_fma(&f, x[0], x[1], x[2], TF_RNE); break;
  case TF_OP_FREM: r = tf_rem(&f, x[0], x[1]); break;
  }
  return tf_store_result(t, &f, out, r);
}

__attribute__((constructor)) static void tf_register(void) {
  for (int i = 0; i < (int)(sizeof tf_ops / sizeof tf_ops[0]); ++i)
    cqe_register_op(tf_ops[i].name, tf_eval);
}
