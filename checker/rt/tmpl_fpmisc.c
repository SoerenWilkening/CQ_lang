/* Checker template family: fp compare, fp misc and fp casts at f16/bf16/f32/f64 (cq-w0-tmpl-fpmisc,
 * bf16: cq-b7e).
 *
 * Evaluator semantics, on basis values, of the templates
 *   fcmp fabs copysign fmax fmin floor ceil trunc rint round is_fpclass
 *   fpext fptrunc sitofp uitofp fptosi fptoui
 * per CONSTRUCTION_RULES §2 (wins) and BACKEND_ABI §2.4, §2.6, §2.10.
 *
 * Everything is soft: fp values are bit patterns, integers are two's complement on N bits in
 * little-endian 64-bit words, any N >= 1. Nothing here touches the host FPU, so the host rounding
 * mode and exception flags (used by the fenv family) neither affect nor see these ops. The fp
 * formats are described by their exponent and fraction widths (f16 5/10, bf16 8/7, f32 8/23,
 * f64 11/52); the code is generic over them. bf16 follows the same rounding and NaN rules as the
 * IEEE widths (CR §1.1).
 *
 * Semantics, where §2 or x86-64 LLVM 19 -O1 code fixes a choice:
 *   - fcmp: LLVM predicates, o = ordered and, u = unordered or; ±0 equal; i1 result.
 *   - fmax/fmin (llvm.maxnum/minnum): isnan(a) ? b : isnan(b) ? a : (b > a ? b : a), min with <;
 *     operands returned bit for bit (no quieting), equal values give a (CR §2).
 *   - floor ceil trunc rint round: IEEE roundToIntegral, rint ties to even whatever the dynamic
 *     mode, round ties away; a NaN comes back quieted with its payload; -0 and signs preserved.
 *   - is_fpclass(h, mask): LLVM class bits 0 sNaN .. 9 +Inf; a pure bit test.
 *   - fpext exact; fptrunc RNE with subnormals and overflow to Inf; a NaN is quieted, its payload
 *     left-aligned (fpext) or truncated on the right (fptrunc), as x86 and compiler-rt.
 *     Direction follows clang 19's spelling over the order f16 < bf16 < f32 < f64: (__bf16) of a
 *     _Float16 is fpext_f16_to_bf16 (rounds to 8 bits), (_Float16) of a __bf16 is
 *     fptrunc_bf16_to_f16 (overflows to Inf, rounds subnormals); both are the same correctly rounded
 *     conversion. The reverse spellings are malformed.
 *   - sitofp/uitofp: correctly rounded, RNE, from any width.
 *   - fptosi/fptoui: in range, truncation toward 0. Out of range, NaN, ±Inf: the x86-64 LLVM 19
 *     -O1 result (CR §2 row, f16 and bf16 via f32), extended to every width the way LLVM legalizes it:
 *       with c32/c64 = cvtt to i32/i64 (indefinite INT_MIN of that width) and fixN = the
 *       compiler-rt __fixXfti rule at width F (|x| < 1 -> 0; unbiased exponent >= F, NaN, Inf ->
 *       sign ? INT_MIN_F : INT_MAX_F; otherwise sign * trunc(|x|) mod 2^F), fixuN its unsigned
 *       twin (negative or |x| < 1 -> 0; exponent >= F, NaN, Inf -> 2^F - 1):
 *         fptosi  N <= 32: trunc(c32)   33..64: trunc(c64)   65..128: trunc(fix128)
 *                 N > 128: LLVM's ExpandLargeFpConvert (fm_expand)
 *         fptoui  N <= 31: trunc(c32)   32..63: trunc(c64)   64: r1 | (r2 & (r1 >>s 63))
 *                 65..128: trunc(fixu128)   N > 128: fm_expand, the same as fptosi
 *     CR §2 fixes i8 i16 i32 i64; the other widths are what the same legalization produces
 *     (measured against native code in tests/tmpl-fpmisc/).
 *
 * f80 operands or results are the f80 family's (cq-w0-tmpl-f80); _rm/_rmq/_exc forms and fcmps are
 * the fenv family's (cq-w0-tmpl-fenv); trunc with _to_ is the integer cast (cq-w0-tmpl-int). For
 * those names an op here returns CQE_OP_NOT_MINE (1) without logging anything and without touching
 * out, and the dispatcher tries the next handler registered under the op name (cq-mgi, cq-arch M1).
 *
 * Calling convention (cqe_op_fn, cqe.h): args are the DATA operands in signature order, resolved to
 * values (handle or literal, whatever the shape says; cq-arch M1). The shape letters do not matter
 * here: the op is f(args[0], args[1], ...). The core owns out: out->w holds out->nw words, bits and
 * kind preset; the op writes every word (bits above the result width zero), never reallocates, and
 * returns 0. On a malformed call it calls cqe_fail and returns -1. Forward and _unc are the same
 * XOR map (BACKEND_ABI §2.1); the op computes f(args) whatever t->unc says and the core XORs it in.
 */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

