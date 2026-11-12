/* fx_standin.h: the checker's model of the host at the rule-16 boundary (CR §6, ruling Q8): no host call is
 * made by either side; a callee with no body is cq_standin.h's deterministic function of its name and argument
 * bits. This file adds what an effect entry needs of it, one source for the evaluator (rt_tape.c, host_fx.c)
 * and the C oracle: the table of callees the backend knows by name (BACKEND_ABI §1.11), which argument bits
 * count, the result, and the bytes an INPUT call stores.
 *
 * Argument bits. Host addresses differ per run and side (CR §6), and on the lowered side a pointer is an
 * i64 field. So a table role that is a pointer is never mixed, and for every other argument an i64 value in
 * [2^32, 2^47), where x86-64 macOS host addresses lie, is not mixed either: both sides apply this to the bits,
 * whatever the C type. A length of an INPUT call is not mixed: the stand-in's bytes cannot depend on it.
 *
 * Result. The low W bits of the hash; W = 64 (a pointer or a long, the lowered side cannot tell) reads 0, null.
 * INPUT calls have their natural result (cq_fx_input_plan).
 *
 * Input (ruling Q5, DECISIONS 2026-11-11): one finite input stream with state, the same bytes on both sides
 * (cq_fx_in below: the default CQ_FX_STDIN_DEFAULT, or the bytes a drivers.txt line's stdin field gives, set by
 * the driver's setup through cq_fx_stdin_set). Every INPUT call, whatever its FILE or descriptor, consumes from
 * it in call order what the C function consumes on that basis input, and after its end sees end of file. A call
 * whose predicate reads 0 consumes nothing; a length consumes for its value. BACKEND_ABI §1.11's two
 * consumption deviations (the K2 call, input consumed on every branch) are effects across branches on a real
 * backend and are not modelled. The position is a static of the executable: each sample starts from the
 * post-setup state (the snapshot of __DATA on both sides). An INPUT call's effect line carries "in":[pos,n],
 * the stream offset it read from and the bytes it took, so a divergence in consumption is a difference of the
 * effect sequences.
 *
 * Roles, one character per argument (past the string: none):
 *   W buffer the call writes  B buffer the call reads, length the following n's  n a length factor
 *   s string the call reads   p string that identifies (a path)   F format string, the varargs follow
 *   G wide (wchar_t) format string, the varargs follow
 *   v the va_list the format's arguments come from (after F or G; rt_tape.c capture_va, cq-83c9c)
 *   f identifying (stream, descriptor)   - other
 * C17 and C++17 (header only, static). */
#ifndef CQ_FX_STANDIN_H
#define CQ_FX_STANDIN_H

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <wchar.h>

#include "cq_standin.h"

#define CQ_FX_K2 4096u /* the input-length bound K2, BACKEND_ABI §0 default */
/* ruling Q5: the default input stream. Numbers, letters, an 'a' (the Q5 witness counts them), three lines. */
#define CQ_FX_STDIN_DEFAULT "7 ab\n-12 c 3.5\nxyz\n"

typedef struct { const char *name; char cls; const char *roles; } cq_fx_ent; /* cls 'I' INPUT, 'O' OUTPUT */

static const cq_fx_ent cq_fx_table[] = {
    {"fgets", 'I', "Wnf"},  {"fread", 'I', "Wnnf"}, {"read", 'I', "fWn"},  {"fgetc", 'I', "f"},   {"getc", 'I', "f"},
    {"getchar", 'I', ""},   {"fwrite", 'O', "Bnnf"}, {"write", 'O', "fBn"}, {"puts", 'O', "s"},    {"fputs", 'O', "sf"},
    {"fprintf", 'O', "fF"}, {"perror", 'O', "s"},   {"putchar", 'O', "-"}, {"putc", 'O', "-f"},   {"fputc", 'O', "-f"},
    {"fflush", 'O', "f"},   {"fclose", 'O', "f"},   {"fopen", 'O', "pp"},  {"open", 'O', "p"},     {"close", 'O', "f"},
    {"lseek", 'O', "f--"},  {"remove", 'O', "p"},   {"unlink", 'O', "p"},  {"rename", 'O', "pp"},
    {"raise", 'O', "-"},    {"vfprintf", 'O', "fFv"}, {"vprintf", 'O', "Fv"},
    {"fwprintf", 'O', "fG"}, {"wprintf", 'O', "G"},    {"vfwprintf", 'O', "fGv"}, {"vwprintf", 'O', "Gv"},
    /* cq-tgl3i: the scanf family, INPUT calls the host performs (cq_fx_scan below), on the one input stream */
    {"scanf", 'I', "F"},    {"fscanf", 'I', "fF"},  {"vscanf", 'I', "Fv"},  {"vfscanf", 'I', "fFv"},
    {"wscanf", 'I', "G"},   {"fwscanf", 'I', "fG"}, {"vwscanf", 'I', "Gv"}, {"vfwscanf", 'I', "fGv"},
    /* ruling Q5: every input call consumes from the one stream */
    {"gets", 'I', "W"},     {"fgetws", 'I', "Wnf"}, {"fgetwc", 'I', "f"},  {"getwc", 'I', "f"},   {"getwchar", 'I', ""},
};

