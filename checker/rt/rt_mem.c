/* rt_mem.c (cq-w0-rt-mem): evaluator semantics of QROM and QRAM on basis values.
 *
 * Semantics: CONSTRUCTION_RULES §1.2 (qrom), §1.3 (qram_*), §2 (out-of-range rows), rule 20; CR wins
 * over BACKEND_ABI §1.10/§2.11, which this file also follows. Any width N: values are little-endian
 * 64-bit words, nothing is tabulated per width.
 *
 * Handler contract: M1 in cqe.h (freeze bead cq-mgi). 0 = handled, CQE_OP_NOT_MINE = not this
 * family's call (decided from tname and nargs, nothing touched), -1 = cqe_fail was called. out is the
 * dispatcher's: preallocated, zeroed, bits/kind preset; out_words() is the only code touching it.
 *
 * QROM (cq_template_qrom_load_<W>[_s], ops qrom_load / qrom_load_s): the M1 template path. args
 * are the data operands in signature order (table ptr, i64 n, [i64 stride,] the index rail's VALUE at
 * its width); the handler returns the forward value whatever tname->unc says and the dispatcher XORs
 * it into out. Rule 20: the forward snapshots T[idx]; the _unc returns that snapshot, never a re-read
 * of host memory. M1 does not hand the _unc its out handle o, so the snapshot is keyed by the
 * operands (table, n, stride, W, index value) and the most recent unconsumed one is used: exact for
 * uncompute in reverse order; two loads with identical operands over a table that changed between
 * them, uncomputed out of order, would swap snapshots (noted on cq-mgi). Index >= n (unsigned at the
 * index rail's width): 0 and no host read (CR §2).
 *
 * QRAM (cqrt_qram_*, ops qram_alloc, qram_realloc, qram_store, qram_load, qram_free, plus
 * qram_store_controlled / qram_load_controlled in case the dispatcher keeps the suffix): stateful
 * ops, which a pure f(args) cannot express: the M1 family path (op spelling: cq-4cy):
 *   - args[] are the call's ABI arguments in ABI order, unresolved: a handle is its i32 number, a
 *     literal its value; for a _unc the out handle comes first, as in the ABI signature;
 *   - the op does all rail work itself (cqe_new_rail, cqe_rail, cqe_xor_into, cqe_set_known), logs
 *     {"ev":"qram",...} events and calls cqe_fail on a violation;
 *   - out receives the returned handle (bits 32) of a non-void call and is untouched for a void call;
 *   - _controlled is told by nargs (it adds argument 0), _hl by tname->shape == "hl".
 *
 * QRAM: an object is a list of physical cells plus a stack of views (bus handle, logical size n,
 * logical->physical map). realloc pushes a view (shrinking hides, growing maps to fresh cells),
 * realloc_unc pops it and drops the cells it appended. Every store owns a tape slot; a _unc pops the
 * most recent unpopped slot with identical (a, idx|j, v[, c]) and is evaluated at the view its forward
 * store saw. Live cells of unfreed objects and unpopped slots are reported at process exit as one
 * {"ev":"qram","op":"exit","live":[{"h","w","v","role"}]} event (roles qram_cell, qram_slot): they are
 * Kept items (CR §1.3, §0).
 *
 * Violations (cqe_fail, all prefixed "qram:" or "qrom:"): unknown or stale bus handle, width mismatch,
 * load _unc residue, load _unc operands differing from the forward, a pop with no matching store, a
 * pop whose v/idx/c changed since the forward, a pop out of LIFO order on a cell, a slot not |0> after
 * its pop, realloc_unc with an unpopped store made through a' or a wrong n_old, free with an unpopped
 * store or a nonzero cell, qrom _unc with no forward or with operands differing from the forward,
 * qrom _unc residue. */
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"


/* ------------------------------------------------------------------ values */

static uint32_t nwords(uint32_t bits) { return (bits + 63u) / 64u; }

static void mask_top(uint64_t *w, uint32_t bits) {
  uint32_t r = bits % 64u;
  if (r) w[nwords(bits) - 1] &= (UINT64_C(1) << r) - 1u;
}

static int is_zero(const uint64_t *w, uint32_t nw) {
  for (uint32_t i = 0; i < nw; ++i)
    if (w[i]) return 0;
  return 1;
}

static void *xcalloc(size_t n, size_t s) {
  void *p = calloc(n ? n : 1, s ? s : 1);
  if (!p) {
    fprintf(stderr, "cq: rt-mem: out of memory\n");
    abort();
  }
  return p;
}

static void *xrealloc(void *p, size_t s) {
  void *q = realloc(p, s ? s : 1);
  if (!q) {
    fprintf(stderr, "cq: rt-mem: out of memory\n");
    abort();
  }
  return q;
}

/* "0x..." of a W-bit value, most significant digit first, no leading zeros. The result lives in a
 * ring of four heap buffers, so up to four may be used in one expression; any width fits. */