/* cq-mgi / cq-arch M1: not this family's template; no cqe_fail, out untouched. */
#ifndef CQE_OP_NOT_MINE
#define CQE_OP_NOT_MINE 1
#endif

/* ---------------------------------------------------------------- multiword integers */

static uint32_t fm_nwords(uint32_t bits) { return (bits + 63u) / 64u; }

static uint64_t *fm_alloc(uint32_t nw) {
  uint64_t *r = calloc(nw ? nw : 1, sizeof *r);
  if (!r)
    abort();
  return r;
}

static void fm_mask(uint64_t *w, uint32_t bits) {
  uint32_t nw = fm_nwords(bits);
  if (bits % 64u)
    w[nw - 1] &= ((uint64_t)1 << (bits % 64u)) - 1;
}

/* A fresh copy of the low `bits` bits of v, zero-extended to fm_nwords(bits) words. */
static uint64_t *fm_read(const cqe_val *v, uint32_t bits) {
  uint32_t nw = fm_nwords(bits);
  uint64_t *r = fm_alloc(nw);
  uint32_t have = v->nw < nw ? v->nw : nw;
  if (have && v->w)
    memcpy(r, v->w, have * sizeof *r);
  fm_mask(r, bits);
  return r;
}

static int fm_bit(const uint64_t *w, uint32_t i) { return (int)((w[i / 64u] >> (i % 64u)) & 1u); }

/* Bit length of a value of nw words (0 for zero). */
static uint32_t fm_bitlen(const uint64_t *w, uint32_t nw) {
  for (uint32_t i = nw; i-- > 0;)
    if (w[i])
      return i * 64u + 64u - (uint32_t)__builtin_clzll(w[i]);
  return 0;
}

static uint32_t fm_bitlen64(uint64_t x) { return x ? 64u - (uint32_t)__builtin_clzll(x) : 0; }

static void fm_neg(uint64_t *w, uint32_t nw) {
  uint64_t carry = 1;
  for (uint32_t i = 0; i < nw; ++i) {
    uint64_t t = ~w[i] + carry;
    carry = (carry && t == 0) ? 1 : 0;
    w[i] = t;
  }
}

/* r (nw words) = x << s, truncated to nw words. */
static void fm_shl64(uint64_t *r, uint32_t nw, uint64_t x, uint32_t s) {
  memset(r, 0, nw * sizeof *r);
  uint32_t q = s / 64u, b = s % 64u;
  if (q < nw)
    r[q] = x << b;
  if (b && q + 1 < nw)
    r[q + 1] = x >> (64u - b);
}

/* ---------------------------------------------------------------- formats and names */

typedef struct {
  uint32_t bits, eb, mb; /* total, exponent, fraction (no implicit bit) */
} fm_fmt;

enum { FM_BAD = -1, FM_OK = 0, FM_F80 = 1 };

/* "f16" / "bf16" / "f32" / "f64" -> format; "f80" -> FM_F80 (another family); else FM_BAD. */
static int fm_fmt_of(const char *w, fm_fmt *f) {
  if (!strcmp(w, "f16")) { *f = (fm_fmt){16, 5, 10}; return FM_OK; }
  if (!strcmp(w, "bf16")) { *f = (fm_fmt){16, 8, 7}; return FM_OK; }
  if (!strcmp(w, "f32")) { *f = (fm_fmt){32, 8, 23}; return FM_OK; }
  if (!strcmp(w, "f64")) { *f = (fm_fmt){64, 11, 52}; return FM_OK; }
  if (!strcmp(w, "f80")) return FM_F80;
  return FM_BAD;
}

/* fpext/fptrunc direction: f16 < bf16 < f32 < f64 (clang 19's spelling of the 16-bit pair). */
static uint32_t fm_rank(const fm_fmt *f) { return 2u * f->bits + (f->eb > 5u ? 1u : 0u); }

/* "i<N>" -> N >= 1, else 0. */
static uint32_t fm_int_of(const char *w) {
  if (w[0] != 'i' || w[1] < '1' || w[1] > '9')
    return 0;
  uint64_t n = 0;
  for (const char *p = w + 1; *p; ++p) {
    if (*p < '0' || *p > '9')
      return 0;
    n = n * 10u + (uint64_t)(*p - '0');
    if (n > (1u << 24))
      return 0;
  }
  return (uint32_t)n;
}

