/* rt-mem differential and semantic test (cq-w0-rt-mem).
 *
 * Drives checker/rt/rt_mem.c through the raw-op convention (see its header) on a mock core, and
 * compares every in-range QROM/QRAM read against native x86-64 code: the same LLVM IR memory
 * operation (getelementptr + load/store of the element type, and of a struct field for the strided
 * form) compiled by clang-19 -O1 (native.ll from gen_native.py). Out-of-range indices (CR §2: load 0,
 * store a no-op) are checked against the table, not against native code. Widths: every corpus width
 * (i1 i7 i8 i16 i32 i64 i80 i100 i128 f16 f32 f64 f80), edge values, fp specials, a seeded random set.
 *
 * Usage: harness [seed]        all checks; exit 0 iff every check passed
 *        harness --exit-kept   leave a QRAM with unpopped stores for the exit-event check */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"
#include "mock_core.h"
#include "native_table.h"

static int g_checks, g_bad;
#define CHECK(cond, ...)                                  \
  do {                                                    \
    ++g_checks;                                           \
    if (!(cond)) {                                        \
      ++g_bad;                                            \
      fprintf(stderr, "FAIL %s:%d: ", __FILE__, __LINE__); \
      fprintf(stderr, __VA_ARGS__);                       \
      fprintf(stderr, "\n");                              \
    }                                                     \
  } while (0)

/* ---------------------------------------------------------------- helpers */

static uint64_t g_rng = 0x9E3779B97F4A7C15ull;
static uint64_t rnd(void) {
  g_rng ^= g_rng >> 12;
  g_rng ^= g_rng << 25;
  g_rng ^= g_rng >> 27;
  return g_rng * 0x2545F4914F6CDD1Dull;
}

typedef struct { _Alignas(16) uint64_t w[4]; } val4; /* 16-aligned: native i128/f80 moves */ /* up to 256 bits; corpus widths need 2 words */

static void maskw(val4 *v, uint32_t bits) {
  for (uint32_t i = 0; i < 4; ++i) {
    uint32_t lo = i * 64;
    if (lo >= bits) v->w[i] = 0;
    else if (bits - lo < 64) v->w[i] &= (UINT64_C(1) << (bits - lo)) - 1;
  }
}

static int eqw(const uint64_t *a, const uint64_t *b, uint32_t bits) {
  val4 x = {{0}}, y = {{0}};
  memcpy(x.w, a, ((bits + 63) / 64) * 8);
  memcpy(y.w, b, ((bits + 63) / 64) * 8);
  maskw(&x, bits);
  maskw(&y, bits);
  return memcmp(&x, &y, sizeof x) == 0;
}

static int zerow(const uint64_t *a, uint32_t bits) {
  val4 z = {{0}};
  return eqw(a, z.w, bits);
}

static val4 v_of(uint64_t lo, uint64_t hi, uint32_t bits) {
  val4 v = {{lo, hi, 0, 0}};
  maskw(&v, bits);
  return v;
}

/* Edge values, fp specials and random values of a width; k picks one. */
static val4 gen_value(const nat_width *nw, uint64_t k) {
  uint32_t b = nw->bits;
  if (nw->kind == 'f') {
    static const uint64_t f16[] = {0x0000, 0x8000, 0x7c00, 0xfc00, 0x7e00, 0x7d00, 0x0001, 0x8001, 0x3c00, 0x7bff, 0x0400};
    static const uint64_t f32[] = {0, 0x80000000, 0x7f800000, 0xff800000, 0x7fc00000, 0x7fa00000,
                                   0x00000001, 0x80000001, 0x3f800000, 0x7f7fffff, 0x00800000};
    static const uint64_t f64[] = {0, 0x8000000000000000ull, 0x7ff0000000000000ull, 0xfff0000000000000ull,
                                   0x7ff8000000000000ull, 0x7ff4000000000000ull, 1, 0x8000000000000001ull,
                                   0x3ff0000000000000ull, 0x7fefffffffffffffull, 0x0010000000000000ull};
    static const uint64_t f80lo[] = {0, 0, 0x8000000000000000ull, 0x8000000000000000ull, 0xC000000000000000ull,
                                     0xA000000000000000ull, 1, 1, 0x8000000000000000ull, 0xFFFFFFFFFFFFFFFFull,
                                     0x4000000000000000ull, 0x4000000000000000ull};
    static const uint64_t f80hi[] = {0, 0x8000, 0x7fff, 0xffff, 0x7fff, 0x7fff, 0, 0x8000, 0x3fff, 0x7ffe,
                                     0x7fff /* pseudo-NaN */, 0x3fff /* unnormal */};
    size_t ns = b == 16 ? 11 : b == 32 ? 11 : b == 64 ? 11 : 12;
    if (k < ns) {
      if (b == 16) return v_of(f16[k], 0, b);
      if (b == 32) return v_of(f32[k], 0, b);
      if (b == 64) return v_of(f64[k], 0, b);
      return v_of(f80lo[k], f80hi[k], b);
    }
  } else {
    val4 ones = v_of(~0ull, ~0ull, b);
    val4 top = {{0}}, max = ones;
    top.w[(b - 1) / 64] = UINT64_C(1) << ((b - 1) % 64);
    max.w[(b - 1) / 64] &= ~top.w[(b - 1) / 64];
    switch (k) {
    case 0: return v_of(0, 0, b);
    case 1: return v_of(1, 0, b);
    case 2: return ones;      /* -1 */
    case 3: return top;       /* MIN */
    case 4: return max;       /* MAX */
    case 5: return v_of(2, 0, b);
    default: break;
    }
  }
  return v_of(rnd(), rnd(), b);
}

