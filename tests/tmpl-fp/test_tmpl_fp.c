/* Differential test of checker/rt/tmpl_fp.c (cq-w0-tmpl-fp; bf16 cq-jtx).
 *
 * Every template op of the family (fadd fsub fmul fdiv fneg sqrt fma frem) at every width it
 * covers (f16 bf16 f32 f64) is evaluated through the cqe_op_fn the family registers and compared bit
 * for bit with native.ll, the same LLVM IR operation compiled by clang-19 -O1 and run on this host.
 *
 * Inputs per width: an edge set built from the format (±0, ±min/max subnormal, ±min normal, ±1 and
 * neighbours, ±max finite, ±Inf, quiet and signalling NaNs of both signs with payloads), every
 * tuple of edges, a seeded random set (uniform bit patterns, operands of nearby magnitude for
 * cancellation, fma with z near -x*y), and every f16 and every bf16 value for the unary ops.
 *
 * bf16 native code: clang-19 -O1 on x86_64-apple-macosx compiles bfloat IR by promoting to float,
 * doing the float operation (fmodf/fmaf for frem/fma) and truncating with __truncsfbf2 (RNE, NaN
 * payload kept and quieted). For fadd fsub fmul fdiv sqrt that double rounding is innocuous
 * (float precision 24 >= 2*8+2), frem is exact, so native is the reference there; fma is not
 * (fmaf rounds to float first), so non-NaN fma bf16 goes to the table oracle below.
 *
 * Where CR §2 fixes a result that native code does not produce, the case is checked against the
 * table instead, by an oracle written here independently of tmpl_fp.c:
 *   - the NaN rule (first NaN operand in IR order, quieted; invalid -> default NaN) for every op:
 *     native fma and frem are libm calls (fma/fmaf/fmod/fmodf), not SSE instructions;
 *   - fma f16 is one rounding of the exact x*y+z (CR §2 "only llvm.fma is fused", BACKEND_ABI
 *     §2.9 "one rounding"); native code computes fmaf then rounds again to half. The oracle is an
 *     exact 128-bit fixed-point sum rounded by nearest search over all f16 values.
 *   - fma bf16, the same rule; native computes fmaf then truncates. The bf16 range does not fit a
 *     128-bit fixed point, so this oracle is different: the exact product in x87 long double, the
 *     sum by TwoSum, rounded to odd at 64 bits (sound for a final rounding to 8 bits), then
 *     rounded to nearest even by search over all bf16 values.
 * Each such case is counted and the counts are printed; where native disagrees with the table one
 * example is printed per (op, width).
 *
 * Malformed calls (wrong arity, an integer width such as i1/i7/i100, a bad shape, an operand of the
 * wrong width) must fail through cqe_fail and return -1; the _rm/_rmq/_exc forms and f80 must
 * return CQE_OP_NOT_MINE without failing. Every call hands out over as the M1 dispatcher does
 * (cqe.h) and checks that the family left out's preset fields alone.
 *
 * The test links tmpl_fp.c directly with the two cqe.h functions it calls defined here, so it does
 * not depend on the evaluator core.
 */
#include <inttypes.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

/* ---- shim for the two cqe.h functions the family calls ------------------------------------- */

static struct { char op[24]; cqe_op_fn fn; } reg[64];
static int nreg;
static int nfail_calls;
static char last_fail[512];

void cqe_register_op(const char *op, cqe_op_fn fn) {
  if (nreg == 64)
    abort();
  snprintf(reg[nreg].op, sizeof reg[nreg].op, "%s", op);
  reg[nreg].fn = fn;
  nreg++;
}

void cqe_fail(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(last_fail, sizeof last_fail, fmt, ap);
  va_end(ap);
  nfail_calls++;
}

static cqe_op_fn lookup(const char *op) {
  for (int i = 0; i < nreg; ++i)
    if (!strcmp(reg[i].op, op))
      return reg[i].fn;
  return NULL;
}

/* ---- native reference (native.ll) ---------------------------------------------------------- */