static int fm_bad(const cqe_tname *t, const char *why) {
  cqe_fail("tmpl_fpmisc: %s: op=%s pred=%s w=%s to=%s shape=%s", why, t->op, t->pred, t->w, t->to,
           t->shape);
  return -1;
}

static int fm_check_args(const cqe_tname *t, const cqe_val *args, int nargs, int want, cqe_val *out,
                         uint32_t outbits) {
  if (nargs != want)
    return fm_bad(t, "wrong operand count");
  for (int i = 0; i < nargs; ++i)
    if (!args[i].w || args[i].nw == 0)
      return fm_bad(t, "operand without storage");
  if (!out || !out->w || out->nw < fm_nwords(outbits))
    return fm_bad(t, "result storage too small");
  if (out->bits && out->bits != outbits)
    return fm_bad(t, "result width disagrees with the template name");
  return 0;
}

/* Write a <= 64-bit result into out, zeroing the rest. */
static void fm_put64(cqe_val *out, uint64_t v, uint32_t bits) {
  memset(out->w, 0, out->nw * sizeof *out->w);
  if (bits < 64)
    v &= ((uint64_t)1 << bits) - 1;
  out->w[0] = v;
}

static void fm_putw(cqe_val *out, const uint64_t *w, uint32_t bits) {
  memset(out->w, 0, out->nw * sizeof *out->w);
  memcpy(out->w, w, fm_nwords(bits) * sizeof *w);
  fm_mask(out->w, bits);
}

/* The family claims a name only for plain (no _rm/_rmq/_exc) f16/bf16/f32/f64 forms. */
static int fm_plain(const cqe_tname *t) { return !t->rm && !t->exc && !t->strided; }

/* ---------------------------------------------------------------- fp bit helpers */

static uint64_t fm_fbits(const cqe_val *v, const fm_fmt *f) {
  uint64_t x = v->w[0];
  return f->bits < 64 ? x & (((uint64_t)1 << f->bits) - 1) : x;
}

static uint64_t fm_sign(const fm_fmt *f) { return (uint64_t)1 << (f->bits - 1); }
static uint64_t fm_fracmask(const fm_fmt *f) { return ((uint64_t)1 << f->mb) - 1; }
static uint64_t fm_expall(const fm_fmt *f) { return ((uint64_t)1 << f->eb) - 1; }
static uint64_t fm_rawexp(uint64_t x, const fm_fmt *f) { return (x >> f->mb) & fm_expall(f); }
static uint64_t fm_quiet(const fm_fmt *f) { return (uint64_t)1 << (f->mb - 1); }
static int fm_bias(const fm_fmt *f) { return (int)fm_expall(f) >> 1; }

static int fm_isnan(uint64_t x, const fm_fmt *f) {
  return fm_rawexp(x, f) == fm_expall(f) && (x & fm_fracmask(f)) != 0;
}
static int fm_isinf(uint64_t x, const fm_fmt *f) {
  return fm_rawexp(x, f) == fm_expall(f) && (x & fm_fracmask(f)) == 0;
}
static int fm_iszero(uint64_t x, const fm_fmt *f) { return (x & ~fm_sign(f)) == 0; }

/* A finite nonzero x as |x| = sig * 2^E, sig with its implicit bit. */
static void fm_unpack(uint64_t x, const fm_fmt *f, uint64_t *sig, int *E) {
  uint64_t e = fm_rawexp(x, f), fr = x & fm_fracmask(f);
  if (e == 0) {
    *sig = fr;
    *E = 1 - fm_bias(f) - (int)f->mb;
  } else {
    *sig = fr | ((uint64_t)1 << f->mb);
    *E = (int)e - fm_bias(f) - (int)f->mb;
  }
}