static cqe_tname tn(const char *op, const char *w, const char *shape, int strided, int unc) {
  cqe_tname t;
  memset(&t, 0, sizeof t);
  snprintf(t.op, sizeof t.op, "%s", op);
  snprintf(t.w, sizeof t.w, "%s", w);
  snprintf(t.shape, sizeof t.shape, "%s", shape);
  t.strided = (uint8_t)strided;
  t.unc = (uint8_t)unc;
  return t;
}

/* Calls a raw op; arg i is a[i] with width bits[i]. Returns the out value (a handle) or -1. */
static int32_t call(const char *op, const cqe_tname *t, int n, const uint64_t *a, const uint32_t *bits) {
  uint64_t store[8];
  cqe_val v[8];
  for (int i = 0; i < n; ++i) {
    store[i] = a[i];
    v[i] = (cqe_val){bits[i], 'i', 1, &store[i]};
  }
  uint64_t ow = 0; /* M1: the dispatcher presets out (an i32 handle result; void calls leave it alone) */
  cqe_val out = {32, 'i', 1, &ow};
  int r = mock_dispatch(op, t, v, n, &out);
  if (r != 0 && r != -1) fprintf(stderr, "unexpected return %d from %s\n", r, op), abort();
  if (r == -1) return -1;
  return (int32_t)(uint32_t)ow;
}

static int32_t rail(const char *w, val4 v) {
  char kind = w[0] == 'f' ? 'f' : 'i';
  uint32_t bits = (uint32_t)strtoul(w + 1, NULL, 10);
  maskw(&v, bits);
  cqe_val init = {bits, kind, (bits + 63) / 64, v.w};
  return cqe_new_rail(w, &init, 1);
}

static const char *itok(uint32_t bits) {
  static char buf[8][8];
  static int k;
  char *b = buf[k++ % 8];
  snprintf(b, 8, "i%u", bits);
  return b;
}

/* ---- thin wrappers over the QRAM ops (u32 = an i32 argument) ---- */
#define H32 32u
static int32_t q_alloc(const char *w, uint32_t n) {
  cqe_tname t = tn("qram_alloc", w, "", 0, 0);
  uint64_t a[] = {n};
  uint32_t b[] = {H32};
  return call("qram_alloc", &t, 1, a, b);
}
static int32_t q_realloc(const char *w, int32_t bus, uint32_t n, int unc) {
  cqe_tname t = tn("qram_realloc", w, "", 0, unc);
  uint64_t a[] = {(uint32_t)bus, n};
  uint32_t b[] = {H32, H32};
  return call("qram_realloc", &t, 2, a, b);
}
static void q_free(int32_t bus) {
  cqe_tname t = tn("qram_free", "", "", 0, 0);
  uint64_t a[] = {(uint32_t)bus};
  uint32_t b[] = {H32};
  call("qram_free", &t, 1, a, b);
}
/* c < 0: uncontrolled. hl: idx is the literal j. */
static void q_store(const char *w, int unc, int32_t c, int32_t bus, int hl, uint32_t idx, int32_t v) {
  cqe_tname t = tn("qram_store", w, hl ? "hl" : "", 0, unc);
  if (c >= 0) snprintf(t.pred, sizeof t.pred, "ctl"); /* C1 */
  uint64_t a[4];
  uint32_t b[4] = {H32, H32, H32, H32};
  int n = 0;
  if (c >= 0) a[n++] = (uint32_t)c;
  a[n++] = (uint32_t)bus;
  a[n++] = idx;
  a[n++] = (uint32_t)v;
  call("qram_store", &t, n, a, b);
}
static int32_t q_load(const char *w, int32_t unc_h, int32_t c, int32_t bus, int hl, uint32_t idx) {
  cqe_tname t = tn("qram_load", w, hl ? "hl" : "", 0, unc_h >= 0);
  if (c >= 0) snprintf(t.pred, sizeof t.pred, "ctl"); /* C1 */
  uint64_t a[4];
  uint32_t b[4] = {H32, H32, H32, H32};
  int n = 0;
  if (unc_h >= 0) a[n++] = (uint32_t)unc_h;
  if (c >= 0) a[n++] = (uint32_t)c;
  a[n++] = (uint32_t)bus;
  a[n++] = idx;
  return call("qram_load", &t, n, a, b);
}
/* QROM as the M1 dispatcher drives a template: arguments resolved to values (the index rail's
 * value at its width, ptr a 64-bit 'i'), out preallocated and zeroed with bits/kind preset, the
 * handler returns f(args); forward: a fresh rail o holds it; _unc: it is XORed into o. Returns o, or
 * -1 when the handler failed. */
static int32_t qrom(const char *w, int unc_o, void *table, uint64_t n, int strided, uint64_t stride, int32_t idx) {
  cqe_tname t = tn("qrom_load", w, "", strided, unc_o >= 0);
  uint64_t st[3] = {(uint64_t)(uintptr_t)table, n, stride};
  cqe_val a[4];
  int k = 0;
  a[k++] = (cqe_val){64, 'i', 1, &st[0]};
  a[k++] = (cqe_val){64, 'i', 1, &st[1]};
  if (strided) a[k++] = (cqe_val){64, 'i', 1, &st[2]};
  const cqe_val *ir = cqe_rail(idx);
  if (!ir) abort();
  a[k++] = *ir;
  uint64_t pre[4] = {0};
  uint32_t ob = (uint32_t)strtoul(w + 1, NULL, 10);
  cqe_val out = {ob, w[0] == 'f' ? 'f' : 'i', (ob + 63) / 64, pre};
  int r = mock_dispatch("qrom_load", &t, a, k, &out);
  if (r != 0) return -1;
  int32_t o = unc_o;
  if (unc_o < 0)
    o = cqe_new_rail(w, &out, 0);
  else
    cqe_xor_into(unc_o, &out);
  if (out.w != pre || out.bits != ob || out.nw != (ob + 63) / 64) fprintf(stderr, "qrom: out replaced\n"), abort();
  return o;
}

