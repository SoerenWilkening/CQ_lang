/* rt_replay.c: exact clone replay (cq-kcn5i; DECISIONS 2026-11-08, owner option (a): every eligible clone, no
 * verification gate, the 1-in-64 spot check kept).
 *
 * A call to an eligible clone (run.py replay_module, DESIGN §4: templates, alloc/free, the i1 gates, copy/xorc, bus
 * load/store/swap, balanced push/pop (cq-mxe2q) and calls of eligible clones only; no rotation, measurement, tape, abort, host call, memory access
 * outside the bus but the pass-minted counters, fenv template, twin or indirect call; a call of a pure helper of the
 * module is allowed, run.py _rp_pure_helpers) goes through a wrapper run.py writes:
 *   hit = __cqe_rp_enter(id, desc, args, &ret); if (hit) return ret; ret = S.real(args...); __cqe_rp_leave(id, &ret);
 * The wrapper is not instrumented (nosanitize_coverage): it adds no step.
 *
 * Key. The clone, its classical argument values, per handle argument the rail as the clone can read it (core.c
 * cqe__rp_argkey: value, flags, liveness, sources, the order of the argument rails' event clocks, aliasing), and the
 * floating-point environment (x87 control word and exception flags, MXCSR). Then the bus: a record holds the ordered
 * bytes its run read before writing them (address, value, QUANTUM, known) and the host bytes whose writability it
 * tested; a record applies only where every one of them reads the same now. K is fixed per clone in the module, or
 * read from @__cq_k: a pass-minted counter (@__cq_act_<f>, @__cq_k) a run read before writing it is part of the record
 * as a bus byte is, with the value it had, and one it wrote with its final value (the counters, below).
 *
 * A miss runs the clone in a window: core.c watches every rail touched (a rail outside the call's handle arguments
 * makes the window dirty), its frees, violations and trace lines (any makes it dirty); rt_bus.c logs its bus reads,
 * writability tests and writes; dispatch.c its word-stack depth and anything a replayed clone never does. At the end
 * the handle arguments must hold what they held (an absolute snapshot), and the window's record is: the rails it made
 * (core.c cqe__rp_encode: every field, clocks relative to its start, handles relative to its base or as arguments),
 * the handle counter's and the event clock's advance, the steps it took, its frees in order (the shot_end digest), the
 * final state of every bus byte it wrote (QUANTUM value and known flag, or HOST, and the host byte), the fp environment
 * it left and its result. A dirty window keeps nothing: the next call with that key runs real again.
 *
 * A hit applies the record: the steps (a step budget passed ends the sample as the real run would), one block of
 * untouched rails (core.c: no handle is taken, owner 2026-11-09; the rails are named in the open occurrence and the
 * clock advances; a rail gets a handle when the caller reaches it and is made from the record when something reads
 * it; the exit event reads the others from the record), the bus bytes, the free digest (by name), the fp environment
 * and the result. Nothing the real run would have logged is lost: a recordable run logs nothing.
 *
 * Names (core.c, rail names). A call made while no wrapper call runs opens an occurrence (cqe__rp_occ) that ends with
 * it; every rail made in it, by a real run or a replay, is named by the occurrence and its place in it, so a rail's
 * name does not depend on whether a call hit, recorded, was spot-checked, closed or dirty, which depend on values.
 *
 * Spot check. One hit in 64 (FNV of the sample's k and the hit's index; $CQE_REPLAY_CHECK=N for one in N, 0 never)
 * runs the real clone instead, in a window, and compares the record it makes with the stored one field by field; any
 * difference (or a dirty run) is the violation summary_mismatch, which fails the sample, and the record is retired.
 *
 * Records live in the sample's heap: one sample, one worker. Windows do not nest: a clone called while one records
 * runs real inside it. Replay needs the compact trace (CQE_COMPACT=1; a full trace logs every gate) and no open
 * cq_invert region. $CQE_REPLAY=0 turns it off (every call runs real; the wrapper adds nothing).
 *
 * Self-checks: $CQE_REPLAY_TAMPER=1 flips a bit in the first record's first live rail, which the spot check must
 * report; $CQE_REPLAY_STATS=<file> appends one JSON line per sample (and every 2^26 runtime calls, or 2^N with
 * $CQE_REPLAY_STATS_LOG2=N) with the counts and the basic blocks stepped so far (replayed ones included). */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"
#include "rt_replay.h"

static const char *rp_chr(const char *s, char c) { /* strchr, never the program's (rt_replay.h) */
  for (; *s; ++s)
    if (*s == c)
      return s;
  return NULL;
}

void cqe__init(void);
int cqe__trace_all(void);
void cqe__violation(const char *what, int32_t h, const char *fmt, ...);
void cqe__set_store_kept(int32_t h); /* core.c: the rail is the value or control rail of a bus store (rule 5) */