/* Round (sig + sticky) * 2^E, sig != 0, to format f, RNE; overflow to Inf, subnormals. */
static uint64_t fm_round_pack(int neg, uint64_t sig, int E, int sticky, const fm_fmt *f) {
  uint64_t sbit = neg ? fm_sign(f) : 0;
  int p = (int)f->mb + 1, bias = fm_bias(f), emin = 1 - bias;
  int n = (int)fm_bitlen64(sig);
  int shift = n - p;
  if ((emin - (int)f->mb) - E > shift)
    shift = (emin - (int)f->mb) - E;
  uint64_t m;
  int round = 0;
  if (shift <= 0) {
    m = sig << -shift; /* exact; a sticky alone is below half an ulp */
  } else {
    if (shift > 64) {
      m = 0;
      sticky |= sig != 0;
    } else {
      round = (int)((sig >> (shift - 1)) & 1u);
      if (shift >= 2 && (sig & (((uint64_t)1 << (shift - 1)) - 1)))
        sticky = 1;
      m = shift == 64 ? 0 : sig >> shift;
    }
  }
  int q = E + shift; /* exponent of m's lsb */
  if (round && (sticky || (m & 1u)))
    ++m;
  if (m == 0)
    return sbit;
  if ((int)fm_bitlen64(m) > p) {
    m >>= 1;
    ++q;
  }
  int bl = (int)fm_bitlen64(m);
  if (bl == p) {
    int X = q + bl - 1;
    if (X > bias)
      return sbit | (fm_expall(f) << f->mb);
    return sbit | ((uint64_t)(X + bias) << f->mb) | (m & fm_fracmask(f));
  }
  return sbit | m; /* subnormal: q == emin - mb */
}

/* ---------------------------------------------------------------- fcmp */

static int fm_fcmp_eval(const char *pred, uint64_t a, uint64_t b, const fm_fmt *f, int *res) {
  int u = fm_isnan(a, f) || fm_isnan(b, f);
  int eq = 0, lt = 0, gt = 0;
  if (!u) {
    if (fm_iszero(a, f) && fm_iszero(b, f)) {
      eq = 1;
    } else {
      uint64_t s = fm_sign(f);
      int64_t ka = (a & s) ? -(int64_t)(a & ~s) : (int64_t)(a & ~s);
      int64_t kb = (b & s) ? -(int64_t)(b & ~s) : (int64_t)(b & ~s);
      eq = ka == kb;
      lt = ka < kb;
      gt = ka > kb;
    }
  }
  static const struct { const char *p; int k; } preds[] = {
      {"false", 0}, {"oeq", 1}, {"ogt", 2}, {"oge", 3}, {"olt", 4}, {"ole", 5}, {"one", 6}, {"ord", 7},
      {"ueq", 8},   {"ugt", 9}, {"uge", 10}, {"ult", 11}, {"ule", 12}, {"une", 13}, {"uno", 14}, {"true", 15}};
  for (size_t i = 0; i < sizeof preds / sizeof preds[0]; ++i) {
    if (strcmp(pred, preds[i].p))
      continue;
    int o = !u;
    switch (preds[i].k) {
    case 0: *res = 0; break;
    case 1: *res = o && eq; break;
    case 2: *res = o && gt; break;
    case 3: *res = o && (gt || eq); break;
    case 4: *res = o && lt; break;
    case 5: *res = o && (lt || eq); break;
    case 6: *res = o && !eq; break;
    case 7: *res = o; break;
    case 8: *res = u || eq; break;
    case 9: *res = u || gt; break;
    case 10: *res = u || gt || eq; break;
    case 11: *res = u || lt; break;
    case 12: *res = u || lt || eq; break;
    case 13: *res = u || !eq; break;
    case 14: *res = u; break;
    default: *res = 1; break;
    }
    return 0;
  }
  return -1;
}

static int op_fcmp(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  fm_fmt f;
  int k = fm_fmt_of(t->w, &f);
  if (k == FM_F80 || !fm_plain(t))
    return CQE_OP_NOT_MINE;
  if (k != FM_OK || t->to[0])
    return fm_bad(t, "fcmp needs f16, bf16, f32 or f64");
  if (fm_check_args(t, args, nargs, 2, out, 1))
    return -1;
  int r;
  if (fm_fcmp_eval(t->pred, fm_fbits(&args[0], &f), fm_fbits(&args[1], &f), &f, &r))
    return fm_bad(t, "unknown fcmp predicate");
  fm_put64(out, (uint64_t)r, 1);
  return 0;
}

/* ---------------------------------------------------------------- unary/binary fp misc */

enum { RT_FLOOR, RT_CEIL, RT_TRUNC, RT_RINT, RT_ROUND };