#define NAT2(op, f, T) T native_##op##_##f(T, T);
#define NATW(f, T)                                                                                  \
  NAT2(fadd, f, T) NAT2(fsub, f, T) NAT2(fmul, f, T) NAT2(fdiv, f, T) NAT2(frem, f, T)               \
  T native_fneg_##f(T); T native_sqrt_##f(T); T native_fma_##f(T, T, T);
NATW(f16, uint16_t)
NATW(f32, uint32_t)
NATW(f64, uint64_t)
NATW(bf16, uint16_t)

enum { FADD, FSUB, FMUL, FDIV, FREM, FNEG, SQRT, FMA, NOPS };
static const char *opname[NOPS] = {"fadd", "fsub", "fmul", "fdiv", "frem", "fneg", "sqrt", "fma"};
static const int arity[NOPS] = {2, 2, 2, 2, 2, 1, 1, 3};

typedef struct { const char *name; unsigned bits, eb, mb; } fmt;
enum { F16, F32, F64, BF16, NFMT };
static const fmt fmts[NFMT] = {{"f16", 16, 5, 10}, {"f32", 32, 8, 23}, {"f64", 64, 11, 52}, {"bf16", 16, 8, 7}};

static uint64_t native(int op, int fi, const uint64_t *x) {
#define CASES(f, T)                                                                                  \
  switch (op) {                                                                                      \
  case FADD: return native_fadd_##f((T)x[0], (T)x[1]);                                               \
  case FSUB: return native_fsub_##f((T)x[0], (T)x[1]);                                               \
  case FMUL: return native_fmul_##f((T)x[0], (T)x[1]);                                               \
  case FDIV: return native_fdiv_##f((T)x[0], (T)x[1]);                                               \
  case FREM: return native_frem_##f((T)x[0], (T)x[1]);                                               \
  case FNEG: return native_fneg_##f((T)x[0]);                                                        \
  case SQRT: return native_sqrt_##f((T)x[0]);                                                        \
  case FMA: return native_fma_##f((T)x[0], (T)x[1], (T)x[2]);                                        \
  }
  if (fi == 0) CASES(f16, uint16_t)
  if (fi == 1) CASES(f32, uint32_t)
  if (fi == 2) CASES(f64, uint64_t)
  if (fi == 3) CASES(bf16, uint16_t)
#undef CASES
  abort();
}

/* ---- calling the family -------------------------------------------------------------------- */

/* out is handed over as the M1 dispatcher does: out->w non-NULL and zeroed, nw = ceil(bits/64),
 * bits and kind preset to the result type (an fp result of the operand width). bad_preset != 0
 * presets a wrong result width instead, which the family must report. After a call returning 0
 * the handler must have left w, nw, bits and kind unchanged and every bit above bits zero. */
static int call_tmpl(const char *op, const char *w, const char *shape, uint8_t rm, uint8_t exc, const uint64_t *x,
                     int nargs, unsigned argbits, uint64_t *res, int bad_preset) {
  cqe_op_fn fn = lookup(op);
  if (!fn) {
    printf("FAIL: op %s not registered\n", op);
    exit(1);
  }
  cqe_tname t;
  memset(&t, 0, sizeof t);
  snprintf(t.op, sizeof t.op, "%s", op);
  snprintf(t.w, sizeof t.w, "%s", w);
  snprintf(t.shape, sizeof t.shape, "%s", shape);
  t.rm = rm;
  t.exc = exc;
  uint64_t aw[3];
  cqe_val a[3];
  for (int i = 0; i < nargs && i < 3; ++i) {
    aw[i] = x[i];
    a[i] = (cqe_val){argbits, 'f', 1, &aw[i]};
  }
  uint64_t ow[4] = {0, 0, 0, 0};
  uint32_t obits = bad_preset ? argbits * 2 : argbits;
  uint32_t onw = (obits + 63) / 64;
  cqe_val out = {obits, 'f', onw, ow};
  int rc = fn(&t, a, nargs, &out);
  if (out.w != ow || out.nw != onw || out.bits != obits || out.kind != 'f') {
    printf("FAIL: %s_%s changed the dispatcher's out fields (rc=%d)\n", op, w, rc);
    exit(1);
  }
  if (rc == 0) {
    for (uint32_t i = 0; i < 4; ++i) {
      uint64_t above = i * 64 >= obits ? ~0ull : (obits - i * 64 >= 64 ? 0 : ~0ull << (obits - i * 64));
      if (ow[i] & above) {
        printf("FAIL: %s_%s set bits above %u in word %u\n", op, w, obits, i);
        exit(1);
      }
    }
  }
  *res = ow[0];
  return rc;
}

