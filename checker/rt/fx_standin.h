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
 *   L the address of a buffer pointer the call may reallocate (getline)   N the address of a size_t it writes
 *   f identifying (stream, descriptor)   - other
 * C17 and C++17 (header only, static). */
#ifndef CQ_FX_STANDIN_H
#define CQ_FX_STANDIN_H

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
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
    {"ungetc", 'I', "-f"},  {"ungetwc", 'I', "-f"}, {"feof", 'I', "f"},    {"ferror", 'I', "f"},  {"clearerr", 'I', "f"},
    {"getw", 'I', "f"},     {"pread", 'I', "fWn-"}, {"getline", 'I', "LNf"}, {"getdelim", 'I', "LN-f"},
    {"fgetln", 'I', "fN"},
    /* cq-d4n0n: the _unlocked forms (POSIX getc_unlocked, getchar_unlocked, putc_unlocked, putchar_unlocked, which
     * pass/lib/Common.cpp streamName lists; musl's other aliases, bodiless under ruling Q6) are their locked form: the
     * same roles and, through cq_fx_is, the same model (owner ruling 2026-11-12: an _unlocked variant follows its
     * locked form). tests/rt-tape/test_fx_table.py keeps this table and streamName from drifting apart. */
    {"getc_unlocked", 'I', "f"},      {"getchar_unlocked", 'I', ""},    {"fgetc_unlocked", 'I', "f"},
    {"fgets_unlocked", 'I', "Wnf"},   {"fread_unlocked", 'I', "Wnnf"},  {"fgetwc_unlocked", 'I', "f"},
    {"getwc_unlocked", 'I', "f"},     {"getwchar_unlocked", 'I', ""},   {"fgetws_unlocked", 'I', "Wnf"},
    {"feof_unlocked", 'I', "f"},      {"ferror_unlocked", 'I', "f"},    {"clearerr_unlocked", 'I', "f"},
    {"fwrite_unlocked", 'O', "Bnnf"}, {"fputs_unlocked", 'O', "sf"},    {"putchar_unlocked", 'O', "-"},
    {"putc_unlocked", 'O', "-f"},     {"fputc_unlocked", 'O', "-f"},    {"fflush_unlocked", 'O', "f"},
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
    if (role == 'W' || role == 'B' || role == 's' || role == 'p' || role == 'F' || role == 'G' || role == 'v' || role == 'L' ||
        role == 'N')
      return h;
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
 * one; zero-initialized in __DATA, put back per sample with the rest. set 0: the default. The state past the position:
 * a byte pushed back (ungetc, ungetwc: read before the stream's next byte), the end-of-file indicator (feof; set by a read
 * that ran into the end, cleared by clearerr and a push-back), and quantum: the evaluator's mark that a call that was not
 * classical consumed, so the position depends on the quantum inputs (rt_tape.c sets it; fx_call.h's direct calls on the
 * lowered side then store through the bus as quantum stores, cq_fx_bus_store). */
typedef struct { const uint8_t *b; size_t n, pos; int set, haspb, eof, quantum; uint8_t pbv; void *ln; } cq_fx_in_t;
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

/* A store of an input call's byte. The C oracle: a plain host write (where write). The evaluator (rt_tape.c defines
 * CQ_FX_BUS_STORE and the strong one): a bus store, cstore when classical, else qstore under write. */
#ifndef CQ_FX_BUS_STORE
__attribute__((weak)) void cq_fx_bus_store(uint64_t addr, uint8_t byte, int write, int classical) {
  (void)classical;
  if (write) *(uint8_t *)(uintptr_t)addr = byte;
}
#else
void cq_fx_bus_store(uint64_t addr, uint8_t byte, int write, int classical);
#endif

/* What one INPUT call does at the stream's state (C17 7.21.7, 7.21.8.1, 7.29.3, C99 gets, POSIX read, pread, getline,
 * getdelim, getw, BSD fgetln): v the total length (fread: size * nmemb, the element size apart), aux the value of its
 * first '-' argument (ungetc's character, getdelim's delimiter, pread's offset). take: the bytes it consumes from the
 * stream's sequence (the pushed-back byte first); stored: the bytes it stores at its buffer (fgets, gets, getline: and the
 * null character; gets drops the new-line), unit bytes per character (the wide calls: one wide character per byte, the C
 * locale's ASCII; a byte past 0x7f reads as its own value, the same on both sides); result its result. pread reads at an
 * offset of the stream and consumes nothing (it does not move the file offset). */