static uint64_t fm_round_int(uint64_t x, const fm_fmt *f, int mode) {
  if (fm_isnan(x, f))
    return x | fm_quiet(f);
  if (fm_isinf(x, f) || fm_iszero(x, f))
    return x;
  uint64_t s = x & fm_sign(f), mag = x & ~fm_sign(f);
  int ue = (int)fm_rawexp(x, f) - fm_bias(f);
  if (ue >= (int)f->mb)
    return x; /* already integral */
  uint64_t one = (uint64_t)fm_bias(f) << f->mb;
  if (ue < 0) { /* 0 < |x| < 1 */
    int up;
    uint64_t half = (uint64_t)(fm_bias(f) - 1) << f->mb;
    switch (mode) {
    case RT_FLOOR: up = s != 0; break;
    case RT_CEIL: up = s == 0; break;
    case RT_TRUNC: up = 0; break;
    case RT_RINT: up = mag > half; break;
    default: up = mag >= half; break;
    }
    return s | (up ? one : 0);
  }
  uint32_t d = f->mb - (uint32_t)ue; /* 1..mb fraction bits to drop */
  uint64_t lowmask = ((uint64_t)1 << d) - 1, low = mag & lowmask, hb = (uint64_t)1 << (d - 1);
  uint64_t tr = mag & ~lowmask;
  int up;
  switch (mode) {
  case RT_FLOOR: up = s && low; break;
  case RT_CEIL: up = !s && low; break;
  case RT_TRUNC: up = 0; break;
  case RT_RINT: up = low > hb || (low == hb && ((tr >> d) & 1u)); break;
  default: up = low >= hb; break;
  }
  if (up)
    tr += (uint64_t)1 << d; /* a carry into the exponent is the right answer */
  return s | tr;
}

static int fm_unary_fmt(const cqe_tname *t, fm_fmt *f) {
  int k = fm_fmt_of(t->w, f);
  if (k == FM_F80 || !fm_plain(t))
    return CQE_OP_NOT_MINE;
  if (k != FM_OK || t->to[0] || t->pred[0])
    return fm_bad(t, "needs a plain f16, bf16, f32 or f64 name");
  return 0;
}

static int fm_rounding_op(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out, int mode) {
  fm_fmt f;
  int k = fm_unary_fmt(t, &f);
  if (k)
    return k;
  if (fm_check_args(t, args, nargs, 1, out, f.bits))
    return -1;
  fm_put64(out, fm_round_int(fm_fbits(&args[0], &f), &f, mode), f.bits);
  return 0;
}

static int op_floor(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_rounding_op(t, a, n, o, RT_FLOOR); }
static int op_ceil(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_rounding_op(t, a, n, o, RT_CEIL); }
static int op_rint(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_rounding_op(t, a, n, o, RT_RINT); }
static int op_round(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_rounding_op(t, a, n, o, RT_ROUND); }

/* "trunc" is both the fp rounding op and, with _to_, the integer cast (tmpl_int's). */
static int op_trunc(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) {
  if (t->to[0])
    return CQE_OP_NOT_MINE;
  return fm_rounding_op(t, a, n, o, RT_TRUNC);
}

static int op_fabs(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  fm_fmt f;
  int k = fm_unary_fmt(t, &f);
  if (k)
    return k;
  if (fm_check_args(t, args, nargs, 1, out, f.bits))
    return -1;
  fm_put64(out, fm_fbits(&args[0], &f) & ~fm_sign(&f), f.bits);
  return 0;
}

static int op_copysign(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  fm_fmt f;
  int k = fm_unary_fmt(t, &f);
  if (k)
    return k;
  if (fm_check_args(t, args, nargs, 2, out, f.bits))
    return -1;
  uint64_t s = fm_sign(&f);
  fm_put64(out, (fm_fbits(&args[0], &f) & ~s) | (fm_fbits(&args[1], &f) & s), f.bits);
  return 0;
}

static int fm_minmax(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out, int isMax) {
  fm_fmt f;
  int k = fm_unary_fmt(t, &f);
  if (k)
    return k;
  if (fm_check_args(t, args, nargs, 2, out, f.bits))
    return -1;
  uint64_t a = fm_fbits(&args[0], &f), b = fm_fbits(&args[1], &f), r;
  if (fm_isnan(a, &f)) {
    r = b;
  } else if (fm_isnan(b, &f)) {
    r = a;
  } else {
    int c;
    fm_fcmp_eval(isMax ? "ogt" : "olt", b, a, &f, &c); /* b > a (max), b < a (min) */
    r = c ? b : a;
  }
  fm_put64(out, r, f.bits);
  return 0;
}

static int op_fmax(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_minmax(t, a, n, o, 1); }
static int op_fmin(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_minmax(t, a, n, o, 0); }