/* ---- independent CR §2 oracle (bit tests only) --------------------------------------------- */

static uint64_t f_sign(const fmt *f) { return (uint64_t)1 << (f->bits - 1); }
static uint64_t f_expm(const fmt *f) { return (((uint64_t)1 << f->eb) - 1) << f->mb; }
static uint64_t f_fracm(const fmt *f) { return ((uint64_t)1 << f->mb) - 1; }
static int is_nan(const fmt *f, uint64_t x) { return (x & f_expm(f)) == f_expm(f) && (x & f_fracm(f)); }
static int is_inf(const fmt *f, uint64_t x) { return (x & f_expm(f)) == f_expm(f) && !(x & f_fracm(f)); }
static int is_zero(const fmt *f, uint64_t x) { return (x & ~f_sign(f)) == 0; }
static int sgn(const fmt *f, uint64_t x) { return (x & f_sign(f)) != 0; }
static uint64_t dnan(const fmt *f) { return f_sign(f) | f_expm(f) | ((uint64_t)1 << (f->mb - 1)); }

/* The CR §2 NaN result if the op yields one: 1 and *r, else 0. */
static int cr_nan(int op, const fmt *f, const uint64_t *x, uint64_t *r) {
  if (op == FNEG)
    return 0;
  for (int i = 0; i < arity[op]; ++i)
    if (is_nan(f, x[i])) {
      *r = x[i] | ((uint64_t)1 << (f->mb - 1));
      return 1;
    }
  int inv = 0;
  switch (op) {
  case FADD: inv = is_inf(f, x[0]) && is_inf(f, x[1]) && sgn(f, x[0]) != sgn(f, x[1]); break;
  case FSUB: inv = is_inf(f, x[0]) && is_inf(f, x[1]) && sgn(f, x[0]) == sgn(f, x[1]); break;
  case FMUL: inv = (is_inf(f, x[0]) && is_zero(f, x[1])) || (is_zero(f, x[0]) && is_inf(f, x[1])); break;
  case FDIV: inv = (is_zero(f, x[0]) && is_zero(f, x[1])) || (is_inf(f, x[0]) && is_inf(f, x[1])); break;
  case FREM: inv = is_inf(f, x[0]) || is_zero(f, x[1]); break;
  case SQRT: inv = sgn(f, x[0]) && !is_zero(f, x[0]); break;
  case FMA: {
    int pinf = is_inf(f, x[0]) || is_inf(f, x[1]), pzero = is_zero(f, x[0]) || is_zero(f, x[1]);
    inv = (pinf && pzero) || (pinf && is_inf(f, x[2]) && (sgn(f, x[0]) ^ sgn(f, x[1])) != sgn(f, x[2]));
    break;
  }
  }
  if (inv)
    *r = dnan(f);
  return inv;
}

/* f16 value as a signed multiple of 2^-24 (exact). x is not NaN or Inf. */
static __int128 h_scaled24(uint16_t x) {
  int e = (x >> 10) & 31;
  __int128 m = x & 1023;
  if (e)
    m = (m | 1024) << (e - 1);
  return (x & 0x8000) ? -m : m;
}