typedef struct {
  size_t pos, take, stored, unit, skip;  /* pos: the state before the call (with haspb, pbv, eof) */
  int haspb, eof, at;                     /* at: pread, the bytes come from offset base of the stream, nothing consumed */
  uint8_t pbv;
  size_t base;
  int seteof, push, clear;                /* the state after: the end was hit; push pushes pbv2 back; clear clears eof */
  uint8_t pbv2;
  uint64_t result;
} cq_fx_io;

static inline size_t cq_fx_rem(const cq_fx_in_t *s) { return s->n - s->pos + (s->haspb ? 1u : 0u); }

/* Byte k of the stream's sequence at the call's state. */
static inline uint8_t cq_fx_io_at(const cq_fx_io *io, size_t k) {
  const cq_fx_in_t *s = &cq_fx_in;
  if (io->at) return s->b[io->base + k];
  if (io->haspb) return k == 0 ? io->pbv : s->b[io->pos + k - 1];
  return s->b[io->pos + k];
}

/* e is the function a, or its _unlocked form (cq-d4n0n: the same model). */
static inline int cq_fx_is(const cq_fx_ent *e, const char *a) {
  size_t n = strlen(a);
  return !strncmp(e->name, a, n) && (!e->name[n] || !strcmp(e->name + n, "_unlocked"));
}

static inline cq_fx_io cq_fx_input_plan(const cq_fx_ent *e, uint64_t v, uint64_t buf, uint64_t size, uint64_t aux) {
  cq_fx_in_t *s = cq_fx_stream();
  size_t rem = cq_fx_rem(s);
  cq_fx_io io;
  memset(&io, 0, sizeof io);
  io.pos = s->pos, io.haspb = s->haspb, io.pbv = s->pbv, io.eof = s->eof, io.unit = 1, io.skip = (size_t)-1;
  int wide = cq_fx_is(e, "fgetws");
  if (cq_fx_is(e, "fgets") || wide) {
    io.unit = wide ? sizeof(wchar_t) : 1;
    if (v == 0) return io;                         /* n <= 0: nothing, null */
    size_t k = 0;
    int nl = 0;
    while (k + 1 < v && k < rem)
      if (cq_fx_io_at(&io, k++) == '\n') { nl = 1; break; }
    io.seteof = !nl && k + 1 < v;
    if (k == 0 && v > 1) return io;                /* end of file before any character: null, the buffer as it was */
    io.take = k, io.stored = (k + 1) * io.unit, io.result = buf;
    return io;
  }
  if (cq_fx_is(e, "gets") || cq_fx_is(e, "getline") || cq_fx_is(e, "getdelim") || cq_fx_is(e, "fgetln")) {
    int g = cq_fx_is(e, "gets");
    int delim = cq_fx_is(e, "getdelim") ? (int)(uint8_t)aux : '\n';
    if (!rem) {                                    /* end of file at once: null / -1, nothing stored */
      io.seteof = 1;
      io.result = g || cq_fx_is(e, "fgetln") ? 0 : UINT64_MAX;
      return io;
    }
    size_t k = 0;
    while (k < rem && cq_fx_io_at(&io, k) != delim) k++;
    io.seteof = k == rem;
    io.take = k < rem ? k + 1 : k;                 /* the delimiter is read; gets does not store it */
    if (g) io.skip = k, io.stored = k + 1, io.result = buf;
    else if (cq_fx_is(e, "fgetln")) io.stored = io.take, io.result = 1;   /* the side gives the line's address */
    else io.stored = io.take + 1, io.result = io.take;
    return io;
  }
  if (cq_fx_is(e, "pread")) {
    io.at = 1, io.base = aux < s->n ? (size_t)aux : s->n;
    size_t r = s->n - io.base;
    io.stored = (size_t)(v < r ? v : r);
    io.result = io.stored;
    return io;
  }
  if (cq_fx_is(e, "fread") || cq_fx_is(e, "read")) {
    io.take = io.stored = (size_t)(v < rem ? v : rem);
    io.seteof = cq_fx_is(e, "fread") && io.take < v;
    io.result = cq_fx_is(e, "read") ? io.take : (size ? io.take / size : 0);
    return io;
  }
  if (cq_fx_is(e, "getw")) {                     /* an int, its 4 bytes as stored; EOF short of them */
    io.take = rem < 4 ? rem : 4;
    if (rem < 4) { io.seteof = 1, io.result = (uint64_t)(int64_t)EOF; return io; }
    io.result = (uint64_t)cq_fx_io_at(&io, 0) | (uint64_t)cq_fx_io_at(&io, 1) << 8 | (uint64_t)cq_fx_io_at(&io, 2) << 16 |
                (uint64_t)cq_fx_io_at(&io, 3) << 24;
    return io;
  }
  if (cq_fx_is(e, "ungetc") || cq_fx_is(e, "ungetwc")) {   /* one byte of push-back; EOF (WEOF) or a second fails */
    uint32_t c = (uint32_t)aux;
    if (c == 0xFFFFFFFFu || s->haspb) { io.result = 0xFFFFFFFFu; return io; }
    io.push = 1, io.pbv2 = (uint8_t)c, io.clear = 1;
    io.result = cq_fx_is(e, "ungetc") ? (uint8_t)c : c;
    return io;
  }
  if (cq_fx_is(e, "feof")) { io.result = s->eof ? 1 : 0; return io; }
  if (cq_fx_is(e, "ferror")) return io;          /* the stream never fails */
  if (cq_fx_is(e, "clearerr")) { io.clear = 1; return io; }
  /* fgetc, getc, getchar: the next byte, or EOF; fgetwc, getwc, getwchar: the next character, or WEOF */
  int w = cq_fx_is(e, "fgetwc") || cq_fx_is(e, "getwc") || cq_fx_is(e, "getwchar");
  io.take = rem ? 1 : 0;
  io.seteof = !rem;
  io.result = rem ? cq_fx_io_at(&io, 0) : w ? (uint64_t)(uint32_t)WEOF : (uint64_t)(int64_t)EOF;
  return io;
}