void cqe__rp_put(cqe_rp_buf *b, const void *x, size_t n) {
  if (!n)
    return;
  if (b->n + n > b->cap) {
    size_t c = b->cap ? b->cap : 64;
    while (c < b->n + n)
      c *= 2;
    b->p = realloc(b->p, c);
    if (!b->p)
      abort();
    b->cap = c;
  }
  cqe__rp_cpy(b->p + b->n, x, n);
  b->n += n;
}

/* ---- settings ---- */

static int st_read, st_on = 1, st_tamper;
static unsigned long st_every = 64;
static const char *st_stats;
static uint64_t st_stats_every = (uint64_t)1 << 26;
static size_t st_max_bytes = (size_t)1 << 30;

static void settings(void) {
  if (st_read)
    return;
  st_read = 1;
  const char *e = getenv("CQE_REPLAY");
  st_on = !(e && !strcmp(e, "0"));
  e = getenv("CQE_REPLAY_CHECK");
  if (e && *e)
    st_every = strtoul(e, NULL, 10);
  e = getenv("CQE_REPLAY_TAMPER");
  st_tamper = e && !strcmp(e, "1");
  e = getenv("CQE_REPLAY_STATS");
  st_stats = e && *e ? e : NULL;
  e = getenv("CQE_REPLAY_STATS_LOG2"); /* a progress line per 2^N runtime calls (default 26) */
  if (e && *e)
    st_stats_every = (uint64_t)1 << (strtoul(e, NULL, 10) & 63);
  e = getenv("CQE_REPLAY_MAX_MB");
  if (e && *e)
    st_max_bytes = (size_t)strtoull(e, NULL, 10) << 20;
}

/* ---- records ---- */

typedef struct { uint64_t a; uint8_t v, q, k, pad[5]; } rp_read;
typedef struct { uint64_t a; uint8_t w, pad[7]; } rp_wchk;
typedef struct { uint64_t a; uint8_t q, v, k, hc, hv, pad[3]; } rp_write;
typedef struct { uint64_t a, v; uint32_t n, pad; } rp_gcell; /* a counter: its address, value and width in bytes */

typedef struct rp_rec {
  struct rp_rec *next;
  uint64_t hash;
  uint32_t id;
  int retired;
  cqe_rp_buf key;
  rp_read *reads;
  rp_wchk *wchk;
  rp_write *writes;
  uint32_t *frees;
  rp_gcell *gr, *gw; /* the counters read before written (their values then) and written (their final values) */
  size_t nreads, nwchk, nwrites, nfrees, ngr, ngw;
  uint64_t steps;
  uint16_t fcw, fsw;
  uint32_t mxcsr;
  int32_t ret_h;
  uint64_t ret_raw;
  uint64_t arg_sk; /* bit i: the run made handle argument i a store's kept rail (arguments, below) */
  cqe_rp_rails rails;
} rp_rec;

/* A clone of the module: run.py's descriptor "<name>|<kind per argument: h handle, c classical>|<result: v void, h handle, i classical
 * i32, c other>". */
typedef struct {
  int parsed, nargs, closed;
  int nonleaf; /* a wrapper call was seen inside one of its windows: its window keeps those calls from replaying */
  char kinds[65], rk;
  const char *name;
  uint64_t calls, hits, recs, dirty, checks, mism, rails;
} rp_clone;

static rp_clone *clones;
static size_t nclones;

static rp_clone *clone_of(int32_t id, const char *desc) {
  if (id < 0)
    return NULL;
  if ((size_t)id >= nclones) {
    size_t n = (size_t)id + 1 > 2 * nclones ? (size_t)id + 1 : 2 * nclones;
    clones = realloc(clones, n * sizeof *clones);
    if (!clones)
      abort();
    cqe__rp_zero(clones + nclones, (n - nclones) * sizeof *clones);
    nclones = n;
  }
  rp_clone *c = &clones[id];
  if (!c->parsed) {
    c->parsed = 1;
    c->name = desc;
    const char *b1 = rp_chr(desc, '|'), *b2 = b1 ? rp_chr(b1 + 1, '|') : NULL;
    c->nargs = b1 && b2 ? (int)(b2 - b1 - 1) : -1;
    if (c->nargs < 0 || c->nargs > 64 || !b2[1]) {
      c->nargs = -1; /* run.py wrote no such descriptor: this clone never replays */
      return c;
    }
    cqe__rp_cpy(c->kinds, b1 + 1, (size_t)c->nargs);
    c->rk = b2[1];
  }
  return c;
}

static rp_rec **tab;
static size_t tab_cap, tab_n, rec_bytes;
static uint64_t n_calls, n_hits, n_recs, n_dirty, n_checks, n_mism, n_rails, n_nhit;