/* Correctly rounded (RNE) f16 nearest to s * 2^-48, s != 0, by search over all f16 values. */
static uint16_t h_round48(__int128 s) {
  int neg = s < 0;
  __int128 a = neg ? -s : s;
  /* candidates: bit patterns 0..0x7C00 ascending in value; 0x7C00 (Inf) stands for 2^16 */
  int lo = 0, hi = 0x7C00;
  #define VAL(b) ((b) == 0x7C00 ? ((__int128)1 << 64) : (h_scaled24((uint16_t)(b)) << 24))
  while (hi - lo > 1) { /* VAL(lo) <= a < VAL(hi) */
    int mid = (lo + hi) / 2;
    if (VAL(mid) <= a)
      lo = mid;
    else
      hi = mid;
  }
  if (a >= VAL(0x7C00)) {
    lo = 0x7C00;
    hi = 0x7C00;
  }
  int pick;
  if (lo == hi || a == VAL(lo))
    pick = lo;
  else {
    __int128 dl = a - VAL(lo), dh = VAL(hi) - a;
    pick = dl < dh ? lo : dh < dl ? hi : ((lo & 1) ? hi : lo);
  }
  #undef VAL
  return (uint16_t)(pick | (neg ? 0x8000 : 0));
}

/* CR §2 fma f16: one rounding of the exact x*y+z. Non-NaN results only (cr_nan first). */
static uint16_t h_fma_exact(uint16_t x, uint16_t y, uint16_t z) {
  const fmt *f = &fmts[0];
  int sp = sgn(f, x) ^ sgn(f, y);
  if (is_inf(f, x) || is_inf(f, y))
    return (uint16_t)(0x7C00 | (sp ? 0x8000 : 0));
  if (is_inf(f, z))
    return z;
  __int128 s = h_scaled24(x) * h_scaled24(y) + (h_scaled24(z) << 24);
  if (s == 0) /* exact zero sum: the common sign of the terms, else +0 (RNE) */
    return (uint16_t)((sp == sgn(f, z) && sp) ? 0x8000 : 0);
  return h_round48(s);
}

/* bf16 bit pattern to its exact value, decoded from the fields (no host bfloat). Finite x only. */
static long double b_value(uint16_t x) {
  int e = (x >> 7) & 0xFF;
  long double m = (long double)(x & 0x7F);
  long double v = e ? ldexpl(m + 128.0L, e - 127 - 7) : ldexpl(m, -126 - 7);
  return (x & 0x8000) ? -v : v;
}

/* Correctly rounded (RNE) bf16 nearest to s, s != 0 finite, by search over all bf16 values.
 * s must not lie exactly on a bf16 midpoint unless it is the exact value (round to odd ensures
 * that for an inexact s). */
static uint16_t b_round(long double s) {
  int neg = s < 0;
  long double a = neg ? -s : s;
  /* patterns 0..0x7F80 ascending in value; 0x7F80 (Inf) stands for 2^128, the next binade */
  #define BVAL(b) ((b) == 0x7F80 ? ldexpl(1.0L, 128) : b_value((uint16_t)(b)))
  int lo = 0, hi = 0x7F80, pick;
  if (a >= BVAL(0x7F80)) {
    pick = 0x7F80;
  } else {
    while (hi - lo > 1) { /* BVAL(lo) <= a < BVAL(hi) */
      int mid = (lo + hi) / 2;
      if (BVAL(mid) <= a)
        lo = mid;
      else
        hi = mid;
    }
    if (a == BVAL(lo))
      pick = lo;
    else {
      long double dl = a - BVAL(lo), dh = BVAL(hi) - a; /* exact: 64-bit significands, close values */
      pick = dl < dh ? lo : dh < dl ? hi : ((lo & 1) ? hi : lo);
    }
  }
  #undef BVAL
  return (uint16_t)(pick | (neg ? 0x8000 : 0));
}