static void *alloc_buf(size_t n) {
  void *p = NULL;
  if (posix_memalign(&p, 16, n + 64)) abort();
  memset(p, 0xA5, n + 64); /* garbage around the elements: only W bits may be read */
  return p;
}

/* ------------------------------------------------------------------ QROM */

static const uint32_t IDXW[] = {1, 7, 8, 32, 64, 100};

static void test_qrom_width(const nat_width *nw, int strided) {
  int64_t lay[3];
  char scratch[64];
  nw->layout(scratch, lay);
  uint64_t esz = strided ? (uint64_t)lay[1] : (uint64_t)lay[2];
  uint64_t n = 1 + rnd() % 12;
  for (int big = 0; big < 2; ++big) {
    if (big) n = 256; /* 76: n = 256 with an i8 index (unsigned 255 is in range) */
    char *buf = alloc_buf(n * esz);
    void *base = strided ? buf + lay[0] : buf;
    nat_fn st = strided ? nw->aos_store : nw->store, ld = strided ? nw->aos_load : nw->load;
    val4 *elems = calloc(n, sizeof *elems);
    for (uint64_t i = 0; i < n; ++i) {
      elems[i] = gen_value(nw, i + 1); /* element 0 nonzero: a misread index shows */
      st(buf, (int64_t)i, elems[i].w);
    }
    for (size_t wi = 0; wi < sizeof IDXW / sizeof IDXW[0]; ++wi) {
      uint32_t ib = IDXW[wi];
      if (big && ib != 8) continue;
      val4 cand[32];
      int nc = 0;
      for (uint64_t i = 0; i < n && i < 16; ++i) cand[nc++] = v_of(i, 0, ib);
      if (big) { cand[nc++] = v_of(255, 0, ib); cand[nc++] = v_of(128, 0, ib); }
      cand[nc++] = v_of(n, 0, ib);
      cand[nc++] = v_of(n + 1, 0, ib);
      cand[nc++] = v_of(~0ull, ~0ull, ib); /* -1: unsigned, out of range */
      val4 top = {{0}};
      top.w[(ib - 1) / 64] = UINT64_C(1) << ((ib - 1) % 64);
      cand[nc++] = top;
      cand[nc++] = v_of(rnd(), rnd(), ib);
      cand[nc++] = v_of(rnd() % (n + 2), 0, ib);
      for (int ci = 0; ci < nc; ++ci) {
        val4 iv = cand[ci];
        int in_range = iv.w[1] == 0 && iv.w[0] < n;
        int32_t ih = rail(itok(ib), iv);
        int fails0 = mock_fails();
        int32_t o = qrom(nw->tok, -1, base, n, strided, esz, ih);
        val4 want = {{0}};
        if (in_range) ld(buf, (int64_t)iv.w[0], want.w); /* native read */
        CHECK(o >= 0 && eqw(mock_words(o), want.w, nw->bits), "qrom%s_%s idx i%u=%llx n=%llu: got %llx:%llx want %llx:%llx",
              strided ? "_s" : "", nw->tok, ib, (unsigned long long)iv.w[0], (unsigned long long)n,
              (unsigned long long)mock_words(o)[nw->bits > 64], (unsigned long long)mock_words(o)[0],
              (unsigned long long)want.w[1], (unsigned long long)want.w[0]);
        CHECK(mock_known(o) == 0, "qrom result must not be known");
        /* rule 20: the _unc uses the table AT THE LOAD; change host memory first */
        if (in_range) {
          val4 other = gen_value(nw, 1000 + ci);
          other.w[0] ^= 1;
          st(buf, (int64_t)iv.w[0], other.w);
        }
        CHECK(qrom(nw->tok, o, base, n, strided, esz, ih) == o, "qrom _unc failed");
        if (zerow(mock_words(o), nw->bits)) cqe_set_known(o, 1); /* the dispatcher's residue check */
        CHECK(mock_fails() == fails0, "qrom%s_%s: unexpected violation: %s", strided ? "_s" : "", nw->tok, mock_last_fail());
        CHECK(zerow(mock_words(o), nw->bits) && mock_known(o) == 1, "qrom%s_%s _unc did not return the rail to known 0",
              strided ? "_s" : "", nw->tok);
        if (in_range) st(buf, (int64_t)iv.w[0], elems[iv.w[0]].w);
        mock_free(o);
        mock_free(ih);
      }
    }
    free(elems);
    free(buf);
  }
}

/* ------------------------------------------------------------------ QRAM */

enum { OP_STORE, OP_LOAD, OP_REALLOC };
typedef struct {
  int kind;
  int32_t bus, c, v, h; /* h: load result, or the new bus of a realloc */
  int hl;
  uint32_t idx; /* j, or the index rail handle */
  uint32_t n_old;
} qop;

