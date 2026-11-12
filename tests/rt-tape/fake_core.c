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

typedef struct { int live, known; const char *role; cqe_val v; } rail;
static rail *rails;
static int nrails, caprails;
static struct { char op[64]; cqe_op_fn fn; } ops[128];
static int nops;
static FILE *trace;
static const char *fake_new_role;   /* C1: the role the dispatcher gives rails created now */
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
  r->role = fake_new_role;
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

int cqe__known(int32_t h) {
  rail *r = get(h);
  return r ? r->known : 0;
}
/* core.c: a handle as an event writes it; the fake core's rails have no names apart from their handles */
long long cqe__hname(int32_t h) { return (long long)h; }
void cqe__setrole(int32_t h, int role) {
  rail *r = get(h);
  if (r && role == 2) r->role = "tape";
}

void cqe_log(const char *json) { fprintf(tr(), "%s\n", json); fflush(tr()); }
/* core.c (cq-9hzgh): every event is written here (no compact trace) */
int cqe__trace_all(void) { return 1; }

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
int32_t fake_qrail(const char *w, cqe_val v) { return cqe_new_rail(w, &v, 0); }

/* Plays the dispatcher of C1 (cqe.h): parses cqrt_<op>[_<W>][_hl|_lit][_controlled][_unc] into a zeroed
 * cqe_tname, sets the roles, presets out per M1, and checks the handler's return code and out. */
int32_t fake_call(const char *sym, int nargs, ...) {
  static const char *const opnames[] = {"qram_alloc", "qram_realloc", "qram_store", "qram_load", "qram_free",
                                        "tape_alloc", "tape_fmt", "tape_effect", "tape_write", "abort"};
  cqe_val args[8];
  va_list ap;
  va_start(ap, nargs);
  for (int i = 0; i < nargs; i++) args[i] = va_arg(ap, cqe_val);
  va_end(ap);
  cqe_tname tn;
  memset(&tn, 0, sizeof tn);
  if (strncmp(sym, "cqrt_", 5)) { fprintf(stderr, "fake_core: %s\n", sym); exit(2); }
  const char *s = sym + 5;
  size_t best = 0;
  for (size_t i = 0; i < sizeof opnames / sizeof opnames[0]; i++) {
    size_t n = strlen(opnames[i]);
    if (!strncmp(s, opnames[i], n) && (s[n] == 0 || s[n] == '_') && n > best) best = n;
  }
  if (!best) { fprintf(stderr, "fake_core: unknown_symbol %s\n", sym); exit(2); }
  memcpy(tn.op, s, best);
  s += best;
  while (*s == '_') {
    s++;
    const char *e = strchr(s, '_');
    size_t n = e ? (size_t)(e - s) : strlen(s);
    if ((s[0] == 'i' || s[0] == 'f') && n > 1 && n < 8 && strspn(s + 1, "0123456789") >= n - 1) memcpy(tn.w, s, n);
    else if (n == 2 && !strncmp(s, "hl", 2)) strcpy(tn.shape, "hl");
    else if (n == 3 && !strncmp(s, "lit", 3)) strcpy(tn.shape, "l");
    else if (n == 10 && !strncmp(s, "controlled", 10)) strcpy(tn.pred, "ctl");
    else if (n == 3 && !strncmp(s, "unc", 3)) tn.unc = 1;
    else { fprintf(stderr, "fake_core: unknown_symbol %s\n", sym); exit(2); }
    s += n;
  }
  /* C1 roles: argument 0 of abort, and every rail created during tape_write */
  if (!strcmp(tn.op, "abort") && nargs >= 1) {
    rail *r = get((int32_t)args[0].w[0]);
    if (r) r->role = "abort";
  }
  fake_new_role = !strcmp(tn.op, "tape_write") ? "tape" : NULL;
  /* M1: out is the dispatcher's, preset to the declared return type (i32 handle or void), zeroed */
  int ret = !strcmp(tn.op, "tape_alloc") || (!strcmp(tn.op, "tape_write") && strcmp(tn.shape, "l")) ||
            (!strcmp(tn.op, "tape_effect") && tn.w[0]);
  uint64_t word = 0;
  cqe_val out = {ret ? 32u : 0u, ret ? 'i' : 0, 1, &word};
  int handled = 0;
  for (int i = 0; i < nops && !handled; i++)
    if (!strcmp(ops[i].op, tn.op)) {
      int before = fake_violations;
      int rc = ops[i].fn(&tn, args, nargs, &out);
      if (rc == CQE_OP_NOT_MINE) {
        if (fake_violations != before) cqe_fail("TEST: %s: NOT_MINE after a violation", sym);
        word = 0;
        continue;
      }
      handled = 1;
      if (!(rc == 0 && fake_violations == before) && !(rc == -1 && fake_violations > before))
        cqe_fail("TEST: %s returned %d with %d new violations", sym, rc, fake_violations - before);
      if (out.w != &word || out.nw != 1 || out.bits != (ret ? 32u : 0u) || out.kind != (ret ? 'i' : 0) ||
          (!ret && word) || (ret && (word >> 32)))
        cqe_fail("TEST: %s broke the M1 out contract", sym);
    }
  fake_new_role = NULL;
  if (!handled) cqe_fail("fake: no_family for %s", sym);
  return (int32_t)(uint32_t)word;
}

void fake_free(int32_t h) {
  rail *r = get(h);
  if (!r) { cqe_fail("fake: free of dead rail %d", (int)h); return; }
  if (r->role) cqe_fail("fake: free_forbidden: rail %d has role %s", (int)h, r->role);
  else if (!r->known) cqe_fail("fake: free of rail %d not in a known basis state", (int)h);
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
