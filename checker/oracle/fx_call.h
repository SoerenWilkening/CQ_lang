/* fx_call.h: a direct call of a host function no body lifts (CR §6, ruling Q8): no host call is made by either
 * side. The module's call goes to a generated wrapper (drivers.effect_wrappers_ir) that hands its arguments here;
 * this logs what rt_tape.c logs for an effect entry and gives fx_standin.h's result, and for an INPUT call
 * stores the stand-in's bytes. One source for the C oracle (cqo_rt.c) and the lowered side (fx_lowered.c), which
 * define FX_LOG(line, n). Host memory is the program's memory: plain reads and writes.
 * The line: {"ev":"effect","seq":-1,"kind":"effect","class":"host","pred":1,"performed":true,"when":"call",
 * "name","fields":[{"k":"lit","w","v"[,"p":1][,"cap"]}]}; "p" marks a pointer argument. */
#ifndef CQ_FX_CALL_H
#define CQ_FX_CALL_H

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include "../rt/fx_standin.h"

#define FXC_MAX 256
typedef struct { uint64_t w[2]; unsigned bits; const char *token; int ptr; } fxc_arg;
static const char *fxc_name;
static fxc_arg fxc_args[FXC_MAX];
static int fxc_n;
static char fxc_line[1 << 17];
static size_t fxc_len;
static char fxc_in[80]; /* ruling Q5: an INPUT call's "in" field (fx_standin.h cq_fx_in_json), or empty */

void cqd_fxc_begin(const char *name) { fxc_name = name, fxc_n = 0; }
void cqd_fxc_int(uint64_t lo, uint64_t hi, unsigned bits, const char *token) {
#ifdef FX_PTR_HOOK
  /* rulings Q2: a 64-bit word where host addresses lie may be a pointer the callee follows (a long, __cq_syscall's
   * arguments); it is one only when it is the address of a byte of a live object of the C program (cqo_rt.c
   * __cqo_q2_check, which decides): an integer that merely looks like an address excludes nothing (cq-auqs3) */
  if (bits == 64 && lo >= (UINT64_C(1) << 32) && lo < (UINT64_C(1) << 47)) FX_PTR_HOOK(fxc_name, (uintptr_t)lo);
#endif
  if (fxc_n < FXC_MAX) fxc_args[fxc_n++] = (fxc_arg){{lo, hi}, bits, token, 0};
}
void cqd_fxc_ptr(const void *p) {
#ifdef FX_PTR_HOOK
  FX_PTR_HOOK(fxc_name, p); /* rulings Q2: cqo_rt.c (decides), fx_lowered.c (narrows) */
#endif
  if (fxc_n < FXC_MAX) fxc_args[fxc_n++] = (fxc_arg){{(uint64_t)(uintptr_t)p, 0}, 64, "i64", 1};
}

static void fxc_put(const char *s) {
  size_t n = strlen(s);
  if (fxc_len + n + 1 < sizeof fxc_line) memcpy(fxc_line + fxc_len, s, n), fxc_len += n, fxc_line[fxc_len] = 0;
}
static void fxc_str(const unsigned char *s, size_t n) {
  char e[8];
  fxc_put("\"");
  for (size_t i = 0; i < n; i++) {
    if (s[i] == '"') fxc_put("\\\"");
    else if (s[i] == '\\') fxc_put("\\\\");
    else if (s[i] < 0x20 || s[i] >= 0x7f) snprintf(e, sizeof e, "\\u%04x", s[i]), fxc_put(e);
    else e[0] = (char)s[i], e[1] = 0, fxc_put(e);
  }
  fxc_put("\"");
}

/* The product of the length factors from argument i on (fx_standin.h cq_fx_len_mul, as rt_tape.c length_of). */
static uint64_t fxc_length(const char *roles, int i) {
  uint64_t v = 1;
  for (int j = i; roles[j] == 'n' && j < fxc_n; j++) v = cq_fx_len_mul(v, fxc_args[j].w[0], fxc_args[j].bits);
  return v > (uint64_t)INT64_MAX ? (uint64_t)INT64_MAX : v;
}

