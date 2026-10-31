/* tests/chk-core (cq-off6, cq-cqcj): sitofp/uitofp iN -> f80 for N > 128 through the evaluator
 * against the same conversion compiled natively by clang 19 -O1 (_BitInt casts lower to LLVM 19's
 * ExpandLargeFpConvert: 113 bits nearest even in integer code, then compiler-rt __trunctfxf2).
 * Reads lines "N hexvalue" (most significant first); prints, per line,
 * "N s|u <ev se> <ev m> <native se> <native m>". The native uitofp carries LLVM 19's sign bug
 * (cq-cqcj), which the caller masks.
 *
 * LLVM 19's darwin libclang_rt.osx.a ships trunctfxf2.c.o empty (no fp128 mode there), so the
 * native program cannot link __trunctfxf2; it is supplied below as compiler-rt's
 * fp_trunc_impl.inc computes it for finite inputs: one rounding to nearest even, no mode. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"

void cqe_dispatch(const char *sym, const char *sig, int32_t nargs, void **argv, void *ret);

typedef struct {
  uint64_t lo, hi;
} q128;
typedef uint64_t fp128_bits __attribute__((vector_size(16))); /* fp128 travels in xmm0, as this does */
long double __trunctfxf2(fp128_bits x) {
  q128 q;
  memcpy(&q, &x, 16);
  int e = (int)((q.hi >> 48) & 0x7fff);
  uint64_t top = ((q.hi & UINT64_C(0xffffffffffff)) << 15) | (q.lo >> 49);
  uint64_t rest = q.lo & ((UINT64_C(1) << 49) - 1), half = UINT64_C(1) << 48;
  uint64_t m = (UINT64_C(1) << 63) | top;
  if (rest > half || (rest == half && (m & 1)))
    if (++m == 0) {
      m = UINT64_C(1) << 63;
      ++e;
    }
  uint8_t b[16] = {0};
  uint16_t se = (uint16_t)(e | (int)(q.hi >> 63) << 15);
  memcpy(b, &m, 8);
  memcpy(b + 8, &se, 2);
  long double r;
  memcpy(&r, b, 10);
  return r;
}

#define NAT(n)                                                                                    \
  static long double u##n(const uint64_t *w) {                                                   \
    unsigned _BitInt(n) x;                                                                         \
    memcpy(&x, w, sizeof x < 64 ? sizeof x : 64);                                                  \
    return (long double)x;                                                                         \
  }                                                                                                \
  static long double s##n(const uint64_t *w) {                                                   \
    _BitInt(n) x;                                                                                  \
    memcpy(&x, w, sizeof x < 64 ? sizeof x : 64);                                                  \
    return (long double)x;                                                                         \
  }
NAT(129)
NAT(192)
NAT(200)
NAT(256)

static void ev(int N, int sgn, const uint64_t *w, int rm, uint16_t *se, uint64_t *m) {
  char ty[16], sym[96], sig[32];
  snprintf(ty, sizeof ty, "i%d", N);
  cqe_val v = {(uint32_t)N, 'i', (uint32_t)((N + 63) / 64), (uint64_t *)w};
  int32_t h = cqe_new_rail(ty, &v, 1), r = 0;
  void *argv[2] = {&h, &rm};
  snprintf(sym, sizeof sym, "cq_template_%s_%s_to_f80%s", sgn ? "sitofp" : "uitofp", ty, rm >= 0 ? "_rm" : "");
  snprintf(sig, sizeof sig, rm >= 0 ? "i32|i32,i32" : "i32|i32");
  cqe_dispatch(sym, sig, rm >= 0 ? 2 : 1, argv, &r);
  const cqe_val *o = cqe_rail(r);
  *m = o->w[0];
  *se = (uint16_t)o->w[1];
}

int main(int argc, char **argv) {
  int rm = argc > 1 ? atoi(argv[1]) : -1; /* x86 FE_* value for the _rm form; native only at -1 */
  char hex[160];
  int N;
  while (scanf("%d %159s", &N, hex) == 2) {
    uint64_t w[8] = {0};
    size_t L = strlen(hex);
    for (size_t i = 0; i < L; ++i) {
      char c = hex[L - 1 - i];
      uint64_t d = (uint64_t)(c <= '9' ? c - '0' : (c | 32) - 'a' + 10);
      w[i / 16] |= d << (4 * (i % 16));
    }
    for (int sgn = 0; sgn < 2; ++sgn) {
      long double x = 0;
      switch (N) {
      case 129: x = sgn ? s129(w) : u129(w); break;
      case 192: x = sgn ? s192(w) : u192(w); break;
      case 200: x = sgn ? s200(w) : u200(w); break;
      case 256: x = sgn ? s256(w) : u256(w); break;
      default: return 2;
      }
      uint8_t b[16] = {0};
      memcpy(b, &x, 10);
      uint64_t nm;
      uint16_t nse;
      memcpy(&nm, b, 8);
      memcpy(&nse, b + 8, 2);
      uint16_t se;
      uint64_t m;
      ev(N, sgn, w, rm, &se, &m);
      printf("%d %c %04x %016llx %04x %016llx\n", N, sgn ? 's' : 'u', se, (unsigned long long)m, nse,
             (unsigned long long)nm);
    }
  }
  return 0;
}
