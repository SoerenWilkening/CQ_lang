/* rt_tape.c: the evaluator semantics of the tape and abort family.
 *
 * Symbols: cqrt_tape_alloc, cqrt_tape_fmt[_controlled], cqrt_tape_effect[_<W>]_controlled,
 * cqrt_tape_write_<W>[_controlled], cqrt_tape_write_<W>_lit, cqrt_abort_i1.
 * Semantics: BACKEND_ABI §1.11, CR rule 16; the host is the stand-in of fx_standin.h (CR §6, ruling Q8):
 * no host call is ever made. §2 has no row for this family.
 *
 *  - All format entries, effect entries and abort flags form ONE event sequence in call order.
 *  - A format entry is opened by tape_fmt and takes the fields its format string consumes. An effect
 *    entry takes the last n fields written to its tape before the call (its argument n; ABI 1.11, rule
 *    16, cq-6ucw), and is complete at its call. Fields past what a format consumes wait for the tape's
 *    next entry: every argument of a printf is a field of its format entry and the excess is ignored as
 *    C ignores it (CR rule 16, C11 7.21.6.1p2; rulings 2 C, cq-kzfv). A next format entry or the end of
 *    the shot gives them to the format entry they follow, and so does an effect entry those fields are
 *    earlier than its last n.
 *  - The predicate is read at the call. A classical-valued c is kept as its bit; any other c is copied
 *    to a fresh kept tape rail of the event, which the end of the shot reads.
 *  - Capture (at completion): the buffers and strings the backend knows by name (fx_standin.h roles, a
 *    format's %s) are read over their extent: a HOST cell as its byte, a QUANTUM cell or a cell at a
 *    quantum address into a fresh kept i8 tape rail. Under a classical c = 0 nothing is read.
 *  - Classification, the table of §1.11, is made in sequence order by advance(): an event is RESOLVED
 *    when it is complete, its predicate, fields and captures are classical, and every earlier event is
 *    resolved with no abort flag reading 1. An event that is not, and every later one, is DEFERRED. An
 *    effect entry not resolved at its call is deferred there (its r is |0>).
 *  - INPUT calls (by name) are performed at the call whatever precedes, unless an identifying argument
 *    is truly quantum (deferred). Stand-in bytes are bus stores, as every write the backend makes for an
 *    effect entry (ABI §1.10; rulings 2 D, cq-ytux): cqe_tape_bus.cstore when everything is classical
 *    (the cell is HOST, a QUANTUM one too), else cqe_tape_bus.qstore over every cell the store can reach.
 *    An INPUT call with a quantum argument or predicate is performed and still not "resolved", so a
 *    later output stays behind it.
 *  - The result rail r of tape_effect_<W>: the stand-in result when performed at the call and the
 *    predicate is 1, else |0>. It is kept (role tape) and classical-valued when everything was.
 *  - An abort flag is kept. End of shot (process exit via return from main or exit(); _Exit loses the
 *    tape): deferred entries are read and those with predicate 1 and no earlier abort reading 1 count
 *    as performed. A format entry is rendered with printf semantics, never printed.
 *
 * Violations (cqe_fail): a field that no entry takes, a tape handle not returned by cqrt_tape_alloc, a
 * predicate or abort flag that is not a live i1 rail, a width token that disagrees with the rail, an _unc
 * of a tape/abort symbol, a tape rail or abort flag gone or changed at the end of the shot, a format that
 * needs a field the entry lacks, an unknown conversion, a form the family does not define. The dispatcher
 * gives tape_write rails role "tape", abort flags role "abort"; rails made here take role tape too.
 *
 * Trace events ("tape" free-form, "abort" frozen as {"ev","f","fv"}):
 *   {"ev":"tape","op":"alloc","t"}
 *   {"ev":"tape","op":"fmt"|"effect","seq","t","c","cv","cq","fmt"|"name"}  c = -1 when uncontrolled; cq: c is
 *                                                                           classical-valued; name null: a host address
 *   {"ev":"tape","op":"write","seq","t","field","c","cv","src","h","w","v"}  seq -1: waits for its entry
 *   {"ev":"tape","op":"write_lit","seq","t","field","w","v"}
 *   {"ev":"abort","f","fv","seq"}
 *   {"ev":"effect", <an entry object below>, "when":"call"|"end"}           one per entry whose predicate read 1
 *        with no earlier abort reading 1: what the C program does at this call. "call" lines precede
 *        "end" lines; "seq" gives the sequence order.
 *   {"ev":"tape","op":"shot","aborted","abort_seq","stdout","deviation",
 *    "events":[{"seq","kind":"abort","f","fv"} | <an entry object>]}        one line at the end of the shot
 * An entry object: "seq","kind":"fmt"|"effect","t","pred","class":"resolved"|"input"|"deferred","performed",
 * "fmt"|"name" (null name: a host address, the first field),"fields":[{"k":"rail","h","w","v"[,"cap"]}|
 * {"k":"lit","w","v"[,"cap"]}], "text" for a format entry (what printf prints for it), "r":{"h","w","v"} for
 * the result form. "cap" is the bytes captured for that field. "deviation" is true when a deferred entry
 * that the program reads the result of would have been performed: rule 16's stated deviation (ruling Q8).
 * Values are hex bit patterns ("0x…"). Strings are bytes, each written as the code point U+0000–U+00FF of
 * the same number.
 *
 * Dispatch (cqe.h M1 and C1): the family registers the bare ops tape_alloc, tape_fmt, tape_effect,
 * tape_write and abort. cqe_tname.w is the width token, shape "l" marks _lit, pred "ctl" marks
 * _controlled (the arity must agree), and args are the raw ABI arguments (a handle as its i32 number, a
 * ptr as a 64-bit 'i' holding the address, a literal in its own type). Return: 0 computed,
 * CQE_OP_NOT_MINE for an op outside the family, -1 after cqe_fail.
 */
