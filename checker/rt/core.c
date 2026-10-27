/* Checker core (cq-w0-chk-core): the rail store of the §6.1 classical basis-state evaluator, the
 * JSONL trace, violations, and the cqe.h API that families use. Symbol handling (the stub entry
 * cqe_dispatch, core-gate semantics, the template registry and parser) is in dispatch.c.
 *
 * Rails. A handle names one rail for the whole run; handles are never reused (1, 2, 3, ...). A rail
 * has a width token ("i32", "f80", ...), a basis value (cqe_val, little-endian 64-bit words, bits
 * above the width zero), a liveness state and its known-basis flag (CR §0, CLAUDE.md "The §6
 * checker"): a rail is known when it is in a known classical basis state, so cqrt_free may reset it.
 * Known: a seed (cqrt_alloc), a seed after an uncontrolled xorc, a template result or copy computed
 * only from known rails, a measured rail, and a rail an XOR-into write (template _unc, copy,
 * and/or/xor_i1) returned to 0 with no non-diagonal gate (Ry) on the target or any source after
 * the target's or the sources' creation (dispatch.c, zero_rule). A rotated rail is not known.
 *
 * Trace. One JSON object per line, to the file named by $CQE_TRACE (stderr when unset), flushed
 * per line so a crash keeps every event before it. The frozen events of cq-arch are written with
 * their frozen fields; some carry additive fields (documented at each writer). The exit event is
 * written by an atexit handler registered before any other runtime handler, so it comes last.
 *
 * Exit roles (event "exit", field "role" of each live rail): measured, abort, tape, qram, frozen
 * (rotated, not measured), kept_entangled (cq-arch A4: a rail one of whose direct sources received
 * a non-diagonal gate or a measurement after the rail was written), seed (an alloc never written
 * since), garbage (anything else).
 */
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

/* ---- values ------------------------------------------------------------------------------ */

uint32_t cqe__nwords(uint32_t bits) { return bits ? (bits + 63) / 64 : 1; }

static void *xcalloc(size_t n, size_t sz) {
  void *p = calloc(n ? n : 1, sz);
  if (!p) {
    fprintf(stderr, "cq: chk-core: out of memory\n");
    abort();
  }
  return p;
}

/* Bits and kind of a width token: i<N> (N >= 1, no leading zero), f16, f32, f64, f80. 0 if malformed. */
uint32_t cqe__wtok_bits(const char *w, char *kind) {
  if (!w)
    return 0;
  if (w[0] == 'f') {
    static const char *f[] = {"f16", "f32", "f64", "f80"};
    static const uint32_t b[] = {16, 32, 64, 80};
    for (int i = 0; i < 4; ++i)
      if (strcmp(w, f[i]) == 0) {
        if (kind)
          *kind = 'f';
        return b[i];
      }
    return 0;
  }
  if (w[0] != 'i' || w[1] < '1' || w[1] > '9')
    return 0;
  uint64_t n = 0;
  for (const char *p = w + 1; *p; ++p) {
    if (*p < '0' || *p > '9')
      return 0;
    n = n * 10 + (uint64_t)(*p - '0');
    if (n > (1u << 24))
      return 0;
  }
  if (kind)
    *kind = 'i';
  return (uint32_t)n;
}

void cqe__val_init(cqe_val *v, uint32_t bits, char kind) {
  v->bits = bits;
  v->kind = kind;
  v->nw = cqe__nwords(bits);
  v->w = xcalloc(v->nw, sizeof *v->w);
}

void cqe__val_free(cqe_val *v) {
  free(v->w);
  v->w = NULL;
  v->nw = 0;
}

void cqe__val_mask(cqe_val *v) {
  uint32_t full = v->bits / 64, rem = v->bits % 64;
  for (uint32_t i = 0; i < v->nw; ++i) {
    if (i > full || (i == full && rem == 0))
      v->w[i] = 0;
    else if (i == full)
      v->w[i] &= ((uint64_t)1 << rem) - 1;
  }
}