static const char *hexs(const uint64_t *w, uint32_t bits) {
  static char *ring[4];
  static size_t cap[4];
  static unsigned next;
  unsigned r = next++ % 4u;
  uint32_t nw = nwords(bits);
  size_t need = (size_t)nw * 16u + 4u;
  if (cap[r] < need) {
    free(ring[r]);
    ring[r] = malloc(need);
    if (!ring[r]) {
      fprintf(stderr, "cq: rt-mem: out of memory\n");
      abort();
    }
    cap[r] = need;
  }
  int top = (int)nw - 1;
  while (top > 0 && w[top] == 0) --top;
  size_t k = (size_t)snprintf(ring[r], need, "0x%llx", (unsigned long long)w[top]);
  for (int i = top - 1; i >= 0; --i) k += (size_t)snprintf(ring[r] + k, need - k, "%016llx", (unsigned long long)w[i]);
  return ring[r];
}

/* A raw scalar argument: low 64 bits of the cqe_val, masked to its width. */
static uint64_t raw_u64(const cqe_val *v) {
  if (!v->w || v->nw == 0) return 0;
  uint64_t x = v->w[0];
  if (v->bits < 64) x &= (UINT64_C(1) << v->bits) - 1u;
  return x;
}

static int32_t raw_handle(const cqe_val *v) { return (int32_t)(uint32_t)raw_u64(v); }

/* Unsigned reading of a value of any width as an index; *big = 1 iff it does not fit in 64 bits. */
static uint64_t index_value(const cqe_val *v, int *big) {
  *big = 0;
  if (!v->w || v->nw == 0) return 0;
  uint64_t lo = v->w[0];
  if (v->bits < 64) lo &= (UINT64_C(1) << v->bits) - 1u;
  for (uint32_t i = 1; i < v->nw && i * 64u < v->bits; ++i) {
    uint64_t wi = v->w[i];
    uint32_t rem = v->bits - i * 64u;
    if (rem < 64) wi &= (UINT64_C(1) << rem) - 1u;
    if (wi) *big = 1;
  }
  return lo;
}

/* Width token -> bits, kind, alloc size (x86-64 data layout of the corpus triple:
 * e-m:o-...-i64:64-i128:128-f80:128). An iN without its own entry takes the alignment of the
 * smallest listed integer at least as wide, else of the widest (i128). */
typedef struct { uint32_t bits; char kind; uint64_t alloc; char tok[8]; } wdesc;

static int parse_width(const char *tok, wdesc *d) {
  memset(d, 0, sizeof *d);
  if (!tok || !tok[0] || strlen(tok) >= sizeof d->tok) return 0;
  snprintf(d->tok, sizeof d->tok, "%s", tok);
  char *end = NULL;
  unsigned long n = strtoul(tok + 1, &end, 10);
  if (!end || *end || n == 0) return 0;
  if (tok[0] == 'f') {
    d->kind = 'f';
    switch (n) {
    case 16: d->bits = 16; d->alloc = 2; return 1;
    case 32: d->bits = 32; d->alloc = 4; return 1;
    case 64: d->bits = 64; d->alloc = 8; return 1;
    case 80: d->bits = 80; d->alloc = 16; return 1;
    default: return 0;
    }
  }
  if (tok[0] != 'i' || n > 0xFFFFFFu) return 0;
  d->kind = 'i';
  d->bits = (uint32_t)n;
  uint64_t store = (n + 7u) / 8u, align;
  if (n <= 8) align = 1;
  else if (n <= 16) align = 2;
  else if (n <= 32) align = 4;
  else if (n <= 64) align = 8;
  else align = 16;
  d->alloc = (store + align - 1u) / align * align;
  return 1;
}

/* The W-bit little-endian element at host address p (reads ceil(W/8) bytes, nothing past them). */
static void read_element(uint64_t *w, const wdesc *d, uintptr_t p) {
  uint32_t nw = nwords(d->bits);
  memset(w, 0, nw * sizeof *w);
  memcpy(w, (const void *)p, (d->bits + 7u) / 8u); /* little-endian host */
  mask_top(w, d->bits);
}

static void make_val(cqe_val *v, const wdesc *d, uint64_t *w) {
  v->bits = d->bits;
  v->kind = d->kind;
  v->nw = nwords(d->bits);
  v->w = w;
}

/* THE one place that touches out's storage. M1 (cqe.h): the dispatcher owns out; it arrives with
 * out->w non-NULL, zeroed, out->nw = ceil(out->bits / 64) and bits/kind preset; the handler only
 * writes words. Checks the preset against the result this handler computes and returns the words,
 * or NULL after cqe_fail. */
static uint64_t *out_words(cqe_val *out, const wdesc *d, const char *what) {
  if (!out || !out->w || out->bits != d->bits || out->nw < nwords(d->bits)) {
    cqe_fail("%s: out preset as %u bits in %u words, the result is %s (%u bits)", what, out ? out->bits : 0,
             out ? out->nw : 0, d->tok, d->bits);
    return NULL;
  }
  memset(out->w, 0, out->nw * sizeof *out->w);
  return out->w;
}