#define MAXCELLS 16
static void test_qram_width(const nat_width *nw, int trials) {
  int64_t lay[3];
  char scratch[64];
  nw->layout(scratch, lay);
  uint64_t esz = (uint64_t)lay[2];
  for (int tr = 0; tr < trials; ++tr) {
    char *shadow = alloc_buf(MAXCELLS * esz);
    uint32_t n = 1 + (uint32_t)(rnd() % 8);
    val4 zero = {{0}};
    for (uint32_t i = 0; i < MAXCELLS; ++i) nw->store(shadow, i, zero.w);
    int32_t a0 = q_alloc(nw->tok, n), a = a0;
    int fails0 = mock_fails();
    qop ops[24];
    int nops = 0, depth = 0;
    for (int s = 0; s < 24; ++s) {
      uint64_t r = rnd() % 10;
      qop *op = &ops[nops];
      memset(op, 0, sizeof *op);
      op->bus = a;
      op->c = -1;
      if (r == 9) {
        if (depth >= 3) continue;
        uint32_t nn = 1 + (uint32_t)(rnd() % 10); /* n = 0 is 2^64 cells: test_unknown_extent */
        op->kind = OP_REALLOC;
        op->n_old = n;
        op->h = q_realloc(nw->tok, a, nn, 0);
        CHECK(op->h >= 0 && op->h != a, "realloc must return a fresh bus");
        for (uint32_t i = n; i < nn; ++i) nw->store(shadow, i, zero.w); /* grown: fresh |0> cells */
        n = nn;
        a = op->h;
        depth++;
        nops++;
        continue;
      }
      /* index: a literal j or an index rail of some width; sometimes out of range */
      uint64_t iv = rnd() % (n + 3);
      uint32_t ib = (uint32_t[]){8, 32, 1, 100, 7}[rnd() % 5];
      op->hl = rnd() % 2;
      if (rnd() % 8 == 0) iv = op->hl ? 0xFFFFFFFFull : ~0ull;
      val4 ivv = v_of(iv, op->hl ? 0 : (iv == ~0ull ? ~0ull : 0), op->hl ? 32 : ib);
      int in_range = ivv.w[1] == 0 && ivv.w[0] < n;
      op->idx = op->hl ? (uint32_t)ivv.w[0] : (uint32_t)rail(itok(ib), ivv);
      int cval = 1;
      if (rnd() % 3 == 0) {
        cval = (int)(rnd() % 2);
        op->c = rail("i1", v_of((uint64_t)cval, 0, 1));
      }
      if (r < 5) {
        op->kind = OP_STORE;
        val4 v = gen_value(nw, rnd() % 16);
        op->v = rail(nw->tok, v);
        q_store(nw->tok, 0, op->c, a, op->hl, op->idx, op->v);
        if (cval && in_range) nw->store(shadow, (int64_t)ivv.w[0], v.w); /* native */
      } else {
        op->kind = OP_LOAD;
        op->h = q_load(nw->tok, -1, op->c, a, op->hl, op->idx);
        val4 want = {{0}};
        if (cval && in_range) nw->load(shadow, (int64_t)ivv.w[0], want.w); /* native */
        CHECK(op->h >= 0 && eqw(mock_words(op->h), want.w, nw->bits),
              "qram_load_%s%s%s idx %llx (n %u, c %d): got %llx want %llx", nw->tok, op->hl ? "_hl" : "",
              op->c >= 0 ? "_controlled" : "", (unsigned long long)ivv.w[0], n, cval,
              (unsigned long long)mock_words(op->h)[0], (unsigned long long)want.w[0]);
      }
      nops++;
    }
    CHECK(mock_fails() == fails0, "qram_%s forward: unexpected violation: %s", nw->tok, mock_last_fail());
    /* uncompute in reverse: every pop and un-copy must be clean, then the object frees at 0 */
    for (int i = nops - 1; i >= 0; --i) {
      qop *op = &ops[i];
      if (op->kind == OP_STORE) {
        q_store(nw->tok, 1, op->c, op->bus, op->hl, op->idx, op->v);
      } else if (op->kind == OP_LOAD) {
        q_load(nw->tok, op->h, op->c, op->bus, op->hl, op->idx);
        CHECK(zerow(mock_words(op->h), nw->bits) && mock_known(op->h) == 1, "qram_load_unc must leave a known 0");
      } else {
        q_realloc(nw->tok, op->h, op->n_old, 1);
      }
    }
    q_free(a0);
    CHECK(mock_fails() == fails0, "qram_%s uncompute/free: unexpected violation: %s", nw->tok, mock_last_fail());
    free(shadow);
  }
}

/* --------------------------------------------- violations the family must report */

#define EXPECT_FAIL(stmt, what)                                                    \
  do {                                                                             \
    int f0_ = mock_fails();                                                        \
    stmt;                                                                          \
    CHECK(mock_fails() > f0_, "expected a violation: %s", what);                   \
  } while (0)
#define EXPECT_OK(stmt, what)                                                      \
  do {                                                                             \
    int f0_ = mock_fails();                                                        \
    stmt;                                                                          \
    CHECK(mock_fails() == f0_, "unexpected violation (%s): %s", what, mock_last_fail()); \
  } while (0)

