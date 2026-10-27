/* Native side, WITHOUT FENV_ACCESS: the clang-19 -O1 code CR §2 (CQ_spec e46f5e3) adopts for the
 * value of sitofp/uitofp from more than 128 bits (ExpandLargeFpConvert: integer code, no mode,
 * the exponent wraps past the format's range), whose strict form LLVM 19 cannot compile.
 * to: 16 and 17 (bf16) return the f16/bf16 of the library fptrunc; the test uses only 32 and 64.
 * The caller sets the rounding mode around the call; each function is only the conversion.
 * Flags are not read here (non-strict code may raise or drop them freely). */
#include <stdint.h>
#include <string.h>

/* N: 129 200 1100; to: 16 (f16), 17 (bf16), 32, 64; w: ceil(N/64) little-endian words, the bits
 * above N ignored. Returns the result bits. */
#define WIDE(NB)                                                                                   \
  static uint64_t wide_##NB(int sgn, int to, const uint64_t *w) {                                  \
    unsigned _BitInt(NB) u = 0;                                                                    \
    for (int i = (NB + 63) / 64 - 1; i >= 0; --i)                                                  \
      u = (u << 32 << 32) | w[i];                                                                  \
    _BitInt(NB) s = (_BitInt(NB))u;                                                                \
    uint64_t b = 0;                                                                                \
    switch (to) {                                                                                  \
    case 16: { _Float16 r = sgn ? (_Float16)s : (_Float16)u; memcpy(&b, &r, 2); break; }          \
    case 17: { __bf16 r = sgn ? (__bf16)s : (__bf16)u; memcpy(&b, &r, 2); break; }                \
    case 32: { float r = sgn ? (float)s : (float)u; memcpy(&b, &r, 4); break; }                   \
    case 64: { double r = sgn ? (double)s : (double)u; memcpy(&b, &r, 8); break; }                \
    }                                                                                              \
    return b;                                                                                      \
  }
WIDE(129)
WIDE(200)
WIDE(1100)

uint64_t ns_wide(int N, int sgn, int to, const uint64_t *w) {
  switch (N) {
  case 129: return wide_129(sgn, to, w);
  case 200: return wide_200(sgn, to, w);
  case 1100: return wide_1100(sgn, to, w);
  }
  return 0;
}
