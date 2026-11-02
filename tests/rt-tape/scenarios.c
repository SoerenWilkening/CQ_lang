/* Semantic scenarios of the tape and abort family, one per process (the end of the shot is process
 * exit). run_tests.py runs each and checks its trace. Usage: scenarios <name>. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "fake_core.h"

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
static void str(int32_t t, const char *s) { fake_call("cqrt_tape_write_str_lit", 2, H(t), P(s)); }
static void sb(int32_t t) { fake_call("cqrt_tape_str_begin", 1, H(t)); }
static void se(int32_t t) { fake_call("cqrt_tape_str_end", 1, H(t)); }
static int32_t i8(unsigned char x) { return fake_rail("i8", fake_i(8, x, 0)); }
static void ab(int32_t f) { fake_call("cqrt_abort_i1", 1, H(f)); }
static int32_t i1(int b) { return fake_rail("i1", fake_i(1, (uint64_t)b, 0)); }
static int32_t i32(uint32_t x) { return fake_rail("i32", fake_i(32, x, 0)); }

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
  } else if (!strcmp(s, "effect")) {        /* an effect entry is recorded, never executed */
    int32_t t = alloc();
    fake_call("cqrt_tape_effect_controlled", 3, H(i1(1)), H(t), P("remove"));
    str(t, "/tmp/cq_rt_tape_must_not_exist");
    fake_call("cqrt_tape_effect_controlled", 3, H(i1(0)), H(t), P("raise"));
    lit("i32", t, fake_i(32, 30, 0));
  } else if (!strcmp(s, "str_group")) {   /* tape_str_begin/end: one %s up to the first byte reading 0 */
    int32_t t = alloc();
    fmt(t, "[%s] %d <%s>\n");
    sb(t);
    wr("i8", t, i8('h'));
    wrc("i8", i1(1), t, i8('i'));
    lit("i8", t, fake_i(8, '!', 0));
    wrc("i8", i1(0), t, i8('x'));          /* c = 0: reads 0, the string ends here */
    wr("i8", t, i8('z'));
    se(t);
    wr("i32", t, i32(7));
    sb(t);
    se(t);                                  /* an empty group: the empty string */
  } else if (!strcmp(s, "str_group_effect")) {  /* an effect's string argument from a group */
    int32_t t = alloc();
    fake_call("cqrt_tape_effect_controlled", 3, H(i1(1)), H(t), P("remove"));
    sb(t);
    const char *path = "/tmp/cq_rt_tape_str_group";
    for (const char *c = path; *c; c++) wr("i8", t, i8((unsigned char)*c));
    wr("i8", t, i8(0));
    wr("i8", t, i8('Q'));
    se(t);
  } else if (!strcmp(s, "spellings")) {     /* op keys that keep cqrt_, the width or _controlled */
    /* C1 names: an i32 literal equal to a live handle's number must be read as the literal */
    int32_t t = fake_call("cqrt_tape_alloc", 0);
    int32_t h7 = i32(7);
    fake_call("cqrt_tape_fmt_controlled", 3, H(i1(1)), H(t), P("%d %d %d %s\n"));
    fake_call("cqrt_tape_write_i32_controlled", 3, H(i1(1)), H(t), H(h7));
    fake_call("cqrt_tape_write_i32", 2, H(t), H(i32(8)));
    fake_call("cqrt_tape_write_i32_lit", 2, H(t), fake_i(32, (uint32_t)h7, 0));
    fake_call("cqrt_tape_write_str_lit", 2, H(t), P("s"));
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
  } else if (!strcmp(s, "v_percent_n")) {
    int32_t t = alloc();
    fmt(t, "%n");
    lit("i64", t, fake_i(64, 0, 0));
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
  } else if (!strcmp(s, "v_quantum_string")) {
    int32_t t = alloc();
    fmt(t, "%s");
    wr("i64", t, fake_rail("i64", fake_i(64, 0, 0)));
  } else if (!strcmp(s, "v_str_nested")) {
    int32_t t = alloc();
    fmt(t, "%s");
    sb(t);
    sb(t);
  } else if (!strcmp(s, "v_str_end_alone")) {
    int32_t t = alloc();
    fmt(t, "%s");
    se(t);
  } else if (!strcmp(s, "v_str_open_at_end")) {
    int32_t t = alloc();
    fmt(t, "%s");
    sb(t);
    wr("i8", t, i8('a'));
  } else if (!strcmp(s, "v_str_wide_field")) {
    int32_t t = alloc();
    fmt(t, "%s");
    sb(t);
    wr("i32", t, i32('a'));
    se(t);
  } else if (!strcmp(s, "v_str_no_entry")) {
    int32_t t = alloc();
    sb(t);
  } else if (!strcmp(s, "v_str_entry_inside")) {
    int32_t t = alloc();
    fmt(t, "%s");
    sb(t);
    fmt(t, "x");
  } else {
    fprintf(stderr, "unknown scenario %s\n", s);
    return 2;
  }
  return 0;
}