/* dst ^= low dst->bits of src (src may be narrower or wider). */
void cqe__val_xor(cqe_val *dst, const cqe_val *src) {
  for (uint32_t i = 0; i < dst->nw && i < src->nw; ++i)
    dst->w[i] ^= src->w[i];
  cqe__val_mask(dst);
}

void cqe__val_copy_into(cqe_val *dst, const cqe_val *src) {
  memset(dst->w, 0, dst->nw * sizeof *dst->w);
  cqe__val_xor(dst, src);
}

int cqe__val_iszero(const cqe_val *v) {
  for (uint32_t i = 0; i < v->nw; ++i)
    if (v->w[i])
      return 0;
  return 1;
}

/* "0x..." lowercase, no leading zeros; buf must hold 3 + 16 * nw bytes. */
char *cqe__hex(const cqe_val *v, char *buf) {
  char *p = buf;
  *p++ = '0';
  *p++ = 'x';
  int started = 0;
  for (uint32_t i = v->nw; i-- > 0;) {
    if (!started) {
      if (v->w[i] == 0 && i > 0)
        continue;
      p += sprintf(p, "%llx", (unsigned long long)v->w[i]);
      started = 1;
    } else {
      p += sprintf(p, "%016llx", (unsigned long long)v->w[i]);
    }
  }
  *p = 0;
  return buf;
}

/* Heap hex of a value (caller frees). */
char *cqe__hexa(const cqe_val *v) { return cqe__hex(v, xcalloc(3 + 16 * (size_t)v->nw + 1, 1)); }

/* ---- trace ------------------------------------------------------------------------------- */

static FILE *trace_f;
static int inited;
static unsigned long nviolations;

static void at_exit_handler(void);

void cqe__init(void) {
  if (inited)
    return;
  inited = 1;
  const char *path = getenv("CQE_TRACE");
  if (path && *path) {
    trace_f = fopen(path, "w");
    if (!trace_f) {
      fprintf(stderr, "cq: chk-core: cannot open CQE_TRACE '%s'\n", path);
      exit(97);
    }
  } else {
    trace_f = stderr;
  }
  atexit(at_exit_handler);
}

__attribute__((constructor(101))) static void cqe__ctor(void) { cqe__init(); }

void cqe_log(const char *json_object) {
  cqe__init();
  fputs(json_object, trace_f);
  fputc('\n', trace_f);
  fflush(trace_f);
}

/* printf-style log of one line. */
void cqe__logf(const char *fmt, ...) {
  cqe__init();
  va_list ap;
  va_start(ap, fmt);
  vfprintf(trace_f, fmt, ap);
  va_end(ap);
  fputc('\n', trace_f);
  fflush(trace_f);
}

/* JSON string body escaping into a heap buffer. */
static char *json_escape(const char *s) {
  size_t n = strlen(s);
  char *o = xcalloc(6 * n + 1, 1), *p = o;
  for (; *s; ++s) {
    unsigned char c = (unsigned char)*s;
    if (c == '"' || c == '\\') {
      *p++ = '\\';
      *p++ = (char)c;
    } else if (c < 0x20) {
      p += sprintf(p, "\\u%04x", c);
    } else {
      *p++ = (char)c;
    }
  }
  return o;
}

/* A violation: {"ev":"violation","what","h"} plus an additive "msg". h < 0 is written as null. */
void cqe__violation(const char *what, int32_t h, const char *fmt, ...) {
  char msg[1024];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(msg, sizeof msg, fmt ? fmt : "", ap);
  va_end(ap);
  char *e = json_escape(msg);
  ++nviolations;
  if (h > 0)
    cqe__logf("{\"ev\":\"violation\",\"what\":\"%s\",\"h\":%d,\"msg\":\"%s\"}", what, (int)h, e);
  else
    cqe__logf("{\"ev\":\"violation\",\"what\":\"%s\",\"h\":null,\"msg\":\"%s\"}", what, e);
  free(e);
}