/* CR §2 fma bf16: one rounding of the exact x*y+z. Non-NaN results only (cr_nan first). */
static uint16_t b_fma_exact(uint16_t x, uint16_t y, uint16_t z) {
  const fmt *f = &fmts[BF16];
  int sp = sgn(f, x) ^ sgn(f, y);
  if (is_inf(f, x) || is_inf(f, y))
    return (uint16_t)(0x7F80 | (sp ? 0x8000 : 0));
  if (is_inf(f, z))
    return z;
  volatile long double p = b_value(x) * b_value(y); /* exact: 16-bit product, in range */
  volatile long double c = b_value(z);
  volatile long double s = p + c; /* TwoSum (Knuth): s + err == p + c exactly */
  volatile long double bv = s - p;
  volatile long double err = (p - (s - bv)) + (c - bv);
  long double sv = s, ev = err;
  if (sv == 0 && ev == 0) /* exact zero sum: the common sign of the terms, else +0 (RNE) */
    return (uint16_t)((sp == sgn(f, z) && sp) ? 0x8000 : 0);
  if (ev != 0) { /* round to odd: of the two 64-bit neighbours around p + c, the odd one */
    uint64_t sig;
    memcpy(&sig, &sv, sizeof sig);
    if (!(sig & 1))
      sv = nextafterl(sv, ev > 0 ? INFINITY : -INFINITY);
  }
  return b_round(sv);
}

/* ---- inputs -------------------------------------------------------------------------------- */

static uint64_t rng_state = 0x9E3779B97F4A7C15ull;
static uint64_t rnd(void) {
  rng_state ^= rng_state >> 12;
  rng_state ^= rng_state << 25;
  rng_state ^= rng_state >> 27;
  return rng_state * 0x2545F4914F6CDD1Dull;
}

static int edges(const fmt *f, uint64_t *e) {
  int n = 0;
  uint64_t one = (uint64_t)((1u << (f->eb - 1)) - 1) << f->mb;
  uint64_t q = (uint64_t)1 << (f->mb - 1), inf = f_expm(f), fr = f_fracm(f);
  uint64_t pos[] = {
      0,                                     /* +0 */
      1,                                     /* min subnormal */
      2, fr,                                 /* subnormals, max subnormal */
      (uint64_t)1 << f->mb,                  /* min normal */
      ((uint64_t)1 << f->mb) | 1,
      one, one + 1, one - 1,                 /* 1, 1+ulp, largest below 1 */
      one | q,                               /* 1.5 */
      one + ((uint64_t)1 << f->mb),          /* 2 */
      one + ((uint64_t)1 << f->mb) + q,      /* 3 */
      one - ((uint64_t)1 << f->mb),          /* 0.5 */
      one + 3 * ((uint64_t)1 << f->mb) + 0x5, /* 8.something */
      inf - ((uint64_t)1 << f->mb) + fr,     /* max finite */
      inf - ((uint64_t)2 << f->mb),          /* max/2 order */
      inf,                                   /* Inf */
      inf | q,                               /* default-ish qNaN */
      inf | q | 0x5,                         /* qNaN with payload */
      inf | 1,                               /* sNaN */
      inf | (q - 1),                         /* sNaN, full payload */
  };
  for (size_t i = 0; i < sizeof pos / sizeof pos[0]; ++i) {
    e[n++] = pos[i];
    e[n++] = pos[i] | f_sign(f);
  }
  return n;
}

static uint64_t mask_of(const fmt *f) { return f->bits == 64 ? ~0ull : ((1ull << f->bits) - 1); }

/* A random finite value with biased exponent in [lo, hi]. */
static uint64_t rnd_exp(const fmt *f, int lo, int hi) {
  int emax = (1 << f->eb) - 2;
  if (lo < 0) lo = 0;
  if (hi > emax) hi = emax;
  if (hi < lo) hi = lo;
  uint64_t e = (uint64_t)(lo + (int)(rnd() % (uint64_t)(hi - lo + 1)));
  return (rnd() & f_fracm(f)) | (e << f->mb) | ((rnd() & 1) ? f_sign(f) : 0);
}
static int bexp(const fmt *f, uint64_t x) { return (int)((x & f_expm(f)) >> f->mb); }

/* ---- the comparison ------------------------------------------------------------------------ */

