/* rt_tape.c: the evaluator semantics of the tape and abort family (cq-w0-rt-tape).
 *
 * Symbols: cqrt_tape_alloc, cqrt_tape_fmt[_controlled], cqrt_tape_effect_controlled,
 * cqrt_tape_write_<W>[_controlled], cqrt_tape_write_<W>_lit, cqrt_tape_write_str_lit, cqrt_abort_i1.
 * Semantics: CONSTRUCTION_RULES §1.3 (the deferred-measurement paragraph, rule 16; it wins) and
 * BACKEND_ABI §1.11. §2 has no row for this family.
 *
 *  - All tape entries and abort flags form ONE event sequence in call order, across every tape.
 *  - An entry (fmt or effect) records its predicate at call time (1 when uncontrolled). Its predicate
 *    rail may be uncomputed and freed afterwards (47), so the value is captured here.
 *  - Fields append to the most recent entry of their own tape. A rail field is a fresh write-only tape
 *    rail h' with h' ^= h (controlled: h' ^= c ? h : 0); h is unchanged; h' is never freed. Literal
 *    and string fields, the format string and the effect name are copied at call time.
 *  - An abort flag is kept and measured at the end of the shot.
 *  - End of shot (process exit via return from main or exit(); _Exit loses the tape): every entry
 *    whose predicate read 1 and that no earlier abort flag reading 1 precedes is performed. A format
 *    entry is printed with printf semantics on its measured fields; an effect entry is recorded as
 *    performed and never executed. The evaluator registers the end-of-shot handler with atexit on its
 *    first call, as BACKEND_ABI §1.11 prescribes for a backend.
 *
 * Violations (cqe_fail): a field with no open entry on its tape, a tape handle not returned by
 * cqrt_tape_alloc, a predicate or abort flag that is not a live i1 rail, a width token that disagrees
 * with the rail, an _unc of a tape/abort symbol, a tape rail or abort flag that is gone or changed at
 * the end of the shot, a format that needs a field the entry lacks, a conversion with no defined
 * meaning on a tape field (%n, an unknown conversion), a form the family does not define. Tape rails are
 * created with known = 0 (they stay entangled with their source, BACKEND_ABI §1.11). The dispatcher gives
 * them role "tape" and abort flags role "abort" and rejects a cqrt_free of either (C1, free_forbidden).
 *
 * Trace events (cq-arch: "tape" free-form, "abort" frozen as {"ev","f","fv"}):
 *   {"ev":"tape","op":"alloc","t"}
 *   {"ev":"tape","op":"fmt"|"effect","seq","t","c","cv","fmt"|"name"}      c = -1 when uncontrolled
 *   {"ev":"tape","op":"write","seq","t","field","c","cv","src","h","w","v"}
 *   {"ev":"tape","op":"write_lit","seq","t","field","w","v"}
 *   {"ev":"tape","op":"write_str","seq","t","field","s"}
 *   {"ev":"abort","f","fv","seq"}
 *   {"ev":"tape","op":"shot","aborted","abort_seq","stdout",
 *    "events":[{"seq","kind":"fmt"|"effect"|"abort", ...}]}                 one line at the end of the shot
 * In "events" an entry carries "t","pred","performed","fmt"|"name","fields":[{"k":"rail","h","w","v"}|
 * {"k":"lit","w","v"}|{"k":"str","s"}] (rail values read at the end of the shot) and, for a format
 * entry, "text" (what printf prints for it); an abort carries "f","fv" (its end-of-shot value).
 * Values are hex bit patterns ("0x…"). Strings are bytes, each written as the code point U+0000–U+00FF
 * of the same number.
 *
 * Dispatch (cqe.h M1 and C1): the family registers the bare ops tape_alloc, tape_fmt, tape_effect,
 * tape_write, tape_write_str and abort. cqe_tname.w is the width token, shape "l" marks _lit, pred "ctl"
 * marks _controlled (the arity must agree), and args are the raw ABI arguments (a handle as its i32
 * number, a ptr as a 64-bit 'i' holding the address, a literal in its own type). Return: 0 computed,
 * CQE_OP_NOT_MINE for an op outside the family, -1 after cqe_fail.
 */
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include "cqe.h"

/* Every violation this family reports also makes the current call return -1 (cq-f69). */
static int g_failed;
#define cqe_fail(...) (g_failed = 1, cqe_fail(__VA_ARGS__))