static uint64_t fnv(const uint8_t *p, size_t n) {
  uint64_t h = 0xcbf29ce484222325ULL;
  for (size_t i = 0; i < n; ++i)
    h = (h ^ p[i]) * 0x100000001b3ULL;
  return h;
}

static uint64_t g_get(uint64_t a, uint32_t n) {
  uint64_t v = 0;
  cqe__rp_cpy(&v, (const void *)(uintptr_t)a, n);
  return v;
}

static void tab_insert(rp_rec *r) {
  if (2 * (tab_n + 1) > tab_cap) {
    size_t cap = tab_cap ? 2 * tab_cap : 1024;
    rp_rec **t = calloc(cap, sizeof *t);
    if (!t)
      abort();
    for (size_t i = 0; i < tab_cap; ++i)
      for (rp_rec *x = tab[i], *nx; x; x = nx) {
        nx = x->next;
        x->next = t[x->hash & (cap - 1)];
        t[x->hash & (cap - 1)] = x;
      }
    free(tab);
    tab = t;
    tab_cap = cap;
  }
  r->next = tab[r->hash & (tab_cap - 1)];
  tab[r->hash & (tab_cap - 1)] = r;
  ++tab_n;
}

/* Every bus byte the record read and every writability it tested reads the same now. */
static int pre_ok(const rp_rec *r) {
  for (size_t i = 0; i < r->nreads; ++i) {
    int q, k;
    uint8_t v;
    cqe__bus_cell_state(r->reads[i].a, &q, &v, &k);
    if (q != r->reads[i].q || v != r->reads[i].v || k != r->reads[i].k)
      return 0;
  }
  for (size_t i = 0; i < r->nwchk; ++i)
    if (cqe__bus_writable(r->wchk[i].a) != r->wchk[i].w)
      return 0;
  for (size_t i = 0; i < r->ngr; ++i)
    if (g_get(r->gr[i].a, r->gr[i].n) != r->gr[i].v)
      return 0;
  return 1;
}

static int rec_same(const rp_rec *a, const rp_rec *b) {
  return a->id == b->id && a->key.n == b->key.n && cqe__rp_eq(a->key.p, b->key.p, a->key.n) && a->nreads == b->nreads &&
         cqe__rp_eq(a->reads, b->reads, a->nreads * sizeof *a->reads) && a->nwchk == b->nwchk &&
         cqe__rp_eq(a->wchk, b->wchk, a->nwchk * sizeof *a->wchk) && a->nwrites == b->nwrites &&
         cqe__rp_eq(a->writes, b->writes, a->nwrites * sizeof *a->writes) && a->nfrees == b->nfrees &&
         cqe__rp_eq(a->frees, b->frees, a->nfrees * sizeof *a->frees) && a->ngr == b->ngr &&
         cqe__rp_eq(a->gr, b->gr, a->ngr * sizeof *a->gr) && a->ngw == b->ngw &&
         cqe__rp_eq(a->gw, b->gw, a->ngw * sizeof *a->gw) && a->steps == b->steps && a->fcw == b->fcw &&
         a->fsw == b->fsw && a->mxcsr == b->mxcsr && a->ret_h == b->ret_h && a->ret_raw == b->ret_raw &&
         a->arg_sk == b->arg_sk &&
         a->rails.n == b->rails.n && a->rails.ticks == b->rails.ticks && a->rails.blob.n == b->rails.blob.n &&
         cqe__rp_eq(a->rails.blob.p, b->rails.blob.p, a->rails.blob.n);
}

static void rec_free(rp_rec *r) {
  if (!r)
    return;
  free(r->key.p);
  free(r->reads);
  free(r->wchk);
  free(r->writes);
  free(r->frees);
  free(r->gr);
  free(r->gw);
  free(r->rails.off);
  free(r->rails.blob.p);
  free(r->rails.hexoff);
  free(r->rails.hexpool);
  free(r);
}

/* ---- the open window ---- */

enum { M_NONE = 1, M_REC, M_CHECK };
static uint8_t *dstack; /* per call of a wrapper still running: its mode */
static size_t dn, dcap;
static uint32_t w_id, w_base; /* the window's clone is clones[w_id] (an inner call may grow the table) */
static uint64_t w_c0, w_steps0, w_hash;
static int32_t w_hs[64];
static int w_nh;
static cqe_rp_buf w_key, w_snap;
static size_t w_snapoff[65]; /* w_snap: one absolute snapshot per handle argument */
static uint64_t w_argsk;     /* close_window: the arguments the run made store-kept */
static rp_rec *w_ref;