void cqe_fail(const char *fmt, ...) {
  char msg[1024];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(msg, sizeof msg, fmt, ap);
  va_end(ap);
  cqe__violation("fail", -1, "%s", msg);
}

unsigned long cqe__violations(void) { return nviolations; }

/* ---- rails ------------------------------------------------------------------------------- */

typedef struct {
  char w[8];
  cqe_val v;
  uint8_t live, known, measured, frozen, written, seed, role;   /* role: 0 none, 1 abort, 2 tape, 3 qram */
  uint64_t t_create, t_write, t_nd, t_meas;                       /* event clock; 0 = never */
  int32_t *deps;
  uint32_t ndeps, capdeps;
} rail_t;

#define CQE_RAIL_LIMIT 0x51000000u /* rail handles stay below rt-mem's QRAM bus handles (cq-lxv) */
static rail_t *rails; /* rails[h], h >= 1 */
static uint32_t nrails, caprails;
static uint64_t clock_;

uint64_t cqe__tick(void) { return ++clock_; }
uint32_t cqe__nrails_peek(void) { return nrails; }

int32_t cqe__new(const char *w, const cqe_val *init, int known, int seed) {
  cqe__init();
  char kind = 0;
  uint32_t bits = cqe__wtok_bits(w, &kind);
  if (!bits) {
    cqe__violation("bad_width", -1, "rail width token '%s' is not i<N>, f16, f32, f64 or f80", w ? w : "(null)");
    bits = 1;
    kind = 'i';
    w = "i1";
  }
  if (nrails + 2 > caprails) {
    caprails = caprails ? 2 * caprails : 256;
    rails = realloc(rails, caprails * sizeof *rails);
    if (!rails)
      abort();
  }
  if (nrails + 1 >= CQE_RAIL_LIMIT) {
    /* rt-mem numbers QRAM buses from 0x51000000 and its synthetic exit ids from 0x5A000000 */
    fprintf(stderr, "cq: chk-core: rail handles exhausted (limit 0x%x, below rt-mem's bus range)\n",
            (unsigned)CQE_RAIL_LIMIT);
    abort();
  }
  int32_t h = (int32_t)++nrails;
  rail_t *r = &rails[h];
  memset(r, 0, sizeof *r);
  snprintf(r->w, sizeof r->w, "%s", w);
  cqe__val_init(&r->v, bits, kind);
  if (init)
    cqe__val_xor(&r->v, init);
  r->live = 1;
  r->known = known ? 1 : 0;
  r->seed = seed ? 1 : 0;
  r->t_create = r->t_write = cqe__tick();
  return h;
}

/* 0: h names a live rail. 1: freed (use_after_free logged). -1: no such rail (bad_handle logged). */
int cqe__check(int32_t h, const char *ctx) {
  cqe__init();
  if (h < 1 || (uint32_t)h > nrails) {
    cqe__violation("bad_handle", h > 0 ? h : -1, "%s: handle %d names no rail", ctx, (int)h);
    return -1;
  }
  if (!rails[h].live) {
    cqe__violation("use_after_free", h, "%s: rail %d was freed", ctx, (int)h);
    return 1;
  }
  return 0;
}

/* Quiet existence test (no violation). */
int cqe__exists(int32_t h) { return h >= 1 && (uint32_t)h <= nrails; }

cqe_val *cqe__val(int32_t h) { return &rails[h].v; }
const char *cqe__w(int32_t h) { return rails[h].w; }
int cqe__known(int32_t h) { return rails[h].known; }
void cqe__setknown(int32_t h, int k) { rails[h].known = k ? 1 : 0; }
uint64_t cqe__created(int32_t h) { return rails[h].t_create; }
uint64_t cqe__last_nd(int32_t h) { return rails[h].t_nd; }
int cqe__measured(int32_t h) { return rails[h].measured; }
int cqe__frozen(int32_t h) { return rails[h].frozen; }
int cqe__role(int32_t h) { return rails[h].role; }
void cqe__setrole(int32_t h, int role) { rails[h].role = (uint8_t)role; }