/* ---------- small utilities ---------- */

typedef struct { char *p; size_t n, cap; } sbuf;

static void sb_reserve(sbuf *b, size_t extra) {
  if (b->n + extra + 1 <= b->cap) return;
  size_t cap = b->cap ? b->cap : 256;
  while (cap < b->n + extra + 1) cap *= 2;
  char *p = realloc(b->p, cap);
  if (!p) { fprintf(stderr, "cq: rt_tape: out of memory\n"); abort(); }
  b->p = p; b->cap = cap;
}
static void sb_put(sbuf *b, const char *s, size_t n) {
  sb_reserve(b, n);
  memcpy(b->p + b->n, s, n);
  b->n += n;
  b->p[b->n] = 0;
}
static void sb_puts(sbuf *b, const char *s) { sb_put(b, s, strlen(s)); }
static void sb_printf(sbuf *b, const char *fmt, ...) {
  va_list ap, aq;
  va_start(ap, fmt);
  va_copy(aq, ap);
  int n = vsnprintf(NULL, 0, fmt, ap);
  va_end(ap);
  if (n < 0) { va_end(aq); return; }
  sb_reserve(b, (size_t)n);
  vsnprintf(b->p + b->n, (size_t)n + 1, fmt, aq);
  va_end(aq);
  b->n += (size_t)n;
}
/* A JSON string literal of n bytes; each byte becomes the code point of the same number. */
static void sb_json_str(sbuf *b, const char *s, size_t n) {
  sb_put(b, "\"", 1);
  for (size_t i = 0; i < n; i++) {
    unsigned char c = (unsigned char)s[i];
    if (c == '"') sb_puts(b, "\\\"");
    else if (c == '\\') sb_puts(b, "\\\\");
    else if (c == '\n') sb_puts(b, "\\n");
    else if (c < 0x20 || c >= 0x7f) sb_printf(b, "\\u%04x", c);
    else sb_put(b, (const char *)&c, 1);
  }
  sb_put(b, "\"", 1);
}

/* An owned copy of a value. */
typedef struct { uint32_t bits; char kind; uint32_t nw; uint64_t *w; } tval;

static uint32_t words_for(uint32_t bits) { return bits ? (bits + 63) / 64 : 1; }

static tval tv_copy(const cqe_val *v) {
  tval r = {v->bits, v->kind, words_for(v->bits), NULL};
  r.w = calloc(r.nw, sizeof(uint64_t));
  for (uint32_t i = 0; i < r.nw && i < v->nw; i++) r.w[i] = v->w ? v->w[i] : 0;
  if (r.bits % 64) r.w[r.nw - 1] &= (UINT64_C(1) << (r.bits % 64)) - 1;
  return r;
}
static tval tv_zero(uint32_t bits, char kind) {
  tval r = {bits, kind, words_for(bits), NULL};
  r.w = calloc(r.nw, sizeof(uint64_t));
  return r;
}
static int tv_eq(const tval *a, const cqe_val *b) {
  tval c = tv_copy(b);
  int eq = a->bits == c.bits && a->kind == c.kind && memcmp(a->w, c.w, a->nw * sizeof(uint64_t)) == 0;
  free(c.w);
  return eq;
}
static void sb_hex(sbuf *b, const tval *v) {
  int top = (int)v->nw - 1;
  while (top > 0 && v->w[top] == 0) top--;
  sb_printf(b, "\"0x%llx", (unsigned long long)v->w[top]);
  for (int i = top - 1; i >= 0; i--) sb_printf(b, "%016llx", (unsigned long long)v->w[i]);
  sb_puts(b, "\"");
}
static void width_token(const tval *v, char out[8]) {
  if (v->kind == 'f') snprintf(out, 8, "f%u", v->bits);
  else snprintf(out, 8, "i%u", v->bits);
}
static char *dupstr(const char *s) {
  size_t n = strlen(s);
  char *r = malloc(n + 1);
  memcpy(r, s, n + 1);
  return r;
}

/* ---------- the event sequence ---------- */

enum { F_RAIL, F_LIT, F_STR };
typedef struct {
  int k;
  int32_t h, src, c;     /* rail fields: tape rail, source, predicate (-1: none) */
  int cv;
  char w[8];
  tval v;                /* rail: value at the call; lit: the literal */
  char *s;               /* str */
} field;