/* Logs the call begun by cqd_fxc_begin (the line above) and returns the stand-in's hash over its arguments. */
static uint64_t fxc_log(const cq_fx_ent *e) {
  uint64_t h = cq_fx_begin(fxc_name);
  char b[128];
  fxc_len = 0, fxc_line[0] = 0;
  fxc_put("{\"ev\":\"effect\",\"seq\":-1,\"kind\":\"effect\",\"class\":\"host\",\"pred\":1,\"performed\":true,\"when\":\"call\",\"name\":\"");
  fxc_put(fxc_name);
  fxc_put("\",\"fields\":[");
  for (int i = 0; i < fxc_n; i++) {
    fxc_arg *a = &fxc_args[i];
    if (a->bits < 64) a->w[0] &= (UINT64_C(1) << a->bits) - 1;
    h = cq_fx_arg(h, e, i, a->bits, a->w, (int)((a->bits + 63) / 64));
    if (i) fxc_put(",");
    if (a->w[1]) snprintf(b, sizeof b, "{\"k\":\"lit\",\"w\":\"%s\",\"v\":\"0x%llx%016llx\"", a->token,
                          (unsigned long long)a->w[1], (unsigned long long)a->w[0]);
    else snprintf(b, sizeof b, "{\"k\":\"lit\",\"w\":\"%s\",\"v\":\"0x%llx\"", a->token, (unsigned long long)a->w[0]);
    fxc_put(b);
    if (a->ptr) fxc_put(",\"p\":1");
    char role = e && i < (int)strlen(e->roles) ? e->roles[i] : '-';
    const unsigned char *p = (const unsigned char *)(uintptr_t)a->w[0];
    if (p && (role == 's' || role == 'p' || role == 'F')) {
      fxc_put(",\"cap\":"), fxc_str(p, strnlen((const char *)p, 4096));
    } else if (p && role == 'G') {   /* a wchar_t format: its bytes and its null character, as rt_tape.c captures it */
      size_t k = wcsnlen((const wchar_t *)(const void *)p, CQ_FX_K2);
      fxc_put(",\"cap\":"), fxc_str(p, (k < CQ_FX_K2 ? k + 1 : k) * sizeof(wchar_t));
    } else if (p && role == 'B') {
      uint64_t n = fxc_length(e->roles, i + 1);
      fxc_put(",\"cap\":"), fxc_str(p, n > CQ_FX_K2 ? CQ_FX_K2 : (size_t)n);   /* the line's room (fxc_line) */
    }
    fxc_put("}");
  }
  fxc_put("]");
  fxc_put(fxc_in);   /* ruling Q5, as rt_tape.c's entry_json */
  fxc_in[0] = 0;
  fxc_put("}");
  FX_LOG(fxc_line, fxc_len);
  return h;
}

/* ruling Q5: host memory as an input call reads and writes it. A direct call (the C program's; the lowered module's
 * own) writes host bytes, but on the lowered side once a call that was not classical moved the stream (its quantum mark,
 * set only by rt_tape.c) the bytes depend on the quantum inputs, so they go to the bus as quantum stores
 * (cq_fx_bus_store: rt_tape.c's on the lowered side). */
static int fxc_peek(uint64_t addr, uint8_t *byte) { *byte = *(const uint8_t *)(uintptr_t)addr; return 1; }
static void fxc_store(uint64_t addr, uint8_t byte, int write, int classical) {
  if (classical) { if (write) *(uint8_t *)(uintptr_t)addr = byte; }
  else cq_fx_bus_store(addr, byte, write, 0);
}

static uint64_t fxc_masked(int i) {
  uint64_t x = fxc_args[i].w[0];
  return fxc_args[i].bits < 64 ? x & ((UINT64_C(1) << fxc_args[i].bits) - 1) : x;
}