static void test_violations(const char *w) {
  uint32_t bits = (uint32_t)strtoul(w + 1, NULL, 10);
  val4 five = v_of(5, 0, bits), seven = v_of(7, 0, bits), ones = v_of(~0ull, ~0ull, bits);
  int32_t v5 = rail(w, five), v7 = rail(w, seven), vm = rail(w, ones);
  int32_t i2 = rail("i8", v_of(2, 0, 8)), i3 = rail("i32", v_of(3, 0, 32));

  /* pops on the same cell out of LIFO order */
  int32_t a = q_alloc(w, 4);
  EXPECT_OK(q_store(w, 0, -1, a, 0, (uint32_t)i2, v5), "store");
  EXPECT_OK(q_store(w, 0, -1, a, 1, 2, v7), "store_hl same cell");
  EXPECT_FAIL(q_store(w, 1, -1, a, 0, (uint32_t)i2, v5), "pop out of LIFO order on a cell");

  /* stores to different cells commute */
  a = q_alloc(w, 4);
  EXPECT_OK(q_store(w, 0, -1, a, 0, (uint32_t)i2, v5), "store cell 2");
  EXPECT_OK(q_store(w, 0, -1, a, 0, (uint32_t)i3, v7), "store cell 3");
  EXPECT_OK(q_store(w, 1, -1, a, 0, (uint32_t)i2, v5), "pop cell 2 first (commutes)");
  EXPECT_OK(q_store(w, 1, -1, a, 0, (uint32_t)i3, v7), "pop cell 3");
  EXPECT_OK(q_free(a), "free after all pops");

  /* a pop whose value rail changed */
  a = q_alloc(w, 4);
  int32_t vx = rail(w, five);
  EXPECT_OK(q_store(w, 0, -1, a, 1, 1, vx), "store");
  cqe_val sv = {bits, w[0] == 'f' ? 'f' : 'i', (bits + 63) / 64, seven.w};
  cqe_xor_into(vx, &sv);
  EXPECT_FAIL(q_store(w, 1, -1, a, 1, 1, vx), "pop with v changed");

  /* a pop with no matching store; free with an unpopped store; double free */
  a = q_alloc(w, 4);
  EXPECT_FAIL(q_store(w, 1, -1, a, 1, 0, v5), "pop with no store");
  EXPECT_OK(q_store(w, 0, -1, a, 1, 0, v5), "store");
  EXPECT_FAIL(q_free(a), "free with an unpopped store");
  EXPECT_FAIL(q_free(a), "double free");
  a = q_alloc(w, 4);
  int32_t vz = rail(w, v_of(0, 0, bits));
  EXPECT_OK(q_store(w, 0, -1, a, 1, 2, vz), "store of 0 (every cell stays 0)");
  EXPECT_FAIL(q_free(a), "free with an unpopped store of 0 (its slot is still allocated)");

  /* load _unc after the cell changed; load _unc with different operands */
  a = q_alloc(w, 4);
  int32_t l = q_load(w, -1, -1, a, 1, 1);
  EXPECT_OK(q_store(w, 0, -1, a, 1, 1, v7), "store over the loaded cell");
  EXPECT_FAIL(q_load(w, l, -1, a, 1, 1), "load_unc residue");
  a = q_alloc(w, 4);
  EXPECT_OK(q_store(w, 0, -1, a, 1, 1, v7), "store");
  l = q_load(w, -1, -1, a, 1, 0);
  EXPECT_FAIL(q_load(w, l, -1, a, 1, 2), "load_unc with a different j");

  /* stale bus after realloc; realloc_unc with an unpopped store through a'; wrong n_old */
  a = q_alloc(w, 4);
  int32_t a2 = q_realloc(w, a, 6, 0);
  EXPECT_FAIL(q_load(w, -1, -1, a, 1, 0), "load through a stale bus");
  EXPECT_FAIL(q_store(w, 0, -1, a, 1, 0, v5), "store through a stale bus");
  EXPECT_FAIL(q_realloc(w, a2, 3, 1), "realloc_unc with the wrong n_old");
  a = q_alloc(w, 4);
  a2 = q_realloc(w, a, 6, 0);
  EXPECT_OK(q_store(w, 0, -1, a2, 1, 5, v5), "store into a grown cell");
  EXPECT_FAIL(q_realloc(w, a2, 4, 1), "realloc_unc with an unpopped store through a'");
  EXPECT_FAIL(q_load(w, -1, -1, 12345, 1, 0), "unknown bus handle");

  /* grow after shrink maps the new indices to FRESH cells, never to the hidden ones */
  a = q_alloc(w, 4);
  EXPECT_OK(q_store(w, 0, -1, a, 1, 3, v5), "store cell 3");
  a2 = q_realloc(w, a, 2, 0);
  int32_t a3 = q_realloc(w, a2, 4, 0);
  l = q_load(w, -1, -1, a3, 1, 3);
  CHECK(zerow(mock_words(l), bits), "grown index 3 is a fresh |0> cell, not the hidden one");
  int32_t lh = q_load(w, -1, -1, a2, 1, 1);
  CHECK(lh < 0, "a' is stale after a later realloc");
  EXPECT_OK(q_load(w, l, -1, a3, 1, 3), "un-copy");
  EXPECT_OK(q_realloc(w, a3, 2, 1), "undo grow");
  EXPECT_OK(q_realloc(w, a2, 4, 1), "undo shrink");
  l = q_load(w, -1, -1, a, 1, 3);
  CHECK(eqw(mock_words(l), five.w, bits), "the hidden cell is exposed again after the undo");
  EXPECT_OK(q_load(w, l, -1, a, 1, 3), "un-copy");
  EXPECT_OK(q_store(w, 1, -1, a, 1, 3, v5), "pop");
  EXPECT_OK(q_free(a), "free");

  /* C1: pred "ctl" without the control argument is malformed */
  a = q_alloc(w, 2);
  {
    cqe_tname t = tn("qram_load", w, "hl", 0, 0);
    snprintf(t.pred, sizeof t.pred, "ctl");
    uint64_t args2[] = {(uint32_t)a, 0};
    uint32_t b2[] = {32, 32};
    EXPECT_FAIL(call("qram_load", &t, 2, args2, b2), "pred ctl with 2 arguments");
  }

  /* a width mismatch between the call and the object */
  a = q_alloc(w, 4);
  EXPECT_FAIL(q_store(bits == 8 ? "i32" : "i8", 0, -1, a, 1, 0, v5), "store of the wrong width");

  /* §2: out-of-range stores are no-ops whose slot stays |0>; loads read 0 */
  a = q_alloc(w, 4);
  int32_t big = rail("i8", v_of(0xFF, 0, 8)); /* unsigned 255 >= 4 */
  EXPECT_OK(q_store(w, 0, -1, a, 0, (uint32_t)big, vm), "out-of-range store");
  EXPECT_OK(q_store(w, 0, -1, a, 1, 0xFFFFFFFFu, vm), "out-of-range store_hl (j = -1)");
  EXPECT_OK(q_store(w, 0, -1, a, 1, 4, vm), "out-of-range store_hl (j = n)");
  l = q_load(w, -1, -1, a, 0, (uint32_t)big);
  CHECK(zerow(mock_words(l), bits), "out-of-range load reads 0");
  int32_t l2 = q_load(w, -1, -1, a, 1, 3);
  CHECK(zerow(mock_words(l2), bits), "no out-of-range store touched cell 3");
  EXPECT_OK(q_load(w, l2, -1, a, 1, 3), "un-copy");
  EXPECT_OK(q_load(w, l, -1, a, 0, (uint32_t)big), "un-copy out of range");
  EXPECT_OK(q_store(w, 1, -1, a, 1, 4, vm), "pop no-op");
  EXPECT_OK(q_store(w, 1, -1, a, 1, 0xFFFFFFFFu, vm), "pop no-op");
  EXPECT_OK(q_store(w, 1, -1, a, 0, (uint32_t)big, vm), "pop no-op");
  EXPECT_OK(q_free(a), "free");

  /* _controlled with c = 0: nothing happens */
  a = q_alloc(w, 2);
  int32_t c0 = rail("i1", v_of(0, 0, 1)), c1 = rail("i1", v_of(1, 0, 1));
  EXPECT_OK(q_store(w, 0, c0, a, 1, 1, v5), "controlled store, c = 0");
  l = q_load(w, -1, c1, a, 1, 1);
  CHECK(zerow(mock_words(l), bits), "c = 0 store left the cell alone");
  EXPECT_OK(q_store(w, 0, c1, a, 1, 1, v7), "controlled store, c = 1");
  l2 = q_load(w, -1, c0, a, 1, 1);
  CHECK(zerow(mock_words(l2), bits), "controlled load with c = 0 reads 0");
  int32_t l3 = q_load(w, -1, c1, a, 1, 1);
  CHECK(eqw(mock_words(l3), seven.w, bits), "controlled load with c = 1 reads the cell");
  EXPECT_OK(q_load(w, l3, c1, a, 1, 1), "un-copy");
  EXPECT_OK(q_load(w, l2, c0, a, 1, 1), "un-copy");
  EXPECT_FAIL(q_store(w, 1, c0, a, 1, 1, v7), "pop with a different control rail");
  EXPECT_OK(q_store(w, 1, c1, a, 1, 1, v7), "pop");
  EXPECT_OK(q_load(w, l, c1, a, 1, 1), "un-copy");
  EXPECT_OK(q_store(w, 1, c0, a, 1, 1, v5), "pop c = 0 store");
  EXPECT_OK(q_free(a), "free");

  /* a pop whose control rail changed value */
  a = q_alloc(w, 2);
  int32_t cx = rail("i1", v_of(1, 0, 1));
  EXPECT_OK(q_store(w, 0, cx, a, 1, 0, v5), "controlled store");
  cqe_val one = {1, 'i', 1, (uint64_t[]){1}};
  cqe_xor_into(cx, &one);
  EXPECT_FAIL(q_store(w, 1, cx, a, 1, 0, v5), "pop with c changed");

  /* QROM: _unc with a changed index rail, a different table, or no forward */
  uint64_t tab[4] = {11, 22, 33, 44};
  int32_t qi = rail("i32", v_of(1, 0, 32));
  int32_t o = qrom("i64", -1, tab, 4, 0, 0, qi);
  cqe_val two = {32, 'i', 1, (uint64_t[]){2}};
  cqe_xor_into(qi, &two);
  EXPECT_FAIL(qrom("i64", o, tab, 4, 0, 0, qi), "qrom _unc with a changed index");
  qi = rail("i32", v_of(1, 0, 32));
  o = qrom("i64", -1, tab, 4, 0, 0, qi);
  EXPECT_FAIL(qrom("i64", o, tab + 1, 4, 0, 0, qi), "qrom _unc with a different table");
  int32_t qj = rail("i32", v_of(3, 0, 32));
  EXPECT_FAIL(qrom("i64", v5, tab, 4, 0, 0, qj), "qrom _unc with no forward of these operands");
  /* not this family's template: NOT_MINE, no violation */
  {
    cqe_tname t = tn("add", "i32", "", 0, 0);
    uint64_t pre[1] = {0};
    cqe_val out = {32, 'i', 1, pre};
    int f0 = mock_fails();
    CHECK(mock_handler("qrom_load")(&t, NULL, 0, &out) == 1 && mock_fails() == f0, "a foreign op must be NOT_MINE");
  }
}