enum { E_FMT, E_EFFECT, E_ABORT };
typedef struct {
  int k;
  int32_t t, c, f;       /* tape, predicate rail (-1: uncontrolled), abort flag */
  int pred;              /* predicate at the call (entry) or flag value at the call (abort) */
  char *str;             /* fmt or effect name */
  field *fields;
  int nfields, capfields;
} event;

static event *g_ev;
static int g_nev, g_capev;
static int *g_tape_open;          /* per tape: index of its open entry in g_ev, or -1 */
static int g_ntapes, g_captapes;
static int g_registered_exit;

#define TAPE_BASE 0x7a000000      /* tape handles live in their own range, away from rail handles */

static void shot(void);
/* C1: registered on the family's first operation, which is after its first cqe_* call (cqe_register_op
 * in the constructor), so it runs before the core's exit event with cqe_rail/cqe_log/cqe_fail valid. */
static void ensure_exit(void) {
  if (!g_registered_exit) { g_registered_exit = 1; atexit(shot); }
}

static event *new_event(int k) {
  if (g_nev == g_capev) {
    g_capev = g_capev ? 2 * g_capev : 32;
    g_ev = realloc(g_ev, (size_t)g_capev * sizeof(event));
  }
  event *e = &g_ev[g_nev++];
  memset(e, 0, sizeof *e);
  e->k = k;
  e->c = -1;
  e->f = -1;
  return e;
}

static int tape_index(int32_t t, const char *sym) {
  int64_t i = (int64_t)t - TAPE_BASE;
  if (i < 0 || i >= g_ntapes) {
    cqe_fail("tape: %s: handle %d was not returned by cqrt_tape_alloc", sym, (int)t);
    return -1;
  }
  return (int)i;
}

/* The basis value of an i1 rail, or -1 after a violation. */
static int read_i1(int32_t h, const char *sym, const char *what) {
  const cqe_val *v = cqe_rail(h);
  if (!v) { cqe_fail("tape: %s: %s %d is not a live rail", sym, what, (int)h); return -1; }
  if (v->bits != 1 || v->kind != 'i') {
    cqe_fail("tape: %s: %s %d is not an i1 rail", sym, what, (int)h);
    return -1;
  }
  return (int)(v->w[0] & 1);
}

static int32_t arg_i32(const cqe_val *a) { return (int32_t)(uint32_t)(a->w ? a->w[0] : 0); }
static const char *arg_ptr(const cqe_val *a) { return (const char *)(uintptr_t)(a->w ? a->w[0] : 0); }

static void log_line(sbuf *b) { cqe_log(b->p); free(b->p); }

/* ---------- operations ---------- */

static int32_t op_tape_alloc(void) {
  ensure_exit();
  if (g_ntapes == g_captapes) {
    g_captapes = g_captapes ? 2 * g_captapes : 8;
    g_tape_open = realloc(g_tape_open, (size_t)g_captapes * sizeof(int));
  }
  g_tape_open[g_ntapes] = -1;
  int32_t t = TAPE_BASE + g_ntapes++;
  sbuf b = {0};
  sb_printf(&b, "{\"ev\":\"tape\",\"op\":\"alloc\",\"t\":%d}", (int)t);
  log_line(&b);
  return t;
}

static void op_entry(int kind, int ctl, int32_t c, int32_t t, const char *s, const char *sym) {
  ensure_exit();
  int ti = tape_index(t, sym);
  int pred = 1;
  if (!ctl) c = -1;
  else {
    pred = read_i1(c, sym, "predicate");
    if (pred < 0) pred = 0;
  }
  if (!s) { cqe_fail("tape: %s: null string", sym); s = ""; }
  event *e = new_event(kind);
  e->t = t;
  e->c = c;
  e->pred = pred;
  e->str = dupstr(s);
  if (ti >= 0) g_tape_open[ti] = g_nev - 1;
  sbuf b = {0};
  sb_printf(&b, "{\"ev\":\"tape\",\"op\":\"%s\",\"seq\":%d,\"t\":%d,\"c\":%d,\"cv\":%d,\"%s\":",
            kind == E_FMT ? "fmt" : "effect", g_nev - 1, (int)t, (int)c, pred,
            kind == E_FMT ? "fmt" : "name");
  sb_json_str(&b, e->str, strlen(e->str));
  sb_puts(&b, "}");
  log_line(&b);
}