/* Owner ruling 2026-11-12: the result of a C library output call is musl's when every write succeeds, never the
 * stand-in's hash. The C program's calls take it from cq-oracle-output-results (OracleInstr.cpp, the bundle's entries
 * run natively); a direct call the lowered program makes (putchar, putwchar with classical arguments: an ordinary host
 * call) takes it here, the same values: puts, fputs, fflush, putw 0; fputc, putc, putchar (unsigned char)c; fwrite
 * size ? nmemb : 0; fputwc, putwc, putwchar c, or WEOF where musl's wctomb fails in the C locale the bundle runs in
 * (musl wcrtomb.c: c < 0x80, or a byte code unit 0xdf80..0xdfff, else EILSEQ); and (ruling cq-dbtpi) fclose, remove,
 * rename, fsetpos, close 0, fseek, fseeko, setvbuf 0 or -1, write its count, raise (its complement branch, cqo_rt.c __cqo_raise) 0 or -1. An
 * _unlocked form is its locked form.
 * 1 and the value when fxc_name is one of them. */
static int fxc_output_value(uint64_t *out) {
  const char *n = fxc_name;
  if (!n) return 0;
  size_t l = strlen(n);
  char b[32];
  if (l >= sizeof b) return 0;
  memcpy(b, n, l + 1);
  if (l > 9 && !strcmp(b + l - 9, "_unlocked")) b[l - 9] = 0;
  uint64_t a0 = fxc_n > 0 ? fxc_args[0].w[0] : 0;
  if (!strcmp(b, "puts") || !strcmp(b, "fputs") || !strcmp(b, "fflush") || !strcmp(b, "putw")) return *out = 0, 1;
  /* owner ruling 2026-11-12 cq-dbtpi: musl's success values (fclose.c, remove.c, rename.c, fsetpos.c, unistd/close.c 0;
   * fseek.c -1 for a whence outside {0, 1, 2}, setvbuf.c -1 for a type outside {0, 1, 2}; raise.c the kernel's tkill,
   * which refuses a sig outside 0..64: -1) */
  if (!strcmp(b, "fclose") || !strcmp(b, "remove") || !strcmp(b, "rename") || !strcmp(b, "fsetpos") || !strcmp(b, "close"))
    return *out = 0, 1;
  if (!strcmp(b, "write") && fxc_n == 3) return *out = fxc_args[2].w[0], 1;   /* write.c: its count */
  if ((!strcmp(b, "fseek") || !strcmp(b, "fseeko") || !strcmp(b, "setvbuf")) && fxc_n >= 3)
    return *out = (uint32_t)fxc_args[2].w[0] < 3 ? 0 : UINT64_MAX, 1;
  if (!strcmp(b, "raise") && fxc_n == 1) return *out = (uint32_t)a0 <= 64 ? 0 : UINT64_MAX, 1;
  if (!strcmp(b, "fputc") || !strcmp(b, "putc") || !strcmp(b, "putchar")) return *out = a0 & 0xff, 1;
  if (!strcmp(b, "fwrite") && fxc_n == 4) return *out = fxc_args[1].w[0] ? fxc_args[2].w[0] : 0, 1;
  if (!strcmp(b, "fputwc") || !strcmp(b, "putwc") || !strcmp(b, "putwchar")) {
    uint32_t c = (uint32_t)a0;
    return *out = (c < 0x80 || c - 0xdf80u < 0x80) ? c : 0xffffffffu, 1;
  }
  return 0;
}