#include <dlfcn.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include <mach/mach.h>
#include <mach/mach_vm.h>

#include "cqe.h"
#include "fx_standin.h"
#include "rt_tape.h"

/* core.c's rail attributes (the family path's only use: classical-valuedness and exit roles) */
int cqe__known(int32_t h);
int cqe__trace_all(void); /* core.c (cq-9hzgh): the tape bookkeeping events are not in a compact trace */
void cqe__setrole(int32_t h, int role);
#define ROLE_TAPE 2

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

/* What one field's buffer or string held at capture: b[j] the byte, rail[j] its tape rail or 0 for a
 * HOST byte. */
typedef struct { size_t n; uint8_t *b; int32_t *rail; int done; } capture;

enum { F_RAIL, F_LIT };
typedef struct {
  int k;
  int32_t h, src, c;     /* rail fields: tape rail, source, predicate (-1: none) */
  int cv;
  int known;             /* classical-valued at the write */
  char w[8];
  tval v;                /* rail: value at the call; lit: the literal */
  capture cap;
} field;

enum { E_FMT, E_EFFECT, E_ABORT };
enum { C_NONE, C_RESOLVED, C_INPUT, C_DEFERRED };
typedef struct {
  int k;
  int32_t t, c, f;       /* tape, predicate rail (-1: uncontrolled), abort flag */
  int pred;              /* predicate at the call (entry) or flag value at the call (abort) */
  int pred_known;        /* classical-valued at the call */
  int32_t prail;         /* the event's copy of a c, under a control; else 0 */
  char *str;             /* fmt or effect name, NULL: a null name */
  field *fields;
  int nfields, capfields;
  int need;              /* format entry: the fields its format consumes */
  int complete;
  int reads_quantum;     /* a capture took a tape rail */
  int cls;
  int behind_abort;      /* an earlier abort flag read 1 */
  int performed;         /* the entry was performed at the call (or, at the shot, will be) */
  int32_t r;             /* the result rail, 0: bare form */
  char rw[8];
} event;

typedef struct { field *f; int n, cap; } pendlist;

static event *g_ev;
static int g_nev, g_capev;
static int *g_tape_open;          /* per tape: index of its last format entry in g_ev while it takes fields, or -1 */
static int *g_tape_last;          /* per tape: index of its last entry, or -1 */
static pendlist *g_tape_pend;     /* per tape: fields no entry has taken yet */
static int g_ntapes, g_captapes;
static int g_registered_exit;
static int g_front;               /* the first event advance() has not resolved */
static int g_blocked;             /* an event was deferred or an abort read 1: nothing later resolves */
static int g_abort_seen;

static const cqe_tape_bus *g_bus;
void cqe_tape_set_bus(const cqe_tape_bus *bus) { g_bus = bus; }

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
  e->behind_abort = g_abort_seen;
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

/* A fresh kept tape rail holding the low bits of the words (fp as its pattern). */
static int32_t new_tape_rail(const char *w, const tval *v, int known) {
  cqe_val init = {v->bits, v->kind, v->nw, v->w};
  int32_t h = cqe_new_rail(w, &init, known);
  cqe__setrole(h, ROLE_TAPE);
  return h;
}

/* ---------- format strings ---------- */

typedef struct {
  char flags[16], width[16], prec[16];
  int wstar, pstar, has_prec;
  char len[3];
  char conv;              /* 0: not a defined conversion */
  const char *start, *end;
} conv_t;

/* The next conversion at or after p (literal text and %% go to lit, if any). NULL at the end of the string. */
static const char *next_conv(const char *p, sbuf *lit, conv_t *c) {
  while (*p) {
    if (*p != '%') { if (lit) sb_put(lit, p, 1); p++; continue; }
    if (p[1] == '%') { if (lit) sb_put(lit, "%", 1); p += 2; continue; }
    memset(c, 0, sizeof *c);
    c->start = p++;
    size_t n = 0;
    while (*p && strchr("-+ #0'", *p)) { if (n + 1 < sizeof c->flags) c->flags[n++] = *p; p++; }
    if (*p == '*') { c->wstar = 1; p++; }
    else { n = 0; while (*p >= '0' && *p <= '9') { if (n + 1 < sizeof c->width) c->width[n++] = *p; p++; } }
    if (*p == '.') {
      c->has_prec = 1;
      p++;
      if (*p == '*') { c->pstar = 1; p++; }
      else { n = 0; while (*p >= '0' && *p <= '9') { if (n + 1 < sizeof c->prec) c->prec[n++] = *p; p++; } }
    }
    if (*p == 'h' || *p == 'l') {
      c->len[0] = *p++;
      if (*p == c->len[0]) c->len[1] = *p++;
    } else if (*p && strchr("jztLq", *p)) {
      c->len[0] = *p++;
    }
    char x = *p ? *p++ : 0;
    c->conv = x && strchr("diuoxXcspfFeEgGaAn", x) ? x : 0;
    c->end = p;
    return p;
  }
  return NULL;
}