static inline const cq_fx_ent *cq_fx_find(const char *name) {
  if (!name) return NULL;
  for (size_t i = 0; i < sizeof cq_fx_table / sizeof cq_fx_table[0]; ++i)
    if (!strcmp(cq_fx_table[i].name, name)) return &cq_fx_table[i];
  return NULL;
}

/* The hash after the name; a null name (a host address) mixes no name. */
static inline uint64_t cq_fx_begin(const char *name) { return cq_standin_name(name ? name : "", name ? strlen(name) : 0); }

/* Mixes argument idx of bit width bits. */
static inline uint64_t cq_fx_arg(uint64_t h, const cq_fx_ent *e, int idx, unsigned bits, const uint64_t *w, int nw) {
  if (e && idx < (int)strlen(e->roles)) {
    char role = e->roles[idx];
    if (role == 'W' || role == 'B' || role == 's' || role == 'p' || role == 'F' || role == 'G' || role == 'v') return h;
    if (role == 'n' && e->cls == 'I') return h;
  }
  if (bits == 64 && w[0] >= (UINT64_C(1) << 32) && w[0] < (UINT64_C(1) << 47)) return h;
  for (int i = 0; i < nw; ++i) h = cq_standin_mix(h, w[i]);
  return h;
}

/* The result of a callee that is no INPUT call: the low bits (bits <= 64; wider rails take it zero-extended). */
static inline uint64_t cq_fx_result(uint64_t h, unsigned bits) {
  if (bits == 64 || bits == 0) return 0;
  return bits < 64 ? h & ((UINT64_C(1) << bits) - 1) : h;
}

/* ruling Q5: the one input stream. Weak, so the evaluator's objects (rt_tape.c, fx_lowered.c) and the C oracle share
 * one; zero-initialized in __DATA, put back per sample with the rest. set 0: the default. */
typedef struct { const uint8_t *b; size_t n, pos; int set; } cq_fx_in_t;
__attribute__((weak)) cq_fx_in_t cq_fx_in;

static inline cq_fx_in_t *cq_fx_stream(void) {
  if (!cq_fx_in.set) {
    cq_fx_in.b = (const uint8_t *)CQ_FX_STDIN_DEFAULT;
    cq_fx_in.n = sizeof CQ_FX_STDIN_DEFAULT - 1;
    cq_fx_in.pos = 0;
    cq_fx_in.set = 1;
  }
  return &cq_fx_in;
}

/* A drivers.txt line's stdin field (drivers.py): the driver's setup calls this once, before any sample. */
__attribute__((weak)) void cq_fx_stdin_set(const char *b, unsigned long n) {
  cq_fx_in.b = (const uint8_t *)b;
  cq_fx_in.n = (size_t)n;
  cq_fx_in.pos = 0;
  cq_fx_in.set = 1;
}

/* What one INPUT call (fgets, fread, read, fgetc, getc, getchar, gets, and the wide fgetws, fgetwc, getwc, getwchar)
 * does at the stream's position for total length v (fread: v = size * nmemb, the element size apart): take the bytes it
 * consumes, stored the bytes it stores at its buffer (fgets, gets: those and the null character; gets drops the
 * new-line), result its result. A wide call reads one wide character per byte (the C locale's ASCII; a byte past 0x7f
 * reads as its own value, the same on both sides) and stores unit = sizeof(wchar_t) bytes per character.
 * C17 7.21.7.2 / 7.21.8.1 / 7.21.7.1, 7.29.3.1 / 7.29.3.2, C99 gets, POSIX read. */
