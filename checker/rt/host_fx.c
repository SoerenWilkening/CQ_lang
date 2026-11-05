/* host_fx.c: the evaluator's stand-in for the host effects a lowered module calls directly.
 *
 * An effect entry goes through rt_tape.c. A direct call is rule 16's ordinary host call, or a stream call the
 * compiler left: no host call is made by either side (CR §6, ruling Q8), so run.py renames each direct call of
 * a declared host-effect function to __cqe_fx_<name> below, which logs
 *   {"ev":"effect","seq":-1,"kind":"effect","class":"host","pred":1,"performed":true,"when":"call","name":"<name>",
 *    "fields":[{"k":"lit","w":"i<N>","v":hex[,"cap":string]}, ...]}
 * (rt_tape.c's entry object: a pointer is its i64 address with the string it reads as "cap") and returns the
 * stand-in result of fx_standin.h. Strings are bytes, each written as the code point of the same number.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"
#include "fx_standin.h"

typedef struct { char *p; size_t n, cap; } fxbuf;

static void fx_put(fxbuf *b, const char *s, size_t n) {
  if (b->n + n + 1 > b->cap) {
    size_t cap = b->cap ? b->cap : 256;
    while (cap < b->n + n + 1) cap *= 2;
    char *p = realloc(b->p, cap);
    if (!p) { fprintf(stderr, "cq: host_fx: out of memory\n"); abort(); }
    b->p = p, b->cap = cap;
  }
  memcpy(b->p + b->n, s, n);
  b->n += n;
  b->p[b->n] = 0;
}
static void fx_puts(fxbuf *b, const char *s) { fx_put(b, s, strlen(s)); }

/* A pointer argument: its address and the string it reads. */
static void fx_str(fxbuf *b, const char *s) {
  char e[64];
  snprintf(e, sizeof e, "{\"k\":\"lit\",\"w\":\"i64\",\"v\":\"0x%llx\",\"cap\":\"", (unsigned long long)(uintptr_t)s);
  fx_puts(b, e);
  for (const unsigned char *c = (const unsigned char *)s; c && *c; c++) {
    if (*c == '"') fx_puts(b, "\\\"");
    else if (*c == '\\') fx_puts(b, "\\\\");
    else if (*c < 0x20 || *c >= 0x7f) { snprintf(e, sizeof e, "\\u%04x", *c); fx_puts(b, e); }
    else fx_put(b, (const char *)c, 1);
  }
  fx_puts(b, "\"}");
}

static void fx_int(fxbuf *b, uint64_t v, int bits) {
  char e[64];
  if (bits < 64) v &= (UINT64_C(1) << bits) - 1;
  snprintf(e, sizeof e, "{\"k\":\"lit\",\"w\":\"i%d\",\"v\":\"0x%llx\"}", bits, (unsigned long long)v);
  fx_puts(b, e);
}

static void fx_begin(fxbuf *b, const char *name) {
  fx_puts(b, "{\"ev\":\"effect\",\"seq\":-1,\"kind\":\"effect\",\"class\":\"host\",\"pred\":1,\"performed\":true,"
             "\"when\":\"call\",\"name\":\"");
  fx_puts(b, name);
  fx_puts(b, "\",\"fields\":[");
}
static void fx_end(fxbuf *b) {
  fx_puts(b, "]}");
  cqe_log(b->p);
  free(b->p);
}

/* The stand-in's int result: the callee's pointer arguments are never mixed. */
static int fx_result(const char *name, int nint, const int64_t *args, const unsigned *bits) {
  const cq_fx_ent *e = cq_fx_find(name);
  uint64_t h = cq_fx_begin(name);
  for (int i = 0; i < nint; i++) {
    uint64_t w = (uint64_t)args[i];
    if (bits[i] < 64) w &= (UINT64_C(1) << bits[i]) - 1;
    h = cq_fx_arg(h, e, i, bits[i], &w, 1);
  }
  return (int)cq_fx_result(h, 32);
}

int __cqe_fx_remove(const char *path) {
  fxbuf b = {0};
  fx_begin(&b, "remove"), fx_str(&b, path), fx_end(&b);
  return fx_result("remove", 0, NULL, NULL);
}

int __cqe_fx_unlink(const char *path) {
  fxbuf b = {0};
  fx_begin(&b, "unlink"), fx_str(&b, path), fx_end(&b);
  return fx_result("unlink", 0, NULL, NULL);
}

int __cqe_fx_rename(const char *from, const char *to) {
  fxbuf b = {0};
  fx_begin(&b, "rename"), fx_str(&b, from), fx_puts(&b, ","), fx_str(&b, to), fx_end(&b);
  return fx_result("rename", 0, NULL, NULL);
}

int __cqe_fx_raise(int sig) {
  fxbuf b = {0};
  fx_begin(&b, "raise"), fx_int(&b, (uint32_t)sig, 32), fx_end(&b);
  int64_t a = sig;
  unsigned w = 32;
  return fx_result("raise", 1, &a, &w);
}