static field *new_field(int32_t t, const char *sym, int *seq, int *fi) {
  int ti = tape_index(t, sym);
  if (ti < 0) return NULL;
  if (g_tape_open[ti] < 0) {
    cqe_fail("tape: %s: field appended to tape %d with no open entry", sym, (int)t);
    return NULL;
  }
  event *e = &g_ev[g_tape_open[ti]];
  if (e->nfields == e->capfields) {
    e->capfields = e->capfields ? 2 * e->capfields : 4;
    e->fields = realloc(e->fields, (size_t)e->capfields * sizeof(field));
  }
  field *f = &e->fields[e->nfields];
  memset(f, 0, sizeof *f);
  f->h = f->src = f->c = -1;
  *seq = g_tape_open[ti];
  *fi = e->nfields++;
  return f;
}

static int32_t op_tape_write(int ctl, int32_t c, int32_t t, int32_t h, const char *wtok, const char *sym) {
  ensure_exit();
  const cqe_val *src = cqe_rail(h);
  if (!src) { cqe_fail("tape: %s: source %d is not a live rail", sym, (int)h); return -1; }
  tval v = tv_copy(src);
  char w[8];
  width_token(&v, w);
  if (wtok && *wtok && strcmp(wtok, w) != 0)
    cqe_fail("tape: %s: width %s but rail %d is %s", sym, wtok, (int)h, w);
  int cv = 1;
  if (!ctl) c = -1;
  else {
    cv = read_i1(c, sym, "predicate");
    if (cv < 0) cv = 0;
  }
  if (!cv) { free(v.w); v = tv_zero(src->bits, src->kind); }
  cqe_val init = {v.bits, v.kind, v.nw, v.w};
  int32_t hp = cqe_new_rail(w, &init, 0);   /* write-only, entangled with h: never in a known basis */
  int seq = -1, fi = -1;
  field *f = new_field(t, sym, &seq, &fi);
  sbuf b = {0};
  sb_printf(&b, "{\"ev\":\"tape\",\"op\":\"write\",\"seq\":%d,\"t\":%d,\"field\":%d,\"c\":%d,\"cv\":%d,"
                "\"src\":%d,\"h\":%d,\"w\":\"%s\",\"v\":",
            seq, (int)t, fi, (int)c, cv, (int)h, (int)hp, w);
  sb_hex(&b, &v);
  sb_puts(&b, "}");
  log_line(&b);
  if (f) {
    f->k = F_RAIL; f->h = hp; f->src = h; f->c = c; f->cv = cv; f->v = v;
    memcpy(f->w, w, 8);
  } else {
    free(v.w);
  }
  return hp;
}

static void op_tape_write_lit(int32_t t, const cqe_val *lit, const char *wtok, const char *sym) {
  ensure_exit();
  tval v = tv_copy(lit);
  char w[8];
  width_token(&v, w);
  if (wtok && *wtok && strcmp(wtok, w) != 0)
    cqe_fail("tape: %s: width %s but the literal is %s", sym, wtok, w);
  int seq = -1, fi = -1;
  field *f = new_field(t, sym, &seq, &fi);
  sbuf b = {0};
  sb_printf(&b, "{\"ev\":\"tape\",\"op\":\"write_lit\",\"seq\":%d,\"t\":%d,\"field\":%d,\"w\":\"%s\",\"v\":",
            seq, (int)t, fi, w);
  sb_hex(&b, &v);
  sb_puts(&b, "}");
  log_line(&b);
  if (f) { f->k = F_LIT; f->v = v; memcpy(f->w, w, 8); }
  else free(v.w);
}

static void op_tape_write_str(int32_t t, const char *s, const char *sym) {
  ensure_exit();
  if (!s) { cqe_fail("tape: %s: null string", sym); s = ""; }
  int seq = -1, fi = -1;
  field *f = new_field(t, sym, &seq, &fi);
  sbuf b = {0};
  sb_printf(&b, "{\"ev\":\"tape\",\"op\":\"write_str\",\"seq\":%d,\"t\":%d,\"field\":%d,\"s\":", seq, (int)t, fi);
  sb_json_str(&b, s, strlen(s));
  sb_puts(&b, "}");
  log_line(&b);
  if (f) { f->k = F_STR; f->s = dupstr(s); }
}