/* Byte j of what the call stores (fgets, gets, fgetws, getline end with the null character). Before cq_fx_input_done. */
static inline uint8_t cq_fx_input_byte(const cq_fx_io *io, size_t j) {
  size_t c = j / io->unit;
  if (j % io->unit || c == io->skip) return 0;
  if (io->at) return c < io->stored ? cq_fx_io_at(io, c) : 0;
  return c < io->take ? cq_fx_io_at(io, c) : 0;
}

/* The call consumed its bytes and left the stream's state. */
static inline void cq_fx_input_done(const cq_fx_io *io) {
  cq_fx_in_t *s = cq_fx_stream();
  if (io->take) {
    s->pos = io->pos + io->take - (io->haspb ? 1u : 0u);
    s->haspb = 0;
  }
  if (io->seteof) s->eof = 1;
  if (io->clear) s->eof = 0;
  if (io->push) s->haspb = 1, s->pbv = io->pbv2;
}

/* The cells a store of the call can reach for length v from any state of the stream: a bound that does not depend on
 * the quantum inputs (an earlier call under a quantum predicate moves the position). */
static inline size_t cq_fx_input_reach(const cq_fx_ent *e, uint64_t v) {
  size_t n = cq_fx_stream()->n + 1;            /* a pushed-back byte too */
  if (cq_fx_is(e, "fgets")) return v == 0 ? 0 : (size_t)((v - 1 < n ? v - 1 : n) + 1);
  if (cq_fx_is(e, "fgetws")) return v == 0 ? 0 : (size_t)((v - 1 < n ? v - 1 : n) + 1) * sizeof(wchar_t);
  if (cq_fx_is(e, "gets")) return n + 1;
  if (cq_fx_is(e, "fread") || cq_fx_is(e, "read") || cq_fx_is(e, "pread")) return (size_t)(v < n ? v : n);
  return 0;
}