static long n_cmp, n_native_agree, n_table, n_table_native_differs, n_bad;
static long w_cmp[NFMT], w_native[NFMT], w_table[NFMT], w_bad[NFMT];
static long tbl_cnt[NOPS][NFMT], tbl_diff[NOPS][NFMT];
/* why native differs from the table: 0 two or more NaN operands, 1 exactly one NaN operand,
 * 2 invalid operation (no NaN operand), 3 a finite or infinite result (fma f16 rounding) */
static long diff_why[NOPS][NFMT][4];
static const char *why_name[4] = {"several NaN operands", "one NaN operand", "invalid operation", "non-NaN result"};
static int tbl_shown[NOPS][NFMT];

static void check(int op, int fi, const uint64_t *x) {
  const fmt *f = &fmts[fi];
  uint64_t m = mask_of(f), xs[3] = {0, 0, 0};
  for (int i = 0; i < arity[op]; ++i)
    xs[i] = x[i] & m;
  uint64_t mine;
  /* Alternate the shape spelling: the value semantics never depend on it. */
  static const char *sh2[] = {"", "hl", "lh"}, *sh3[] = {"", "qql", "qlq", "qll", "llq"};
  const char *shape = arity[op] == 3 ? sh3[n_cmp % 5] : arity[op] == 2 ? sh2[n_cmp % 3] : "";
  int rc = call_tmpl(opname[op], f->name, shape, 0, 0, xs, arity[op], f->bits, &mine, 0);
  n_cmp++;
  w_cmp[fi]++;
  if (rc != 0) {
    w_bad[fi]++;
    printf("FAIL: %s_%s rc=%d (%s)\n", opname[op], f->name, rc, last_fail);
    n_bad++;
    return;
  }
  uint64_t nat = native(op, fi, xs) & m;
  uint64_t tbl = 0;
  int have_tbl = cr_nan(op, f, xs, &tbl);
  if (!have_tbl && op == FMA && fi == F16) {
    tbl = h_fma_exact((uint16_t)xs[0], (uint16_t)xs[1], (uint16_t)xs[2]);
    have_tbl = 1;
  }
  if (!have_tbl && op == FMA && fi == BF16) {
    tbl = b_fma_exact((uint16_t)xs[0], (uint16_t)xs[1], (uint16_t)xs[2]);
    have_tbl = 1;
  }
  int ok;
  if (have_tbl) {
    n_table++;
    w_table[fi]++;
    tbl_cnt[op][fi]++;
    ok = mine == tbl;
    if (nat != tbl) {
      n_table_native_differs++;
      tbl_diff[op][fi]++;
      int nn = 0;
      for (int i = 0; i < arity[op]; ++i)
        nn += is_nan(f, xs[i]);
      diff_why[op][fi][nn >= 2 ? 0 : nn == 1 ? 1 : is_nan(f, tbl) ? 2 : 3]++;
      if (!tbl_shown[op][fi]++)
        printf("  note: %s_%s native differs from CR §2: args %" PRIx64 " %" PRIx64 " %" PRIx64
               " native %" PRIx64 " table %" PRIx64 "\n",
               opname[op], f->name, xs[0], xs[1], xs[2], nat, tbl);
    }
  } else {
    ok = mine == nat;
    n_native_agree += ok;
    w_native[fi]++;
  }
  if (!ok) {
    w_bad[fi]++;
    if (n_bad < 40)
      printf("FAIL: %s_%s(%" PRIx64 ", %" PRIx64 ", %" PRIx64 ") = %" PRIx64 ", expected %" PRIx64 " (%s)\n",
             opname[op], f->name, xs[0], xs[1], xs[2], mine, have_tbl ? tbl : nat, have_tbl ? "table" : "native");
    n_bad++;
  }
}