static int op_is_fpclass(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  fm_fmt f;
  int k = fm_unary_fmt(t, &f);
  if (k)
    return k;
  if (fm_check_args(t, args, nargs, 2, out, 1))
    return -1;
  uint64_t x = fm_fbits(&args[0], &f), mask = args[1].w[0];
  int neg = (x & fm_sign(&f)) != 0, bit;
  if (fm_isnan(x, &f))
    bit = (x & fm_quiet(&f)) ? 1 : 0;
  else if (fm_isinf(x, &f))
    bit = neg ? 2 : 9;
  else if (fm_iszero(x, &f))
    bit = neg ? 5 : 6;
  else if (fm_rawexp(x, &f) == 0)
    bit = neg ? 4 : 7;
  else
    bit = neg ? 3 : 8;
  fm_put64(out, (mask >> bit) & 1u, 1);
  return 0;
}

/* ---------------------------------------------------------------- fp <-> fp casts */

static int fm_two_fmts(const cqe_tname *t, fm_fmt *src, fm_fmt *dst) {
  int a = fm_fmt_of(t->w, src), b = fm_fmt_of(t->to, dst);
  if (a == FM_F80 || b == FM_F80 || !fm_plain(t))
    return CQE_OP_NOT_MINE;
  if (a != FM_OK || b != FM_OK || t->pred[0])
    return fm_bad(t, "needs f16, bf16, f32 or f64 on both sides");
  return 0;
}

static uint64_t fm_convert(uint64_t x, const fm_fmt *s, const fm_fmt *d) {
  uint64_t sbit = (x & fm_sign(s)) ? fm_sign(d) : 0;
  if (fm_isnan(x, s)) {
    uint64_t fr = x & fm_fracmask(s);
    fr = d->mb >= s->mb ? fr << (d->mb - s->mb) : fr >> (s->mb - d->mb);
    return sbit | (fm_expall(d) << d->mb) | fm_quiet(d) | (fr & fm_fracmask(d));
  }
  if (fm_isinf(x, s))
    return sbit | (fm_expall(d) << d->mb);
  if (fm_iszero(x, s))
    return sbit;
  uint64_t sig;
  int E;
  fm_unpack(x, s, &sig, &E);
  return fm_round_pack(sbit != 0, sig, E, 0, d);
}

static int op_fpext(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  fm_fmt s, d;
  int k = fm_two_fmts(t, &s, &d);
  if (k)
    return k;
  if (fm_rank(&d) <= fm_rank(&s))
    return fm_bad(t, "fpext must widen");
  if (fm_check_args(t, args, nargs, 1, out, d.bits))
    return -1;
  fm_put64(out, fm_convert(fm_fbits(&args[0], &s), &s, &d), d.bits);
  return 0;
}

static int op_fptrunc(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  fm_fmt s, d;
  int k = fm_two_fmts(t, &s, &d);
  if (k)
    return k;
  if (fm_rank(&d) >= fm_rank(&s))
    return fm_bad(t, "fptrunc must narrow");
  if (fm_check_args(t, args, nargs, 1, out, d.bits))
    return -1;
  fm_put64(out, fm_convert(fm_fbits(&args[0], &s), &s, &d), d.bits);
  return 0;
}

/* ---------------------------------------------------------------- int -> fp */

static int fm_itofp(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out, int isSigned) {
  fm_fmt d;
  uint32_t N = fm_int_of(t->w);
  int k = fm_fmt_of(t->to, &d);
  if (k == FM_F80 || !fm_plain(t))
    return CQE_OP_NOT_MINE;
  if (!N || k != FM_OK || t->pred[0])
    return fm_bad(t, "needs i<N> to f16, bf16, f32 or f64");
  if (fm_check_args(t, args, nargs, 1, out, d.bits))
    return -1;
  uint32_t nw = fm_nwords(N);
  uint64_t *m = fm_read(&args[0], N);
  int neg = isSigned && fm_bit(m, N - 1);
  if (neg) {
    fm_neg(m, nw);
    fm_mask(m, N); /* INT_MIN: magnitude 2^(N-1), still N bits */
  }
  uint32_t n = fm_bitlen(m, nw);
  uint64_t r;
  if (n == 0) {
    r = 0; /* +0 */
  } else {
    uint64_t sig = 0;
    int E = 0, sticky = 0;
    if (n <= 64) {
      sig = m[0];
    } else {
      uint32_t lo = n - 64; /* bits [lo, n) */
      for (uint32_t i = 0; i < 64; ++i)
        sig |= (uint64_t)fm_bit(m, lo + i) << i;
      for (uint32_t i = 0; i < lo && !sticky; ++i)
        sticky = fm_bit(m, i);
      E = (int)lo;
    }
    r = fm_round_pack(neg, sig, E, sticky, &d);
  }
  free(m);
  fm_put64(out, r, d.bits);
  return 0;
}

static int op_sitofp(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_itofp(t, a, n, o, 1); }
static int op_uitofp(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_itofp(t, a, n, o, 0); }