/* The arguments. A window's run may change nothing of its handle arguments (core.c cqe__rp_argkey, absolute: every
 * field, raw clocks) but one flag: a bus store whose value or control rail is the argument itself marks it store_kept
 * (rt_bus.c; rule 5 sentence 3: its exit role), as __towrite's first store does with its predicate. The flag is part
 * of the key (the argument's flags), so a call that hits has it clear as the recorded one had, the run would set it,
 * and the hit sets it (cqe__set_store_kept, what the store calls). Any other change of an argument: no record.
 * A snapshot of a live rail begins with the word 0x5ec0... | flags << 16 (cqe__rp_argkey), flags bit 6 store_kept
 * (core.c tomb_flags); args_apply checks on every hit that setting the flag changed that bit of that word and nothing
 * else, so a change of core.c's layout fails loudly (summary_mismatch) instead of replaying something else. */
#define SNAP_TAG(w) ((w) >> 48)
#define SNAP_LIVE 0x5ec0u
#define SNAP_SK ((uint64_t)1 << (16 + 6))

static void args_snap(const int32_t *hs, int nh, cqe_rp_buf *o, size_t *off) {
  o->n = 0;
  for (int i = 0; i < nh; ++i) {
    off[i] = o->n;
    cqe__rp_argkey(&hs[i], 1, 1, o);
  }
  off[nh] = o->n;
}
/* 0: a and b are the same; 1: the same but b has store_kept where a has not; -1: anything else */
static int snap_cmp(const uint8_t *a, size_t an, const uint8_t *b, size_t bn) {
  if (an != bn)
    return -1;
  if (cqe__rp_eq(a, b, an))
    return 0;
  uint64_t wa, wb;
  if (an < sizeof wa)
    return -1;
  cqe__rp_cpy(&wa, a, sizeof wa);
  cqe__rp_cpy(&wb, b, sizeof wb);
  if (SNAP_TAG(wa) != SNAP_LIVE || (wa & SNAP_SK) || wb != (wa | SNAP_SK) ||
      !cqe__rp_eq(a + sizeof wa, b + sizeof wb, an - sizeof wa))
    return -1;
  return 1;
}
/* A hit's arguments take what the recorded run gave them. 0 when core.c did not do exactly that. */
static int args_apply(uint64_t sk, const int32_t *hs, int nh) {
  static cqe_rp_buf a, b;
  int ok = 1;
  for (int i = 0; i < nh && sk; ++i) {
    if (!(sk >> i & 1))
      continue;
    a.n = b.n = 0;
    cqe__rp_argkey(&hs[i], 1, 1, &a);
    if (a.n >= 8) {
      uint64_t w;
      cqe__rp_cpy(&w, a.p, sizeof w);
      if (SNAP_TAG(w) == SNAP_LIVE)
        cqe__set_store_kept(hs[i]);
    }
    cqe__rp_argkey(&hs[i], 1, 1, &b);
    int c = snap_cmp(a.p, a.n, b.p, b.n);
    int earlier = 0; /* the same rail given twice: the first of them took the flag */
    for (int j = 0; j < i; ++j)
      earlier |= hs[j] == hs[i] && (sk >> j & 1);
    if (!(c == 1 || (c == 0 && earlier)))
      ok = 0;
  }
  return ok;
}

/* the window's bus bytes: an address set (by generation) and the ordered logs */
enum { F_READ = 1, F_WRITE = 2, F_HOST = 4, F_WCHK = 8 };
typedef struct { uint64_t a; uint32_t gen; uint8_t f; } aset_e;
static aset_e *aset;
static size_t aset_cap, aset_n;
static uint32_t aset_gen;
static rp_read *br;
static size_t brn, brcap;
static rp_wchk *bwc;
static size_t bwcn, bwccap;
static uint64_t *bwa;
static size_t bwan, bwacap;

/* the window's counters (run.py: the pass-minted @__cq_act_<f> and @__cq_k, each always read and written whole) */
static rp_gcell *wgr, *wgw;
static size_t wgrn, wgrcap, wgwn, wgwcap;

static void *grow(void *p, size_t *cap, size_t n, size_t sz) {
  if (n < *cap)
    return p;
  *cap = *cap ? 2 * *cap : 64;
  p = realloc(p, *cap * sz);
  if (!p)
    abort();
  return p;
}

static aset_e *aset_get(uint64_t a) {
  if (2 * (aset_n + 1) > aset_cap) {
    size_t cap = aset_cap ? 2 * aset_cap : 256;
    aset_e *t = calloc(cap, sizeof *t);
    if (!t)
      abort();
    for (size_t i = 0; i < aset_cap; ++i)
      if (aset[i].gen == aset_gen) {
        size_t j = (size_t)(aset[i].a * 0x9E3779B97F4A7C15ULL >> 17) & (cap - 1);
        while (t[j].gen == aset_gen)
          j = (j + 1) & (cap - 1);
        t[j] = aset[i];
      }
    free(aset);
    aset = t;
    aset_cap = cap;
  }
  size_t j = (size_t)(a * 0x9E3779B97F4A7C15ULL >> 17) & (aset_cap - 1);
  while (aset[j].gen == aset_gen && aset[j].a != a)
    j = (j + 1) & (aset_cap - 1);
  if (aset[j].gen != aset_gen) {
    aset[j] = (aset_e){a, aset_gen, 0};
    ++aset_n;
  }
  return &aset[j];
}

