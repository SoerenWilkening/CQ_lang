/* fx_call.h: a direct call of a host function no body lifts (CR §6, ruling Q8): no host call is made by either
 * side. The module's call goes to a generated wrapper (drivers.effect_wrappers_ir) that hands its arguments here;
 * this logs what rt_tape.c logs for an effect entry and gives fx_standin.h's result, and for an INPUT call
 * stores the stand-in's bytes. One source for the C oracle (cqo_rt.c) and the lowered side (fx_lowered.c), which
 * define FX_LOG(line, n). Host memory is the program's memory: plain reads and writes.
 * The line: {"ev":"effect","seq":-1,"kind":"effect","class":"host","pred":1,"performed":true,"when":"call",
 * "name","fields":[{"k":"lit","w","v"[,"p":1][,"cap"]}]}; "p" marks a pointer argument. */
#ifndef CQ_FX_CALL_H
#define CQ_FX_CALL_H

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "../rt/fx_standin.h"

#define FXC_MAX 16
typedef struct { uint64_t w[2]; unsigned bits; const char *token; int ptr; } fxc_arg;
static const char *fxc_name;
static fxc_arg fxc_args[FXC_MAX];
static int fxc_n;
static char fxc_line[1 << 17];
static size_t fxc_len;

void cqd_fxc_begin(const char *name) { fxc_name = name, fxc_n = 0; }
void cqd_fxc_int(uint64_t lo, uint64_t hi, unsigned bits, const char *token) {
  if (fxc_n < FXC_MAX) fxc_args[fxc_n++] = (fxc_arg){{lo, hi}, bits, token, 0};
}
void cqd_fxc_ptr(const void *p) {
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

/* The product of the length factors from argument i on; a negative int length is nothing (rt_tape.c length_of). */
static uint64_t fxc_length(const char *roles, int i) {
  uint64_t v = 1;
  for (int j = i; roles[j] == 'n' && j < fxc_n; j++) {
    uint64_t x = fxc_args[j].w[0];
    unsigned b = fxc_args[j].bits;
    if (b < 64) {
      x &= (UINT64_C(1) << b) - 1;
      if ((x >> (b - 1)) & 1) x = 0;
    }
    v = x && v > UINT64_MAX / x ? UINT64_MAX : v * x;
  }
  return v > (uint64_t)INT64_MAX ? (uint64_t)INT64_MAX : v;
}

uint64_t cqd_fxc_done(unsigned rbits) {
  const cq_fx_ent *e = cq_fx_find(fxc_name);
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
    } else if (p && role == 'B') {
      uint64_t n = fxc_length(e->roles, i + 1);
      fxc_put(",\"cap\":"), fxc_str(p, n > 4096 ? 4096 : (size_t)n);
    }
    fxc_put("}");
  }
  fxc_put("]}");
  FX_LOG(fxc_line, fxc_len);
  if (!e || e->cls != 'I') return cq_fx_result(h, rbits);
  int bi = -1, li = -1;
  for (int i = 0; e->roles[i]; i++) {
    if (e->roles[i] == 'W') bi = i;
    if (e->roles[i] == 'n' && li < 0) li = i;
  }
  uint64_t v = bi >= 0 && li >= 0 && li < fxc_n ? fxc_length(e->roles, li) : 0;
  uint64_t addr = bi >= 0 && bi < fxc_n ? fxc_args[bi].w[0] : 0;
  if (bi >= 0) {
    size_t stored = cq_fx_input_stored(e, v);
    for (size_t j = 0; j < stored; j++) ((unsigned char *)(uintptr_t)addr)[j] = cq_fx_input_byte(e, h, j, stored);
  }
  uint64_t size = bi >= 0 && li + 1 < fxc_n && e->roles[li + 1] == 'n' ? fxc_args[li].w[0] : 1;
  return cq_fx_input_result(e, h, addr, v, size);
}

#endif
