/* tests/chk-core: calls runtime symbols through the real dispatcher (core, families). Reads lines
 * "<sym> <sig> <arg>..." where sig is "ret|t0,t1,..." (a runtime declaration) and each arg is
 *   h:<width>:<hex>  a fresh known rail of that width token holding the value, passed as its handle;
 *   l:<hex>          a literal (up to 64 bits) of the declared parameter type;
 *   p:<hex bytes>    a pointer to a buffer holding those bytes (memory order).
 * Prints, per line, the returned rail's value as hex (a handle result) or "void". The trace goes to
 * $CQE_TRACE as usual; a violation ends the run through the core. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

void cqe_dispatch(const char *sym, const char *sig, int32_t nargs, void **argv, void *ret);

static void hex_words(const char *hex, uint64_t *w, size_t nw) {
  memset(w, 0, nw * sizeof *w);
  size_t L = strlen(hex);
  for (size_t i = 0; i < L && i / 16 < nw; ++i) {
    char c = hex[L - 1 - i];
    w[i / 16] |= (uint64_t)(c <= '9' ? c - '0' : (c | 32) - 'a' + 10) << (4 * (i % 16));
  }
}

int main(void) {
  char line[8192];
  while (fgets(line, sizeof line, stdin)) {
    line[strcspn(line, "\n")] = 0;
    char *sym = strtok(line, " "), *sig = strtok(NULL, " ");
    if (!sym || !sig)
      continue;
    void *argv[16];
    uint64_t lit[16];
    int32_t hs[16];
    unsigned char *bufs[16];
    void *ptrs[16];
    int n = 0;
    for (char *a = strtok(NULL, " "); a && n < 16; a = strtok(NULL, " "), ++n) {
      bufs[n] = NULL;
      if (a[0] == 'h') {
        char *w = a + 2, *hex = strchr(w, ':');
        *hex++ = 0;
        uint64_t words[64];
        hex_words(hex, words, 64);
        uint32_t bits = !strcmp(w, "bf16") ? 16 : (uint32_t)atoi(w + 1);
        cqe_val v = {bits, w[0] == 'i' ? 'i' : 'f', (bits + 63) / 64, words};
        hs[n] = cqe_new_rail(w, &v, 1);
        argv[n] = &hs[n];
      } else if (a[0] == 'l') {
        hex_words(a + 2, &lit[n], 1);
        argv[n] = &lit[n];
      } else {
        size_t L = strlen(a + 2) / 2;
        bufs[n] = calloc(L + 16, 1);
        for (size_t i = 0; i < L; ++i) sscanf(a + 2 + 2 * i, "%2hhx", &bufs[n][i]);
        ptrs[n] = bufs[n];
        argv[n] = &ptrs[n];
      }
    }
    int32_t r = 0;
    cqe_dispatch(sym, sig, n, argv, &r);
    if (!strncmp(sig, "void|", 5)) {
      printf("void\n");
    } else {
      const cqe_val *o = cqe_rail(r);
      for (uint32_t i = o->nw; i-- > 0;) printf(i + 1 == o->nw ? "%llx" : "%016llx", (unsigned long long)o->w[i]);
      printf("\n");
    }
    fflush(stdout);
  }
  return 0;
}