static void op_abort(int32_t fh, const char *sym) {
  ensure_exit();
  int fv = read_i1(fh, sym, "abort flag");
  event *e = new_event(E_ABORT);
  e->f = fh;
  e->pred = fv < 0 ? 0 : fv;
  sbuf b = {0};
  sb_printf(&b, "{\"ev\":\"abort\",\"f\":%d,\"fv\":\"0x%d\",\"seq\":%d}", (int)fh, e->pred, g_nev - 1);
  log_line(&b);
}

/* ---------- printf on measured fields ---------- */

static uint64_t low64(const tval *v) { return v->w[0]; }

/* IEEE half to double, exact; a NaN keeps its sign and payload and is quieted, as fpext does. */
static double half_to_double(uint16_t h) {
  uint64_t sign = (uint64_t)(h >> 15) << 63;
  int exp = (h >> 10) & 0x1f;
  uint64_t man = h & 0x3ff, bits;
  if (exp == 0x1f) {
    bits = sign | (UINT64_C(0x7ff) << 52) | (man << 42) | (man ? UINT64_C(1) << 51 : 0);
  } else if (exp == 0) {
    if (man == 0) bits = sign;
    else {
      int e = -14;
      while (!(man & 0x400)) { man <<= 1; e--; }
      man &= 0x3ff;
      bits = sign | ((uint64_t)(e + 1023) << 52) | (man << 42);
    }
  } else {
    bits = sign | ((uint64_t)(exp - 15 + 1023) << 52) | (man << 42);
  }
  double d;
  memcpy(&d, &bits, 8);
  return d;
}
static long double field_ld(const tval *v) {
  if (v->kind == 'f' && v->bits == 80) {
    long double x = 0;
    unsigned char buf[16] = {0};
    memcpy(buf, &v->w[0], 8);
    uint16_t hi = (uint16_t)(v->nw > 1 ? v->w[1] : 0);
    memcpy(buf + 8, &hi, 2);
    memcpy(&x, buf, sizeof x < 16 ? sizeof x : 16);
    return x;
  }
  if (v->kind == 'f' && v->bits == 64) { double d; uint64_t u = low64(v); memcpy(&d, &u, 8); return d; }
  if (v->kind == 'f' && v->bits == 32) { float f; uint32_t u = (uint32_t)low64(v); memcpy(&f, &u, 4); return f; }
  if (v->kind == 'f' && v->bits == 16) return half_to_double((uint16_t)low64(v));
  double d; uint64_t u = low64(v); memcpy(&d, &u, 8); return d;   /* an integer field: its bits */
}
static double field_d(const tval *v) {
  if (v->kind == 'f' && v->bits == 64) { double d; uint64_t u = low64(v); memcpy(&d, &u, 8); return d; }
  if (v->kind == 'f' && v->bits == 32) { float f; uint32_t u = (uint32_t)low64(v); memcpy(&f, &u, 4); return f; }
  if (v->kind == 'f' && v->bits == 16) return half_to_double((uint16_t)low64(v));
  if (v->kind == 'f' && v->bits == 80) return (double)field_ld(v);
  double d; uint64_t u = low64(v); memcpy(&d, &u, 8); return d;
}

/* The printf text of one entry. A field that a conversion consumes is read as the C argument the
 * conversion expects: an integer field contributes its low bits, zero-extended or truncated to the
 * argument type (the lowering writes the promoted printf argument, so the widths agree in practice);
 * an fp field is converted to double, or to long double under L. Returns 0 after a violation. */