static int fields_consumed(const char *fmt) {
  conv_t c;
  int n = 0;
  for (const char *p = fmt; (p = next_conv(p, NULL, &c)) != NULL;) n += c.wstar + c.pstar + 1;
  return n;
}

/* ---------- memory the entries read and write ---------- */

/* Without a bus every cell is HOST: its value is the host byte, read guarded. */
static int host_peek(uint64_t addr, uint8_t *byte) {
  mach_vm_size_t got = 0;
  *byte = 0;
  if (mach_vm_read_overwrite(mach_task_self(), (mach_vm_address_t)addr, 1, (mach_vm_address_t)(uintptr_t)byte, &got) !=
      KERN_SUCCESS || got != 1)
    *byte = 0;
  return 0;
}
static int peek(uint64_t addr, uint8_t *byte) { return g_bus ? g_bus->peek(addr, byte) : host_peek(addr, byte); }

static uint64_t field_low64(const field *f) { return f->v.w[0]; }

#define CAP_MAX (UINT64_C(1) << 24)

/* Reads the extent into f->cap under the event's predicate. len < 0: a NUL-terminated string. */
static void capture_field(event *e, field *f, int64_t len) {
  if (f->cap.done || (e->pred_known && !e->pred)) return;
  if (len >= 0 && (uint64_t)len > CAP_MAX) {
    cqe_fail("tape: entry %d: a buffer of %lld bytes is more than the evaluator captures", (int)(e - g_ev), (long long)len);
    return;
  }
  f->cap.done = 1;
  uint64_t addr = field_low64(f);
  size_t limit = len >= 0 ? (size_t)len : CQ_FX_K2;
  f->cap.b = malloc(limit ? limit : 1);
  f->cap.rail = calloc(limit ? limit : 1, sizeof(int32_t));
  for (size_t j = 0; j < limit; j++) {
    uint8_t byte = 0;
    int q = peek(addr + j, &byte) || !f->known;
    if (len < 0 && !q && byte == 0) break;          /* the first HOST 0 */
    if (len < 0 && !f->known && byte == 0) break;   /* a quantum address: the string this sample reaches */
    if (q) {
      uint64_t word = e->pred ? byte : 0;
      tval tv = {8, 'i', 1, &word};
      f->cap.rail[j] = new_tape_rail("i8", &tv, 0);
      byte = (uint8_t)word;
      e->reads_quantum = 1;
    }
    f->cap.b[j] = byte;
    f->cap.n = j + 1;
  }
}

/* The product of the length fields from field i on, capped at K2 when one of them is a rail. */
static int64_t length_of(const event *e, const char *roles, int i, int *lknown) {
  uint64_t v = 1;
  int known = 1;
  for (int j = i; roles[j] == 'n' && j < e->nfields; j++) {
    const field *f = &e->fields[j];
    uint64_t x = field_low64(f);
    if (f->v.bits < 64) {
      x &= (UINT64_C(1) << f->v.bits) - 1;
      if ((x >> (f->v.bits - 1)) & 1) x = 0;    /* a negative int length: nothing */
    }
    if (x && v > UINT64_MAX / x) v = UINT64_MAX;
    else v *= x;
    known &= f->known;
  }
  if (lknown) *lknown = known;
  if (!known && v > CQ_FX_K2) v = CQ_FX_K2;
  return v > (uint64_t)INT64_MAX ? INT64_MAX : (int64_t)v;
}

/* A format's %s fields, from field index first on. */
static void capture_format(event *e, const char *fmt, int first) {
  conv_t c;
  int next = first;
  for (const char *p = fmt; (p = next_conv(p, NULL, &c)) != NULL;) {
    next += c.wstar + c.pstar;
    if (c.conv == 's' && next < e->nfields) capture_field(e, &e->fields[next], -1);
    next++;
  }
}

static void capture_event(event *e) {
  if (e->k == E_FMT) { capture_format(e, e->str, 0); return; }
  const cq_fx_ent *ent = cq_fx_find(e->str);
  if (!ent) return;
  for (int i = 0; ent->roles[i] && i < e->nfields; i++) {
    char role = ent->roles[i];
    if (role == 's' || role == 'p') capture_field(e, &e->fields[i], -1);
    else if (role == 'B') capture_field(e, &e->fields[i], length_of(e, ent->roles, i + 1, NULL));
    else if (role == 'F') {
      field *f = &e->fields[i];
      capture_field(e, f, -1);
      if (f->cap.done) {
        char *fmt = calloc(f->cap.n + 1, 1);
        memcpy(fmt, f->cap.b, f->cap.n);
        capture_format(e, fmt, i + 1);
        free(fmt);
      }
    }
  }
}

/* ---------- the host, by the stand-in ---------- */