void cqe__rp_cell_read(uint64_t a, uint8_t v, int q, int known) {
  aset_e *e = aset_get(a);
  if (e->f & (F_READ | F_WRITE))
    return;
  e->f |= F_READ;
  br = grow(br, &brcap, brn, sizeof *br);
  br[brn++] = (rp_read){a, v, (uint8_t)(q != 0), (uint8_t)(known != 0), {0}};
}

void cqe__rp_cell_wcheck(uint64_t a, int writable) {
  aset_e *e = aset_get(a);
  if (e->f & F_WCHK)
    return;
  e->f |= F_WCHK;
  bwc = grow(bwc, &bwccap, bwcn, sizeof *bwc);
  bwc[bwcn++] = (rp_wchk){a, (uint8_t)(writable != 0), {0}};
}

void cqe__rp_cell_wrote(uint64_t a, int host) {
  aset_e *e = aset_get(a);
  if (!(e->f & F_WRITE)) {
    e->f |= F_WRITE;
    bwa = grow(bwa, &bwacap, bwan, sizeof *bwa);
    bwa[bwan++] = a;
  }
  if (host)
    e->f |= F_HOST;
}

/* The counters. An eligible body's loads and stores of a pass-minted counter (rule 14's activation counter
 * @__cq_act_<f>, the run-time K @__cq_k) come here (run.py _rp_counters), the bodies it calls by name included (they
 * are eligible too). Outside a window they are the load and the store. In a window the first access of a counter
 * decides: a read logs the value read (the record applies only where the counter holds it: pre_ok), a write makes the
 * counter one whose final value the record carries and a hit stores. A counter met at two widths cannot be recorded. */
static rp_gcell *g_find(rp_gcell *t, size_t n, uint64_t a, uint32_t w) {
  for (size_t i = 0; i < n; ++i)
    if (t[i].a == a) {
      if (t[i].n != w)
        cqe__rp_dirty = 1;
      return &t[i];
    }
  return NULL;
}
static void g_read(uint64_t a, uint32_t w) {
  if (!cqe__rp_window || g_find(wgw, wgwn, a, w) || g_find(wgr, wgrn, a, w))
    return;
  wgr = grow(wgr, &wgrcap, wgrn, sizeof *wgr);
  wgr[wgrn++] = (rp_gcell){a, g_get(a, w), w, 0};
}
static void g_write(uint64_t a, uint32_t w) {
  if (!cqe__rp_window || g_find(wgw, wgwn, a, w))
    return;
  wgw = grow(wgw, &wgwcap, wgwn, sizeof *wgw);
  wgw[wgwn++] = (rp_gcell){a, 0, w, 0};
}
#define RP_G(W)                                                                                                         \
  uint##W##_t __cqe_rp_gload_i##W(const uint##W##_t *p) {                                                                \
    g_read((uint64_t)(uintptr_t)p, W / 8);                                                                              \
    return *p;                                                                                                          \
  }                                                                                                                     \
  void __cqe_rp_gstore_i##W(uint##W##_t *p, uint##W##_t v) {                                                             \
    g_write((uint64_t)(uintptr_t)p, W / 8);                                                                             \
    *p = v;                                                                                                             \
  }
RP_G(32)
RP_G(64)

/* The fp environment a clone's templates and classical fp operations depend on and leave: the x87 control word, its
 * exception flags and MXCSR, read and written by instruction (the program may define fegetenv itself). */
static void fenv_parts(uint16_t *fcw, uint16_t *fsw, uint32_t *mxcsr) {
  uint16_t cw, sw;
  uint32_t mx;
  __asm__ volatile("fnstcw %0" : "=m"(cw));
  __asm__ volatile("fnstsw %0" : "=m"(sw));
  __asm__ volatile("stmxcsr %0" : "=m"(mx));
  *fcw = cw;
  *fsw = sw & 0x3f;
  *mxcsr = mx;
}
static void fenv_put(uint16_t fcw, uint16_t fsw, uint32_t mxcsr) {
  struct { uint32_t cw, sw, tw, ip, cs, dp, ds; } env; /* fnstenv's 28-byte image */
  __asm__ volatile("fnstenv %0" : "=m"(env));
  env.cw = (env.cw & 0xffff0000u) | fcw;
  env.sw = (env.sw & ~0x3fu) | (fsw & 0x3fu);
  __asm__ volatile("fldenv %0" : : "m"(env));
  __asm__ volatile("ldmxcsr %0" : : "m"(mxcsr));
}

static void dpush(uint8_t m) {
  dstack = grow(dstack, &dcap, dn, 1);
  dstack[dn++] = m;
}

/* ---- statistics ($CQE_REPLAY_STATS) ---- */

