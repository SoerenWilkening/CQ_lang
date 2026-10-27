/* Test double of checker/rt/cqe.h for tests/rt-tape (cq-w0-rt-tape). The real core (cq-w0-chk-core)
 * is not linked: this file supplies the rail store, the op registry, the trace and the violation log,
 * plus test-private helpers (fake_*) that play the dispatcher and cqrt_free. The trace goes to the file
 * named by $CQE_TRACE (stdout otherwise), one JSON object per line. */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"
#include "fake_core.h"

typedef struct { int live, known; cqe_val v; } rail;
static rail *rails;
static int nrails, caprails;
static struct { char op[64]; cqe_op_fn fn; } ops[128];
static int nops;
static FILE *trace;
int fake_violations;

static FILE *tr(void) {
  if (!trace) {
    const char *p = getenv("CQE_TRACE");
    trace = p ? fopen(p, "w") : stdout;
    if (!trace) { perror("CQE_TRACE"); exit(2); }
  }
  return trace;
}

int cqe_parse_template(const char *sym, cqe_tname *out) { (void)sym; (void)out; return -1; }

void cqe_register_op(const char *op, cqe_op_fn fn) {
  for (int i = 0; i < nops; i++)
    if (!strcmp(ops[i].op, op) && ops[i].fn == fn) return;   /* M1: a repeated pair is a no-op */
  snprintf(ops[nops].op, sizeof ops[nops].op, "%s", op);
  ops[nops++].fn = fn;
}

static uint32_t nw_of(uint32_t bits) { return bits ? (bits + 63) / 64 : 1; }

int32_t cqe_new_rail(const char *w, const cqe_val *init, int known) {
  if (nrails == caprails) {
    caprails = caprails ? 2 * caprails : 64;
    rails = realloc(rails, (size_t)caprails * sizeof(rail));
  }
  rail *r = &rails[nrails];
  uint32_t bits = init ? init->bits : (uint32_t)atoi(w + 1);
  char kind = init ? init->kind : w[0];
  r->v.bits = bits;
  r->v.kind = kind;
  r->v.nw = nw_of(bits);
  r->v.w = calloc(r->v.nw, 8);
  if (init) for (uint32_t i = 0; i < r->v.nw && i < init->nw; i++) r->v.w[i] = init->w[i];
  r->live = 1;
  r->known = known;
  int32_t h = 100 + nrails++;
  fprintf(tr(), "{\"ev\":\"alloc\",\"h\":%d,\"w\":\"%s\",\"known\":%d}\n", (int)h, w, known);
  return h;
}

static rail *get(int32_t h) {
  int i = (int)h - 100;
  if (i < 0 || i >= nrails || !rails[i].live) return NULL;
  return &rails[i];
}

const cqe_val *cqe_rail(int32_t h) {
  rail *r = get(h);
  return r ? &r->v : NULL;
}

void cqe_xor_into(int32_t h, const cqe_val *v) {
  rail *r = get(h);
  if (!r) { cqe_fail("fake: xor into dead rail %d", (int)h); return; }
  for (uint32_t i = 0; i < r->v.nw && i < v->nw; i++) r->v.w[i] ^= v->w[i];
}

void cqe_set_known(int32_t h, int known) {
  rail *r = get(h);
  if (r) r->known = known;
}

void cqe_log(const char *json) { fprintf(tr(), "%s\n", json); fflush(tr()); }

void cqe_fail(const char *fmt, ...) {
  char buf[1024];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(buf, sizeof buf, fmt, ap);
  va_end(ap);
  fake_violations++;
  FILE *f = tr();
  fputs("{\"ev\":\"violation\",\"what\":\"", f);
  for (char *p = buf; *p; p++) {
    if (*p == '"' || *p == '\\') fputc('\\', f);
    fputc((unsigned char)*p < 0x20 ? ' ' : *p, f);
  }
  fputs("\"}\n", f);
  fflush(f);
}

/* ---- test-private helpers ---- */

cqe_val fake_i(uint32_t bits, uint64_t lo, uint64_t hi) {
  cqe_val v = {bits, 'i', nw_of(bits), calloc(nw_of(bits) < 2 ? 2 : nw_of(bits), 8)};
  v.w[0] = lo;
  if (v.nw > 1) v.w[1] = hi;
  return v;
}
cqe_val fake_f(uint32_t bits, uint64_t lo, uint64_t hi) {
  cqe_val v = fake_i(bits, lo, hi);
  v.kind = 'f';
  return v;
}
cqe_val fake_h(int32_t h) { return fake_i(32, (uint32_t)h, 0); }
cqe_val fake_p(const void *p) { return fake_i(64, (uint64_t)(uintptr_t)p, 0); }

int32_t fake_rail(const char *w, cqe_val v) { return cqe_new_rail(w, &v, 1); }

int32_t fake_call(const char *op, const char *w, int unc, int nargs, ...) {
  cqe_val args[8];
  va_list ap;
  va_start(ap, nargs);
  for (int i = 0; i < nargs; i++) args[i] = va_arg(ap, cqe_val);
  va_end(ap);
  cqe_tname tn;
  memset(&tn, 0, sizeof tn);
  snprintf(tn.op, sizeof tn.op, "%s", op);
  snprintf(tn.w, sizeof tn.w, "%s", w ? w : "");
  tn.unc = (uint8_t)unc;
  /* M1: out is the dispatcher's, preset to the declared return type (i32 handle or void), zeroed */
  int ret = strstr(op, "alloc") || (strstr(op, "write") && !strstr(op, "lit"));
  uint64_t word = 0;
  cqe_val out = {ret ? 32u : 0u, ret ? 'i' : 0, 1, &word};
  for (int i = 0; i < nops; i++)
    if (!strcmp(ops[i].op, op)) {
      int before = fake_violations;
      int rc = ops[i].fn(&tn, args, nargs, &out);
      if (!(rc == 0 && fake_violations == before) && !(rc == -1 && fake_violations > before))
        cqe_fail("TEST: %s returned %d with %d new violations", op, rc, fake_violations - before);
      if (out.w != &word || out.nw != 1 || out.bits != (ret ? 32u : 0u) || out.kind != (ret ? 'i' : 0) ||
          (!ret && word) || (ret && (word >> 32)))
        cqe_fail("TEST: %s broke the M1 out contract", op);
      return (int32_t)(uint32_t)word;
    }
  fprintf(stderr, "fake_core: no op registered under %s\n", op);
  exit(2);
}

void fake_free(int32_t h) {
  rail *r = get(h);
  if (!r) { cqe_fail("fake: free of dead rail %d", (int)h); return; }
  if (!r->known) cqe_fail("fake: free of rail %d not in a known basis state", (int)h);
  r->live = 0;
}

void fake_set(int32_t h, cqe_val v) {
  rail *r = get(h);
  if (r) for (uint32_t i = 0; i < r->v.nw && i < v.nw; i++) r->v.w[i] = v.w[i];
}

int fake_rc(const char *key, const char *op) {
  cqe_tname tn;
  memset(&tn, 0, sizeof tn);
  snprintf(tn.op, sizeof tn.op, "%s", op);
  uint64_t word = 0;
  cqe_val out = {32, 'i', 1, &word};
  for (int i = 0; i < nops; i++)
    if (!strcmp(ops[i].op, key)) return ops[i].fn(&tn, NULL, 0, &out);
  return -99;
}