static int fields_known(const event *e) {
  for (int i = 0; i < e->nfields; i++)
    if (e->fields[i].k == F_RAIL && !e->fields[i].known) return 0;
  return 1;
}

/* The stand-in's hash over this entry's fields. */
static uint64_t entry_hash(const event *e, const cq_fx_ent *ent) {
  uint64_t h = cq_fx_begin(e->str);
  for (int i = 0; i < e->nfields; i++) {
    const field *f = &e->fields[i];
    h = cq_fx_arg(h, ent, i, f->v.bits, f->v.w, (int)f->v.nw);
  }
  return h;
}

/* The result rail's value: words of width w from the low 64-bit value x. */
static tval result_value(const char *w, uint64_t x) {
  uint32_t bits = (uint32_t)strtoul(w + 1, NULL, 10);
  tval v = tv_zero(bits ? bits : 1, w[0] == 'f' ? 'f' : 'i');
  v.w[0] = x;
  if (v.bits < 64) v.w[0] &= (UINT64_C(1) << v.bits) - 1;
  return v;
}

static void set_result(event *e, uint64_t x, int known) {
  if (!e->rw[0]) return;
  tval v = result_value(e->rw, x);
  e->r = new_tape_rail(e->rw, &v, known);
  free(v.w);
}

/* Performs an INPUT call now (the four INPUT rows of §1.11). */
static void perform_input(event *e, const cq_fx_ent *ent) {
  int bi = -1, li = -1;
  for (int i = 0; ent->roles[i]; i++) {
    if (ent->roles[i] == 'W') bi = i;
    if (ent->roles[i] == 'n' && li < 0) li = i;
  }
  int nknown = 1;
  int64_t v = 0;
  if (bi >= 0 && li >= 0 && li < e->nfields) v = length_of(e, ent->roles, li, &nknown);
  uint64_t addr = bi >= 0 && bi < e->nfields ? field_low64(&e->fields[bi]) : 0;
  int classical = e->pred_known && fields_known(e);
  int cv = e->pred;
  uint64_t h = entry_hash(e, ent);
  size_t stored = 0, reach = 0;                       /* the bytes stored for v; the cells the store can reach */
  if (bi >= 0) {
    stored = cq_fx_input_stored(ent, (uint64_t)v);
    reach = nknown ? stored : cq_fx_input_reach(ent);
  }
  if (!(e->pred_known && !cv)) {                      /* classical predicate 0: skipped, nothing is touched */
    for (size_t j = 0; j < reach; j++) {
      int write = j < stored && cv;
      uint8_t byte = write ? cq_fx_input_byte(ent, h, j, stored) : 0;
      if (classical && !write) continue;
      if (!g_bus) { cqe_fail("tape: %s: a bus store with no bus linked", e->str); return; }
      if (classical) g_bus->cstore(addr + j, byte);
      else g_bus->qstore(addr + j, byte, write);
    }
  }
  uint64_t r = cv ? cq_fx_input_result(ent, h, addr, (uint64_t)v, bi >= 0 && li + 1 < e->nfields && ent->roles[li + 1] == 'n'
                                                                       ? field_low64(&e->fields[li]) : 1) : 0;
  set_result(e, r, classical);
  e->cls = C_INPUT;
  e->performed = !(e->pred_known && !cv);
}

/* ---------- classification ---------- */

static void entry_json(sbuf *b, const event *e, const char *when);
static void effect_line(const event *e, const char *when) {
  if (!e->pred || e->behind_abort) return;
  sbuf b = {0};
  sb_puts(&b, "{\"ev\":\"effect\",");
  entry_json(&b, e, when);
  sb_puts(&b, "}");
  log_line(&b);
}

/* Resolves events in sequence order as far as they go. */
static void advance(void) {
  while (!g_blocked && g_front < g_nev) {
    event *e = &g_ev[g_front];
    if (e->k == E_ABORT) {
      if (!e->pred_known || e->pred) { g_blocked = 1; if (e->pred_known) { e->cls = C_RESOLVED; g_front++; } return; }
      e->cls = C_RESOLVED;
      g_front++;
      continue;
    }
    if (e->cls == C_DEFERRED) { g_blocked = 1; return; }
    if (!e->complete) return;
    if (!(e->pred_known && fields_known(e) && !e->reads_quantum)) {
      if (e->cls == C_NONE) e->cls = C_DEFERRED;
      g_blocked = 1;
      return;
    }
    if (e->cls == C_NONE) {                            /* an all-classical INPUT call took C_INPUT at its call */
      e->cls = C_RESOLVED;
      e->performed = e->pred;
      if (e->k == E_EFFECT)
        set_result(e, e->pred ? cq_fx_result(entry_hash(e, cq_fx_find(e->str)), (unsigned)strtoul(e->rw[0] ? e->rw + 1 : "0", NULL, 10)) : 0, 1);
      effect_line(e, "call");
    }
    g_front++;
  }
}

/* Past g_blocked a format entry is deferred when it completes. */
static void entry_complete(event *e) {
  e->complete = 1;
  capture_event(e);
  advance();
  if (e->cls == C_NONE && g_blocked) e->cls = C_DEFERRED;
}

/* ---------- operations ---------- */

