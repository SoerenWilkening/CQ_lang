/* tmpl-int differential test (cq-w0-tmpl-int acceptance).
 *
 * For every (op, width[, to]) in cases.inc, the handler checker/rt/tmpl_int.c registered is run
 * against the same LLVM IR operation compiled by clang-19 -O1 and executed natively (native.ll from
 * gen_native.py) on edge values, fp specials, a seeded random set, and every input when the inputs
 * total at most 16 bits. The CR §2 rows where native LLVM is undefined are checked against literal
 * table values (table_rows) as well as against the guarded native functions. Malformed operand
 * lists must be rejected through cqe_fail (negative_tests). */
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"
#include "fake_cqe.h"

#define CQE_OP_NOT_MINE 1
#define MAXN 8 /* words; widths up to 512 bits */

typedef void (*native_fn)(const uint64_t *, const uint64_t *, uint64_t *);
typedef struct {
  const char *op, *w, *to, *shape;
  int arity;
  char fk; uint32_t fb; char tk; uint32_t tb;
  native_fn fn;
} case_t;
#include "cases.inc"

typedef struct { uint64_t w[MAXN]; } val_t;

static uint64_t rng_state;
static uint64_t rnd(void) { /* splitmix64 */
  uint64_t z = (rng_state += UINT64_C(0x9E3779B97F4A7C15));
  z = (z ^ (z >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
  z = (z ^ (z >> 27)) * UINT64_C(0x94D049BB133111EB);
  return z ^ (z >> 31);
}

static uint32_t nw(uint32_t bits) { return (bits + 63) / 64; }
static void mask(val_t *v, uint32_t bits) {
  for (uint32_t i = nw(bits); i < MAXN; ++i) v->w[i] = 0;
  if (bits % 64) v->w[nw(bits) - 1] &= (UINT64_C(1) << (bits % 64)) - 1;
}
static void setbit(val_t *v, uint32_t i) { v->w[i / 64] |= UINT64_C(1) << (i % 64); }
static val_t zero(void) { val_t v; memset(&v, 0, sizeof v); return v; }
static val_t ones(uint32_t bits) { val_t v; memset(&v, 0xff, sizeof v); mask(&v, bits); return v; }
static val_t small(uint64_t x, uint32_t bits) { val_t v = zero(); v.w[0] = x; mask(&v, bits); return v; }
static val_t int_min(uint32_t bits) { val_t v = zero(); setbit(&v, bits - 1); return v; }
static val_t negate(val_t a, uint32_t bits) {
  val_t o = zero(); uint64_t c = 1;
  for (uint32_t i = 0; i < MAXN; ++i) { uint64_t t = ~a.w[i] + c; c = c && t == 0; o.w[i] = t; }
  mask(&o, bits); return o;
}

/* ---- input sets ---- */

#define MAXV 512
static int add_val(val_t *vs, int n, val_t v, uint32_t bits) {
  mask(&v, bits);
  for (int i = 0; i < n; ++i) if (!memcmp(&vs[i], &v, sizeof v)) return n;
  if (n < MAXV) vs[n++] = v;
  return n;
}

static int fp_specials(val_t *vs, int n, uint32_t bits) {
  static const uint64_t h[] = {0x0000, 0x8000, 0x7C00, 0xFC00, 0x7E00, 0x7D00, 0xFE01, 0x0001,
                               0x8001, 0x03FF, 0x0400, 0x7BFF, 0x3C00, 0xBC00};
  static const uint64_t f[] = {0x00000000, 0x80000000, 0x7F800000, 0xFF800000, 0x7FC00000,
                               0x7FA00000, 0xFFC00001, 0x00000001, 0x80000001, 0x007FFFFF,
                               0x00800000, 0x7F7FFFFF, 0x3F800000, 0xBF800000};
  static const uint64_t d[] = {0, UINT64_C(0x8000000000000000), UINT64_C(0x7FF0000000000000),
                               UINT64_C(0xFFF0000000000000), UINT64_C(0x7FF8000000000000),
                               UINT64_C(0x7FF4000000000000), UINT64_C(0xFFF8000000000001), 1,
                               UINT64_C(0x8000000000000001), UINT64_C(0x000FFFFFFFFFFFFF),
                               UINT64_C(0x0010000000000000), UINT64_C(0x7FEFFFFFFFFFFFFF),
                               UINT64_C(0x3FF0000000000000), UINT64_C(0xBFF0000000000000)};
  /* x87 extended: {significand, sign|exponent}, including the non-canonical encodings */
  static const uint64_t x[][2] = {
      {0, 0}, {0, 0x8000},                                                   /* +-0 */
      {UINT64_C(0x8000000000000000), 0x7FFF}, {UINT64_C(0x8000000000000000), 0xFFFF}, /* +-Inf */
      {UINT64_C(0xC000000000000000), 0x7FFF}, {UINT64_C(0xC000000000000000), 0xFFFF}, /* qNaN, indefinite */
      {UINT64_C(0x8000000000000001), 0x7FFF},                                /* sNaN */
      {1, 0}, {UINT64_C(0x7FFFFFFFFFFFFFFF), 0x8000},                        /* subnormals */
      {UINT64_C(0x8000000000000000), 1}, {UINT64_C(0xFFFFFFFFFFFFFFFF), 0x7FFE}, /* min normal, max */
      {UINT64_C(0x8000000000000000), 0x3FFF}, {UINT64_C(0x8000000000000000), 0xBFFF}, /* +-1 */
      {UINT64_C(0x4000000000000000), 0x7FFF}, {0, 0x7FFF},                   /* pseudo-NaN, pseudo-Inf */
      {UINT64_C(0x4000000000000000), 0x3FFF}, {UINT64_C(0x8000000000000000), 0}}; /* unnormal, pseudo-denormal */
  const uint64_t *t = NULL; size_t k = 0;
  if (bits == 16) { t = h; k = sizeof h / sizeof h[0]; }
  if (bits == 32) { t = f; k = sizeof f / sizeof f[0]; }
  if (bits == 64) { t = d; k = sizeof d / sizeof d[0]; }
  for (size_t i = 0; i < k; ++i) n = add_val(vs, n, small(t[i], bits), bits);
  if (bits == 80)
    for (size_t i = 0; i < sizeof x / sizeof x[0]; ++i) {
      val_t v = zero(); v.w[0] = x[i][0]; v.w[1] = x[i][1]; n = add_val(vs, n, v, bits);
    }
  return n;
}

static int edges(val_t *vs, int n, uint32_t bits) {
  n = add_val(vs, n, zero(), bits);
  n = add_val(vs, n, small(1, bits), bits);
  n = add_val(vs, n, small(2, bits), bits);
  n = add_val(vs, n, small(3, bits), bits);
  n = add_val(vs, n, small(7, bits), bits);
  n = add_val(vs, n, ones(bits), bits);                        /* -1 */
  n = add_val(vs, n, negate(small(2, bits), bits), bits);      /* -2 */
  n = add_val(vs, n, negate(small(3, bits), bits), bits);      /* -3 */
  val_t mn = int_min(bits);
  n = add_val(vs, n, mn, bits);                                /* MIN */
  val_t mn1 = mn; mn1.w[0] |= 1; n = add_val(vs, n, mn1, bits); /* MIN+1 */
  val_t mx = ones(bits); mx.w[(bits - 1) / 64] &= ~(UINT64_C(1) << ((bits - 1) % 64));
  n = add_val(vs, n, mx, bits);                                /* MAX */
  val_t mx1 = mx; mx1.w[0] &= ~UINT64_C(1); n = add_val(vs, n, mx1, bits); /* MAX-1 */
  val_t p; memset(&p, 0x55, sizeof p); n = add_val(vs, n, p, bits);
  memset(&p, 0xAA, sizeof p); n = add_val(vs, n, p, bits);
  uint32_t pos[] = {bits / 2, bits > 1 ? bits - 2 : 0, 31, 32, 63, 64, 65, 127, 128};
  for (size_t i = 0; i < sizeof pos / sizeof pos[0]; ++i)
    if (pos[i] < bits) { val_t b = zero(); setbit(&b, pos[i]); n = add_val(vs, n, b, bits); }
  val_t lw = zero(); lw.w[0] = ~UINT64_C(0); n = add_val(vs, n, lw, bits); /* 2^64-1 */
  return fp_specials(vs, n, bits);
}

static val_t random_val(uint32_t bits) {
  val_t v = zero();
  for (uint32_t i = 0; i < nw(bits); ++i) v.w[i] = rnd();
  mask(&v, bits);
  uint32_t sh = (uint32_t)(rnd() % bits); /* random magnitude, so small divisors occur */
  if (rnd() & 1) {
    for (uint32_t k = 0; k < sh; ++k) { /* logical shift right by one */
      for (uint32_t i = 0; i < MAXN - 1; ++i) v.w[i] = (v.w[i] >> 1) | (v.w[i + 1] << 63);
      v.w[MAXN - 1] >>= 1;
    }
    if (rnd() & 1) v = negate(v, bits); /* small negatives */
  }
  return v;
}

static int randoms(val_t *vs, int n, uint32_t bits, int count) {
  for (int i = 0; i < count; ++i) n = add_val(vs, n, random_val(bits), bits);
  return n;
}

/* ---- running the handler ---- */

static long n_cmp, n_mismatch, n_table, n_neg;

static int run_handler(const char *op, const char *w, const char *to, const char *shape, int unc,
                       const val_t *args, const uint32_t *abits, const char *akind, int nargs,
                       val_t *res, uint32_t *rbits, char *rkind, int prealloc) {
  cqe_tname tn; memset(&tn, 0, sizeof tn);
  snprintf(tn.op, sizeof tn.op, "%s", op);
  snprintf(tn.w, sizeof tn.w, "%s", w);
  snprintf(tn.to, sizeof tn.to, "%s", to);
  snprintf(tn.shape, sizeof tn.shape, "%s", shape);
  tn.unc = (uint8_t)unc;
  cqe_val av[3]; uint64_t abuf[3][MAXN];
  for (int i = 0; i < nargs; ++i) {
    memcpy(abuf[i], args[i].w, sizeof abuf[i]);
    av[i].bits = abits[i]; av[i].kind = akind[i]; av[i].nw = nw(abits[i]); av[i].w = abuf[i];
  }
  uint64_t obuf[MAXN];
  cqe_val out; memset(&out, 0, sizeof out);
  if (prealloc) { memset(obuf, 0xEE, sizeof obuf); out.w = obuf; out.nw = MAXN; }
  cqe_op_fn fn = fake_lookup(op);
  if (!fn) { fprintf(stderr, "op %s not registered\n", op); exit(1); }
  int rc = fn(&tn, av, nargs, &out);
  *res = zero();
  if (rc == 0) {
    for (uint32_t i = 0; i < out.nw && i < MAXN; ++i) res->w[i] = out.w[i];
    *rbits = out.bits; *rkind = out.kind;
    if (out.nw != nw(out.bits)) { fprintf(stderr, "%s_%s: out.nw %u for %u bits\n", op, w, out.nw, out.bits); exit(1); }
    /* the handler must leave bits above out.bits zero */
    val_t m = *res; mask(&m, out.bits);
    if (memcmp(&m, res, sizeof m)) { fprintf(stderr, "%s_%s: bits above the width set\n", op, w); exit(1); }
    if (!prealloc) free(out.w);
    for (uint32_t i = nw(out.bits); prealloc && i < MAXN; ++i)
      if (obuf[i] != UINT64_C(0xEEEEEEEEEEEEEEEE)) { fprintf(stderr, "%s_%s: wrote past the result\n", op, w); exit(1); }
  }
  for (int i = 0; i < nargs; ++i)
    if (memcmp(abuf[i], args[i].w, sizeof abuf[i])) { fprintf(stderr, "%s_%s: operand modified\n", op, w); exit(1); }
  return rc;
}

static void print_val(const char *tag, const val_t *v, uint32_t bits) {
  fprintf(stderr, " %s=0x", tag);
  for (int i = (int)nw(bits) - 1; i >= 0; --i) fprintf(stderr, "%016" PRIx64, v->w[i]);
}

static void diff_one(const case_t *c, const val_t *a, const val_t *b, long k) {
  val_t args[2] = {*a, b ? *b : zero()};
  uint32_t abits[2] = {c->fb, c->fb};
  char akind[2] = {c->fk, c->fk};
  val_t nat = zero();
  c->fn(args[0].w, args[1].w, nat.w);
  mask(&nat, c->tb);
  val_t got; uint32_t rb = 0; char rk = 0;
  int rc = run_handler(c->op, c->w, c->to, c->shape, (int)(k & 2) != 0, args, abits, akind,
                       c->arity, &got, &rb, &rk, (int)(k & 1));
  ++n_cmp;
  if (rc != 0 || rb != c->tb || rk != c->tk || memcmp(&got, &nat, sizeof got)) {
    if (++n_mismatch <= 40) {
      fprintf(stderr, "MISMATCH %s_%s%s%s rc=%d", c->op, c->w, c->to[0] ? "_to_" : "", c->to, rc);
      print_val("a", a, c->fb);
      if (b) print_val("b", b, c->fb);
      print_val("native", &nat, c->tb);
      print_val("ours", &got, c->tb);
      fprintf(stderr, " (%c%u %s)\n", rk ? rk : '?', rb, fake_fail_last);
    }
  }
}

static val_t VS[MAXV];

static void run_case(const case_t *c, int idx) {
  rng_state = UINT64_C(0xC0DE5EED) ^ ((uint64_t)idx << 20);
  long k = 0;
  if (c->arity == 2) {
    if (c->fb <= 8) { /* exhaustive: inputs total at most 16 bits */
      for (uint64_t x = 0; x < (UINT64_C(1) << c->fb); ++x)
        for (uint64_t y = 0; y < (UINT64_C(1) << c->fb); ++y) {
          val_t a = small(x, c->fb), b = small(y, c->fb);
          diff_one(c, &a, &b, k++);
        }
      return;
    }
    int ne = edges(VS, 0, c->fb);
    int nv = randoms(VS, ne, c->fb, 64);
    for (int i = 0; i < nv; ++i)
      for (int j = 0; j < nv; ++j)
        if (i < ne || j < ne || ((i * 131 + j) % 7) == 0) diff_one(c, &VS[i], &VS[j], k++);
    for (int r = 0; r < 2000; ++r) {
      val_t a = random_val(c->fb), b = random_val(c->fb);
      diff_one(c, &a, &b, k++);
    }
  } else {
    if (c->fb <= 16) {
      for (uint64_t x = 0; x < (UINT64_C(1) << c->fb); ++x) { val_t a = small(x, c->fb); diff_one(c, &a, NULL, k++); }
      return;
    }
    int nv = randoms(VS, edges(VS, 0, c->fb), c->fb, 400);
    for (int i = 0; i < nv; ++i) diff_one(c, &VS[i], NULL, k++);
  }
}

/* ---- CR §2 rows that differ from native LLVM, against literal table values ---- */

static void expect(const char *op, uint32_t bits, val_t a, val_t b, val_t want, const char *row) {
  char w[16]; snprintf(w, sizeof w, "i%u", bits);
  val_t args[2] = {a, b}; uint32_t ab[2] = {bits, bits}; char ak[2] = {'i', 'i'};
  val_t got; uint32_t rb = 0; char rk = 0;
  int rc = run_handler(op, w, "", n_table & 1 ? "hl" : "", 0, args, ab, ak, 2, &got, &rb, &rk, 0);
  ++n_table;
  mask(&want, bits);
  if (rc != 0 || memcmp(&got, &want, sizeof got)) {
    ++n_mismatch;
    fprintf(stderr, "TABLE %s %s_i%u rc=%d", row, op, bits, rc);
    print_val("a", &a, bits); print_val("b", &b, bits);
    print_val("want", &want, bits); print_val("ours", &got, bits);
    fprintf(stderr, "\n");
  }
}

static void table_rows(void) {
  static const uint32_t W[] = {1, 2, 3, 7, 8, 16, 32, 33, 63, 64, 65, 80, 100, 127, 128, 129, 192, 256};
  for (size_t wi = 0; wi < sizeof W / sizeof W[0]; ++wi) {
    uint32_t bits = W[wi];
    rng_state = UINT64_C(0x7AB1E) + bits;
    int nv = randoms(VS, edges(VS, 0, bits), bits, 32);
    for (int i = 0; i < nv; ++i) {
      val_t a = VS[i];
      int neg = (a.w[(bits - 1) / 64] >> ((bits - 1) % 64)) & 1;
      expect("udiv", bits, a, zero(), ones(bits), "udiv(a,0)=2^W-1");
      expect("urem", bits, a, zero(), a, "urem(a,0)=a");
      expect("sdiv", bits, a, zero(), neg ? small(1, bits) : ones(bits), "sdiv(a,0)=a>=0?-1:+1");
      expect("srem", bits, a, zero(), a, "srem(a,0)=a");
    }
    expect("sdiv", bits, int_min(bits), ones(bits), int_min(bits), "sdiv(INT_MIN,-1)=INT_MIN");
    expect("srem", bits, int_min(bits), ones(bits), zero(), "srem(INT_MIN,-1)=0");
  }
}

/* ---- malformed operand lists are rejected through cqe_fail; foreign templates pass ---- */

static void neg_case(const char *what, const char *op, const char *w, const char *to,
                     const char *shape, uint8_t pred_rm_exc, int nargs, uint32_t b0, char k0,
                     int want_rc, int prealloc_small) {
  cqe_tname tn; memset(&tn, 0, sizeof tn);
  snprintf(tn.op, sizeof tn.op, "%s", op); snprintf(tn.w, sizeof tn.w, "%s", w);
  snprintf(tn.to, sizeof tn.to, "%s", to); snprintf(tn.shape, sizeof tn.shape, "%s", shape);
  if (pred_rm_exc == 1) snprintf(tn.pred, sizeof tn.pred, "eq");
  if (pred_rm_exc == 2) tn.rm = 1;
  if (pred_rm_exc == 3) tn.exc = 1;
  if (pred_rm_exc == 4) tn.strided = 1;
  uint64_t buf[3][MAXN]; memset(buf, 0, sizeof buf);
  cqe_val av[3];
  for (int i = 0; i < 3; ++i) { av[i].bits = b0; av[i].kind = k0; av[i].nw = nw(b0 ? b0 : 1); av[i].w = buf[i]; }
  uint64_t ob[1]; cqe_val out; memset(&out, 0, sizeof out);
  if (prealloc_small) { out.w = ob; out.nw = 1; }
  int before = fake_fail_count;
  int rc = fake_lookup(op)(&tn, av, nargs, &out);
  int failed = fake_fail_count != before;
  ++n_neg;
  int ok = rc == want_rc && failed == (want_rc == -1);
  if (!ok) {
    ++n_mismatch;
    fprintf(stderr, "NEGATIVE %s: rc=%d (want %d), cqe_fail %s\n", what, rc, want_rc, failed ? "called" : "not called");
  }
  if (rc == 0 && !prealloc_small) free(out.w);
}

static void negative_tests(void) {
  neg_case("fp trunc is another family's", "trunc", "f64", "", "", 0, 1, 64, 'f', CQE_OP_NOT_MINE, 0);
  neg_case("binary arity", "add", "i32", "", "", 0, 1, 32, 'i', -1, 0);
  neg_case("binary arity 3", "mul", "i32", "", "", 0, 3, 32, 'i', -1, 0);
  neg_case("cast arity", "zext", "i8", "i32", "", 0, 2, 8, 'i', -1, 0);
  neg_case("operand width", "add", "i32", "", "", 0, 2, 64, 'i', -1, 0);
  neg_case("operand narrower", "udiv", "i128", "", "", 0, 2, 64, 'i', -1, 0);
  neg_case("operand kind", "add", "i64", "", "", 0, 2, 64, 'f', -1, 0);
  neg_case("fp width on add", "add", "f64", "", "", 0, 2, 64, 'f', -1, 0);
  neg_case("binary with _to_", "sub", "i32", "i64", "", 0, 2, 32, 'i', -1, 0);
  neg_case("zext narrowing", "zext", "i32", "i8", "", 0, 1, 32, 'i', -1, 0);
  neg_case("zext same width", "zext", "i32", "i32", "", 0, 1, 32, 'i', -1, 0);
  neg_case("sext from fp", "sext", "f32", "i64", "", 0, 1, 32, 'f', -1, 0);
  neg_case("trunc widening", "trunc", "i8", "i32", "", 0, 1, 8, 'i', -1, 0);
  neg_case("trunc to fp", "trunc", "i64", "f32", "", 0, 1, 64, 'i', -1, 0);
  neg_case("bitcast bit count", "bitcast", "f64", "i32", "", 0, 1, 64, 'f', -1, 0);
  neg_case("bitcast without _to_", "bitcast", "i64", "", "", 0, 1, 64, 'i', -1, 0);
  neg_case("predicate", "add", "i32", "", "", 1, 2, 32, 'i', -1, 0);
  neg_case("rounding mode", "add", "i32", "", "", 2, 2, 32, 'i', -1, 0);
  neg_case("_exc", "sdiv", "i32", "", "", 3, 2, 32, 'i', -1, 0);
  neg_case("stride", "zext", "i8", "i32", "", 4, 1, 8, 'i', -1, 0);
  neg_case("shape length", "add", "i32", "", "hll", 0, 2, 32, 'i', -1, 0);
  neg_case("shape letter", "add", "i32", "", "hx", 0, 2, 32, 'i', -1, 0);
  neg_case("width i0", "add", "i0", "", "", 0, 2, 0, 'i', -1, 0);
  neg_case("width ix", "add", "ix", "", "", 0, 2, 32, 'i', -1, 0);
  neg_case("width f128", "bitcast", "f128", "i128", "", 0, 1, 128, 'f', -1, 0);
  neg_case("result buffer too small", "add", "i128", "", "", 0, 2, 128, 'i', -1, 1);
  neg_case("well-formed control", "add", "i128", "", "hl", 0, 2, 128, 'i', 0, 0);

  /* and, or and xor (the i1 data templates included) are tmpl-bits' (owner ruling, bead cq-f69):
   * tmpl-int registers none of them, and its handler declines them without cqe_fail if reached. */
  {
    static const char *const bitops[] = {"and", "or", "xor"};
    static const char *const bw[] = {"i1", "i8", "i32", "i64", "i128"};
    for (size_t i = 0; i < 3; ++i) {
      ++n_neg;
      if (fake_lookup(bitops[i])) { ++n_mismatch; fprintf(stderr, "NEGATIVE %s is registered by tmpl-int\n", bitops[i]); }
      for (size_t j = 0; j < sizeof bw / sizeof bw[0]; ++j) {
        cqe_tname tn; memset(&tn, 0, sizeof tn);
        snprintf(tn.op, sizeof tn.op, "%s", bitops[i]); snprintf(tn.w, sizeof tn.w, "%s", bw[j]);
        uint32_t b = (uint32_t)atoi(bw[j] + 1);
        uint64_t buf[2][MAXN], ob[MAXN]; memset(buf, 0, sizeof buf); memset(ob, 0, sizeof ob);
        cqe_val av[2], out;
        for (int k = 0; k < 2; ++k) { av[k].bits = b; av[k].kind = 'i'; av[k].nw = nw(b); av[k].w = buf[k]; }
        out.bits = b; out.kind = 'i'; out.nw = nw(b); out.w = ob;
        int before = fake_fail_count;
        int rc = fake_lookup("add")(&tn, av, 2, &out); /* tmpl-int's one handler */
        ++n_neg;
        if (rc != CQE_OP_NOT_MINE || fake_fail_count != before) {
          ++n_mismatch;
          fprintf(stderr, "NEGATIVE %s_%s: rc=%d (want CQE_OP_NOT_MINE), cqe_fail %s\n", bitops[i], bw[j], rc,
                  fake_fail_count != before ? "called" : "not called");
        }
      }
    }
  }

  /* Bits above W in an operand word are not read (CR §1.2: the low W bits only). */
  {
    val_t a = small(6, 64), b = small(3, 64); a.w[0] |= 0xFF80; b.w[0] |= UINT64_C(0xFFFFFFFFFFFFFF80);
    val_t args[2] = {a, b}; uint32_t ab[2] = {7, 7}; char ak[2] = {'i', 'i'};
    val_t got; uint32_t rb; char rk;
    int rc = run_handler("udiv", "i7", "", "", 0, args, ab, ak, 2, &got, &rb, &rk, 0);
    ++n_neg;
    if (rc || got.w[0] != 2) { ++n_mismatch; fprintf(stderr, "NEGATIVE high junk udiv: rc=%d got %" PRIu64 "\n", rc, got.w[0]); }
    val_t c = small(0x7F, 64); c.w[0] |= 0x100; /* i7 0x7F with junk at bit 8 */
    uint32_t cb[1] = {7}; char ck[1] = {'i'};
    rc = run_handler("zext", "i7", "i32", "", 0, &c, cb, ck, 1, &got, &rb, &rk, 1);
    ++n_neg;
    if (rc || got.w[0] != 0x7F) { ++n_mismatch; fprintf(stderr, "NEGATIVE high junk zext: got %" PRIx64 "\n", got.w[0]); }
    rc = run_handler("sext", "i7", "i32", "", 0, &c, cb, ck, 1, &got, &rb, &rk, 0);
    ++n_neg;
    if (rc || got.w[0] != 0xFFFFFFFF) { ++n_mismatch; fprintf(stderr, "NEGATIVE high junk sext: got %" PRIx64 "\n", got.w[0]); }
  }
}

int main(void) {
  static const char *const ops[] = {"add",  "sub",  "mul",  "udiv",  "sdiv",   "urem",
                                    "srem", "zext", "sext", "trunc", "bitcast"};
  for (size_t i = 0; i < sizeof ops / sizeof ops[0]; ++i)
    if (!fake_lookup(ops[i])) { fprintf(stderr, "op %s not registered\n", ops[i]); return 1; }

  int ncases = (int)(sizeof CASES / sizeof CASES[0]);
  for (int i = 0; i < ncases; ++i) run_case(&CASES[i], i);
  long diff = n_cmp;
  table_rows();
  negative_tests();
  printf("tmpl-int: %d native cases, %ld differential comparisons, %ld CR §2 table checks, "
         "%ld negative checks, %ld mismatches\n", ncases, diff, n_table, n_neg, n_mismatch);
  return n_mismatch ? 1 : 0;
}