/* ------------------------------- unknown extent (n = 0: 2^64 cells) and qram_size (CQ_spec f684858) */

static int32_t q_size(int32_t bus) {
  cqe_tname t = tn("qram_size", "", "", 0, 0);
  uint64_t a[] = {(uint32_t)bus};
  uint32_t b[] = {H32};
  return call("qram_size", &t, 1, a, b);
}

static void test_unknown_extent(const char *w) {
  uint32_t bits = (uint32_t)strtoul(w + 1, NULL, 10);
  val4 five = v_of(5, 0, bits), seven = v_of(7, 0, bits);
  int32_t v5 = rail(w, five), v7 = rail(w, seven);
  int32_t far = rail("i64", v_of(UINT64_C(1) << 40, 0, 64));          /* far past any i32 count */
  int32_t top = rail("i64", v_of(~UINT64_C(0), 0, 64));               /* 2^64 - 1: the last cell */
  int32_t over = rail("i100", v_of(0, 1, 100));                       /* 2^64: out of range */

  /* alloc(0): every index below 2^64 is a cell; qram_size reads 0 back */
  int32_t a = q_alloc(w, 0);
  CHECK(a >= 0 && q_size(a) == 0, "qram_size of an unknown-extent bus is 0");
  EXPECT_OK(q_store(w, 0, -1, a, 0, (uint32_t)far, v5), "store at 2^40");
  EXPECT_OK(q_store(w, 0, -1, a, 0, (uint32_t)top, v7), "store at 2^64 - 1");
  EXPECT_OK(q_store(w, 0, -1, a, 0, (uint32_t)over, v7), "store at 2^64 (out of range: a no-op)");
  int32_t l1 = q_load(w, -1, -1, a, 0, (uint32_t)far), l2 = q_load(w, -1, -1, a, 0, (uint32_t)top);
  int32_t l3 = q_load(w, -1, -1, a, 0, (uint32_t)over), l4 = q_load(w, -1, -1, a, 1, 0xFFFFFFFFu);
  CHECK(eqw(mock_words(l1), five.w, bits) && eqw(mock_words(l2), seven.w, bits), "cells 2^40 and 2^64 - 1 hold their stores");
  CHECK(zerow(mock_words(l3), bits) && zerow(mock_words(l4), bits), "2^64 is out of range; cell 2^32 - 1 is an untouched |0>");

  /* shrink to 4 hides 2^40; size reads 4; undo with n_old = 0 exposes it again */
  int32_t a2 = q_realloc(w, a, 4, 0);
  CHECK(a2 >= 0 && q_size(a2) == 4, "qram_size after the shrink");
  int32_t l5 = q_load(w, -1, -1, a2, 0, (uint32_t)far);
  CHECK(zerow(mock_words(l5), bits), "2^40 is out of range after the shrink to 4");
  EXPECT_OK(q_load(w, l5, -1, a2, 0, (uint32_t)far), "un-copy");
  EXPECT_FAIL(q_realloc(w, a2, 4, 1), "realloc_unc with n_old 4 (it was 2^64)");
  a2 = q_realloc(w, a, 4, 0);
  EXPECT_OK(q_realloc(w, a2, 0, 1), "realloc_unc back to 2^64 cells");
  CHECK(q_size(a) == 0, "qram_size after the undo");
  EXPECT_OK(q_load(w, l4, -1, a, 1, 0xFFFFFFFFu), "un-copy");
  EXPECT_OK(q_load(w, l3, -1, a, 0, (uint32_t)over), "un-copy");
  EXPECT_OK(q_load(w, l2, -1, a, 0, (uint32_t)top), "un-copy");
  EXPECT_OK(q_load(w, l1, -1, a, 0, (uint32_t)far), "un-copy");
  EXPECT_OK(q_store(w, 1, -1, a, 0, (uint32_t)over, v7), "pop");
  EXPECT_OK(q_store(w, 1, -1, a, 0, (uint32_t)top, v7), "pop");
  EXPECT_OK(q_store(w, 1, -1, a, 0, (uint32_t)far, v5), "pop");
  EXPECT_OK(q_free(a), "free of an unknown-extent object at 0");

  /* grow a finite object to 2^64: the kept prefix is the old cells, the rest fresh */
  a = q_alloc(w, 3);
  EXPECT_OK(q_store(w, 0, -1, a, 1, 2, v5), "store cell 2");
  a2 = q_realloc(w, a, 0, 0);
  CHECK(q_size(a2) == 0 && q_size(a) < 0, "the grown bus reads 0; the old one is stale");
  l1 = q_load(w, -1, -1, a2, 1, 2);
  CHECK(eqw(mock_words(l1), five.w, bits), "cell 2 survives the grow to 2^64");
  EXPECT_OK(q_store(w, 0, -1, a2, 0, (uint32_t)far, v7), "store at 2^40 through the grown bus");
  EXPECT_OK(q_store(w, 1, -1, a2, 0, (uint32_t)far, v7), "pop");
  EXPECT_OK(q_load(w, l1, -1, a2, 1, 2), "un-copy");
  EXPECT_OK(q_realloc(w, a2, 3, 1), "undo the grow");
  CHECK(q_size(a) == 3, "qram_size after the undo of the grow");
  EXPECT_OK(q_store(w, 1, -1, a, 1, 2, v5), "pop");
  EXPECT_OK(q_free(a), "free");

  /* realloc_unc with a store through a' (of 2^64 cells) unpopped */
  a = q_alloc(w, 3);
  a2 = q_realloc(w, a, 0, 0);
  EXPECT_OK(q_store(w, 0, -1, a2, 0, (uint32_t)far, v7), "store at 2^40");
  EXPECT_FAIL(q_realloc(w, a2, 3, 1), "realloc_unc with a store through a' unpopped");

  /* a grown cell left dirty is reported by realloc_unc */
  a = q_alloc(w, 1);
  a2 = q_realloc(w, a, 0, 0);
  EXPECT_OK(q_store(w, 0, -1, a2, 0, (uint32_t)far, v7), "store");
  EXPECT_FAIL(q_realloc(w, a2, 1, 1), "realloc_unc over a dirty grown cell");

  /* QROM of unknown extent (n = 0): host memory at any index; an unmapped address reads 0 */
  if (bits == 32) {
    uint32_t tab[8] = {10, 11, 12, 13, 14, 15, 16, 17};
    int32_t i5 = rail("i32", v_of(5, 0, 32));
    int32_t o = qrom("i32", -1, tab, 0, 0, 0, i5);
    CHECK(o >= 0 && mock_words(o)[0] == 15, "qrom n = 0 reads tab[5]");
    EXPECT_OK(qrom("i32", o, tab, 0, 0, 0, i5), "qrom n = 0 _unc");
    CHECK(zerow(mock_words(o), 32), "qrom n = 0 _unc returns the rail to 0");
    int32_t ifar = rail("i64", v_of(UINT64_C(1) << 60, 0, 64));
    o = qrom("i32", -1, (void *)(uintptr_t)16, 0, 0, 0, ifar);
    CHECK(o >= 0 && zerow(mock_words(o), 32), "qrom n = 0 at an unmapped address reads 0");
  }
}