/* A raw op's returned handle: an i32 result. */
static int set_out_handle(cqe_val *out, int32_t h) {
  static const wdesc i32 = {32, 'i', 4, "i32"};
  uint64_t *w = out_words(out, &i32, "qram: returned handle");
  if (!w) return -1;
  w[0] = (uint32_t)h;
  return 0;
}

static int rail_matches(const cqe_val *r, const wdesc *d) { return r && r->bits == d->bits; }

static void emit(const char *fmt, ...) {
  va_list ap, ap2;
  va_start(ap, fmt);
  va_copy(ap2, ap);
  int k = vsnprintf(NULL, 0, fmt, ap);
  va_end(ap);
  char *buf = xcalloc((size_t)k + 1, 1);
  vsnprintf(buf, (size_t)k + 1, fmt, ap2);
  va_end(ap2);
  cqe_log(buf);
  free(buf);
}

/* ------------------------------------------------------------------- QROM */

typedef struct {
  int live;
  uintptr_t table;
  uint64_t n, stride;
  int strided;
  uint32_t idx_bits;
  uint64_t idx_lo;
  int idx_big;
  wdesc d;
  uint64_t *val; /* T[idx] as read at the forward call (0 out of range) */
} qrom_snap;

static qrom_snap *g_snaps;
static size_t g_nsnaps, g_capsnaps;

static int op_qrom(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  if (strcmp(t->op, "qrom_load") != 0 && strcmp(t->op, "qrom_load_s") != 0) return CQE_OP_NOT_MINE;
  int strided = t->strided || strcmp(t->shape, "s") == 0 || strcmp(t->op, "qrom_load_s") == 0;
  int unc = t->unc != 0;
  const char *what = strided ? (unc ? "qrom: qrom_load_s_unc" : "qrom: qrom_load_s") : (unc ? "qrom: qrom_load_unc" : "qrom: qrom_load");
  int fwd_n = strided ? 4 : 3;
  if (nargs != fwd_n) {
    cqe_fail("%s: expected %d data operands, got %d", what, fwd_n, nargs);
    return -1;
  }
  wdesc d;
  if (!parse_width(t->w, &d)) {
    cqe_fail("%s: bad element width token '%s'", what, t->w);
    return -1;
  }
  uintptr_t table = (uintptr_t)raw_u64(&args[0]);
  uint64_t n = raw_u64(&args[1]);
  uint64_t stride = strided ? raw_u64(&args[2]) : d.alloc;
  const cqe_val *iv = &args[fwd_n - 1];
  int big;
  uint64_t idx = index_value(iv, &big);
  uint64_t *ow = out_words(out, &d, what);
  if (!ow) return -1;
  uint32_t nw = nwords(d.bits);

  if (!unc) {
    uint64_t *val = xcalloc(nw, sizeof *val);
    if (!big && idx < n) read_element(val, &d, table + (uintptr_t)(idx * stride));
    if (g_nsnaps == g_capsnaps) {
      g_capsnaps = g_capsnaps ? 2 * g_capsnaps : 64;
      g_snaps = xrealloc(g_snaps, g_capsnaps * sizeof *g_snaps);
    }
    g_snaps[g_nsnaps++] = (qrom_snap){1, table, n, stride, strided, iv->bits, idx, big, d, val};
    memcpy(ow, val, nw * sizeof *ow);
    return 0;
  }
  for (size_t i = g_nsnaps; i-- > 0;) {
    qrom_snap *s = &g_snaps[i];
    if (s->live && s->table == table && s->n == n && s->strided == strided && (!strided || s->stride == stride) &&
        s->d.bits == d.bits && s->d.kind == d.kind && s->idx_bits == iv->bits && s->idx_lo == idx && s->idx_big == big) {
      memcpy(ow, s->val, nw * sizeof *ow);
      s->live = 0;
      free(s->val);
      s->val = NULL;
      return 0;
    }
  }
  cqe_fail("%s: no forward qrom_load with these operands (table 0x%llx, n %llu, index 0x%llx at i%u)", what,
           (unsigned long long)table, (unsigned long long)n, (unsigned long long)idx, iv->bits);
  return -1;
}

/* ------------------------------------------------------------------- QRAM */

#define BUS_BASE 0x51000000
#define KEPT_ID_BASE 0x5A000000

typedef struct {
  int32_t bus;    /* the handle naming this view */
  uint32_t n;     /* logical size */
  uint32_t *map;  /* logical index -> physical cell */
  uint32_t phys0; /* physical cell count before this view (cells >= phys0 were appended by it) */
} qview;

typedef struct {
  int live;
  wdesc d;
  uint32_t nphys, capphys;
  uint64_t *cells; /* nphys * nw words */
  qview *views;
  uint32_t nviews, capviews;
} qobj;

typedef struct {
  int obj;
  int depth; /* view depth (index into views) the bus handle names */
  int dead;  /* realloc'd away (a), undone (a'), or freed */
} qbus;