static int stats_hooked;
static void stats_line(const char *when) {
  FILE *f = fopen(st_stats, "a");
  if (!f)
    return;
  fprintf(f, "{\"when\":\"%s\",\"k\":%ld,\"calls\":%llu,\"hits\":%llu,\"records\":%llu,\"dirty\":%llu,\"checks\":%llu,"
             "\"mismatch\":%llu,\"rails_replayed\":%llu,\"materialized\":%llu,\"rails\":%u,\"record_bytes\":%zu,"
             "\"runtime_calls\":%llu,\"steps\":%llu,\"clones\":[",
          when, cqe__rp_shot_k(), (unsigned long long)n_calls, (unsigned long long)n_hits, (unsigned long long)n_recs,
          (unsigned long long)n_dirty, (unsigned long long)n_checks, (unsigned long long)n_mism,
          (unsigned long long)n_rails, (unsigned long long)cqe__rp_materialized(), cqe__rp_nrails(), rec_bytes,
          (unsigned long long)cqe__ncalls, cqe__rp_steps());
  int first = 1;
  for (size_t i = 0; i < nclones; ++i) {
    const rp_clone *c = &clones[i];
    if (!c->calls)
      continue;
    const char *bar = rp_chr(c->name, '|');
    fprintf(f, "%s{\"clone\":\"%.*s\",\"calls\":%llu,\"hits\":%llu,\"records\":%llu,\"dirty\":%llu,\"rails\":%llu}",
            first ? "" : ",", bar ? (int)(bar - c->name) : 0, c->name, (unsigned long long)c->calls,
            (unsigned long long)c->hits, (unsigned long long)c->recs, (unsigned long long)c->dirty,
            (unsigned long long)c->rails);
    first = 0;
  }
  fprintf(f, "]}\n");
  fclose(f);
}
static void stats_at_exit(void) { stats_line("exit"); }

/* ---- enter and leave ---- */

static void open_window(int mode, int32_t id, const int32_t *hs, int nh) {
  w_id = (uint32_t)id;
  w_base = cqe__rp_nrails();
  w_c0 = cqe__rp_clock();
  w_steps0 = cqe__rp_steps();
  cqe__rp_cpy(w_hs, hs, (size_t)nh * sizeof *hs);
  w_nh = nh;
  args_snap(w_hs, w_nh, &w_snap, w_snapoff);
  ++aset_gen;
  aset_n = 0;
  brn = bwcn = bwan = 0;
  wgrn = wgwn = 0;
  cqe__rp_dirty = 0;
  cqe__rp_stack_mark(1);
  cqe__rp_watch(w_base, w_hs, w_nh, 1);
  dpush((uint8_t)mode);
}

static rp_rec *build_record(const uint64_t *ret) {
  const rp_clone *w_c = &clones[w_id];
  rp_rec *r = calloc(1, sizeof *r);
  if (!r)
    abort();
  r->id = w_id;
  r->hash = w_hash;
  r->arg_sk = w_argsk;
  cqe__rp_put(&r->key, w_key.p, w_key.n);
  int ok = cqe__rp_encode(w_base, w_c0, w_hs, w_nh, &r->rails) == 0;
  if (ok && w_c->rk == 'h')
    r->ret_h = cqe__rp_enc_handle((int32_t)(uint32_t)*ret, w_base, w_hs, w_nh, &ok);
  else if (w_c->rk == 'c' || w_c->rk == 'i')
    r->ret_raw = *ret;
  /* a classical i32 result that names a rail the window made may be a handle after all: never replayed as a number */
  if (w_c->rk == 'i' && (uint32_t)*ret > w_base && (uint32_t)*ret <= cqe__rp_nrails())
    ok = 0;
  unsigned long long st = cqe__rp_steps();
  if (st < w_steps0)
    ok = 0;
  r->steps = st - w_steps0;
  if (!ok) {
    rec_free(r);
    return NULL;
  }
  r->nreads = brn;
  r->reads = malloc((brn ? brn : 1) * sizeof *r->reads);
  r->nwchk = bwcn;
  r->wchk = malloc((bwcn ? bwcn : 1) * sizeof *r->wchk);
  r->nwrites = bwan;
  r->writes = calloc(bwan ? bwan : 1, sizeof *r->writes);
  size_t nf;
  const uint32_t *fl = cqe__rp_frees(&nf);
  r->nfrees = nf;
  r->frees = malloc((nf ? nf : 1) * sizeof *r->frees);
  r->ngr = wgrn;
  r->gr = malloc((wgrn ? wgrn : 1) * sizeof *r->gr);
  r->ngw = wgwn;
  r->gw = malloc((wgwn ? wgwn : 1) * sizeof *r->gw);
  if (!r->reads || !r->wchk || !r->writes || !r->frees || !r->gr || !r->gw)
    abort();
  cqe__rp_cpy(r->gr, wgr, wgrn * sizeof *wgr);
  for (size_t i = 0; i < wgwn; ++i)
    r->gw[i] = (rp_gcell){wgw[i].a, g_get(wgw[i].a, wgw[i].n), wgw[i].n, 0};
  cqe__rp_cpy(r->reads, br, brn * sizeof *br);
  cqe__rp_cpy(r->wchk, bwc, bwcn * sizeof *bwc);
  cqe__rp_cpy(r->frees, fl, nf * sizeof *fl);
  for (size_t i = 0; i < bwan; ++i) {
    int q, k;
    uint8_t v;
    cqe__bus_cell_state(bwa[i], &q, &v, &k);
    aset_e *e = aset_get(bwa[i]);
    r->writes[i] = (rp_write){bwa[i], (uint8_t)q, q ? v : 0, (uint8_t)k, (uint8_t)((e->f & F_HOST) != 0),
                              (e->f & F_HOST) ? cqe__bus_host_byte(bwa[i]) : 0, {0}};
  }
  fenv_parts(&r->fcw, &r->fsw, &r->mxcsr);
  return r;
}