/* ------------------------------------------- reference call sequences of the corpus */

static void test_corpus_sequences(void) {
  for (uint32_t k = 0; k < 8; ++k) {
    for (int vi = 0; vi < 3; ++vi) {
      uint64_t vv = (uint64_t[]){0, 9, 0xFF}[vi];
      /* 91 heap_quantum_size */
      int f0 = mock_fails();
      int32_t idx = rail("i32", v_of(k & 3, 0, 32)), v = rail("i8", v_of(vv, 0, 8));
      int32_t a = q_alloc("i8", 3);
      q_store("i8", 0, -1, a, 0, (uint32_t)idx, v);
      int32_t a2 = q_realloc("i8", a, 6, 0);
      int32_t one = rail("i8", v_of(1, 0, 8));
      q_store("i8", 0, -1, a2, 1, 5, one);
      int32_t l = q_load("i8", -1, -1, a2, 1, 1);
      CHECK(mock_words(l)[0] == ((k & 3) == 1 ? vv : 0), "91: a[1]");
      q_load("i8", l, -1, a2, 1, 1);
      q_store("i8", 1, -1, a2, 1, 5, one);
      q_realloc("i8", a2, 3, 1);
      q_store("i8", 1, -1, a, 0, (uint32_t)idx, v);
      q_free(a);
      CHECK(mock_fails() == f0, "91 sequence (k %u): %s", k, mock_last_fail());

      /* 186 free_qram, first function */
      f0 = mock_fails();
      int32_t two = rail("i8", v_of(2, 0, 8)), idx2 = rail("i32", v_of(k % 6, 0, 32));
      a = q_alloc("i8", 4);
      q_store("i8", 0, -1, a, 0, (uint32_t)idx, v);
      int32_t l1 = q_load("i8", -1, -1, a, 1, 1);
      a2 = q_realloc("i8", a, 6, 0);
      q_store("i8", 0, -1, a2, 1, 5, two);
      int32_t l2 = q_load("i8", -1, -1, a2, 0, (uint32_t)idx2);
      uint64_t want = k % 6 == 5 ? 2 : k % 6 == 4 ? 0 : (k % 6 == (k & 3) ? vv : 0);
      CHECK(mock_words(l2)[0] == want, "186: a[k %% 6] (k %u)", k);
      q_load("i8", l2, -1, a2, 0, (uint32_t)idx2);
      q_store("i8", 1, -1, a2, 1, 5, two);
      q_realloc("i8", a2, 4, 1);
      q_load("i8", l1, -1, a, 1, 1);
      q_store("i8", 1, -1, a, 0, (uint32_t)idx, v);
      q_free(a);
      CHECK(mock_fails() == f0, "186 sequence (k %u): %s", k, mock_last_fail());

      /* 192 realloc_vla_global_guarded, the shrink */
      f0 = mock_fails();
      int32_t i1 = rail("i32", v_of(k & 1, 0, 32));
      a = q_alloc("i8", 4);
      q_store("i8", 0, -1, a, 0, (uint32_t)idx, v);
      a2 = q_realloc("i8", a, 2, 0);
      l = q_load("i8", -1, -1, a2, 0, (uint32_t)i1);
      CHECK(mock_words(l)[0] == ((k & 1) == (k & 3) ? vv : 0), "192: a[k & 1] after the shrink");
      q_realloc("i8", a2, 4, 1);
      q_store("i8", 1, -1, a, 0, (uint32_t)idx, v);
      q_free(a);
      CHECK(mock_fails() == f0, "192 sequence (k %u): %s", k, mock_last_fail());
    }
  }
}