typedef struct {
  int live; /* not yet popped */
  int obj, depth;
  int32_t bus;
  int hl;
  int32_t idx_h;
  uint64_t j;
  uint64_t idx_lo;
  int idx_big;
  int32_t v_h;
  int has_c;
  int32_t c_h;
  int c_fwd;
  int active; /* the forward swapped a cell (c = 1 and in range) */
  uint32_t p; /* physical cell, when active */
  uint64_t *t;     /* slot contents */
  uint64_t *v_fwd; /* v at the forward call */
  uint64_t seq;
} qslot;

typedef struct {
  int live;
  int32_t h;
  int32_t bus;
  int hl;
  int32_t idx_h;
  uint64_t j;
  int has_c;
  int32_t c_h;
} qload;

static qobj *g_objs;
static size_t g_nobjs, g_capobjs;
static qbus *g_bus;
static size_t g_nbus, g_capbus;
static qslot *g_slots;
static size_t g_nslots, g_capslots;
static qload *g_loads;
static size_t g_nloads, g_caploads;
static uint64_t g_seq;

static int32_t new_bus(int obj, int depth) {
  if (g_nbus == g_capbus) {
    g_capbus = g_capbus ? 2 * g_capbus : 16;
    g_bus = xrealloc(g_bus, g_capbus * sizeof *g_bus);
  }
  g_bus[g_nbus] = (qbus){obj, depth, 0};
  return (int32_t)(BUS_BASE + (int32_t)g_nbus++);
}

/* The object and view a bus handle names; NULL (and a violation) if unknown or stale. */
static qobj *bus_get(int32_t a, const char *what, qbus **bout) {
  int64_t k = (int64_t)a - BUS_BASE;
  if (k < 0 || (size_t)k >= g_nbus) {
    cqe_fail("qram: %s: %d is not a QRAM bus handle", what, a);
    return NULL;
  }
  qbus *b = &g_bus[k];
  qobj *o = &g_objs[b->obj];
  if (b->dead || !o->live) {
    cqe_fail("qram: %s: bus handle %d is no longer live (freed, realloc'd away, or its realloc undone)", what, a);
    return NULL;
  }
  if ((uint32_t)b->depth + 1 != o->nviews) {
    cqe_fail("qram: %s: bus handle %d is stale (a later realloc replaced it)", what, a);
    return NULL;
  }
  if (bout) *bout = b;
  return o;
}

static uint64_t *cell(qobj *o, uint32_t p) { return o->cells + (size_t)p * nwords(o->d.bits); }

static uint32_t append_cells(qobj *o, uint32_t k) {
  uint32_t nw = nwords(o->d.bits), first = o->nphys;
  if (o->nphys + k > o->capphys) {
    uint32_t cap = o->capphys ? o->capphys : 8;
    while (cap < o->nphys + k) cap *= 2;
    o->cells = xrealloc(o->cells, (size_t)cap * nw * sizeof *o->cells);
    o->capphys = cap;
  }
  memset(o->cells + (size_t)first * nw, 0, (size_t)k * nw * sizeof *o->cells);
  o->nphys += k;
  return first;
}

static qview *push_view(qobj *o) {
  if (o->nviews == o->capviews) {
    o->capviews = o->capviews ? 2 * o->capviews : 4;
    o->views = xrealloc(o->views, o->capviews * sizeof *o->views);
  }
  return &o->views[o->nviews++];
}

/* Index operand of a QRAM access: a rail (idx) or, for _hl, an i32 literal j read unsigned. */
typedef struct {
  int hl;
  int32_t idx_h;
  uint64_t j;
  uint64_t lo;
  int big;
} qindex;

static int read_index(const cqe_tname *t, const cqe_val *arg, qindex *ix, const char *what) {
  memset(ix, 0, sizeof *ix);
  ix->hl = strcmp(t->shape, "hl") == 0;
  if (ix->hl) {
    ix->j = raw_u64(arg) & 0xFFFFFFFFu; /* unsigned reading of the i32 literal */
    ix->lo = ix->j;
    return 1;
  }
  ix->idx_h = raw_handle(arg);
  const cqe_val *r = cqe_rail(ix->idx_h);
  if (!r) {
    cqe_fail("qram: %s: index handle %d is not a live rail", what, ix->idx_h);
    return 0;
  }
  ix->lo = index_value(r, &ix->big);
  return 1;
}

/* Control flag value (0/1), or -1 with a violation. */
static int read_ctl(int32_t c, const char *what) {
  const cqe_val *r = cqe_rail(c);
  if (!r) {
    cqe_fail("qram: %s: control handle %d is not a live rail", what, c);
    return -1;
  }
  if (r->bits != 1) {
    cqe_fail("qram: %s: control rail %d has width %u, not 1", what, c, r->bits);
    return -1;
  }
  return (int)(r->w[0] & 1u);
}