/* The allocator of getline's buffer and fgetln's line: the program's own (the C oracle's tracked heap, cqo_rt.c defines
 * CQ_FX_REALLOC; the evaluator's, core.c's realloc), so the program's loads from it are loads of a heap object. */
#ifndef CQ_FX_REALLOC
#define CQ_FX_REALLOC realloc
#endif

typedef int (*cq_fx_peek_fn)(uint64_t addr, uint8_t *byte);
typedef void (*cq_fx_store_fn)(uint64_t addr, uint8_t byte, int write, int classical);

static inline uint64_t cq_fx_load64(cq_fx_peek_fn pk, uint64_t a) {
  uint64_t v = 0;
  for (int i = 0; i < 8; i++) {
    uint8_t b = 0;
    pk(a + (uint64_t)i, &b);
    v |= (uint64_t)b << (8 * i);
  }
  return v;
}

static inline void cq_fx_store64(cq_fx_store_fn st, uint64_t a, uint64_t v, int write, int classical) {
  for (int i = 0; i < 8; i++) st(a + (uint64_t)i, (uint8_t)(v >> (8 * i)), write, classical);
}

/* Makes the stores of a planned INPUT call (one source for both sides): its buffer's bytes (buf, the 'W' argument),
 * over the cells cq_fx_input_reach bounds when not classical (write where this basis input stores); getline and getdelim
 * reallocate *lineptr (lpa, the 'L' argument) to the line's size when it is null or *n (npa, 'N') is short, and write
 * both; fgetln writes the line's length to *len (npa) and returns the line's address. cv: the predicate on this basis
 * input (0: nothing is written, the reach still is when not classical). Returns the call's result. */
static inline uint64_t cq_fx_input_apply(const cq_fx_ent *e, const cq_fx_io *io, uint64_t buf, int has_buf, uint64_t v,
                                         int nknown, int classical, int cv, uint64_t lpa, uint64_t npa, cq_fx_peek_fn pk,
                                         cq_fx_store_fn st) {
  if (cq_fx_is(e, "getline") || cq_fx_is(e, "getdelim")) {
    if (!cv || !io->stored) return cv ? io->result : 0;
    uint64_t lp = cq_fx_load64(pk, lpa), cap = cq_fx_load64(pk, npa);
    if (!lp || cap < io->stored) {
      lp = (uint64_t)(uintptr_t)CQ_FX_REALLOC((void *)(uintptr_t)lp, io->stored);
      cq_fx_store64(st, lpa, lp, 1, classical);
      cq_fx_store64(st, npa, io->stored, 1, classical);
    }
    for (size_t j = 0; j < io->stored; j++) st(lp + j, j < io->take ? cq_fx_io_at(io, j) : 0, 1, classical);
    return io->result;
  }
  if (cq_fx_is(e, "fgetln")) {
    if (!cv || !io->take) return 0;
    /* the stream's line buffer (the C library's, valid until the next call on the stream): a heap block */
    uint8_t *ln = (uint8_t *)CQ_FX_REALLOC(cq_fx_in.ln, io->take);
    if (!ln) return 0;
    cq_fx_in.ln = ln;
    for (size_t j = 0; j < io->take; j++) ln[j] = cq_fx_io_at(io, j);
    uint64_t line = (uint64_t)(uintptr_t)ln;
    cq_fx_store64(st, npa, io->take, 1, classical);
    return line;
  }
  if (has_buf) {
    size_t reach = classical ? io->stored : cq_fx_input_reach(e, nknown ? v : (uint64_t)CQ_FX_K2);
    for (size_t j = 0; j < reach; j++) {
      int write = cv && j < io->stored;
      if (classical && !write) continue;
      st(buf + j, write ? cq_fx_input_byte(io, j) : 0, write, classical);
    }
  }
  return cv ? io->result : 0;
}