/* A QRAM left with unpopped stores (160's global QRAM): the exit event lists its cells and slots. */
static int exit_kept(void) {
  int32_t a = q_alloc("i32", 4);
  int32_t v5 = rail("i32", v_of(5, 0, 32)), v7 = rail("i32", v_of(7, 0, 32)), c0 = rail("i1", v_of(0, 0, 1));
  q_store("i32", 0, -1, a, 1, 3, v5);  /* slot 0, cell 3 = 5 */
  q_store("i32", 0, -1, a, 1, 3, v7);  /* slot 5, cell 3 = 7 */
  q_store("i32", 0, c0, a, 1, 1, v7);  /* c = 0: slot 0 */
  return mock_fails() == 0 ? 0 : 1;
}

int main(int argc, char **argv) {
  if (argc > 1 && strcmp(argv[1], "--exit-kept") == 0) return exit_kept();
  if (argc > 1) g_rng = strtoull(argv[1], NULL, 0) | 1;
  for (int i = 0; i < NAT_NWIDTHS; ++i) {
    test_qrom_width(&NAT_WIDTHS[i], 0);
    test_qrom_width(&NAT_WIDTHS[i], 1);
    test_qram_width(&NAT_WIDTHS[i], 40);
  }
  test_violations("i8");
  test_violations("i32");
  test_violations("i100");
  test_violations("f80");
  test_unknown_extent("i8");
  test_unknown_extent("i32");
  test_unknown_extent("i100");
  test_corpus_sequences();
  printf("rt-mem: %d checks, %d failed (%d widths, %d violations logged)\n", g_checks, g_bad, NAT_NWIDTHS, mock_fails());
  return g_bad ? 1 : 0;
}