static int format_entry(const event *e, const tval *vals, sbuf *out) {
  const char *p = e->str;
  int next = 0, ok = 1;
  while (*p) {
    if (*p != '%') { sb_put(out, p, 1); p++; continue; }
    const char *start = p++;
    if (*p == '%') { sb_put(out, "%", 1); p++; continue; }
    char spec[96];
    size_t sn = 0;
    spec[sn++] = '%';
    while (*p && strchr("-+ #0'", *p) && sn < 40) spec[sn++] = *p++;
    for (int part = 0; part < 2; part++) {          /* width, then precision */
      if (part == 1) {
        if (*p != '.') break;
        spec[sn++] = *p++;
      }
      if (*p == '*') {
        p++;
        if (next >= e->nfields || e->fields[next].k == F_STR) {
          cqe_fail("tape: entry %d: format \"%s\" needs an int field for '*'", (int)(e - g_ev), e->str);
          return 0;
        }
        int x = (int)(uint32_t)low64(&vals[next++]);
        sn += (size_t)snprintf(spec + sn, sizeof spec - sn, "%d", x);
      } else {
        while (*p >= '0' && *p <= '9' && sn < 80) spec[sn++] = *p++;
      }
    }
    char len[3] = {0};
    if (*p == 'h' || *p == 'l') {
      len[0] = *p++;
      if (*p == len[0]) len[1] = *p++;
    } else if (*p && strchr("jztLq", *p)) {
      len[0] = *p++;
    }
    char conv = *p ? *p++ : 0;
    if (!conv || !strchr("diuoxXcspfFeEgGaAn", conv)) {
      cqe_fail("tape: entry %d: format \"%s\": conversion \"%.*s\" has no defined meaning", (int)(e - g_ev),
               e->str, (int)(p - start), start);
      return 0;
    }
    if (conv == 'n') {
      cqe_fail("tape: entry %d: format \"%s\": %%n on a tape entry", (int)(e - g_ev), e->str);
      return 0;
    }
    if (next >= e->nfields) {
      cqe_fail("tape: entry %d: format \"%s\" needs more fields than the entry has (%d)", (int)(e - g_ev),
               e->str, e->nfields);
      return 0;
    }
    const field *f = &e->fields[next];
    const tval *v = &vals[next];
    next++;
    spec[sn] = 0;
    char full[112];
    if (conv == 's') {
      if (len[0] == 'l') {
        cqe_fail("tape: entry %d: %%ls on a tape entry", (int)(e - g_ev));
        return 0;
      }
      if (f->k == F_STR) { snprintf(full, sizeof full, "%ss", spec); sb_printf(out, full, f->s); }
      else if (f->k == F_LIT) { snprintf(full, sizeof full, "%ss", spec); sb_printf(out, full, (const char *)(uintptr_t)low64(v)); }
      else { cqe_fail("tape: entry %d: %%s on a quantum field", (int)(e - g_ev)); ok = 0; }
      continue;
    }
    if (f->k == F_STR) {
      cqe_fail("tape: entry %d: format \"%s\": a string field for %%%c", (int)(e - g_ev), e->str, conv);
      return 0;
    }
    uint64_t u = low64(v);
    switch (conv) {
    case 'd': case 'i': {
      long long x;
      if (!strcmp(len, "hh")) x = (signed char)u;
      else if (!strcmp(len, "h")) x = (short)u;
      else if (len[0] == 0) x = (int)(uint32_t)u;
      else x = (long long)u;
      snprintf(full, sizeof full, "%sll%c", spec, conv);
      sb_printf(out, full, x);
      break;
    }
    case 'u': case 'o': case 'x': case 'X': {
      unsigned long long x;
      if (!strcmp(len, "hh")) x = (unsigned char)u;
      else if (!strcmp(len, "h")) x = (unsigned short)u;
      else if (len[0] == 0) x = (uint32_t)u;
      else x = u;
      snprintf(full, sizeof full, "%sll%c", spec, conv);
      sb_printf(out, full, x);
      break;
    }
    case 'c': {
      if (len[0] == 'l') { snprintf(full, sizeof full, "%slc", spec); sb_printf(out, full, (wint_t)(uint32_t)u); }
      else { snprintf(full, sizeof full, "%sc", spec); sb_printf(out, full, (int)(uint32_t)u); }
      break;
    }
    case 'p':
      snprintf(full, sizeof full, "%sp", spec);
      sb_printf(out, full, (void *)(uintptr_t)u);
      break;
    default:  /* f F e E g G a A */
      if (len[0] == 'L') { snprintf(full, sizeof full, "%sL%c", spec, conv); sb_printf(out, full, field_ld(v)); }
      else { snprintf(full, sizeof full, "%s%c", spec, conv); sb_printf(out, full, field_d(v)); }
      break;
    }
  }
  return ok;
}

/* ---------- end of shot ---------- */

