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
 * INPUT calls have their natural result (cq_fx_input_result).
 *
 * Input. The stand-in has no state: an INPUT call reads the same 6-byte line every time, 5 letters from the hash
 * and '\n'. So what a call stores depends on its length only as the C function's contract says, and the deviation
 * of §1.11's quantum-length row (the K2 read consumes the line on every branch) cannot show. A program that loops
 * until end of file does not end under this model on either side.
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

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "cq_standin.h"

#define CQ_FX_K2 4096u /* the input-length bound K2, BACKEND_ABI §0 default */
#define CQ_FX_LINE 6u

typedef struct { const char *name; char cls; const char *roles; } cq_fx_ent; /* cls 'I' INPUT, 'O' OUTPUT */

static const cq_fx_ent cq_fx_table[] = {
    {"fgets", 'I', "Wnf"},  {"fread", 'I', "Wnnf"}, {"read", 'I', "fWn"},  {"fgetc", 'I', "f"},   {"getc", 'I', "f"},
    {"getchar", 'I', ""},   {"fwrite", 'O', "Bnnf"}, {"write", 'O', "fBn"}, {"puts", 'O', "s"},    {"fputs", 'O', "sf"},
    {"fprintf", 'O', "fF"}, {"perror", 'O', "s"},   {"putchar", 'O', "-"}, {"putc", 'O', "-f"},   {"fputc", 'O', "-f"},
    {"fflush", 'O', "f"},   {"fclose", 'O', "f"},   {"fopen", 'O', "pp"},  {"open", 'O', "p"},     {"close", 'O', "f"},
    {"lseek", 'O', "f--"},  {"remove", 'O', "p"},   {"unlink", 'O', "p"},  {"rename", 'O', "pp"},
    {"raise", 'O', "-"},    {"vfprintf", 'O', "fFv"}, {"vprintf", 'O', "Fv"},
    {"fwprintf", 'O', "fG"}, {"wprintf", 'O', "G"},    {"vfwprintf", 'O', "fGv"}, {"vwprintf", 'O', "Gv"},
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

/* Byte j of the stand-in's line. */
static inline uint8_t cq_fx_line_byte(uint64_t h, size_t j) {
  if (j + 1 >= CQ_FX_LINE) return '\n';
  return (uint8_t)('a' + cq_standin_mix(h, (uint64_t)j) % 26);
}

/* How many bytes the call stores for length v: fgets: min(v - 1, line) and a NUL for v >= 1, nothing for v <= 0;
 * read and fread: min(v, line). A signed fgets length arrives here as 0 when negative. */
static inline size_t cq_fx_input_stored(const cq_fx_ent *e, uint64_t v) {
  if (!strcmp(e->name, "fgets")) return v == 0 ? 0 : (size_t)((v - 1 < CQ_FX_LINE ? v - 1 : CQ_FX_LINE) + 1);
  return (size_t)(v < CQ_FX_LINE ? v : CQ_FX_LINE);
}

/* The cells a store of the K2 read can reach, whatever the length. */
static inline size_t cq_fx_input_reach(const cq_fx_ent *e) { return CQ_FX_LINE + (strcmp(e->name, "fgets") ? 0u : 1u); }

/* Byte j of the stored bytes; fgets ends them with the NUL. */
static inline uint8_t cq_fx_input_byte(const cq_fx_ent *e, uint64_t h, size_t j, size_t stored) {
  if (!strcmp(e->name, "fgets") && j + 1 == stored) return 0;
  return cq_fx_line_byte(h, j);
}

/* The natural result of an INPUT call at a buffer buf, total length v, element size size (fread). */
static inline uint64_t cq_fx_input_result(const cq_fx_ent *e, uint64_t h, uint64_t buf, uint64_t v, uint64_t size) {
  if (!strcmp(e->name, "fgets")) return v == 0 ? 0 : buf;
  if (!strcmp(e->name, "fread")) return size ? cq_fx_input_stored(e, v) / size : 0;
  if (!strcmp(e->name, "read")) return cq_fx_input_stored(e, v);
  return cq_fx_line_byte(h, 0);    /* fgetc, getc, getchar */
}

#endif