static int op_qram_alloc(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  wdesc d;
  if (t->unc || nargs != 1 || !parse_width(t->w, &d)) {
    cqe_fail("qram: qram_alloc: malformed call (w '%s', %d arguments, unc %d)", t->w, nargs, t->unc);
    return -1;
  }
  uint32_t n = (uint32_t)raw_u64(&args[0]);
  if (g_nobjs == g_capobjs) {
    g_capobjs = g_capobjs ? 2 * g_capobjs : 8;
    g_objs = xrealloc(g_objs, g_capobjs * sizeof *g_objs);
  }
  int oi = (int)g_nobjs++;
  qobj *o = &g_objs[oi];
  memset(o, 0, sizeof *o);
  o->live = 1;
  o->d = d;
  append_cells(o, n);
  qview *v = push_view(o);
  v->n = n;
  v->phys0 = 0;
  v->map = xcalloc(n, sizeof *v->map);
  for (uint32_t i = 0; i < n; ++i) v->map[i] = i;
  v->bus = new_bus(oi, 0);
  if (set_out_handle(out, v->bus)) return -1;
  emit("{\"ev\":\"qram\",\"op\":\"alloc\",\"a\":%d,\"w\":\"%s\",\"n\":%u}", v->bus, d.tok, n);
  return 0;
}

static int op_qram_realloc(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  wdesc d;
  if (nargs != 2 || !parse_width(t->w, &d)) {
    cqe_fail("qram: qram_realloc%s: malformed call (w '%s', %d arguments)", t->unc ? "_unc" : "", t->w, nargs);
    return -1;
  }
  int32_t a = raw_handle(&args[0]);
  uint32_t n = (uint32_t)raw_u64(&args[1]);
  qbus *b;
  qobj *o = bus_get(a, t->unc ? "qram_realloc_unc" : "qram_realloc", &b);
  if (!o) return -1;
  if (o->d.bits != d.bits || o->d.kind != d.kind) {
    cqe_fail("qram: qram_realloc: bus %d holds %s cells, the call says %s", a, o->d.tok, d.tok);
    return -1;
  }
  int oi = b->obj;
  if (!t->unc) {
    qview *old = &o->views[o->nviews - 1];
    uint32_t oldn = old->n;
    uint32_t *oldmap = old->map;
    uint32_t keep = n < oldn ? n : oldn;
    uint32_t phys0 = o->nphys;
    uint32_t first = n > oldn ? append_cells(o, n - oldn) : o->nphys;
    qview *v = push_view(o); /* may move o->views */
    v->n = n;
    v->phys0 = phys0;
    v->map = xcalloc(n, sizeof *v->map);
    memcpy(v->map, oldmap, (size_t)keep * sizeof *v->map);
    for (uint32_t i = keep; i < n; ++i) v->map[i] = first + (i - keep);
    v->bus = new_bus(oi, (int)o->nviews - 1);
    b = &g_bus[a - BUS_BASE]; /* g_bus may have moved */
    b->dead = 1;              /* a' replaces a for every later access */
    if (set_out_handle(out, v->bus)) return -1;
    emit("{\"ev\":\"qram\",\"op\":\"realloc\",\"a\":%d,\"a2\":%d,\"n_old\":%u,\"n\":%u}", a, v->bus, oldn, n);
    return 0;
  }
  /* _unc(a', n_old) */
  if (o->nviews < 2) {
    cqe_fail("qram: qram_realloc_unc: bus %d was not made by a qram_realloc", a);
    return -1;
  }
  qview *v = &o->views[o->nviews - 1];
  qview *prev = &o->views[o->nviews - 2];
  int bad = 0;
  if (prev->n != n) {
    cqe_fail("qram: qram_realloc_unc(%d, %u): the size before the realloc was %u", a, n, prev->n);
    bad = 1;
  }
  for (size_t i = 0; i < g_nslots; ++i)
    if (g_slots[i].live && g_slots[i].bus == a) {
      cqe_fail("qram: qram_realloc_unc(%d): a store made through it is not popped", a);
      bad = 1;
      break;
    }
  for (uint32_t p = v->phys0; p < o->nphys; ++p)
    if (!is_zero(cell(o, p), nwords(o->d.bits))) {
      cqe_fail("qram: qram_realloc_unc(%d): cell %u it added is not |0>", a, p);
      bad = 1;
      break;
    }
  if (!bad) o->nphys = v->phys0; /* the grown cells are |0> and dropped */
  free(v->map);
  o->nviews--;
  b->dead = 1;
  g_bus[prev->bus - BUS_BASE].dead = 0; /* a is the bus again */
  emit("{\"ev\":\"qram\",\"op\":\"realloc_unc\",\"a2\":%d,\"a\":%d,\"n\":%u}", a, prev->bus, prev->n);
  return 0;
}

