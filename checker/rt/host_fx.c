/* host_fx.c: the evaluator's log of the host effects a lowered module performs directly (cq-e4jk).
 *
 * A host effect (CR rule 16) under a quantum predicate is a tape entry (rt_tape.c), performed at the
 * end of the shot; under a classical predicate the lowered module calls the host function itself.
 * Both are what the circuit does to the host, and the checker compares them with the C program's
 * (compare.py, "Host output"). run.py renames each direct call of a declared host-effect function
 * (compare.HOST_EFFECTS: remove, unlink, rename, raise) to __cqe_fx_<name> below, which logs
 *   {"ev":"effect","name":"<name>","args":[{"s": string} | {"w": "i<N>", "v": hex}, ...]}
 * and then performs the call. Strings are bytes, each written as the code point of the same number
 * (rt_tape.c's convention). The C oracle logs the same event at the same calls of the C program
 * (OracleInstr.cpp, effects; cqo_rt.c, __cqo_fx_*).
 */
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "cqe.h"

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

static void fx_str(fxbuf *b, const char *s) {
  fx_puts(b, "{\"s\":\"");
  for (const unsigned char *c = (const unsigned char *)s; c && *c; c++) {
    char e[8];
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
  snprintf(e, sizeof e, "{\"w\":\"i%d\",\"v\":\"0x%llx\"}", bits, (unsigned long long)v);
  fx_puts(b, e);
}

static void fx_begin(fxbuf *b, const char *name) {
  fx_puts(b, "{\"ev\":\"effect\",\"name\":\"");
  fx_puts(b, name);
  fx_puts(b, "\",\"args\":[");
}
static void fx_end(fxbuf *b) {
  fx_puts(b, "]}");
  cqe_log(b->p);
  free(b->p);
}

int __cqe_fx_remove(const char *path) {
  fxbuf b = {0};
  fx_begin(&b, "remove"), fx_str(&b, path), fx_end(&b);
  return remove(path);
}

int __cqe_fx_unlink(const char *path) {
  fxbuf b = {0};
  fx_begin(&b, "unlink"), fx_str(&b, path), fx_end(&b);
  return unlink(path);
}

int __cqe_fx_rename(const char *from, const char *to) {
  fxbuf b = {0};
  fx_begin(&b, "rename"), fx_str(&b, from), fx_puts(&b, ","), fx_str(&b, to), fx_end(&b);
  return rename(from, to);
}

int __cqe_fx_raise(int sig) {
  fxbuf b = {0};
  fx_begin(&b, "raise"), fx_int(&b, (uint32_t)sig, 32), fx_end(&b);
  return raise(sig);
}