static int32_t op_tape_alloc(void) {
  ensure_exit();
  if (g_ntapes == g_captapes) {
    g_captapes = g_captapes ? 2 * g_captapes : 8;
    g_tape_open = realloc(g_tape_open, (size_t)g_captapes * sizeof(int));
    g_tape_last = realloc(g_tape_last, (size_t)g_captapes * sizeof(int));
    g_tape_pend = realloc(g_tape_pend, (size_t)g_captapes * sizeof(pendlist));
  }
  g_tape_open[g_ntapes] = -1;
  g_tape_last[g_ntapes] = -1;
  memset(&g_tape_pend[g_ntapes], 0, sizeof(pendlist));
  int32_t t = TAPE_BASE + g_ntapes++;
  if (cqe__trace_all()) {
    sbuf b = {0};
    sb_printf(&b, "{\"ev\":\"tape\",\"op\":\"alloc\",\"t\":%d}", (int)t);
    log_line(&b);
  }
  return t;
}

static field *event_field_slot(event *e) {
  if (e->nfields == e->capfields) {
    e->capfields = e->capfields ? 2 * e->capfields : 4;
    e->fields = realloc(e->fields, (size_t)e->capfields * sizeof(field));
  }
  return &e->fields[e->nfields++];
}

/* Fields that waited on the tape go to e (an effect entry, or the format entry they follow). */
static void take_pending(int ti, event *e) {
  pendlist *p = &g_tape_pend[ti];
  for (int i = 0; i < p->n; i++) *event_field_slot(e) = p->f[i];
  p->n = 0;
}

/* The fields waiting on tape ti before an effect entry of n fields: its last n stay for it. The earlier ones are the
 * excess of the format entry that was the tape's last, which ignores them (rulings 2 C, cq-kzfv); no entry takes them
 * behind anything else. */
static void split_effect_fields(int ti, int n, const char *sym) {
  pendlist *p = &g_tape_pend[ti];
  if (n < 0 || n > p->n) {
    cqe_fail("tape: %s: an effect entry of %d fields, %d written", sym, n, p->n);
    return;
  }
  int excess = p->n - n;
  if (!excess) return;
  if (g_tape_last[ti] < 0 || g_ev[g_tape_last[ti]].k != E_FMT) {
    cqe_fail("tape: %s: %d fields on the tape that no entry takes", sym, excess);
  } else {
    event *fmt = &g_ev[g_tape_last[ti]];
    for (int i = 0; i < excess; i++) *event_field_slot(fmt) = p->f[i];
  }
  memmove(p->f, p->f + excess, (size_t)n * sizeof *p->f);
  p->n = n;
}

/* The event's copy of its predicate, read at the call. */
static void capture_pred(event *e, int ctl, int32_t c, const char *sym) {
  e->c = ctl ? c : -1;
  e->pred = 1;
  e->pred_known = 1;
  if (!ctl) return;
  int pv = read_i1(c, sym, "predicate");
  if (pv < 0) { e->pred = 0; return; }
  e->pred = pv;
  e->pred_known = cqe__known(c) != 0;
  /* always, a known c included: a rail's known-ness is per sample (and_i1 under a 0 leaves its seed known), and the
   * rails a shot allocates must not vary with the quantum inputs (cq-ytx8) */
  uint64_t word = (uint64_t)pv;
  tval tv = {1, 'i', 1, &word};
  e->prail = new_tape_rail("i1", &tv, 0);
}

static void entry_log(const event *e, int seq) {
  if (!cqe__trace_all())
    return;
  sbuf b = {0};
  sb_printf(&b, "{\"ev\":\"tape\",\"op\":\"%s\",\"seq\":%d,\"t\":%d,\"c\":%d,\"cv\":%d,\"cq\":%d,\"%s\":",
            e->k == E_FMT ? "fmt" : "effect", seq, (int)e->t, (int)e->c, e->pred, e->pred_known,
            e->k == E_FMT ? "fmt" : "name");
  if (e->str) sb_json_str(&b, e->str, strlen(e->str));
  else sb_puts(&b, "null");
  sb_puts(&b, "}");
  log_line(&b);
}

static void op_tape_fmt(int ctl, int32_t c, int32_t t, const char *s, const char *sym) {
  ensure_exit();
  int ti = tape_index(t, sym);
  if (!s) { cqe_fail("tape: %s: null string", sym); s = ""; }
  /* fields past the previous format's conversions are that entry's */
  if (ti >= 0 && g_tape_pend[ti].n) {
    if (g_tape_last[ti] >= 0 && g_ev[g_tape_last[ti]].k == E_FMT) take_pending(ti, &g_ev[g_tape_last[ti]]);
    else cqe_fail("tape: %s: %d fields on tape %d with no open entry", sym, g_tape_pend[ti].n, (int)t);
  }
  event *e = new_event(E_FMT);
  e->t = t;
  capture_pred(e, ctl, c, sym);
  e->str = dupstr(s);
  e->need = fields_consumed(s);
  if (ti >= 0) {
    g_tape_open[ti] = e->need ? g_nev - 1 : -1;
    g_tape_last[ti] = g_nev - 1;
  }
  entry_log(e, g_nev - 1);
  if (!e->need) entry_complete(e);
}