static int op_qram_free(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  (void)out;
  if (t->unc || nargs != 1) {
    cqe_fail("qram: qram_free: malformed call (%d arguments, unc %d)", nargs, t->unc);
    return -1;
  }
  int32_t a = raw_handle(&args[0]);
  qbus *b;
  qobj *o = bus_get(a, "qram_free", &b);
  if (!o) return -1;
  int oi = b->obj;
  for (size_t i = 0; i < g_nslots; ++i)
    if (g_slots[i].live && g_slots[i].obj == oi) {
      cqe_fail("qram: qram_free(%d): a store (through bus %d) is not popped", a, g_slots[i].bus);
      break;
    }
  for (uint32_t p = 0; p < o->nphys; ++p)
    if (!is_zero(cell(o, p), nwords(o->d.bits))) {
      cqe_fail("qram: qram_free(%d): cell %u is not |0>", a, p);
      break;
    }
  emit("{\"ev\":\"qram\",\"op\":\"free\",\"a\":%d}", a);
  /* Released: its cells and any slots are gone (a violation above already failed the run). */
  for (size_t i = 0; i < g_nslots; ++i)
    if (g_slots[i].obj == oi) g_slots[i].live = 0;
  for (uint32_t k = 0; k < o->nviews; ++k) {
    g_bus[o->views[k].bus - BUS_BASE].dead = 1;
    free(o->views[k].map);
  }
  free(o->cells);
  free(o->views);
  memset(o, 0, sizeof *o);
  return 0;
}

static int op_qram_store(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  (void)out;
  const char *what = t->unc ? "qram_store_unc" : "qram_store";
  wdesc d;
  if ((nargs != 3 && nargs != 4) || !parse_width(t->w, &d)) {
    cqe_fail("qram: %s: malformed call (w '%s', %d arguments)", what, t->w, nargs);
    return -1;
  }
  int has_c = nargs == 4;
  const cqe_val *x = args + has_c;
  int32_t c_h = has_c ? raw_handle(&args[0]) : 0;
  int32_t a = raw_handle(&x[0]);
  int32_t v_h = raw_handle(&x[2]);
  uint32_t nw = nwords(d.bits);

  if (!t->unc) {
    qbus *b;
    qobj *o = bus_get(a, what, &b);
    if (!o) return -1;
    if (o->d.bits != d.bits || o->d.kind != d.kind) {
      cqe_fail("qram: %s: bus %d holds %s cells, the call says %s", what, a, o->d.tok, d.tok);
      return -1;
    }
    qindex ix;
    if (!read_index(t, &x[1], &ix, what)) return -1;
    const cqe_val *vr = cqe_rail(v_h);
    if (!vr || !rail_matches(vr, &d)) {
      cqe_fail("qram: %s: value handle %d is not a live %s rail", what, v_h, d.tok);
      return -1;
    }
    int c = has_c ? read_ctl(c_h, what) : 1;
    if (c < 0) return -1;
    qview *view = &o->views[o->nviews - 1];
    int in_range = !ix.big && ix.lo < view->n;
    if (g_nslots == g_capslots) {
      g_capslots = g_capslots ? 2 * g_capslots : 64;
      g_slots = xrealloc(g_slots, g_capslots * sizeof *g_slots);
    }
    qslot *s = &g_slots[g_nslots++];
    memset(s, 0, sizeof *s);
    s->live = 1;
    s->obj = b->obj;
    s->depth = b->depth;
    s->bus = a;
    s->hl = ix.hl;
    s->idx_h = ix.idx_h;
    s->j = ix.j;
    s->idx_lo = ix.lo;
    s->idx_big = ix.big;
    s->v_h = v_h;
    s->has_c = has_c;
    s->c_h = c_h;
    s->c_fwd = c;
    s->active = c && in_range;
    s->t = xcalloc(nw, sizeof *s->t);
    s->v_fwd = xcalloc(nw, sizeof *s->v_fwd);
    memcpy(s->v_fwd, vr->w, nw * sizeof *s->v_fwd);
    s->seq = ++g_seq;
    if (s->active) {
      s->p = view->map[ix.lo];
      uint64_t *cp = cell(o, s->p);
      memcpy(s->t, cp, nw * sizeof *cp); /* t <-> cell (t was |0>) */
      memset(cp, 0, nw * sizeof *cp);
      for (uint32_t i = 0; i < nw; ++i) cp[i] ^= vr->w[i]; /* cell ^= v */
      mask_top(cp, d.bits);
    }
    const char *hv = hexs(vr->w, d.bits);
    emit("{\"ev\":\"qram\",\"op\":\"store\",\"a\":%d,\"idx\":\"0x%llx\",\"hl\":%d,\"v\":%d,\"vv\":\"%s\",\"c\":%d,\"done\":%d}", a,
         (unsigned long long)ix.lo, ix.hl, v_h, hv, has_c ? c : -1, s->active);
    return 0;
  }

  /* _unc: pop the most recent unpopped slot with identical (a, idx|j, v[, c]). */
  int hl = strcmp(t->shape, "hl") == 0;
  int32_t idx_h = hl ? 0 : raw_handle(&x[1]);
  uint64_t j = hl ? (raw_u64(&x[1]) & 0xFFFFFFFFu) : 0;
  qslot *s = NULL;
  for (size_t i = g_nslots; i-- > 0;) {
    qslot *q = &g_slots[i];
    if (q->live && q->bus == a && q->hl == hl && (hl ? q->j == j : q->idx_h == idx_h) && q->v_h == v_h &&
        q->has_c == has_c && (!has_c || q->c_h == c_h)) {
      s = q;
      break;
    }
  }
  if (!s) {
    cqe_fail("qram: %s(a %d, idx %s %llu, v %d): no unpopped store with these operands", what, a, hl ? "j" : "h",
             (unsigned long long)(hl ? j : (uint64_t)idx_h), v_h);
    return -1;
  }
  qbus *b;
  qobj *o = bus_get(a, what, &b);
  if (!o) return -1;
  /* Precondition: v, idx and c hold their forward values. */
  const cqe_val *vr = cqe_rail(v_h);
  if (!vr || !rail_matches(vr, &d)) {
    cqe_fail("qram: %s: value handle %d is not a live %s rail", what, v_h, d.tok);
    return -1;
  }
  if (memcmp(vr->w, s->v_fwd, nw * sizeof *s->v_fwd) != 0)
    cqe_fail("qram: %s: value rail %d changed since its store", what, v_h);
  if (!hl) {
    const cqe_val *ir = cqe_rail(idx_h);
    int big = 0;
    uint64_t lo = ir ? index_value(ir, &big) : 0;
    if (!ir)
      cqe_fail("qram: %s: index handle %d is not a live rail", what, idx_h);
    else if (lo != s->idx_lo || big != s->idx_big)
      cqe_fail("qram: %s: index rail %d changed since its store", what, idx_h);
  }
  if (has_c) {
    int c = read_ctl(c_h, what);
    if (c >= 0 && c != s->c_fwd) cqe_fail("qram: %s: control rail %d changed since its store", what, c_h);
  }
  if (s->active) {
    /* LIFO among stores that touch the same cell: no newer unpopped store may sit on this cell. */
    for (size_t i = 0; i < g_nslots; ++i) {
      qslot *q = &g_slots[i];
      if (q != s && q->live && q->obj == s->obj && q->active && q->p == s->p && q->seq > s->seq) {
        cqe_fail("qram: %s: pop out of last-in-first-out order on a cell (a newer store to it is unpopped)", what);
        break;
      }
    }
    uint64_t *cp = cell(o, s->p);
    for (uint32_t i = 0; i < nw; ++i) cp[i] ^= vr->w[i]; /* cell ^= v */
    mask_top(cp, d.bits);
    for (uint32_t i = 0; i < nw; ++i) { /* t <-> cell */
      uint64_t tmp = s->t[i];
      s->t[i] = cp[i];
      cp[i] = tmp;
    }
  }
  int clean = is_zero(s->t, nw);
  if (!clean) cqe_fail("qram: %s: its tape slot is not |0> after the pop", what);
  emit("{\"ev\":\"qram\",\"op\":\"store_unc\",\"a\":%d,\"idx\":\"0x%llx\",\"hl\":%d,\"v\":%d,\"done\":%d,\"clean\":%d}", a,
       (unsigned long long)s->idx_lo, hl, v_h, s->active, clean);
  s->live = 0; /* released */
  free(s->t);
  free(s->v_fwd);
  s->t = s->v_fwd = NULL;
  return 0;
}