/* ---------------------------------------------------------------- fp -> int */

/* T = trunc(|x|) mod 2^(64 nw) for finite x, and the exact bit length of trunc(|x|). */
static uint32_t fm_trunc_mag(uint64_t x, const fm_fmt *f, uint64_t *T, uint32_t nw) {
  memset(T, 0, nw * sizeof *T);
  if (fm_iszero(x, f))
    return 0;
  uint64_t sig;
  int E;
  fm_unpack(x, f, &sig, &E);
  if (E >= 0) {
    fm_shl64(T, nw, sig, (uint32_t)E);
    return fm_bitlen64(sig) + (uint32_t)E;
  }
  uint64_t v = (-E >= 64) ? 0 : sig >> -E;
  T[0] = v;
  return fm_bitlen64(v);
}

/* cvtt to iK, K in {32, 64}: indefinite INT_MIN of width K. */
static uint64_t fm_cvtt(uint64_t x, const fm_fmt *f, uint32_t K) {
  uint64_t indef = (uint64_t)1 << (K - 1);
  if (fm_isnan(x, f) || fm_isinf(x, f))
    return indef;
  uint64_t T[2];
  uint32_t bl = fm_trunc_mag(x, f, T, 2);
  int neg = (x & fm_sign(f)) != 0;
  if (bl > K)
    return indef;
  if (bl == K && !(neg && T[0] == indef))
    return indef; /* |T| >= 2^(K-1), except -2^(K-1) itself */
  uint64_t r = neg ? (uint64_t)0 - T[0] : T[0];
  return K < 64 ? r & ((((uint64_t)1) << K) - 1) : r;
}

/* compiler-rt __fixXfti generalised to width F (signed): r (nw >= words(F)) gets F bits. */
static void fm_fix(uint64_t x, const fm_fmt *f, uint32_t F, uint64_t *r, uint32_t nw) {
  int neg = (x & fm_sign(f)) != 0;
  memset(r, 0, nw * sizeof *r);
  uint32_t fw = fm_nwords(F);
  uint64_t *T = fm_alloc(fw);
  uint32_t bl = (fm_isnan(x, f) || fm_isinf(x, f)) ? UINT32_MAX : fm_trunc_mag(x, f, T, fw);
  if (bl > F) { /* unbiased exponent >= F, NaN, Inf: saturate */
    for (uint32_t i = 0; i < fw; ++i)
      r[i] = neg ? 0 : ~(uint64_t)0;
    r[(F - 1) / 64u] ^= (uint64_t)1 << ((F - 1) % 64u); /* MAX: top bit 0; MIN: top bit 1 */
  } else {
    memcpy(r, T, fw * sizeof *r);
    if (neg)
      fm_neg(r, fw);
  }
  fm_mask(r, F);
  free(T);
}

/* compiler-rt __fixunsXfti generalised to width F. */
static void fm_fixu(uint64_t x, const fm_fmt *f, uint32_t F, uint64_t *r, uint32_t nw) {
  int neg = (x & fm_sign(f)) != 0;
  memset(r, 0, nw * sizeof *r);
  uint32_t fw = fm_nwords(F);
  if (neg)
    return; /* any negative, -0, -NaN: 0 */
  if (fm_isnan(x, f) || fm_isinf(x, f)) {
    for (uint32_t i = 0; i < fw; ++i)
      r[i] = ~(uint64_t)0;
  } else {
    uint64_t *T = fm_alloc(fw);
    uint32_t bl = fm_trunc_mag(x, f, T, fw);
    if (bl > F)
      for (uint32_t i = 0; i < fw; ++i)
        r[i] = ~(uint64_t)0;
    else
      memcpy(r, T, fw * sizeof *r);
    free(T);
  }
  fm_mask(r, F);
}

/* LLVM 19 ExpandLargeFpConvert (fptosi and fptoui to more than 128 bits), generic over the source
 * format: e = raw exponent - bias with NO special case for NaN/Inf (their raw exponent is all ones),
 * significand = fraction | implicit bit (raw exponent != 0). e < 0 -> 0; e >= N -> sign ? INT_MIN_N
 * : INT_MAX_N (also for fptoui); else sign * (significand scaled by 2^(e - mb)) mod 2^N. */