static size_t rec_size(const rp_rec *r) {
  return sizeof *r + r->key.cap + r->nreads * sizeof *r->reads + r->nwchk * sizeof *r->wchk +
         r->nwrites * sizeof *r->writes + r->nfrees * 4 + (r->ngr + r->ngw) * sizeof *r->gr + r->rails.blob.cap + r->rails.n * 8 + 64;
}

static void close_window(int mode, const uint64_t *ret) {
  rp_clone *w_c = &clones[w_id];
  cqe__rp_watch(0, NULL, 0, 0);
  int dirty = cqe__rp_dirty;
  cqe__rp_dirty = 0;
  if (!cqe__rp_stack_same())
    dirty = 1;
  cqe__rp_stack_mark(0);
  static cqe_rp_buf now;
  size_t off[65];
  args_snap(w_hs, w_nh, &now, off);
  w_argsk = 0;
  for (int i = 0; i < w_nh; ++i) {
    int c = snap_cmp(w_snap.p + w_snapoff[i], w_snapoff[i + 1] - w_snapoff[i], now.p + off[i], off[i + 1] - off[i]);
    if (c < 0)
      dirty = 1; /* the clone changed one of its arguments otherwise than by a store keeping it: outside its record */
    else if (c)
      w_argsk |= (uint64_t)1 << i;
  }
  rp_rec *r = dirty ? NULL : build_record(ret);
  if (mode == M_REC) {
    if (!r) {
      ++w_c->dirty;
      ++n_dirty;
      return;
    }
    if (st_tamper && !n_recs)
      cqe__rp_tamper(&r->rails);
    tab_insert(r);
    rec_bytes += rec_size(r);
    ++w_c->recs;
    ++n_recs;
    return;
  }
  ++n_checks;
  if (!r || !rec_same(r, w_ref)) {
    ++n_mism;
    w_ref->retired = 1;
    const char *bar = rp_chr(w_c->name, '|');
    cqe__violation("summary_mismatch", -1,
                   "cq-kcn5i: the spot check of a replayed call of %.*s: the real run %s its record (k %ld, hit %llu)",
                   bar ? (int)(bar - w_c->name) : 0, w_c->name, r ? "differs from" : "could not be recorded as",
                   cqe__rp_shot_k(), (unsigned long long)n_nhit);
  }
  rec_free(r);
}

static int spot_check(void) {
  uint64_t n = n_nhit++;
  if (!st_every)
    return 0;
  if (st_every == 1)
    return 1;
  uint64_t h = 0xcbf29ce484222325ULL;
  uint64_t k = (uint64_t)cqe__rp_shot_k();
  for (int i = 0; i < 8; ++i)
    h = (h ^ ((k >> (8 * i)) & 0xff)) * 0x100000001b3ULL;
  for (int i = 0; i < 8; ++i)
    h = (h ^ ((n >> (8 * i)) & 0xff)) * 0x100000001b3ULL;
  return h % st_every == 0;
}

static void apply(rp_rec *r, rp_clone *c, const int32_t *hs, int nh, uint64_t *ret) {
  cqe__rp_steps_add(r->steps);
  if (!args_apply(r->arg_sk, hs, nh)) {
    const char *bar = rp_chr(c->name, '|');
    cqe__violation("summary_mismatch", -1, "cq-kcn5i: a replayed call of %.*s: an argument did not take the store_kept flag "
                   "as its record says (rt_replay.c, the arguments)", bar ? (int)(bar - c->name) : 0, c->name);
  }
  int32_t rh = cqe__rp_apply(&r->rails, hs, nh, r->frees, r->nfrees, c->rk == 'h' ? r->ret_h : 0);
  for (size_t i = 0; i < r->nwrites; ++i) {
    const rp_write *w = &r->writes[i];
    cqe__bus_cell_set(w->a, w->q, w->v, w->k, w->hc, w->hv);
  }
  for (size_t i = 0; i < r->ngw; ++i)
    cqe__rp_cpy((void *)(uintptr_t)r->gw[i].a, &r->gw[i].v, r->gw[i].n);
  fenv_put(r->fcw, r->fsw, r->mxcsr);
  if (c->rk == 'h')
    *ret = (uint32_t)rh;
  else if (c->rk == 'c' || c->rk == 'i')
    *ret = r->ret_raw;
  c->rails += r->rails.n;
  n_rails += r->rails.n;
}