typedef struct { size_t pos, take, stored, unit, skip; uint64_t result; } cq_fx_io;

static inline cq_fx_io cq_fx_input_plan(const cq_fx_ent *e, uint64_t v, uint64_t buf, uint64_t size) {
  cq_fx_in_t *s = cq_fx_stream();
  size_t rem = s->n - s->pos;
  cq_fx_io io = {s->pos, 0, 0, 1, (size_t)-1, 0};
  int wide = !strcmp(e->name, "fgetws");
  if (!strcmp(e->name, "fgets") || wide) {
    io.unit = wide ? sizeof(wchar_t) : 1;
    if (v == 0) return io;                         /* n <= 0: nothing, null */
    size_t k = 0;
    while (k + 1 < v && k < rem) {
      if (s->b[s->pos + k++] == '\n') break;
    }
    if (k == 0 && v > 1) return io;                /* end of file before any character: null, the buffer as it was */
    io.take = k, io.stored = (k + 1) * io.unit, io.result = buf;
    return io;
  }
  if (!strcmp(e->name, "gets")) {
    if (!rem) return io;                           /* end of file at once: null, the buffer as it was */
    size_t k = 0;
    while (k < rem && s->b[s->pos + k] != '\n') k++;
    io.take = k < rem ? k + 1 : k;                 /* the new-line is read and not stored */
    io.skip = k;
    io.stored = k + 1, io.result = buf;
    return io;
  }
  if (!strcmp(e->name, "fread") || !strcmp(e->name, "read")) {
    io.take = io.stored = (size_t)(v < rem ? v : rem);
    io.result = !strcmp(e->name, "read") ? io.take : (size ? io.take / size : 0);
    return io;
  }
  /* fgetc, getc, getchar: the next byte, or EOF; fgetwc, getwc, getwchar: the next character, or WEOF */
  int w = !strcmp(e->name, "fgetwc") || !strcmp(e->name, "getwc") || !strcmp(e->name, "getwchar");
  io.take = rem ? 1 : 0;
  io.result = rem ? s->b[s->pos] : w ? (uint64_t)(uint32_t)WEOF : (uint64_t)(int64_t)EOF;
  return io;
}

/* Byte j of what the call stores (fgets, gets, fgetws end with the null character). Before cq_fx_input_done. */
static inline uint8_t cq_fx_input_byte(const cq_fx_io *io, size_t j) {
  size_t c = j / io->unit;
  if (c >= io->take || c == io->skip || j % io->unit) return 0;
  return cq_fx_stream()->b[io->pos + c];
}

/* The call consumed its bytes. */
static inline void cq_fx_input_done(const cq_fx_io *io) { cq_fx_stream()->pos = io->pos + io->take; }

/* The cells a store of the call can reach for length v from any position of the stream: a bound that does not depend
 * on the quantum inputs (an earlier call under a quantum predicate moves the position). */
static inline size_t cq_fx_input_reach(const cq_fx_ent *e, uint64_t v) {
  size_t n = cq_fx_stream()->n;
  if (!strcmp(e->name, "fgets")) return v == 0 ? 0 : (size_t)((v - 1 < n ? v - 1 : n) + 1);
  if (!strcmp(e->name, "fgetws")) return v == 0 ? 0 : (size_t)((v - 1 < n ? v - 1 : n) + 1) * sizeof(wchar_t);
  if (!strcmp(e->name, "gets")) return n + 1;
  if (!strcmp(e->name, "fread") || !strcmp(e->name, "read")) return (size_t)(v < n ? v : n);
  return 0;
}

/* cq-tgl3i: the scanf family (scanf, fscanf, vscanf, vfscanf and the wide four) is a rule-16 stream call by name (CR rule
 * 16: every <stdio.h> and <wchar.h> stream function, input and output alike), performed with the host C library
 * (BACKEND_ABI §1.11), on both sides: the C program's call (fx_call.h cqd_in_*) and the evaluator's INPUT entry (rt_tape.c
 * perform_scan) run the same host vfscanf / vfwscanf, never a stand-in. Ruling Q5: what such a call reads is the one input
 * stream from its position (whatever the FILE argument; cq_fx_in_open), never the checker's own pipes (the sampler serves
 * its batches on stdin), and the stream advances by what it took. A conversion before the first input failure still
 * writes (%n).
 * A role F or G entry of this table with class 'I' is one of them. */