/* §6's stand-in is a function of the name: a null name's host address (rule 19, its first field) is named by the driver's
 * wrapper rows (drivers.effect_wrappers_ir), or, for a function the host really has, by the host's own symbol table. An
 * address neither knows stays a null name. */
__attribute__((weak)) const void *const cqd_fx_addr_rows[][2] = {{0, 0}};
static const char *host_address_name(uint64_t a) {
  for (int i = 0; cqd_fx_addr_rows[i][0]; i++)
    if ((uint64_t)(uintptr_t)cqd_fx_addr_rows[i][0] == a) return (const char *)cqd_fx_addr_rows[i][1];
  Dl_info info;
  if (a && dladdr((const void *)(uintptr_t)a, &info) && info.dli_sname && (uint64_t)(uintptr_t)info.dli_saddr == a)
    return info.dli_sname;
  return NULL;
}

/* Returns the result rail, or 0 for the bare form. */
static int32_t op_tape_effect(int32_t c, int32_t t, const char *name, int32_t n, const char *rw, const char *sym) {
  ensure_exit();
  int ti = tape_index(t, sym);
  event *e = new_event(E_EFFECT);
  e->t = t;
  int seq = g_nev - 1;
  capture_pred(e, 1, c, sym);
  e->str = name ? dupstr(name) : NULL;
  snprintf(e->rw, sizeof e->rw, "%s", rw ? rw : "");
  const cq_fx_ent *ent = cq_fx_find(name);
  if (ti >= 0) {
    if (g_tape_open[ti] >= 0) {
      cqe_fail("tape: %s: format entry %d on tape %d still lacks fields", sym, g_tape_open[ti], (int)t);
      g_tape_open[ti] = -1;
    }
    split_effect_fields(ti, n, sym);
    take_pending(ti, e);
    g_tape_last[ti] = seq;
  }
  if (!name && e->nfields == 0) cqe_fail("tape: %s: a null name with no host address field", sym);
  if (!name && e->nfields && (name = host_address_name(e->fields[0].v.w[0]))) {
    e->str = dupstr(name);
    ent = cq_fx_find(name);
    e->nfields--;
    memmove(e->fields, e->fields + 1, (size_t)e->nfields * sizeof *e->fields);
  }
  entry_log(e, seq);
  if (ent && e->nfields < (int)strlen(ent->roles))
    cqe_fail("tape: %s: %s has %d fields, its arguments are %d", sym, name, e->nfields, (int)strlen(ent->roles));
  e->complete = 1;
  capture_event(e);
  int ident_quantum = 0;
  if (ent)
    for (int i = 0; ent->roles[i] && i < e->nfields; i++)
      if (ent->roles[i] == 'f' && e->fields[i].k == F_RAIL && !e->fields[i].known) ident_quantum = 1;
  if (ent && ent->cls == 'I' && !ident_quantum) {
    perform_input(e, ent);
    effect_line(e, "call");
    advance();
    return e->r;
  }
  advance();
  if (e->cls != C_RESOLVED) {
    e->cls = C_DEFERRED;
    g_blocked = 1;
    set_result(e, 0, 1);
  }
  return e->r;
}

/* The tape's next field: of its open format entry, or waiting for the next entry. */
static field *new_field(int32_t t, const char *sym, int *seq, int *fi) {
  int ti = tape_index(t, sym);
  if (ti < 0) return NULL;
  if (g_tape_open[ti] >= 0) {
    event *e = &g_ev[g_tape_open[ti]];
    field *f = event_field_slot(e);
    memset(f, 0, sizeof *f);
    f->h = f->src = f->c = -1;
    *seq = g_tape_open[ti];
    *fi = e->nfields - 1;
    return f;
  }
  pendlist *p = &g_tape_pend[ti];
  if (p->n == p->cap) {
    p->cap = p->cap ? 2 * p->cap : 4;
    p->f = realloc(p->f, (size_t)p->cap * sizeof(field));
  }
  field *f = &p->f[p->n];
  memset(f, 0, sizeof *f);
  f->h = f->src = f->c = -1;
  *seq = -1;
  *fi = p->n++;
  return f;
}