uint64_t cqd_fxc_done(unsigned rbits) {
  const cq_fx_ent *e = cq_fx_find(fxc_name);
  uint64_t ov;
  if (fxc_output_value(&ov)) { fxc_log(e); return rbits < 64 && rbits ? ov & ((UINT64_C(1) << rbits) - 1) : ov; }
#ifdef FX_ERRNO_CELL
  /* owner ruling 2026-11-12 (signal's EINVAL store): a Darwin-built module reads errno through __error(), the cell
   * __cqo_signal stores EINVAL into; the C oracle gives the call that cell (cqo_rt.c), logged as the stand-in is */
  if (!strcmp(fxc_name, "__error") && fxc_n == 0 && rbits == 64) { fxc_log(e); return (uint64_t)(uintptr_t)FX_ERRNO_CELL(); }
#endif
  if (!e || e->cls != 'I') return cq_fx_result(fxc_log(e), rbits);
  /* ruling Q5: what the C function consumes of the one input stream at its state, logged with the call */
  int bi = -1, li = -1, ai = -1, Li = -1, Ni = -1;
  for (int i = 0; e->roles[i]; i++) {
    char r = e->roles[i];
    if (r == 'W') bi = i;
    if (r == 'n' && li < 0) li = i;
    if (r == '-' && ai < 0) ai = i;
    if (r == 'L') Li = i;
    if (r == 'N') Ni = i;
  }
  uint64_t v = bi >= 0 && li >= 0 && li < fxc_n ? fxc_length(e->roles, li) : 0;
  uint64_t addr = bi >= 0 && bi < fxc_n ? fxc_args[bi].w[0] : 0;
  uint64_t size = bi >= 0 && li + 1 < fxc_n && e->roles[li + 1] == 'n' ? fxc_args[li].w[0] : 1;
  uint64_t aux = ai >= 0 && ai < fxc_n ? fxc_masked(ai) : 0;
  uint64_t lpa = Li >= 0 && Li < fxc_n ? fxc_args[Li].w[0] : 0, npa = Ni >= 0 && Ni < fxc_n ? fxc_args[Ni].w[0] : 0;
  cq_fx_io io = cq_fx_input_plan(e, v, addr, size, aux);
  cq_fx_in_json(fxc_in, sizeof fxc_in, &io);
  fxc_log(e);
  uint64_t r = cq_fx_input_apply(e, &io, addr, bi >= 0, v, 1, !cq_fx_stream()->quantum, 1, lpa, npa, fxc_peek, fxc_store);
  cq_fx_input_done(&io);
  return r;
}

/* cq-tgl3i: the scanf family (fx_standin.h cq_fx_scan): drivers.route_scans sends the C program's call of scanf, fscanf,
 * wscanf or fwscanf to cqd_in_<name>(n, args...) with n its number of arguments (a use that is no direct call, to
 * cqd_in_<name>_a, whose arguments are those its format consumes), and of a v-form to cqd_in_<name>(args), its signature.
 * The call is logged as an effect with its arguments (the format captured, role F or G), as rt_tape.c logs the INPUT entry
 * the lowered program makes of it, and performed by the host C library on the one input stream from its position
 * (cq_fx_scan_host_va, ruling Q5), which advances by what the scan took; its conversions write through the program's own
 * pointers. The log follows the scan, so that it carries the offset and the bytes taken. */
static int fxc_scan_nv(int wide, const void *fmt);
static int fxc_scan(const char *name, int wide, int has_f, const void *f, const void *fmt, int nv, va_list ap,
                    const void *va_addr) {
  cqd_fxc_begin(name);
  if (has_f) cqd_fxc_ptr(f);
  cqd_fxc_ptr(fmt);
  if (va_addr) {
    cqd_fxc_ptr(va_addr);
  } else {
    va_list cp;
    va_copy(cp, ap);
    for (int i = 0; i < nv; i++) cqd_fxc_ptr(va_arg(cp, void *));
    va_end(cp);
  }
  cq_fx_at at;
  size_t took;
  int eof, r;
  if (!cq_fx_stream()->quantum) {
    r = cq_fx_scan_host_va(wide, fmt, ap, &at, &took, &eof);
  } else {   /* the lowered side after a call that was not classical: the backend's scan, its stores quantum (above) */
    size_t n = (size_t)fxc_scan_nv(wide, fmt), given = va_addr ? n : (size_t)nv;
    uint64_t *dst = (uint64_t *)calloc(given + 1, sizeof *dst);
    va_list cp;
    va_copy(cp, ap);
    for (size_t i = 0; i < given; i++) dst[i] = (uint64_t)(uintptr_t)va_arg(cp, void *);
    va_end(cp);
    int hit;
    at = cq_fx_here(), eof = cq_fx_stream()->eof;
    r = cq_fx_scan_apply(wide, fmt, dst, given, n, 0, 1, at, fxc_store, &took, &hit);
    cq_fx_scan_done(at, took, hit);
    free(dst);
  }
  cq_fx_scan_json(fxc_in, sizeof fxc_in, at, took, eof);
  fxc_log(cq_fx_find(name));
  return r;
}