int32_t __cqe_rp_enter(int32_t id, const char *desc, const uint64_t *argv, uint64_t *ret) {
  cqe__init();
  settings();
  rp_clone *c = clone_of(id, desc);
  /* owner 2026-11-09: a call made while no wrapper call runs is an occurrence: its rails are named by it, however it
   * runs (core.c, rail names); it ends at its leave, or here for a hit (the wrapper calls no leave then) */
  int top = dn == 0;
  if (top)
    cqe__rp_occ(1);
  ++n_calls;
  if (c)
    ++c->calls;
  if (st_stats) {
    if (!stats_hooked) {
      stats_hooked = 1;
      atexit(stats_at_exit);
    }
    static uint64_t last;
    if (cqe__ncalls - last >= st_stats_every) { /* a line per 2^26 runtime calls: a sample that never ends still says */
      last = cqe__ncalls;
      stats_line("progress");
    }
  }
  /* run real, outside any window: off, an unparsed clone, inside an open window, a full trace, no occurrence (no
   * compact trace: rail names), cq_invert, prealloc */
  int open = 0;
  for (size_t i = 0; i < dn && !open; ++i)
    open = dstack[i] != M_NONE;
  if (open)
    clones[w_id].nonleaf = 1;
  if (!st_on || !c || c->nargs < 0 || open || cqe__trace_all() || !cqe__rp_named() || !cqe__rp_dispatch_idle() ||
      cqe__rp_prealloc()) {
    dpush(M_NONE);
    return 0;
  }
  int32_t hs[64];
  int nh = 0;
  w_key.n = 0;
  uint32_t idv = (uint32_t)id;
  cqe__rp_put(&w_key, &idv, sizeof idv);
  for (int i = 0; i < c->nargs; ++i) {
    if (c->kinds[i] == 'h')
      hs[nh++] = (int32_t)(uint32_t)argv[i];
    else
      cqe__rp_put(&w_key, &argv[i], sizeof argv[i]);
  }
  cqe__rp_argkey(hs, nh, 0, &w_key);
  uint16_t fcw, fsw;
  uint32_t mx;
  fenv_parts(&fcw, &fsw, &mx);
  cqe__rp_put(&w_key, &fcw, sizeof fcw);
  cqe__rp_put(&w_key, &fsw, sizeof fsw);
  cqe__rp_put(&w_key, &mx, sizeof mx);
  w_hash = fnv(w_key.p, w_key.n);
  rp_rec *hit = NULL;
  if (tab_cap)
    for (rp_rec *r = tab[w_hash & (tab_cap - 1)]; r && !hit; r = r->next)
      if (!r->retired && r->hash == w_hash && r->id == idv && r->key.n == w_key.n && cqe__rp_eq(r->key.p, w_key.p, w_key.n) &&
          pre_ok(r))
        hit = r;
  if (hit) {
    ++c->hits;
    ++n_hits;
    if (spot_check()) {
      w_ref = hit;
      open_window(M_CHECK, id, hs, nh);
      return 0;
    }
    apply(hit, c, hs, nh, ret);
    if (top)
      cqe__rp_occ(0);
    return 1;
  }
  /* a miss records, unless the clone's keys do not repeat or the records' heap is full (efficiency only). A clone that
   * calls wrapped clones is held to more: while its window is open they run real (windows do not nest), so each of
   * its misses costs their replays; it closes once 16 records have not brought 8 hits each (swprintf@0: the table
   * clone sw_write_111_t_ctl misses a third of its calls, and open it took every hit of mbtowc and sw_write). */
  if (c->closed || rec_bytes > st_max_bytes || (c->recs >= 256 && c->hits < c->recs) ||
      (c->nonleaf && c->recs >= 16 && c->hits < 8 * c->recs)) {
    c->closed = 1;
    dpush(M_NONE);
    return 0;
  }
  open_window(M_REC, id, hs, nh);
  return 0;
}

void __cqe_rp_leave(int32_t id, const uint64_t *ret) {
  (void)id;
  if (!dn)
    return;
  uint8_t m = dstack[--dn];
  if (m != M_NONE)
    close_window(m, ret);
  if (!dn)
    cqe__rp_occ(0);
}