/* A format entry that has every field it consumes is complete. */
static void field_done(int32_t t) {
  int ti = (int)((int64_t)t - TAPE_BASE);
  if (g_tape_open[ti] < 0) return;
  event *e = &g_ev[g_tape_open[ti]];
  if (e->nfields < e->need) return;
  g_tape_open[ti] = -1;
  entry_complete(e);
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
  int cv = 1, known = cqe__known(h) != 0;
  if (!ctl) c = -1;
  else {
    cv = read_i1(c, sym, "predicate");
    if (cv < 0) cv = 0;
    else known = known && cqe__known(c);
  }
  if (!cv) { free(v.w); v = tv_zero(src->bits, src->kind); }
  cqe_val init = {v.bits, v.kind, v.nw, v.w};
  int32_t hp = cqe_new_rail(w, &init, known);
  int seq = -1, fi = -1;
  field *f = new_field(t, sym, &seq, &fi);
  if (cqe__trace_all()) {
    sbuf b = {0};
    sb_printf(&b, "{\"ev\":\"tape\",\"op\":\"write\",\"seq\":%d,\"t\":%d,\"field\":%d,\"c\":%d,\"cv\":%d,"
                  "\"src\":%d,\"h\":%d,\"w\":\"%s\",\"v\":",
              seq, (int)t, fi, (int)c, cv, (int)h, (int)hp, w);
    sb_hex(&b, &v);
    sb_puts(&b, "}");
    log_line(&b);
  }
  if (f) {
    f->k = F_RAIL; f->h = hp; f->src = h; f->c = c; f->cv = cv; f->known = known; f->v = v;
    memcpy(f->w, w, 8);
    field_done(t);
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
  if (cqe__trace_all()) {
    sbuf b = {0};
    sb_printf(&b, "{\"ev\":\"tape\",\"op\":\"write_lit\",\"seq\":%d,\"t\":%d,\"field\":%d,\"w\":\"%s\",\"v\":",
              seq, (int)t, fi, w);
    sb_hex(&b, &v);
    sb_puts(&b, "}");
    log_line(&b);
  }
  if (f) {
    f->k = F_LIT; f->known = 1; f->v = v; memcpy(f->w, w, 8);
    field_done(t);
  } else {
    free(v.w);
  }
}

static void op_abort(int32_t fh, const char *sym) {
  ensure_exit();
  int fv = read_i1(fh, sym, "abort flag");
  event *e = new_event(E_ABORT);
  e->f = fh;
  e->pred = fv < 0 ? 0 : fv;
  e->pred_known = fv < 0 ? 1 : cqe__known(fh) != 0;
  e->complete = 1;
  if (e->pred) g_abort_seen = 1;
  if (cqe__trace_all()) {
    sbuf b = {0};
    sb_printf(&b, "{\"ev\":\"abort\",\"f\":%d,\"fv\":\"0x%d\",\"seq\":%d}", (int)fh, e->pred, g_nev - 1);
    log_line(&b);
  }
  advance();
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
 * an fp field is converted to double, or to long double under L; %s prints the captured bytes up to the
 * first 0; %n consumes its field and prints nothing (CR rule 16: the program's %n is the lifted snprintf).
 * Returns 0 after a violation. */
static int format_entry(const event *e, sbuf *out) {
  const char *p = e->str;
  int next = 0, idx = (int)(e - g_ev);
  conv_t c;
  while ((p = next_conv(p, out, &c)) != NULL) {
    if (!c.conv) {
      cqe_fail("tape: entry %d: format \"%s\": conversion \"%.*s\" has no defined meaning", idx, e->str,
               (int)(c.end - c.start), c.start);
      return 0;
    }
    if (next + c.wstar + c.pstar >= e->nfields) {
      cqe_fail("tape: entry %d: format \"%s\" needs more fields than the entry has (%d)", idx, e->str, e->nfields);
      return 0;
    }
    char spec[96], num[32];
    snprintf(spec, sizeof spec, "%%%s", c.flags);
    if (c.wstar) { snprintf(num, sizeof num, "%d", (int)(uint32_t)low64(&e->fields[next++].v)); strlcat(spec, num, sizeof spec); }
    else strlcat(spec, c.width, sizeof spec);
    if (c.has_prec) {
      strlcat(spec, ".", sizeof spec);
      if (c.pstar) { snprintf(num, sizeof num, "%d", (int)(uint32_t)low64(&e->fields[next++].v)); strlcat(spec, num, sizeof spec); }
      else strlcat(spec, c.prec, sizeof spec);
    }
    const field *f = &e->fields[next++];
    const tval *v = &f->v;
    char conv = c.conv;
    const char *len = c.len;
    char full[112];
    if (conv == 'n') continue;
    if (conv == 's') {
      if (len[0] == 'l') {
        cqe_fail("tape: entry %d: %%ls on a tape entry", idx);
        return 0;
      }
      char *text = calloc(f->cap.n + 1, 1);
      if (f->cap.n) memcpy(text, f->cap.b, f->cap.n);
      snprintf(full, sizeof full, "%ss", spec);
      sb_printf(out, full, text);
      free(text);
      continue;
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
  return 1;
}

/* ---------- the entry object ---------- */

static void entry_json(sbuf *b, const event *e, const char *when) {
  static const char *const cls[] = {"none", "resolved", "input", "deferred"};
  sb_printf(b, "\"seq\":%d,\"kind\":\"%s\",\"t\":%d,\"pred\":%d,\"class\":\"%s\",\"performed\":%s,", (int)(e - g_ev),
            e->k == E_FMT ? "fmt" : "effect", (int)e->t, e->pred, cls[e->cls], e->performed ? "true" : "false");
  if (when) sb_printf(b, "\"when\":\"%s\",", when);
  sb_printf(b, "\"%s\":", e->k == E_FMT ? "fmt" : "name");
  if (e->str) sb_json_str(b, e->str, strlen(e->str));
  else sb_puts(b, "null");
  sb_puts(b, ",\"fields\":[");
  for (int j = 0; j < e->nfields; j++) {
    const field *f = &e->fields[j];
    if (j) sb_puts(b, ",");
    if (f->k == F_RAIL) sb_printf(b, "{\"k\":\"rail\",\"h\":%d,\"w\":\"%s\",\"v\":", (int)f->h, f->w);
    else sb_printf(b, "{\"k\":\"lit\",\"w\":\"%s\",\"v\":", f->w);
    sb_hex(b, &f->v);
    if (f->cap.done) { sb_puts(b, ",\"cap\":"); sb_json_str(b, (const char *)f->cap.b, f->cap.n); }
    sb_puts(b, "}");
  }
  sb_puts(b, "]");
  if (e->k == E_FMT) {
    sbuf t = {0};
    sb_reserve(&t, 0);
    format_entry(e, &t);
    sb_puts(b, ",\"text\":");
    sb_json_str(b, t.p, t.n);
    free(t.p);
  }
  if (e->r) {
    const cqe_val *v = cqe_rail(e->r);
    sb_printf(b, ",\"r\":{\"h\":%d,\"w\":\"%s\",\"v\":", (int)e->r, e->rw);
    if (v) { tval tv = tv_copy(v); sb_hex(b, &tv); free(tv.w); }
    else sb_puts(b, "null");
    sb_puts(b, "}");
  }
}

/* ---------- end of shot ---------- */

/* Every kept rail of the entry still holds what it held at the call. */
static void check_rails(const event *e, int i) {
  for (int j = 0; j < e->nfields; j++) {
    const field *f = &e->fields[j];
    if (f->k == F_RAIL) {
      const cqe_val *v = cqe_rail(f->h);
      if (!v) cqe_fail("tape: tape rail %d (event %d field %d) is gone at the end of the shot", (int)f->h, i, j);
      else if (!tv_eq(&f->v, v)) cqe_fail("tape: tape rail %d (event %d field %d) changed after its write", (int)f->h, i, j);
    }
    for (size_t x = 0; x < f->cap.n; x++) {
      if (!f->cap.rail[x]) continue;
      const cqe_val *v = cqe_rail(f->cap.rail[x]);
      if (!v) cqe_fail("tape: capture rail %d (event %d field %d) is gone at the end of the shot", (int)f->cap.rail[x], i, j);
      else if ((uint8_t)v->w[0] != f->cap.b[x]) cqe_fail("tape: capture rail %d (event %d field %d) changed", (int)f->cap.rail[x], i, j);
    }
  }
  if (e->prail) {
    const cqe_val *v = cqe_rail(e->prail);
    if (!v) cqe_fail("tape: the predicate rail %d of event %d is gone at the end of the shot", (int)e->prail, i);
    else if ((int)(v->w[0] & 1) != e->pred) cqe_fail("tape: the predicate rail %d of event %d changed", (int)e->prail, i);
  }
}

static void shot(void) {
  sbuf b = {0}, text = {0};
  sb_reserve(&text, 0);
  int aborted = 0, abort_seq = -1, deviation = 0;
  for (int ti = 0; ti < g_ntapes; ti++) {
    if (!g_tape_pend[ti].n) continue;
    if (g_tape_last[ti] >= 0 && g_ev[g_tape_last[ti]].k == E_FMT) take_pending(ti, &g_ev[g_tape_last[ti]]);
    else {
      cqe_fail("tape: %d fields on tape %d with no open entry at the end of the shot", g_tape_pend[ti].n, (int)(TAPE_BASE + ti));
      g_tape_pend[ti].n = 0;
    }
  }
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
    check_rails(e, i);
    if (e->cls == C_NONE || e->cls == C_DEFERRED) {
      e->cls = C_DEFERRED;
      e->performed = e->pred && !aborted;
      if (e->performed) {
        effect_line(e, "end");
        if (e->r) deviation = 1;
      }
    }
    sb_puts(&b, "{");
    entry_json(&b, e, NULL);
    sb_puts(&b, "}");
    if (e->k == E_FMT && e->pred && !aborted) {
      sbuf t = {0};
      sb_reserve(&t, 0);
      format_entry(e, &t);
      sb_put(&text, t.p, t.n);
      free(t.p);
    }
  }
  sb_printf(&b, "],\"aborted\":%s,\"abort_seq\":%d,\"deviation\":%s,\"stdout\":", aborted ? "true" : "false", abort_seq,
            deviation ? "true" : "false");
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
  static const char *const mine[] = {"tape_alloc", "tape_fmt", "tape_effect", "tape_write", "abort"};
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
    if (ctl) op_tape_fmt(1, arg_i32(&a[0]), arg_i32(&a[1]), arg_ptr(&a[2]), sym);
    else op_tape_fmt(0, -1, arg_i32(&a[0]), arg_ptr(&a[1]), sym);
    return 0;
  }
  if (!strcmp(op, "tape_effect")) {
    FORM(ctl && !lit);   /* no uncontrolled form exists */
    ARITY(4);
    int32_t r = op_tape_effect(arg_i32(&a[0]), arg_i32(&a[1]), arg_ptr(&a[2]), arg_i32(&a[3]), wtok, sym);
    if (!wtok[0]) return 0;
    return set_handle(out, r, sym);
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
  static const char *const keys[] = {"tape_alloc", "tape_fmt", "tape_effect", "tape_write", "abort"};
  for (size_t i = 0; i < sizeof keys / sizeof keys[0]; i++) cqe_register_op(keys[i], tape_dispatch);
}