static void run_width(int fi, long nrand) {
  const fmt *f = &fmts[fi];
  uint64_t e[64];
  int ne = edges(f, e);
  for (int op = 0; op < NOPS; ++op) {
    uint64_t x[3];
    /* every tuple of edges */
    if (arity[op] == 1) {
      for (int i = 0; i < ne; ++i) { x[0] = e[i]; check(op, fi, x); }
    } else if (arity[op] == 2) {
      for (int i = 0; i < ne; ++i)
        for (int j = 0; j < ne; ++j) { x[0] = e[i]; x[1] = e[j]; check(op, fi, x); }
    } else {
      for (int i = 0; i < ne; ++i)
        for (int j = 0; j < ne; ++j)
          for (int k = 0; k < ne; ++k) { x[0] = e[i]; x[1] = e[j]; x[2] = e[k]; check(op, fi, x); }
    }
    /* f16 and bf16 unary: every value */
    if ((fi == F16 || fi == BF16) && arity[op] == 1)
      for (uint64_t v = 0; v < 65536; ++v) { x[0] = v; check(op, fi, x); }
    /* seeded random */
    int emax = (1 << f->eb) - 2;
    for (long r = 0; r < nrand; ++r) {
      int kind = (int)(r % 4);
      if (kind == 0) { /* uniform bit patterns */
        x[0] = rnd(); x[1] = rnd(); x[2] = rnd();
      } else if (kind == 1) { /* nearby magnitudes: cancellation, close quotients */
        x[0] = rnd_exp(f, 0, emax);
        int d = (int)(rnd() % 7) - 3;
        x[1] = rnd_exp(f, bexp(f, x[0]) + d, bexp(f, x[0]) + d);
        x[2] = rnd_exp(f, bexp(f, x[0]) + d, bexp(f, x[0]) + d);
      } else if (kind == 2) { /* around 1, subnormal and overflow results */
        int c = (int)(rnd() % 3), bias = (1 << (f->eb - 1)) - 1;
        int lo = c == 0 ? bias - 4 : c == 1 ? 0 : emax - (int)f->mb - 2;
        int hi = c == 0 ? bias + 4 : c == 1 ? bias / 2 + 2 : emax;
        x[0] = rnd_exp(f, lo, hi); x[1] = rnd_exp(f, lo, hi); x[2] = rnd_exp(f, lo, hi);
      } else { /* fma: z near -(x*y); other ops: the low bits of a nearby product */
        x[0] = rnd_exp(f, (1 << (f->eb - 1)) - 8, (1 << (f->eb - 1)) + 8);
        x[1] = rnd_exp(f, (1 << (f->eb - 1)) - 8, (1 << (f->eb - 1)) + 8);
        uint64_t p = native(FMUL, fi, x) & mask_of(f);
        uint64_t pert = (uint64_t)((int64_t)(rnd() % 9) - 4);
        x[2] = (p + pert) ^ f_sign(f);
        if (op != FMA) x[1] = x[2];
      }
      check(op, fi, x);
    }
  }
}

/* ---- malformed and not-mine calls ---------------------------------------------------------- */

static long n_neg, n_neg_bad;

static void expect_p(int want_rc, int want_fail, const char *op, const char *w, const char *shape, uint8_t rm,
                     uint8_t exc, int nargs, unsigned argbits, int bad_preset, const char *what) {
  uint64_t x[3] = {0, 0, 0}, r;
  int before = nfail_calls;
  int rc = call_tmpl(op, w, shape, rm, exc, x, nargs, argbits, &r, bad_preset);
  int failed = nfail_calls > before;
  n_neg++;
  if (rc != want_rc || failed != want_fail) {
    printf("FAIL: %s: rc=%d cqe_fail=%d, expected rc=%d cqe_fail=%d\n", what, rc, failed, want_rc, want_fail);
    n_neg_bad++;
  }
}

static void expect(int want_rc, int want_fail, const char *op, const char *w, const char *shape, uint8_t rm,
                   uint8_t exc, int nargs, unsigned argbits, const char *what) {
  expect_p(want_rc, want_fail, op, w, shape, rm, exc, nargs, argbits, 0, what);
}