static void shot(void) {
  sbuf b = {0}, text = {0};
  sb_reserve(&text, 0);
  int aborted = 0, abort_seq = -1;
  sb_puts(&b, "{\"ev\":\"tape\",\"op\":\"shot\",\"events\":[");
  for (int i = 0; i < g_nev; i++) {
    event *e = &g_ev[i];
    if (i) sb_puts(&b, ",");
    if (e->k == E_ABORT) {
      int fv = e->pred;
      if (e->f >= 0) {
        const cqe_val *v = cqe_rail(e->f);
        if (!v) cqe_fail("tape: abort flag %d (event %d) is gone at the end of the shot", (int)e->f, i);
        else {
          fv = (int)(v->w[0] & 1);
          if (fv != e->pred)
            cqe_fail("tape: abort flag %d (event %d) changed after cqrt_abort_i1 (%d -> %d)", (int)e->f, i,
                     e->pred, fv);
        }
      }
      sb_printf(&b, "{\"seq\":%d,\"kind\":\"abort\",\"f\":%d,\"fv\":\"0x%d\"}", i, (int)e->f, fv);
      if (fv && !aborted) { aborted = 1; abort_seq = i; }
      continue;
    }
    tval *vals = calloc((size_t)(e->nfields ? e->nfields : 1), sizeof(tval));
    for (int j = 0; j < e->nfields; j++) {
      field *f = &e->fields[j];
      if (f->k == F_RAIL) {
        const cqe_val *v = cqe_rail(f->h);
        if (!v) {
          cqe_fail("tape: tape rail %d (event %d field %d) is gone at the end of the shot", (int)f->h, i, j);
          vals[j] = f->v;
        } else {
          if (!tv_eq(&f->v, v))
            cqe_fail("tape: tape rail %d (event %d field %d) changed after its write", (int)f->h, i, j);
          vals[j] = tv_copy(v);
        }
      } else {
        vals[j] = f->v;
      }
    }
    int performed = e->pred && !aborted;
    sb_printf(&b, "{\"seq\":%d,\"kind\":\"%s\",\"t\":%d,\"pred\":%d,\"performed\":%s,\"%s\":", i,
              e->k == E_FMT ? "fmt" : "effect", (int)e->t, e->pred, performed ? "true" : "false",
              e->k == E_FMT ? "fmt" : "name");
    sb_json_str(&b, e->str, strlen(e->str));
    sb_puts(&b, ",\"fields\":[");
    for (int j = 0; j < e->nfields; j++) {
      field *f = &e->fields[j];
      if (j) sb_puts(&b, ",");
      if (f->k == F_STR) { sb_puts(&b, "{\"k\":\"str\",\"s\":"); sb_json_str(&b, f->s, strlen(f->s)); sb_puts(&b, "}"); }
      else {
        if (f->k == F_RAIL) sb_printf(&b, "{\"k\":\"rail\",\"h\":%d,\"w\":\"%s\",\"v\":", (int)f->h, f->w);
        else sb_printf(&b, "{\"k\":\"lit\",\"w\":\"%s\",\"v\":", f->w);
        sb_hex(&b, &vals[j]);
        sb_puts(&b, "}");
      }
    }
    sb_puts(&b, "]");
    if (e->k == E_FMT) {
      sbuf t = {0};
      sb_reserve(&t, 0);
      format_entry(e, vals, &t);
      sb_puts(&b, ",\"text\":");
      sb_json_str(&b, t.p, t.n);
      if (performed) sb_put(&text, t.p, t.n);
      free(t.p);
    }
    sb_puts(&b, "}");
    for (int j = 0; j < e->nfields; j++)
      if (e->fields[j].k == F_RAIL && vals[j].w != e->fields[j].v.w) free(vals[j].w);
    free(vals);
  }
  sb_printf(&b, "],\"aborted\":%s,\"abort_seq\":%d,\"stdout\":", aborted ? "true" : "false", abort_seq);
  sb_json_str(&b, text.p, text.n);
  sb_puts(&b, "}");
  free(text.p);
  log_line(&b);
}

/* ---------- dispatch ---------- */

/* An i32 handle result. M1 (cq-mgi): the dispatcher owns out; out->w arrives non-NULL and zeroed with
 * bits, kind and nw preset to the declared return type, and the handler only writes the words. */
static int set_handle(cqe_val *out, int32_t h, const char *sym) {
  if (!out || !out->w || out->nw < 1 || out->bits != 32 || out->kind != 'i') {
    cqe_fail("tape: %s: result buffer is not a preset i32 (M1)", sym);
    return -1;
  }
  out->w[0] = (uint32_t)h;
  return 0;
}

