/* Semantic scenarios of the tape and abort family, one per process (the end of the shot is process
 * exit). run_tests.py runs each and checks its trace. Usage: scenarios <name>. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "fake_core.h"
#include "rt_tape.h"

#define H fake_h
#define P fake_p

static int32_t alloc(void) { return fake_call("cqrt_tape_alloc", 0); }
static void fmt(int32_t t, const char *f) { fake_call("cqrt_tape_fmt", 2, H(t), P(f)); }
static void fmtc(int32_t c, int32_t t, const char *f) { fake_call("cqrt_tape_fmt_controlled", 3, H(c), H(t), P(f)); }
static char nm[64];
static const char *sy(const char *a, const char *w, const char *b) { snprintf(nm, sizeof nm, "%s%s%s", a, w, b); return nm; }
static int32_t wr(const char *w, int32_t t, int32_t h) { return fake_call(sy("cqrt_tape_write_", w, ""), 2, H(t), H(h)); }
static int32_t wrc(const char *w, int32_t c, int32_t t, int32_t h) {
  return fake_call(sy("cqrt_tape_write_", w, "_controlled"), 3, H(c), H(t), H(h));
}
static void lit(const char *w, int32_t t, cqe_val v) { fake_call(sy("cqrt_tape_write_", w, "_lit"), 2, H(t), v); }
static void str(int32_t t, const char *s) { fake_call("cqrt_tape_write_i64_lit", 2, H(t), P(s)); }
static void ab(int32_t f) { fake_call("cqrt_abort_i1", 1, H(f)); }
static int32_t i1(int b) { return fake_rail("i1", fake_i(1, (uint64_t)b, 0)); }
static int32_t i32(uint32_t x) { return fake_rail("i32", fake_i(32, x, 0)); }
static int32_t q1(int b) { return fake_qrail("i1", fake_i(1, (uint64_t)b, 0)); }
static int32_t q32(uint32_t x) { return fake_qrail("i32", fake_i(32, x, 0)); }
static int32_t q64p(const void *p) { return fake_qrail("i64", fake_p(p)); }
static int32_t r64p(const void *p) { return fake_rail("i64", fake_p(p)); }
static void eff(int32_t c, int32_t t, const char *name) { fake_call("cqrt_tape_effect_controlled", 3, H(c), H(t), P(name)); }
static int32_t eff32(int32_t c, int32_t t, const char *name) {
  return fake_call("cqrt_tape_effect_i32_controlled", 3, H(c), H(t), P(name));
}
static int32_t eff64(int32_t c, int32_t t, const char *name) {
  return fake_call("cqrt_tape_effect_i64_controlled", 3, H(c), H(t), P(name));
}
static void li32(int32_t t, uint32_t x) { lit("i32", t, fake_i(32, x, 0)); }
static void li64(int32_t t, uint64_t x) { lit("i64", t, fake_i(64, x, 0)); }

/* A test double of the bus hook: QUANTUM cells in a table, every other cell HOST. */
static struct { uint64_t a; uint8_t b; } cells[64];
static int ncells;
static int td_find(uint64_t a) {
  for (int i = 0; i < ncells; i++) if (cells[i].a == a) return i;
  return -1;
}
static int td_peek(uint64_t a, uint8_t *b) {
  int i = td_find(a);
  if (i >= 0) { *b = cells[i].b; return 1; }
  *b = *(const uint8_t *)(uintptr_t)a;
  return 0;
}
static void td_qstore(uint64_t a, uint8_t b, int write) {
  int i = td_find(a);
  if (i < 0) { i = ncells++; cells[i].a = a; cells[i].b = *(const uint8_t *)(uintptr_t)a; }
  if (write) cells[i].b = b;
  char l[128];
  snprintf(l, sizeof l, "{\"ev\":\"qstore\",\"off\":%llu,\"b\":%d,\"write\":%d}", (unsigned long long)(a & 0xfff), b, write);
  cqe_log(l);
}
static void td_set(const void *p, uint8_t b) { int i = ncells++; cells[i].a = (uint64_t)(uintptr_t)p; cells[i].b = b; }
static const cqe_tape_bus td_bus = {td_peek, td_qstore};
int __cqe_fx_remove(const char *);
int __cqe_fx_raise(int);

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  const char *s = argv[1];
  if (!strcmp(s, "pred")) {                 /* entries under predicate 0 and 1 */
    int32_t t = alloc();
    fmtc(i1(0), t, "zero %d\n"); wrc("i32", i1(0), t, i32(5));
    fmtc(i1(1), t, "one %d\n");  wrc("i32", i1(1), t, i32(6));
    fmt(t, "plain\n");
  } else if (!strcmp(s, "abort")) {         /* an abort reading 1 stops every later entry */
    int32_t t = alloc();
    fmt(t, "a\n"); ab(i1(0)); fmt(t, "b\n"); ab(i1(1)); fmtc(i1(1), t, "c\n"); ab(i1(1)); fmt(t, "d\n");
  } else if (!strcmp(s, "abort_first")) {   /* abort before any entry */
    int32_t t = alloc();
    ab(i1(1)); fmt(t, "never\n");
  } else if (!strcmp(s, "two_tapes")) {     /* one sequence across tapes; fields go to their own tape */
    int32_t a = alloc(), b = alloc();
    fmt(a, "A%d ");
    fmt(b, "B%d ");
    wr("i32", b, i32(2));
    wr("i32", a, i32(1));
    ab(i1(1));
    fmt(a, "late\n");
  } else if (!strcmp(s, "write_ctl")) {     /* h' = c ? h : 0 at every corpus width plus i1/i7/i100 */
    static const struct { const char *w; char k; unsigned bits; } ws[] = {
        {"i1", 'i', 1}, {"i7", 'i', 7}, {"i8", 'i', 8}, {"i16", 'i', 16}, {"i32", 'i', 32},
        {"i64", 'i', 64}, {"i80", 'i', 80}, {"i100", 'i', 100}, {"i128", 'i', 128},
        {"f16", 'f', 16}, {"f32", 'f', 32}, {"f64", 'f', 64}, {"f80", 'f', 80}};
    int32_t t = alloc();
    fmt(t, "");
    for (unsigned i = 0; i < sizeof ws / sizeof ws[0]; i++) {
      uint64_t lo = UINT64_C(0xfedcba9876543211), hi = UINT64_C(0x0123456789abcdef);
      if (ws[i].bits < 64) lo &= (UINT64_C(1) << ws[i].bits) - 1;
      if (ws[i].bits <= 64) hi = 0;
      else if (ws[i].bits < 128) hi &= (UINT64_C(1) << (ws[i].bits - 64)) - 1;
      cqe_val v = ws[i].k == 'f' ? fake_f(ws[i].bits, lo, hi) : fake_i(ws[i].bits, lo, hi);
      int32_t h = fake_rail(ws[i].w, v);
      wr(ws[i].w, t, h);
      wrc(ws[i].w, i1(1), t, h);
      wrc(ws[i].w, i1(0), t, h);
      const cqe_val *after = cqe_rail(h);
      if (after->w[0] != lo || (after->nw > 1 && after->w[1] != hi)) cqe_fail("TEST: source %s changed", ws[i].w);
    }
  } else if (!strcmp(s, "copy_at_call")) {  /* strings are copied at call time */
    char f[16] = "%s!\n", x[16] = "orig";
    int32_t t = alloc();
    fmt(t, f); str(t, x);
    strcpy(f, "BAD%s\n"); strcpy(x, "bad");
  } else if (!strcmp(s, "effect")) {        /* classical: resolved, logged at the call, never executed */
    int32_t t = alloc();
    str(t, "/tmp/cq_rt_tape_must_not_exist");
    eff(i1(1), t, "remove");
    li32(t, 30);
    eff(i1(0), t, "raise");
  } else if (!strcmp(s, "res_result")) {    /* the result form: the stand-in's value, classical-valued */
    int32_t t = alloc();
    li32(t, 30);
    int32_t r = eff32(i1(1), t, "raise");
    fake_rail("i32", *cqe_rail(r));
    li32(t, 30);
    int32_t r0 = eff32(i1(0), t, "raise");
    fake_rail("i32", *cqe_rail(r0));
    li64(t, 5);
    int32_t r64 = eff64(i1(1), t, "unknown_long");
    fake_rail("i64", *cqe_rail(r64));
  } else if (!strcmp(s, "addr_not_mixed")) { /* an address-range i64 is not mixed; a null name mixes no name */
    int32_t t = alloc();
    char buf[8];
    li64(t, (uint64_t)(uintptr_t)buf);
    li32(t, 7);
    int32_t r = eff32(i1(1), t, "unknown_fn");
    fake_rail("i32", *cqe_rail(r));
    li32(t, 7);
    int32_t r2 = eff32(i1(1), t, "unknown_fn");
    fake_rail("i32", *cqe_rail(r2));
    li64(t, (uint64_t)(uintptr_t)buf);
    li32(t, 7);
    int32_t r3 = fake_call("cqrt_tape_effect_i32_controlled", 3, H(i1(1)), H(t), P(NULL));
    fake_rail("i32", *cqe_rail(r3));
  } else if (!strcmp(s, "defer_field")) {   /* a quantum field defers it and every later output, in order */
    int32_t t = alloc();
    fmt(t, "x=%d\n");
    wr("i32", t, q32(3));
    li32(t, 10);
    int32_t r = eff32(i1(1), t, "putchar");
    fake_rail("i32", *cqe_rail(r));
    fmt(t, "end\n");
  } else if (!strcmp(s, "resolved_then_deferred")) {
    int32_t t = alloc();
    fmt(t, "first\n");
    li32(t, 65);
    eff(i1(1), t, "putchar");
    fmt(t, "%d\n");
    wr("i32", t, q32(1));
  } else if (!strcmp(s, "pred_copy")) {     /* a quantum c is copied at the call; later changes do not reach it */
    int32_t t = alloc();
    int32_t c = q1(1), z = q1(0);
    fmtc(c, t, "one\n");
    fmtc(z, t, "zero\n");
    fake_set(c, fake_i(1, 0, 0));
    fake_set(z, fake_i(1, 1, 0));
  } else if (!strcmp(s, "pred_copy_changed")) {  /* the event's own rail is kept and checked: handle = next after c */
    int32_t t = alloc();
    int32_t c = q1(1);
    fmtc(c, t, "one\n");
    fake_set(c + 1, fake_i(1, 0, 0));
  } else if (!strcmp(s, "pred_seed_freed")) {   /* the |1> seed is freed right after the effect (209) */
    int32_t t = alloc();
    int32_t c = i1(1);
    li32(t, 10);
    eff(c, t, "putchar");
    fake_free(c);
    fmt(t, "%d");
    wr("i32", t, q32(1));
    c = i1(1);
    li32(t, 11);
    eff(c, t, "putchar");
    fake_free(c);
  } else if (!strcmp(s, "abort_input")) {   /* an abort reading 1: outputs dead, input still at the call */
    int32_t t = alloc();
    char b[8] = {0};
    ab(i1(1));
    li32(t, 65);
    eff(i1(1), t, "putchar");
    li64(t, (uint64_t)(uintptr_t)b);
    li32(t, 4);
    li64(t, (uint64_t)(uintptr_t)stdin);
    eff(i1(1), t, "fgets");
    if (b[0] == 0 || b[3] != 0) cqe_fail("TEST: the input was not stored behind the abort");
  } else if (!strcmp(s, "abort_q")) {       /* a quantum flag reading 0 still defers what follows */
    int32_t t = alloc();
    ab(q1(0));
    li32(t, 65);
    eff(i1(1), t, "putchar");
  } else if (!strcmp(s, "input_classical")) { /* behind a deferred output: at the call, host write */
    int32_t t = alloc();
    char b[8] = "ZZZZZZZ";
    fmt(t, "%d\n");
    wr("i32", t, q32(4));
    li64(t, (uint64_t)(uintptr_t)b);
    li32(t, 3);
    li64(t, (uint64_t)(uintptr_t)stdin);
    int32_t r = eff64(i1(1), t, "fgets");
    if (b[2] != 0 || b[3] != 'Z' || b[0] < 'a' || b[0] > 'z') cqe_fail("TEST: fgets stored %.8s", b);
    if (cqe_rail(r)->w[0] != (uint64_t)(uintptr_t)b) cqe_fail("TEST: fgets result");
    char l[64];
    snprintf(l, sizeof l, "{\"ev\":\"probe\",\"b0\":%d,\"b1\":%d}", b[0], b[1]);
    cqe_log(l);
  } else if (!strcmp(s, "input_skip")) {    /* classical predicate 0: skipped, r |0>, nothing stored */
    int32_t t = alloc();
    char b[4] = "ZZZ";
    li64(t, (uint64_t)(uintptr_t)b);
    li32(t, 3);
    li64(t, (uint64_t)(uintptr_t)stdin);
    int32_t r = eff64(i1(0), t, "fgets");
    if (b[0] != 'Z' || cqe_rail(r)->w[0] != 0) cqe_fail("TEST: skipped fgets acted");
  } else if (!strcmp(s, "input_len_q")) {   /* 210: quantum length: stores for v = 3 over the 7 cells reached */
    cqe_tape_set_bus(&td_bus);
    int32_t t = alloc();
    static char b[8] = "ZZZZZZZ";
    li64(t, (uint64_t)(uintptr_t)b);
    wr("i32", t, q32(3));
    li64(t, (uint64_t)(uintptr_t)stdin);
    int32_t c = i1(1);
    eff(c, t, "fgets");
    fake_free(c);
    if (b[0] != 'Z') cqe_fail("TEST: a host write under a quantum length");
  } else if (!strcmp(s, "input_addr_q")) {  /* quantum address, classical length */
    cqe_tape_set_bus(&td_bus);
    int32_t t = alloc();
    static char b[8] = "ZZZZZZZ";
    wr("i64", t, q64p(b));
    li32(t, 2);
    li64(t, (uint64_t)(uintptr_t)stdin);
    int32_t r = eff64(i1(1), t, "fgets");
    if (cqe_rail(r)->w[0] != (uint64_t)(uintptr_t)b) cqe_fail("TEST: fgets result");
    fake_call("cqrt_tape_fmt", 2, H(t), P("after\n"));
  } else if (!strcmp(s, "input_pred_q")) {  /* quantum predicate: performed on both values */
    cqe_tape_set_bus(&td_bus);
    int32_t t = alloc();
    static char b[8] = "ZZZZZZZ", a[8] = "ZZZZZZZ";
    li64(t, (uint64_t)(uintptr_t)b);
    li32(t, 2);
    li64(t, (uint64_t)(uintptr_t)stdin);
    int32_t r0 = eff64(q1(0), t, "fgets");
    if (cqe_rail(r0)->w[0] != 0) cqe_fail("TEST: r under c = 0");
    li64(t, (uint64_t)(uintptr_t)a);
    li32(t, 2);
    li64(t, (uint64_t)(uintptr_t)stdin);
    int32_t r1 = eff64(q1(1), t, "fgets");
    if (cqe_rail(r1)->w[0] != (uint64_t)(uintptr_t)a) cqe_fail("TEST: r under c = 1");
  } else if (!strcmp(s, "input_ident_q")) { /* a truly quantum stream: deferred, nothing stored */
    cqe_tape_set_bus(&td_bus);
    int32_t t = alloc();
    static char b[8] = "ZZZZZZZ";
    li64(t, (uint64_t)(uintptr_t)b);
    li32(t, 3);
    wr("i64", t, q64p(stdin));
    int32_t r = eff64(i1(1), t, "fgets");
    if (cqe_rail(r)->w[0] != 0 || b[0] != 'Z') cqe_fail("TEST: the deferred input acted");
  } else if (!strcmp(s, "read_fread_getc")) {
    int32_t t = alloc();
    char a[32], b[32];
    memset(a, 'Z', 32), memset(b, 'Z', 32);
    li32(t, 3);
    li64(t, (uint64_t)(uintptr_t)a);
    li64(t, 20);
    int32_t r = eff64(i1(1), t, "read");
    li64(t, (uint64_t)(uintptr_t)b);
    li64(t, 2);
    li64(t, 10);
    li64(t, (uint64_t)(uintptr_t)stdin);
    int32_t f = eff64(i1(1), t, "fread");
    li64(t, (uint64_t)(uintptr_t)stdin);
    int32_t g = eff32(i1(1), t, "getc");
    int32_t gc = eff32(i1(1), t, "getchar");
    char l[160];
    snprintf(l, sizeof l, "{\"ev\":\"probe\",\"r\":%llu,\"f\":%llu,\"g\":%llu,\"gc\":%llu,\"a6\":%d,\"b6\":%d,\"a0\":%d}",
             (unsigned long long)cqe_rail(r)->w[0], (unsigned long long)cqe_rail(f)->w[0],
             (unsigned long long)cqe_rail(g)->w[0], (unsigned long long)cqe_rail(gc)->w[0], a[6], b[6], a[0]);
    cqe_log(l);
  } else if (!strcmp(s, "capture")) {       /* 99: fwrite's buffer: HOST bytes as bytes, QUANTUM cells on rails */
    cqe_tape_set_bus(&td_bus);
    int32_t t = alloc();
    static char b[3] = {'x', 'y', 'z'};
    td_set(&b[0], 'A');
    td_set(&b[1], 'B');
    li64(t, (uint64_t)(uintptr_t)b);
    li64(t, 1);
    li64(t, 3);
    li64(t, (uint64_t)(uintptr_t)stdout);
    eff(i1(1), t, "fwrite");
    /* captured at the entry: what happens later does not reach it */
    cells[0].b = 'Q';
    b[2] = 'Q';
    li64(t, (uint64_t)(uintptr_t)"hi\n");
    li64(t, (uint64_t)(uintptr_t)stdout);
    eff(i1(0), t, "fputs");
  } else if (!strcmp(s, "capture_ql")) {    /* a rail length: the buffer up to its value */
    int32_t t = alloc();
    li64(t, (uint64_t)(uintptr_t)"abcdef");
    li64(t, 1);
    wr("i64", t, fake_qrail("i64", fake_i(64, 4, 0)));
    li64(t, (uint64_t)(uintptr_t)stdout);
    eff(i1(1), t, "fwrite");
  } else if (!strcmp(s, "string_rail")) {   /* %s of a pointer rail: classical-valued, then quantum */
    int32_t t = alloc();
    fmt(t, "[%s]");
    wr("i64", t, r64p("cl"));
    fmt(t, "<%s>\n");
    wr("i64", t, q64p("qu"));
  } else if (!strcmp(s, "string_quantum_cell")) {  /* %s over a QUANTUM cell: defers, reads its rail */
    cqe_tape_set_bus(&td_bus);
    int32_t t = alloc();
    static char b[4] = "abc";
    td_set(&b[1], 'X');
    fmt(t, "%s\n");
    str(t, b);
  } else if (!strcmp(s, "fprintf_format")) { /* fprintf: its format and %s by name */
    int32_t t = alloc();
    li64(t, (uint64_t)(uintptr_t)stderr);
    li64(t, (uint64_t)(uintptr_t)"%s-%d");
    str(t, "str");
    li32(t, 4);
    eff(i1(1), t, "fprintf");
  } else if (!strcmp(s, "percent_n")) {     /* %n consumes its field and prints nothing (rule 16) */
    int32_t t = alloc();
    int n = 77;
    fmt(t, "ab%nc\n");
    str(t, (const char *)&n);
    if (n != 77) cqe_fail("TEST: %%n wrote");
  } else if (!strcmp(s, "excess")) {        /* a field past the conversions stays with its format */
    int32_t t = alloc();
    fmt(t, "x\n");
    li32(t, 1);
    fmt(t, "y\n");
  } else if (!strcmp(s, "retired")) {       /* the str family is gone */
    alloc();
    if (fake_rc("tape_write", "tape_write_str") != 1 || fake_rc("tape_write", "tape_str_begin") != 1 ||
        fake_rc("tape_write", "tape_str_end") != 1)
      cqe_fail("TEST: a retired op is the family's");
  } else if (!strcmp(s, "host_fx")) {       /* no host call: the file stays, the signal is not raised */
    const char *path = "/tmp/cq_rt_tape_host_fx";
    fclose(fopen(path, "w"));
    int r = __cqe_fx_remove(path);
    FILE *f = fopen(path, "r");
    if (!f) cqe_fail("TEST: remove was performed");
    else fclose(f);
    remove(path);
    int s9 = __cqe_fx_raise(9);
    char l[64];
    snprintf(l, sizeof l, "{\"ev\":\"probe\",\"r\":%u,\"s\":%u}", (unsigned)r, (unsigned)s9);
    cqe_log(l);
  } else if (!strcmp(s, "spellings")) {     /* op keys that keep cqrt_, the width or _controlled */
    /* C1 names: an i32 literal equal to a live handle's number must be read as the literal */
    int32_t t = fake_call("cqrt_tape_alloc", 0);
    int32_t h7 = i32(7);
    fake_call("cqrt_tape_fmt_controlled", 3, H(i1(1)), H(t), P("%d %d %d %s\n"));
    fake_call("cqrt_tape_write_i32_controlled", 3, H(i1(1)), H(t), H(h7));
    fake_call("cqrt_tape_write_i32", 2, H(t), H(i32(8)));
    fake_call("cqrt_tape_write_i32_lit", 2, H(t), fake_i(32, (uint32_t)h7, 0));
    fake_call("cqrt_tape_write_i64_lit", 2, H(t), P("s"));
    fake_call("cqrt_abort_i1", 1, H(i1(0)));
  } else if (!strcmp(s, "not_mine")) {     /* cq-f69: a stem outside the family is CQE_OP_NOT_MINE, silently */
    if (fake_rc("tape_write", "tape_bogus") != 1 || fake_rc("abort", "trunc") != 1) cqe_fail("TEST: not_mine rc");
    if (fake_rc("tape_alloc", "tape_alloc") != 0) cqe_fail("TEST: tape_alloc rc");
  } else if (!strcmp(s, "exit_call")) {     /* exit() is an end of shot */
    int32_t t = alloc();
    fmt(t, "bye\n");
    exit(0);
  } else if (!strcmp(s, "underscore_exit")) {  /* _Exit loses the tape */
    int32_t t = alloc();
    fmt(t, "lost\n");
    fflush(NULL);
    _Exit(0);
  }
  /* ---- violations: each scenario must log at least one ---- */
  else if (!strcmp(s, "v_field_no_entry")) {
    int32_t t = alloc();
    wr("i32", t, i32(1));
  } else if (!strcmp(s, "v_bad_tape")) {
    alloc();
    fmt(i32(1), "x");
  } else if (!strcmp(s, "v_free_tape_rail")) {
    int32_t t = alloc();
    fmt(t, "%d");
    fake_free(wr("i32", t, i32(1)));
  } else if (!strcmp(s, "v_tape_rail_gone")) {   /* freed, so absent at the end of the shot */
    int32_t t = alloc();
    fmt(t, "%d");
    fake_free(wr("i32", t, i32(1)));
  } else if (!strcmp(s, "v_tape_rail_changed")) {
    int32_t t = alloc();
    fmt(t, "%d");
    fake_set(wr("i32", t, i32(1)), fake_i(32, 2, 0));
  } else if (!strcmp(s, "v_abort_changed")) {
    int32_t f = i1(1);
    alloc();
    ab(f);
    fake_set(f, fake_i(1, 0, 0));
  } else if (!strcmp(s, "v_free_abort")) {
    int32_t f = i1(0);
    ab(f);
    fake_free(f);
  } else if (!strcmp(s, "v_abort_not_i1")) {
    ab(i32(1));
  } else if (!strcmp(s, "v_pred_not_i1")) {
    int32_t t = alloc();
    fmtc(i32(1), t, "x");
  } else if (!strcmp(s, "v_pred_dead")) {
    int32_t t = alloc();
    int32_t c = i1(1);
    fake_free(c);
    fmtc(c, t, "x");
  } else if (!strcmp(s, "v_unc")) {
    int32_t t = alloc();
    fmt(t, "%d");
    fake_call("cqrt_tape_write_i32_unc", 2, H(t), H(i32(1)));
  } else if (!strcmp(s, "v_missing_field")) {
    int32_t t = alloc();
    fmt(t, "%d %d\n");
    wr("i32", t, i32(1));
  } else if (!strcmp(s, "v_bad_conv")) {
    int32_t t = alloc();
    fmt(t, "%y");
    li64(t, 0);
  } else if (!strcmp(s, "v_effect_arity")) {
    int32_t t = alloc();
    li64(t, 0);
    eff(i1(1), t, "fgets");
  } else if (!strcmp(s, "v_null_name_empty")) {
    int32_t t = alloc();
    fake_call("cqrt_tape_effect_controlled", 3, H(i1(1)), H(t), P(NULL));
  } else if (!strcmp(s, "v_effect_open_format")) {
    int32_t t = alloc();
    fmt(t, "%d");
    eff(i1(1), t, "putchar");
  } else if (!strcmp(s, "v_width_mismatch")) {
    int32_t t = alloc();
    fmt(t, "%d");
    wr("i32", t, fake_rail("i8", fake_i(8, 1, 0)));
  } else if (!strcmp(s, "v_effect_uncontrolled")) {
    int32_t t = alloc();
    fake_call("cqrt_tape_effect", 2, H(t), P("raise"));
  } else if (!strcmp(s, "v_hl")) {
    int32_t t = alloc();
    fmt(t, "%d");
    fake_call("cqrt_tape_write_i32_hl", 2, H(t), H(i32(1)));
  } else if (!strcmp(s, "v_ctl_arity")) {
    int32_t t = alloc();
    fake_call("cqrt_tape_fmt_controlled", 2, H(t), P("x"));
  } else if (!strcmp(s, "v_lit_ctl")) {
    int32_t t = alloc();
    fmt(t, "%d");
    fake_call("cqrt_tape_write_i32_lit_controlled", 3, H(i1(1)), H(t), fake_i(32, 1, 0));
  } else {
    fprintf(stderr, "unknown scenario %s\n", s);
    return 2;
  }
  return 0;
}