/* The value a load reads now: c ? cell[map[idx]] : 0, 0 out of range. */
static void load_value(qobj *o, const qindex *ix, int c, uint64_t *val) {
  qview *view = &o->views[o->nviews - 1];
  uint32_t nw = nwords(o->d.bits);
  memset(val, 0, nw * sizeof *val);
  if (c && !ix->big && ix->lo < view->n) memcpy(val, cell(o, view->map[ix->lo]), nw * sizeof *val);
}

static int op_qram_load(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  const char *what = t->unc ? "qram_load_unc" : "qram_load";
  wdesc d;
  int base = t->unc ? 3 : 2;
  if ((nargs != base && nargs != base + 1) || !parse_width(t->w, &d)) {
    cqe_fail("qram: %s: malformed call (w '%s', %d arguments)", what, t->w, nargs);
    return -1;
  }
  int has_c = nargs == base + 1;
  int32_t h = t->unc ? raw_handle(&args[0]) : 0;
  const cqe_val *x = args + (t->unc ? 1 : 0);
  int32_t c_h = has_c ? raw_handle(&x[0]) : 0;
  x += has_c;
  int32_t a = raw_handle(&x[0]);
  qobj *o = bus_get(a, what, NULL);
  if (!o) return -1;
  if (o->d.bits != d.bits || o->d.kind != d.kind) {
    cqe_fail("qram: %s: bus %d holds %s cells, the call says %s", what, a, o->d.tok, d.tok);
    return -1;
  }
  qindex ix;
  if (!read_index(t, &x[1], &ix, what)) return -1;
  int c = has_c ? read_ctl(c_h, what) : 1;
  if (c < 0) return -1;
  uint32_t nw = nwords(d.bits);
  uint64_t *val = xcalloc(nw, sizeof *val);
  load_value(o, &ix, c, val);

  if (!t->unc) {
    cqe_val init;
    make_val(&init, &d, val);
    int32_t r = cqe_new_rail(d.tok, &init, 0);
    if (g_nloads == g_caploads) {
      g_caploads = g_caploads ? 2 * g_caploads : 64;
      g_loads = xrealloc(g_loads, g_caploads * sizeof *g_loads);
    }
    g_loads[g_nloads++] = (qload){1, r, a, ix.hl, ix.idx_h, ix.j, has_c, c_h};
    if (set_out_handle(out, r)) {
      free(val);
      return -1;
    }
    const char *hv = hexs(val, d.bits);
    emit("{\"ev\":\"qram\",\"op\":\"load\",\"a\":%d,\"idx\":\"0x%llx\",\"hl\":%d,\"out\":%d,\"v\":\"%s\"}", a,
         (unsigned long long)ix.lo, ix.hl, r, hv);
    free(val);
    return 0;
  }

  const cqe_val *hr = cqe_rail(h);
  if (!hr || !rail_matches(hr, &d)) {
    cqe_fail("qram: %s: out handle %d is not a live %s rail", what, h, d.tok);
    free(val);
    return -1;
  }
  qload *ld = NULL;
  for (size_t i = g_nloads; i-- > 0;)
    if (g_loads[i].live && g_loads[i].h == h) {
      ld = &g_loads[i];
      break;
    }
  if (!ld)
    cqe_fail("qram: %s: rail %d was not made by a qram_load", what, h);
  else if (ld->bus != a || ld->hl != ix.hl || (ix.hl ? ld->j != ix.j : ld->idx_h != ix.idx_h) || ld->has_c != has_c ||
           (has_c && ld->c_h != c_h))
    cqe_fail("qram: %s: operands of rail %d's _unc differ from its qram_load", what, h);
  cqe_val sv;
  make_val(&sv, &d, val);
  cqe_xor_into(h, &sv);
  const cqe_val *after = cqe_rail(h);
  int clean = after && is_zero(after->w, after->nw);
  if (clean)
    cqe_set_known(h, 1);
  else
    cqe_fail("qram: %s: residue on rail %d (the cell changed since the load)", what, h);
  const char *hv = hexs(after ? after->w : val, d.bits);
  emit("{\"ev\":\"qram\",\"op\":\"load_unc\",\"a\":%d,\"idx\":\"0x%llx\",\"hl\":%d,\"out\":%d,\"residue\":\"%s\"}", a,
       (unsigned long long)ix.lo, ix.hl, h, hv);
  if (ld) ld->live = 0;
  free(val);
  return 0;
}