static int tape_dispatch_(const cqe_tname *tn, const cqe_val *a, int n, cqe_val *out) {
  static const char *const mine[] = {"tape_alloc", "tape_fmt", "tape_effect", "tape_write", "tape_write_str",
                                     "abort"};
  int found = 0;
  for (size_t i = 0; i < sizeof mine / sizeof mine[0]; i++) found |= !strcmp(tn->op, mine[i]);
  if (!found) return CQE_OP_NOT_MINE;
  /* C1 (cq-4cy): op is the bare op; w the width token; shape "l" for _lit ("hl" for _hl); pred "ctl" for
   * _controlled; unc for _unc. */
  const char *op = tn->op, *wtok = tn->w;
  int ctl = !strcmp(tn->pred, "ctl"), lit = !strcmp(tn->shape, "l");
  char sym[96];
  snprintf(sym, sizeof sym, "cqrt_%s%s%s%s%s%s", op, wtok[0] ? "_" : "", wtok, lit ? "_lit" : tn->shape[0] ? "_" : "",
           lit ? "" : tn->shape, ctl ? "_controlled" : tn->pred[0] ? "_?" : "");
  /* BACKEND_ABI §1.11 defines no _unc, no _hl and only the forms below for this family. */
  if (tn->unc) { cqe_fail("tape: %s_unc: tape and abort symbols have no _unc", sym); return -1; }
  if (tn->shape[0] && !lit) { cqe_fail("tape: %s: no _%s form in the tape family", sym, tn->shape); return -1; }
  if (tn->pred[0] && !ctl) { cqe_fail("tape: %s: unknown pred \"%s\"", sym, tn->pred); return -1; }
#define FORM(cond) do { if (!(cond)) { cqe_fail("tape: %s: no such form", sym); return -1; } } while (0)
#define ARITY(k) do { if (n != (k)) { cqe_fail("tape: %s: %d arguments, expected %d", sym, n, (k)); return -1; } } while (0)
  if (!strcmp(op, "tape_alloc")) {
    FORM(!ctl && !lit && !wtok[0]);
    ARITY(0);
    return set_handle(out, op_tape_alloc(), sym);
  }
  if (!strcmp(op, "tape_fmt")) {
    FORM(!lit && !wtok[0]);
    ARITY(ctl ? 3 : 2);
    if (ctl) op_entry(E_FMT, 1, arg_i32(&a[0]), arg_i32(&a[1]), arg_ptr(&a[2]), sym);
    else op_entry(E_FMT, 0, -1, arg_i32(&a[0]), arg_ptr(&a[1]), sym);
    return 0;
  }
  if (!strcmp(op, "tape_effect")) {
    FORM(ctl && !lit && !wtok[0]);   /* no uncontrolled form exists */
    ARITY(3);
    op_entry(E_EFFECT, 1, arg_i32(&a[0]), arg_i32(&a[1]), arg_ptr(&a[2]), sym);
    return 0;
  }
  if (!strcmp(op, "tape_write")) {
    FORM(wtok[0] && !(lit && ctl));
    if (lit) {
      ARITY(2);
      op_tape_write_lit(arg_i32(&a[0]), &a[1], wtok, sym);
      return 0;
    }
    ARITY(ctl ? 3 : 2);
    int32_t hp = ctl ? op_tape_write(1, arg_i32(&a[0]), arg_i32(&a[1]), arg_i32(&a[2]), wtok, sym)
                     : op_tape_write(0, -1, arg_i32(&a[0]), arg_i32(&a[1]), wtok, sym);
    if (hp < 0) return -1;
    return set_handle(out, hp, sym);
  }
  if (!strcmp(op, "tape_write_str")) {
    FORM(lit && !ctl && !wtok[0]);
    ARITY(2);
    op_tape_write_str(arg_i32(&a[0]), arg_ptr(&a[1]), sym);
    return 0;
  }
  /* abort */
  FORM(!ctl && !lit && !strcmp(wtok, "i1"));
  ARITY(1);
  op_abort(arg_i32(&a[0]), sym);
  return 0;
#undef ARITY
#undef FORM
}

static int tape_dispatch(const cqe_tname *tn, const cqe_val *a, int n, cqe_val *out) {
  g_failed = 0;
  int rc = tape_dispatch_(tn, a, n, out);
  return rc == 0 && g_failed ? -1 : rc;
}

__attribute__((constructor)) static void rt_tape_register(void) {
  /* C1: a family registers the bare op only. */
  static const char *const keys[] = {"tape_alloc", "tape_fmt", "tape_effect", "tape_write", "tape_write_str", "abort"};
  for (size_t i = 0; i < sizeof keys / sizeof keys[0]; i++) cqe_register_op(keys[i], tape_dispatch);
}