static inline int cq_fx_scan(const cq_fx_ent *e) { return e && e->cls == 'I' && strpbrk(e->roles, "FG") != NULL; }

/* The pointer arguments a scanf format consumes (C17 7.21.6.2): one per conversion without '*' (%n too), none for %%; with
 * POSIX n$ positions, the highest position. fmt is narrow (a wide format's parse copy: its ASCII characters). */
static inline size_t cq_fx_scan_nptr(const char *fmt) {
  size_t n = 0, maxpos = 0;
  for (const char *p = fmt; *p;) {
    if (*p++ != '%') continue;
    if (*p == '%') { p++; continue; }
    size_t pos = 0;
    const char *q = p;
    while (*q >= '0' && *q <= '9') pos = pos * 10 + (size_t)(*q++ - '0');
    if (*q == '$' && q != p) p = q + 1;
    else pos = 0;
    int suppress = *p == '*';
    if (suppress) p++;
    while (*p >= '0' && *p <= '9') p++;
    if (*p == 'm') p++;
    while (*p && strchr("hljztLq", *p)) p++;
    if (!*p) break;
    char c = *p++;
    if (c == '[') {
      if (*p == '^') p++;
      if (*p == ']') p++;
      while (*p && *p != ']') p++;
      if (*p) p++;
    }
    if (suppress) continue;
    if (pos) maxpos = pos > maxpos ? pos : maxpos;
    else n++;
  }
  return maxpos > n ? maxpos : n;
}

/* ruling Q5: a FILE that reads the stream from position pos on (at its end: an empty one). */
static inline FILE *cq_fx_in_open(size_t pos) {
  cq_fx_in_t *s = cq_fx_stream();
  if (pos >= s->n) return fopen("/dev/null", "r");
  return fmemopen((void *)(uintptr_t)(s->b + pos), s->n - pos, "r");
}

/* The bytes a scan took from that FILE. */
static inline size_t cq_fx_in_close(FILE *in) {
  long t = ftell(in);
  fclose(in);
  return t > 0 ? (size_t)t : 0;
}

/* The host's vfscanf (wide: vfwscanf on a wchar_t format) on the stream from position pos (ruling Q5: the lowered side
 * runs its two scans from the same position and advances the stream once, by *took), its arguments the n pointers ptrs,
 * passed as a va_list whose every slot is in the overflow area (x86-64 SysV: gp_offset 48, fp_offset 176, as CR rule 16's
 * variadic clones fill one). Its result. */
static inline int cq_fx_scan_host(int wide, const void *fmt, void *const *ptrs, size_t pos, size_t *took) {
#if defined(__x86_64__)
  struct cq_va { unsigned gp, fp; void *ov, *rs; };
  va_list ap;
  struct cq_va *v = (struct cq_va *)(void *)ap;
  v->gp = 48, v->fp = 176, v->ov = (void *)ptrs, v->rs = NULL;
#else
#error "cq_fx_scan_host: the va_list layout of x86-64 SysV"
#endif
  *took = 0;
  FILE *in = cq_fx_in_open(pos);
  if (!in) return EOF;
  int r = wide ? vfwscanf(in, (const wchar_t *)fmt, ap) : vfscanf(in, (const char *)fmt, ap);
  *took = cq_fx_in_close(in);
  return r;
}

/* The same call from a va_list the C program passed (fx_call.h), at the stream's position; *pos and *took say where it
 * read and what it took, and the stream advances by that. */
static inline int cq_fx_scan_host_va(int wide, const void *fmt, va_list ap, size_t *pos, size_t *took) {
  cq_fx_in_t *s = cq_fx_stream();
  *pos = s->pos, *took = 0;
  FILE *in = cq_fx_in_open(s->pos);
  if (!in) return EOF;
  int r = wide ? vfwscanf(in, (const wchar_t *)fmt, ap) : vfscanf(in, (const char *)fmt, ap);
  *took = cq_fx_in_close(in);
  s->pos += *took;
  return r;
}

#endif