/* The arguments a format consumes, for a use of the function that is no direct call. */
static int fxc_scan_nv(int wide, const void *fmt) {
  if (!wide) return (int)cq_fx_scan_nptr((const char *)fmt);
  size_t k = wcslen((const wchar_t *)fmt);
  char *pc = (char *)malloc(k + 1);
  if (!pc) return 0;
  for (size_t j = 0; j < k; j++) {
    wchar_t c = ((const wchar_t *)fmt)[j];
    pc[j] = (uint32_t)c < 0x80 ? (char)c : 1;
  }
  pc[k] = 0;
  int n = (int)cq_fx_scan_nptr(pc);
  free(pc);
  return n;
}

#define FXC_SCAN_VAR(name, wide, FT)                                                                      \
  int cqd_in_##name(int n, const FT *fmt, ...) {                                                          \
    va_list ap;                                                                                           \
    va_start(ap, fmt);                                                                                    \
    int r = fxc_scan(#name, wide, 0, NULL, fmt, n - 1, ap, NULL);                                         \
    va_end(ap);                                                                                           \
    return r;                                                                                             \
  }                                                                                                       \
  int cqd_in_##name##_a(const FT *fmt, ...) {                                                             \
    va_list ap;                                                                                           \
    va_start(ap, fmt);                                                                                    \
    int r = fxc_scan(#name, wide, 0, NULL, fmt, fxc_scan_nv(wide, fmt), ap, NULL);                        \
    va_end(ap);                                                                                           \
    return r;                                                                                             \
  }
#define FXC_SCAN_FVAR(name, wide, FT)                                                                     \
  int cqd_in_##name(int n, void *f, const FT *fmt, ...) {                                                 \
    va_list ap;                                                                                           \
    va_start(ap, fmt);                                                                                    \
    int r = fxc_scan(#name, wide, 1, f, fmt, n - 2, ap, NULL);                                            \
    va_end(ap);                                                                                           \
    return r;                                                                                             \
  }                                                                                                       \
  int cqd_in_##name##_a(void *f, const FT *fmt, ...) {                                                    \
    va_list ap;                                                                                           \
    va_start(ap, fmt);                                                                                    \
    int r = fxc_scan(#name, wide, 1, f, fmt, fxc_scan_nv(wide, fmt), ap, NULL);                           \
    va_end(ap);                                                                                           \
    return r;                                                                                             \
  }
FXC_SCAN_VAR(scanf, 0, char)
FXC_SCAN_FVAR(fscanf, 0, char)
FXC_SCAN_VAR(wscanf, 1, wchar_t)
FXC_SCAN_FVAR(fwscanf, 1, wchar_t)
/* A va_list parameter is the address of the caller's va_list (x86-64 SysV), the field the lowered entry passes. */
int cqd_in_vscanf(const char *fmt, va_list ap) { return fxc_scan("vscanf", 0, 0, NULL, fmt, 0, ap, (const void *)ap); }
int cqd_in_vfscanf(void *f, const char *fmt, va_list ap) { return fxc_scan("vfscanf", 0, 1, f, fmt, 0, ap, (const void *)ap); }
int cqd_in_vwscanf(const wchar_t *fmt, va_list ap) { return fxc_scan("vwscanf", 1, 0, NULL, fmt, 0, ap, (const void *)ap); }
int cqd_in_vfwscanf(void *f, const wchar_t *fmt, va_list ap) {
  return fxc_scan("vfwscanf", 1, 1, f, fmt, 0, ap, (const void *)ap);
}

#endif