static void run_negative(void) {
  static const char *intw[] = {"i1", "i7", "i8", "i32", "i64", "i100", "i128"};
  for (int op = 0; op < NOPS; ++op) {
    unsigned ib[] = {1, 7, 8, 32, 64, 100, 128};
    for (int i = 0; i < 7; ++i)
      expect(-1, 1, opname[op], intw[i], "", 0, 0, arity[op], ib[i], "fp op at an integer width");
    expect(-1, 1, opname[op], "f17", "", 0, 0, arity[op], 17, "unknown fp width");
    for (int fi = 0; fi < NFMT; ++fi) {
      const fmt *f = &fmts[fi];
      expect(-1, 1, opname[op], f->name, "", 0, 0, arity[op] + 1, f->bits, "one operand too many");
      expect(-1, 1, opname[op], f->name, "", 0, 0, arity[op] - 1, f->bits, "one operand too few");
      expect(-1, 1, opname[op], f->name, "", 0, 0, arity[op], f->bits == 64 ? 32 : 64, "operand of the wrong width");
      expect(-1, 1, opname[op], f->name, arity[op] == 3 ? "hl" : "qqq", 0, 0, arity[op], f->bits,
             "shape of the wrong length");
      expect(-1, 1, opname[op], f->name, arity[op] == 1 ? "x" : arity[op] == 2 ? "hx" : "qqx", 0, 0, arity[op],
             f->bits, "bad shape letter");
      expect_p(-1, 1, opname[op], f->name, "", 0, 0, arity[op], f->bits, 1, "result buffer preset to the wrong width");
      /* the forms other families own */
      expect(CQE_OP_NOT_MINE, 0, opname[op], f->name, "", 1, 0, arity[op] + 1, f->bits, "_rm form (tmpl-fenv)");
      expect(CQE_OP_NOT_MINE, 0, opname[op], f->name, "", 0, 1, arity[op], f->bits, "_exc form (tmpl-fenv)");
    }
    expect(CQE_OP_NOT_MINE, 0, opname[op], "f80", "", 0, 0, arity[op], 80, "f80 form (tmpl-f80)");
  }
}

int main(int argc, char **argv) {
  /* usage: test_tmpl_fp [random samples per op and width, default 200000] [seed] */
  long nrand = argc > 1 ? atol(argv[1]) : 200000;
  if (argc > 2)
    rng_state = strtoull(argv[2], NULL, 0) | 1;
  for (int op = 0; op < NOPS; ++op)
    if (!lookup(opname[op])) {
      printf("FAIL: %s not registered\n", opname[op]);
      return 1;
    }
  for (int fi = 0; fi < NFMT; ++fi)
    run_width(fi, nrand);
  int wf_fail = nfail_calls;
  if (wf_fail)
    printf("FAIL: cqe_fail was called %d times on well-formed calls (last: %s)\n", wf_fail, last_fail);
  run_negative();
  printf("tmpl-fp: %ld comparisons, %ld against native (agree), %ld against CR §2 table "
         "(native differs from the table in %ld), %ld mismatches\n",
         n_cmp, n_native_agree, n_table, n_table_native_differs, n_bad);
  for (int fi = 0; fi < NFMT; ++fi)
    printf("  %s: %ld comparisons, %ld against native, %ld against the table, %ld mismatches\n", fmts[fi].name,
           w_cmp[fi], w_native[fi], w_table[fi], w_bad[fi]);
  for (int op = 0; op < NOPS; ++op)
    for (int fi = 0; fi < NFMT; ++fi)
      if (tbl_diff[op][fi])
      {
        printf("  table rows where native differs: %s_%s %ld of %ld table cases:", opname[op], fmts[fi].name,
               tbl_diff[op][fi], tbl_cnt[op][fi]);
        for (int w = 0; w < 4; ++w)
          if (diff_why[op][fi][w])
            printf(" %s %ld;", why_name[w], diff_why[op][fi][w]);
        printf("\n");
      }
  printf("tmpl-fp: %ld malformed/not-mine calls, %ld wrong\n", n_neg, n_neg_bad);
  return (n_bad || n_neg_bad || wf_fail) ? 1 : 0;
}
