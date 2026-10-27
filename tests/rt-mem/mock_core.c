/* Test-only implementation of checker/rt/cqe.h (cq-w0-rt-mem). It lets tests/rt-mem drive
 * checker/rt/rt_mem.c without the real core (cq-w0-chk-core): a rail table with known flags, the op
 * registry, a JSONL log, and a violation counter. It is never linked into the checker. */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"
#include "mock_core.h"

#define MAX_OPS 64
static struct { char name[32]; cqe_op_fn fn; } g_ops[MAX_OPS];
static int g_nops;

typedef struct { int live, known; cqe_val v; } mrail;
static mrail *g_rails;
static int g_nrails, g_caprails;
static int g_fails;
static char g_last[512];
static FILE *g_log;

static FILE *logf_(void) {
  if (!g_log) {
    const char *p = getenv("RT_MEM_LOG");
    g_log = p ? fopen(p, "w") : NULL;
    if (!g_log) g_log = stderr;
  }
  return g_log;
}

int cqe_parse_template(const char *sym, cqe_tname *out) { (void)sym; (void)out; return -1; }

void cqe_register_op(const char *op, cqe_op_fn fn) {
  if (g_nops == MAX_OPS) abort();
  snprintf(g_ops[g_nops].name, sizeof g_ops[g_nops].name, "%s", op);
  g_ops[g_nops++].fn = fn;
}

/* cq-mgi dispatch: every handler registered for the op, in registration order, until one returns
 * something other than NOT_MINE (1); so no test depends on which constructor ran last. */
int mock_dispatch(const char *op, const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  for (int i = 0; i < g_nops; ++i)
    if (strcmp(g_ops[i].name, op) == 0) {
      int r = g_ops[i].fn(t, args, nargs, out);
      if (r != 1) return r;
    }
  fprintf(stderr, "mock: no family for op %s\n", op);
  abort();
}

cqe_op_fn mock_handler(const char *op) {
  for (int i = 0; i < g_nops; ++i)
    if (strcmp(g_ops[i].name, op) == 0) return g_ops[i].fn;
  return NULL;
}

static uint32_t tok_bits(const char *w, char *kind) {
  *kind = w[0] == 'f' ? 'f' : 'i';
  return (uint32_t)strtoul(w + 1, NULL, 10);
}

int32_t cqe_new_rail(const char *w, const cqe_val *init, int known) {
  if (g_nrails == g_caprails) {
    g_caprails = g_caprails ? 2 * g_caprails : 256;
    g_rails = realloc(g_rails, (size_t)g_caprails * sizeof *g_rails);
  }
  mrail *r = &g_rails[g_nrails];
  char kind;
  uint32_t bits = tok_bits(w, &kind);
  r->live = 1;
  r->known = known;
  r->v.bits = bits;
  r->v.kind = kind;
  r->v.nw = (bits + 63) / 64;
  r->v.w = calloc(r->v.nw, sizeof(uint64_t));
  if (init) {
    if (init->bits != bits) {
      fprintf(stderr, "mock: cqe_new_rail(%s) with a %u-bit init\n", w, init->bits);
      abort();
    }
    memcpy(r->v.w, init->w, r->v.nw * sizeof(uint64_t));
  }
  int32_t h = 1000 + g_nrails++;
  fprintf(logf_(), "{\"ev\":\"alloc\",\"h\":%d,\"w\":\"%s\",\"known\":%d}\n", h, w, known);
  return h;
}

static mrail *get(int32_t h) {
  int k = h - 1000;
  if (k < 0 || k >= g_nrails || !g_rails[k].live) return NULL;
  return &g_rails[k];
}

const cqe_val *cqe_rail(int32_t h) {
  mrail *r = get(h);
  return r ? &r->v : NULL;
}

void cqe_xor_into(int32_t h, const cqe_val *v) {
  mrail *r = get(h);
  if (!r || v->bits != r->v.bits) {
    fprintf(stderr, "mock: cqe_xor_into(%d) bad handle or width\n", h);
    abort();
  }
  for (uint32_t i = 0; i < r->v.nw; ++i) r->v.w[i] ^= v->w[i];
  r->known = 0;
}

void cqe_set_known(int32_t h, int known) {
  mrail *r = get(h);
  if (r) r->known = known;
}

void cqe_log(const char *json_object) { fprintf(logf_(), "%s\n", json_object); fflush(logf_()); }

void cqe_fail(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(g_last, sizeof g_last, fmt, ap);
  va_end(ap);
  g_fails++;
  fprintf(logf_(), "{\"ev\":\"violation\",\"what\":\"%s\"}\n", g_last);
}

int mock_fails(void) { return g_fails; }
const char *mock_last_fail(void) { return g_last; }
int mock_known(int32_t h) {
  mrail *r = get(h);
  return r ? r->known : -1;
}
void mock_free(int32_t h) {
  mrail *r = get(h);
  if (r) r->live = 0;
}
uint64_t *mock_words(int32_t h) {
  mrail *r = get(h);
  return r ? r->v.w : NULL;
}