static void fm_expand(uint64_t x, const fm_fmt *f, uint32_t N, uint64_t *r, uint32_t nw) {
  int neg = (x & fm_sign(f)) != 0;
  uint64_t raw = fm_rawexp(x, f);
  int e = (int)raw - fm_bias(f);
  uint32_t fw = fm_nwords(N);
  memset(r, 0, nw * sizeof *r);
  if (e < 0)
    return;
  if ((uint32_t)e >= N) {
    for (uint32_t i = 0; i < fw; ++i)
      r[i] = neg ? 0 : ~(uint64_t)0;
    r[(N - 1) / 64u] ^= (uint64_t)1 << ((N - 1) % 64u);
  } else {
    uint64_t sig = (x & fm_fracmask(f)) | ((uint64_t)1 << f->mb);
    if (e >= (int)f->mb)
      fm_shl64(r, fw, sig, (uint32_t)e - f->mb);
    else
      r[0] = sig >> (f->mb - (uint32_t)e);
    if (neg)
      fm_neg(r, fw);
  }
  fm_mask(r, N);
}

static int fm_fptoi(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out, int isSigned) {
  fm_fmt s;
  uint32_t N = fm_int_of(t->to);
  int k = fm_fmt_of(t->w, &s);
  if (k == FM_F80 || !fm_plain(t))
    return CQE_OP_NOT_MINE;
  if (!N || k != FM_OK || t->pred[0])
    return fm_bad(t, "needs f16, bf16, f32 or f64 to i<N>");
  if (fm_check_args(t, args, nargs, 1, out, N))
    return -1;
  uint64_t x = fm_fbits(&args[0], &s);
  /* f16 and bf16 go through f32 (LLVM promotes half and bfloat); exact. */
  fm_fmt f32 = {32, 8, 23};
  const fm_fmt *f = &s;
  if (s.bits == 16) {
    x = fm_convert(x, &s, &f32);
    f = &f32;
  }
  uint32_t nw = fm_nwords(N > 128 ? N : 128);
  uint64_t *r = fm_alloc(nw);
  if (isSigned) {
    if (N <= 32)
      r[0] = fm_cvtt(x, f, 32);
    else if (N <= 64)
      r[0] = fm_cvtt(x, f, 64);
    else if (N <= 128)
      fm_fix(x, f, 128, r, nw);
    else
      fm_expand(x, f, N, r, nw);
  } else {
    if (N <= 31) {
      r[0] = fm_cvtt(x, f, 32);
    } else if (N <= 63) {
      r[0] = fm_cvtt(x, f, 64);
    } else if (N == 64) {
      /* r1 | (r2 & (r1 >>s 63)), r1 = c64(x), r2 = c64(x - 2^63). r2 matters only when r1 has its
       * top bit set; then x is NaN, x <= -1, or x >= 2^63. For x <= -1 and NaN, x - 2^63 is out of
       * range or rounds to -2^63, so r2 = 2^63 and the result is r1. For x >= 2^64 or +Inf, r1 = r2
       * = 2^63. For 2^63 <= x < 2^64, x - 2^63 is exact and the result is trunc(x). */
      uint64_t T[2];
      uint32_t bl = (fm_isnan(x, f) || fm_isinf(x, f)) ? 0 : fm_trunc_mag(x, f, T, 2);
      if (!(x & fm_sign(f)) && bl == 64)
        r[0] = T[0];
      else
        r[0] = fm_cvtt(x, f, 64);
    } else if (N <= 128) {
      fm_fixu(x, f, 128, r, nw);
    } else {
      fm_expand(x, f, N, r, nw); /* ExpandLargeFpConvert treats fptoui like fptosi */
    }
  }
  fm_putw(out, r, N);
  free(r);
  return 0;
}

static int op_fptosi(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_fptoi(t, a, n, o, 1); }
static int op_fptoui(const cqe_tname *t, const cqe_val *a, int n, cqe_val *o) { return fm_fptoi(t, a, n, o, 0); }

/* ---------------------------------------------------------------- registration */

__attribute__((constructor)) static void tmpl_fpmisc_register(void) {
  cqe_register_op("fcmp", op_fcmp);
  cqe_register_op("fabs", op_fabs);
  cqe_register_op("copysign", op_copysign);
  cqe_register_op("fmax", op_fmax);
  cqe_register_op("fmin", op_fmin);
  cqe_register_op("floor", op_floor);
  cqe_register_op("ceil", op_ceil);
  cqe_register_op("trunc", op_trunc);
  cqe_register_op("rint", op_rint);
  cqe_register_op("round", op_round);
  cqe_register_op("is_fpclass", op_is_fpclass);
  cqe_register_op("fpext", op_fpext);
  cqe_register_op("fptrunc", op_fptrunc);
  cqe_register_op("sitofp", op_sitofp);
  cqe_register_op("uitofp", op_uitofp);
  cqe_register_op("fptosi", op_fptosi);
  cqe_register_op("fptoui", op_fptoui);
}