/* The "in" field of an input call's effect line: the state it found and the bytes it took. */
static inline int cq_fx_in_json(char *out, size_t cap, const cq_fx_io *io) {
  return snprintf(out, cap, ",\"in\":[%zu,%zu,%d,%d]", io->pos, io->take, io->haspb ? (int)io->pbv : -1, io->eof);
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

/* ruling Q5: where a scan starts: the stream's state (a position, a pushed-back byte), or for the lowered side's union of
 * reach every position with nothing pushed back. */
typedef struct { size_t pos; int haspb; uint8_t pbv; } cq_fx_at;

static inline cq_fx_at cq_fx_here(void) {
  cq_fx_in_t *s = cq_fx_stream();
  cq_fx_at a = {s->pos, s->haspb, s->pbv};
  return a;
}

/* A FILE that reads the stream's sequence from a (at its end: an empty one); *tmp a copy to free after (a push-back). */
static inline FILE *cq_fx_in_open(cq_fx_at a, uint8_t **tmp) {
  cq_fx_in_t *s = cq_fx_stream();
  *tmp = NULL;
  size_t n = s->n - a.pos;
  if (a.haspb) {
    *tmp = (uint8_t *)malloc(n + 1);
    if (!*tmp) return NULL;
    (*tmp)[0] = a.pbv;
    if (n) memcpy(*tmp + 1, s->b + a.pos, n);
    return fmemopen(*tmp, n + 1, "r");
  }
  if (!n) return fopen("/dev/null", "r");
  return fmemopen((void *)(uintptr_t)(s->b + a.pos), n, "r");
}

/* The bytes a scan took from that FILE, and whether it ran into the end. */
static inline size_t cq_fx_in_close(FILE *in, uint8_t *tmp, int *hit_eof) {
  long t = ftell(in);
  *hit_eof = feof(in) != 0;
  fclose(in);
  free(tmp);
  return t > 0 ? (size_t)t : 0;
}

/* The stream after a scan from a that took took bytes (and hit the end or not). */
static inline void cq_fx_scan_done(cq_fx_at a, size_t took, int hit_eof) {
  cq_fx_io io;
  memset(&io, 0, sizeof io);
  io.pos = a.pos, io.haspb = a.haspb, io.pbv = a.pbv, io.take = took, io.seteof = hit_eof;
  cq_fx_input_done(&io);
}

/* The "in" field of a scan's effect line, as cq_fx_in_json. */
static inline int cq_fx_scan_json(char *out, size_t cap, cq_fx_at a, size_t took, int eof) {
  return snprintf(out, cap, ",\"in\":[%zu,%zu,%d,%d]", a.pos, took, a.haspb ? (int)a.pbv : -1, eof);
}

/* The host's vfscanf (wide: vfwscanf on a wchar_t format) on the stream from a (ruling Q5: the lowered side runs its two
 * scans from the same state and advances the stream once, by *took), its arguments the n pointers ptrs, passed as a
 * va_list whose every slot is in the overflow area (x86-64 SysV: gp_offset 48, fp_offset 176, as CR rule 16's variadic
 * clones fill one). Its result. */
static inline int cq_fx_scan_host(int wide, const void *fmt, void *const *ptrs, cq_fx_at a, size_t *took, int *hit_eof) {
#if defined(__x86_64__)
  struct cq_va { unsigned gp, fp; void *ov, *rs; };
  va_list ap;
  struct cq_va *v = (struct cq_va *)(void *)ap;
  v->gp = 48, v->fp = 176, v->ov = (void *)ptrs, v->rs = NULL;
#else
#error "cq_fx_scan_host: the va_list layout of x86-64 SysV"
#endif
  uint8_t *tmp;
  *took = 0, *hit_eof = 0;
  FILE *in = cq_fx_in_open(a, &tmp);
  if (!in) { free(tmp); return EOF; }
  int r = wide ? vfwscanf(in, (const wchar_t *)fmt, ap) : vfscanf(in, (const char *)fmt, ap);
  *took = cq_fx_in_close(in, tmp, hit_eof);
  return r;
}

/* The same call from a va_list the C program passed (fx_call.h), at the stream's state, which advances by what it took;
 * *a, *took and *eof say where it read, what it took, and the end-of-file indicator it found. */
static inline int cq_fx_scan_host_va(int wide, const void *fmt, va_list ap, cq_fx_at *a, size_t *took, int *eof) {
  *a = cq_fx_here(), *took = 0, *eof = cq_fx_stream()->eof;
  uint8_t *tmp;
  int hit = 0;
  FILE *in = cq_fx_in_open(*a, &tmp);
  if (!in) { free(tmp); return EOF; }
  int r = wide ? vfwscanf(in, (const wchar_t *)fmt, ap) : vfscanf(in, (const char *)fmt, ap);
  *took = cq_fx_in_close(in, tmp, &hit);
  cq_fx_scan_done(*a, *took, hit);
  return r;
}

/* A scan as the backend makes it (rt_tape.c perform_scan; fx_call.h's direct call after a call that was not classical):
 * the host's scan into a temporary buffer per pointer, filled 0x00 in one run and 0xFF in a second, both from the
 * state at (ruling Q5: the same offset); a byte one of the runs changed is a byte the call stores at dst[k] + j, through
 * st: classical, those bytes; else every cell a scan from any position of the stream changes, written where this basis
 * input's run changed it (cv 0: none). need: the pointers the format consumes, given: those passed. *took, *hit: what the
 * run took and whether it ran into the end (nothing where cv is 0). Its result. */
#define CQ_FX_SCAN_BUF ((size_t)CQ_FX_K2 + 64)
static inline int cq_fx_scan_twice(int wide, const void *fmt, uint8_t **a, uint8_t **b, size_t n, cq_fx_at at,
                                   size_t *took, int *hit) {
  size_t t2;
  int h2;
  for (size_t k = 0; k < n; k++) memset(a[k], 0x00, CQ_FX_SCAN_BUF), memset(b[k], 0xFF, CQ_FX_SCAN_BUF);
  int r = cq_fx_scan_host(wide, fmt, (void *const *)a, at, took, hit);
  (void)cq_fx_scan_host(wide, fmt, (void *const *)b, at, &t2, &h2);
  return r;
}

static inline int cq_fx_scan_apply(int wide, const void *fmt, const uint64_t *dst, size_t given, size_t need,
                                   int classical, int cv, cq_fx_at at, cq_fx_store_fn st, size_t *took, int *hit) {
  size_t n = need > given ? need : given;
  uint8_t **a = (uint8_t **)calloc(n + 1, sizeof *a), **b = (uint8_t **)calloc(n + 1, sizeof *b);
  for (size_t k = 0; k < n; k++) a[k] = (uint8_t *)malloc(CQ_FX_SCAN_BUF), b[k] = (uint8_t *)malloc(CQ_FX_SCAN_BUF);
  uint8_t **reach = NULL;
  size_t t;
  int h;
  if (!classical) {
    reach = (uint8_t **)calloc(n + 1, sizeof *reach);
    for (size_t k = 0; k < n; k++) reach[k] = (uint8_t *)calloc(CQ_FX_SCAN_BUF, 1);
    for (size_t p = 0; p <= cq_fx_stream()->n; p++) {
      cq_fx_at q = {p, 0, 0};
      (void)cq_fx_scan_twice(wide, fmt, a, b, n, q, &t, &h);
      for (size_t k = 0; k < n; k++)
        for (size_t j = 0; j < CQ_FX_SCAN_BUF; j++) reach[k][j] |= !(a[k][j] == 0 && b[k][j] == 0xFF);
    }
  }
  int r = 0;
  *took = 0, *hit = 0;
  if (cv) r = cq_fx_scan_twice(wide, fmt, a, b, n, at, took, hit);
  else
    for (size_t k = 0; k < n; k++) memset(a[k], 0x00, CQ_FX_SCAN_BUF), memset(b[k], 0xFF, CQ_FX_SCAN_BUF);
  for (size_t k = 0; k < given && k < n; k++)
    for (size_t j = 0; j < CQ_FX_SCAN_BUF; j++) {
      int write = cv && !(a[k][j] == 0 && b[k][j] == 0xFF);   /* this basis input's scan wrote it */
      if (classical ? !write : !(reach[k][j] || write)) continue;
      st(dst[k] + j, write ? a[k][j] : 0, write, classical);
    }
  for (size_t k = 0; k < n; k++) {
    free(a[k]), free(b[k]);
    if (reach) free(reach[k]);
  }
  free(a);
  free(b);
  free(reach);
  return r;
}

#endif