void cqe__mark_written(int32_t h) {
  rails[h].written = 1;
  rails[h].t_write = cqe__tick();
}
void cqe__mark_nd(int32_t h) {
  rails[h].frozen = 1;
  rails[h].t_nd = cqe__tick();
}
void cqe__mark_measured(int32_t h) {
  rails[h].measured = 1;
  rails[h].known = 1;
  rails[h].t_meas = cqe__tick();
}
void cqe__add_dep(int32_t h, int32_t src) {
  rail_t *r = &rails[h];
  for (uint32_t i = 0; i < r->ndeps; ++i)
    if (r->deps[i] == src)
      return;
  if (r->ndeps == r->capdeps) {
    r->capdeps = r->capdeps ? 2 * r->capdeps : 4;
    r->deps = realloc(r->deps, r->capdeps * sizeof *r->deps);
    if (!r->deps)
      abort();
  }
  r->deps[r->ndeps++] = src;
}

void cqe__free(int32_t h) { rails[h].live = 0; }

/* ---- cqe.h rail API (families) ------------------------------------------------------------- */

int32_t cqe_new_rail(const char *w, const cqe_val *init, int known) { return cqe__new(w, init, known, 0); }

const cqe_val *cqe_rail(int32_t h) {
  if (cqe__check(h, "cqe_rail") != 0) /* C1: a freed or unknown handle is a violation and NULL */
    return NULL;
  return &rails[h].v;
}

void cqe_xor_into(int32_t h, const cqe_val *v) {
  if (cqe__check(h, "cqe_xor_into") < 0 || !v)
    return;
  cqe__val_xor(&rails[h].v, v);
  cqe__mark_written(h);
}

void cqe_set_known(int32_t h, int known) {
  if (cqe__check(h, "cqe_set_known") < 0)
    return;
  rails[h].known = known ? 1 : 0;
}

/* ---- exit -------------------------------------------------------------------------------- */

static const char *exit_role(int32_t h) {
  rail_t *r = &rails[h];
  if (r->measured)
    return "measured";
  if (r->role == 1)
    return "abort";
  if (r->role == 2)
    return "tape";
  if (r->role == 3)
    return "qram";
  if (r->frozen)
    return "frozen";
  for (uint32_t i = 0; i < r->ndeps; ++i) {
    rail_t *s = &rails[r->deps[i]];
    if ((s->t_nd && s->t_nd > r->t_write) || (s->t_meas && s->t_meas > r->t_write))
      return "kept_entangled";
  }
  if (r->seed && !r->written)
    return "seed";
  return "garbage";
}

static void at_exit_handler(void) {
  size_t cap = 64, len = 0;
  char *buf = xcalloc(cap, 1);
#define APPEND(...)                                                                                \
  do {                                                                                             \
    int need_ = snprintf(NULL, 0, __VA_ARGS__);                                                    \
    while (len + (size_t)need_ + 1 > cap) {                                                        \
      cap *= 2;                                                                                    \
      buf = realloc(buf, cap);                                                                     \
      if (!buf)                                                                                    \
        abort();                                                                                   \
    }                                                                                              \
    len += (size_t)snprintf(buf + len, cap - len, __VA_ARGS__);                                    \
  } while (0)
  APPEND("{\"ev\":\"exit\",\"live\":[");
  int first = 1;
  for (uint32_t h = 1; h <= nrails; ++h) {
    if (!rails[h].live)
      continue;
    char *hx = cqe__hexa(&rails[h].v);
    APPEND("%s{\"h\":%u,\"w\":\"%s\",\"v\":\"%s\",\"role\":\"%s\"}", first ? "" : ",", h, rails[h].w, hx,
           exit_role((int32_t)h));
    free(hx);
    first = 0;
  }
  APPEND("],\"violations\":%lu}", nviolations);
#undef APPEND
  cqe_log(buf);
  free(buf);
  if (trace_f && trace_f != stderr)
    fclose(trace_f);
  trace_f = stderr;
}