/* ------------------------------------------------------------------- exit */

typedef struct { char *buf; size_t len, cap; } sbuf;

static void sb_add(sbuf *b, const char *fmt, ...) {
  va_list ap, ap2;
  va_start(ap, fmt);
  va_copy(ap2, ap);
  int k = vsnprintf(NULL, 0, fmt, ap);
  va_end(ap);
  while (b->len + (size_t)k + 1 > b->cap) {
    b->cap = b->cap ? 2 * b->cap : 4096;
    b->buf = xrealloc(b->buf, b->cap);
  }
  vsnprintf(b->buf + b->len, (size_t)k + 1, fmt, ap2);
  va_end(ap2);
  b->len += (size_t)k;
}

static void rt_mem_exit(void) {
  if (g_nobjs == 0 && g_nslots == 0) return;
  sbuf b = {0};
  int32_t id = KEPT_ID_BASE;
  const char *sep = "";
  sb_add(&b, "{\"ev\":\"qram\",\"op\":\"exit\",\"live\":[");
  for (size_t oi = 0; oi < g_nobjs; ++oi) {
    qobj *o = &g_objs[oi];
    if (!o->live) continue;
    for (uint32_t p = 0; p < o->nphys; ++p) {
      sb_add(&b, "%s{\"h\":%d,\"w\":\"%s\",\"v\":\"%s\",\"role\":\"qram_cell\"}", sep, id++, o->d.tok,
             hexs(cell(o, p), o->d.bits));
      sep = ",";
    }
  }
  for (size_t i = 0; i < g_nslots; ++i) {
    qslot *s = &g_slots[i];
    if (!s->live) continue;
    qobj *o = &g_objs[s->obj];
    sb_add(&b, "%s{\"h\":%d,\"w\":\"%s\",\"v\":\"%s\",\"role\":\"qram_slot\"}", sep, id++, o->d.tok,
           hexs(s->t, o->d.bits));
    sep = ",";
  }
  sb_add(&b, "]}");
  cqe_log(b.buf);
  free(b.buf);
}

/* ------------------------------------------------------------- registration */

__attribute__((constructor(101))) static void rt_mem_register(void) {
  cqe_register_op("qrom_load", op_qrom);
  cqe_register_op("qrom_load_s", op_qrom);
  cqe_register_op("qram_alloc", op_qram_alloc);
  cqe_register_op("qram_realloc", op_qram_realloc);
  cqe_register_op("qram_store", op_qram_store);
  cqe_register_op("qram_store_controlled", op_qram_store);
  cqe_register_op("qram_load", op_qram_load);
  cqe_register_op("qram_load_controlled", op_qram_load);
  cqe_register_op("qram_free", op_qram_free);
  atexit(rt_mem_exit);
}
