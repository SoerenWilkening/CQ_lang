/* Native side of the tmpl-fenv differential test: each LLVM fp operation compiled by clang-19 -O1
 * for x86_64-apple-macosx under FENV_ACCESS (constrained intrinsics, round.dynamic,
 * fpexcept.strict), run on the host with the rounding mode set and the flags read back.
 * Every function: set the mode, clear the flags, do the operation once, read the flags
 * (INVALID|DIVBYZERO|OVERFLOW|UNDERFLOW|INEXACT, no DENORMAL), restore round-to-nearest.
 * Operands and results travel through memory as bit patterns (f80: 16-byte slots). */
#include <fenv.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

#pragma STDC FENV_ACCESS ON

#define FLAGS (fetestexcept(FE_ALL_EXCEPT) & 0x3d)
#define BEGIN                                                                                      \
  fesetround(mode);                                                                                \
  feclearexcept(FE_ALL_EXCEPT);
#define END                                                                                        \
  int fl_ = FLAGS;                                                                                 \
  fesetround(FE_TONEAREST);                                                                        \
  return fl_;

enum { N_ADD, N_SUB, N_MUL, N_DIV, N_REM, N_MAX, N_MIN };
enum { U_SQRT, U_FLOOR, U_CEIL, U_TRUNC, U_ROUND, U_RINT };
/* compare kinds: quiet olt ole ogt oge oeq une uno one; signaling olt ole ogt oge */
enum { Q_LT, Q_LE, Q_GT, Q_GE, Q_EQ, Q_NE, Q_UN, Q_LG, S_LT, S_LE, S_GT, S_GE };

#define DEF_FP(T, SUF, SQRT, FLOOR, CEIL, TRUNC, ROUND, RINT, FMOD, FMAX, FMIN, FMA)               \
  int nat_bin_##SUF(int op, const void *pa, const void *pb, int mode, void *pr) {                  \
    T a, b, r = 0;                                                                                 \
    memcpy(&a, pa, sizeof a);                                                                      \
    memcpy(&b, pb, sizeof b);                                                                      \
    BEGIN                                                                                          \
    switch (op) {                                                                                  \
    case N_ADD: r = a + b; break;                                                                  \
    case N_SUB: r = a - b; break;                                                                  \
    case N_MUL: r = a * b; break;                                                                  \
    case N_DIV: r = a / b; break;                                                                  \
    case N_REM: r = FMOD(a, b); break;                                                             \
    case N_MAX: r = FMAX(a, b); break;                                                             \
    case N_MIN: r = FMIN(a, b); break;                                                             \
    }                                                                                              \
    int fl_ = FLAGS;                                                                               \
    fesetround(FE_TONEAREST);                                                                      \
    memcpy(pr, &r, sizeof r);                                                                      \
    return fl_;                                                                                    \
  }                                                                                                \
  int nat_fma_##SUF(const void *pa, const void *pb, const void *pc, int mode, void *pr) {          \
    T a, b, c, r;                                                                                  \
    memcpy(&a, pa, sizeof a);                                                                      \
    memcpy(&b, pb, sizeof b);                                                                      \
    memcpy(&c, pc, sizeof c);                                                                      \
    BEGIN r = FMA(a, b, c);                                                                        \
    int fl_ = FLAGS;                                                                               \
    fesetround(FE_TONEAREST);                                                                      \
    memcpy(pr, &r, sizeof r);                                                                      \
    return fl_;                                                                                    \
  }                                                                                                \
  int nat_un_##SUF(int op, const void *pa, int mode, void *pr) {                                   \
    T a, r = 0;                                                                                    \
    memcpy(&a, pa, sizeof a);                                                                      \
    BEGIN                                                                                          \
    switch (op) {                                                                                  \
    case U_SQRT: r = SQRT(a); break;                                                               \
    case U_FLOOR: r = FLOOR(a); break;                                                             \
    case U_CEIL: r = CEIL(a); break;                                                               \
    case U_TRUNC: r = TRUNC(a); break;                                                             \
    case U_ROUND: r = ROUND(a); break;                                                             \
    case U_RINT: r = RINT(a); break;                                                               \
    }                                                                                              \
    int fl_ = FLAGS;                                                                               \
    fesetround(FE_TONEAREST);                                                                      \
    memcpy(pr, &r, sizeof r);                                                                      \
    return fl_;                                                                                    \
  }                                                                                                \
  int nat_cmp_##SUF(int k, const void *pa, const void *pb, int *res) {                             \
    T a, b;                                                                                        \
    int mode = FE_TONEAREST, v = 0;                                                                \
    memcpy(&a, pa, sizeof a);                                                                      \
    memcpy(&b, pb, sizeof b);                                                                      \
    BEGIN                                                                                          \
    switch (k) {                                                                                   \
    case Q_LT: v = __builtin_isless(a, b); break;                                                  \
    case Q_LE: v = __builtin_islessequal(a, b); break;                                             \
    case Q_GT: v = __builtin_isgreater(a, b); break;                                               \
    case Q_GE: v = __builtin_isgreaterequal(a, b); break;                                          \
    case Q_EQ: v = a == b; break;                                                                  \
    case Q_NE: v = a != b; break;                                                                  \
    case Q_UN: v = __builtin_isunordered(a, b); break;                                             \
    case Q_LG: v = __builtin_islessgreater(a, b); break;                                           \
    case S_LT: v = a < b; break;                                                                   \
    case S_LE: v = a <= b; break;                                                                  \
    case S_GT: v = a > b; break;                                                                   \
    case S_GE: v = a >= b; break;                                                                  \
    }                                                                                              \
    *res = v;                                                                                      \
    END                                                                                            \
  }                                                                                                \
  /* fp -> integer, flags only; N: 1 7 8 16 32 64 (1 unsigned only) */                             \
  int nat_toint_##SUF(int N, int sgn, const void *pa, int mode) {                                  \
    T a;                                                                                           \
    memcpy(&a, pa, sizeof a);                                                                      \
    volatile long long sink = 0;                                                                   \
    BEGIN                                                                                          \
    if (sgn) {                                                                                     \
      switch (N) {                                                                                 \
      case 7: sink = (_BitInt(7))a; break;                                                         \
      case 8: sink = (signed char)a; break;                                                        \
      case 16: sink = (short)a; break;                                                             \
      case 32: sink = (int)a; break;                                                               \
      case 64: sink = (long long)a; break;                                                         \
      }                                                                                            \
    } else {                                                                                       \
      switch (N) {                                                                                 \
      case 1: sink = (long long)(unsigned _BitInt(1))a; break;                                     \
      case 7: sink = (long long)(unsigned _BitInt(7))a; break;                                     \
      case 8: sink = (unsigned char)a; break;                                                      \
      case 16: sink = (unsigned short)a; break;                                                    \
      case 32: sink = (unsigned)a; break;                                                          \
      case 64: sink = (long long)(unsigned long long)a; break;                                     \
      }                                                                                            \
    }                                                                                              \
    (void)sink;                                                                                    \
    END                                                                                            \
  }                                                                                                \
  /* integer -> fp; N: 1 (unsigned only) 7 8 16 32 64 */                                           \
  int nat_itofp_##SUF(int N, int sgn, uint64_t v, int mode, void *pr) {                            \
    T r = 0;                                                                                       \
    BEGIN                                                                                          \
    if (sgn) {                                                                                     \
      switch (N) {                                                                                 \
      case 7: r = (T)(_BitInt(7))(long long)v; break;                                              \
      case 8: r = (T)(signed char)v; break;                                                        \
      case 16: r = (T)(short)v; break;                                                             \
      case 32: r = (T)(int)v; break;                                                               \
      case 64: r = (T)(long long)v; break;                                                         \
      }                                                                                            \
    } else {                                                                                       \
      switch (N) {                                                                                 \
      case 1: r = (T)(unsigned _BitInt(1))v; break;                                                \
      case 7: r = (T)(unsigned _BitInt(7))v; break;                                                \
      case 8: r = (T)(unsigned char)v; break;                                                      \
      case 16: r = (T)(unsigned short)v; break;                                                    \
      case 32: r = (T)(unsigned)v; break;                                                          \
      case 64: r = (T)v; break;                                                                    \
      }                                                                                            \
    }                                                                                              \
    int fl_ = FLAGS;                                                                               \
    fesetround(FE_TONEAREST);                                                                      \
    memcpy(pr, &r, sizeof r);                                                                      \
    return fl_;                                                                                    \
  }

/* `_BitInt(7)` from a long long: the low 7 bits, sign-extended (the cast truncates). */
DEF_FP(float, f32, sqrtf, floorf, ceilf, truncf, roundf, rintf, fmodf, fmaxf, fminf, fmaf)
DEF_FP(double, f64, sqrt, floor, ceil, trunc, round, rint, fmod, fmax, fmin, fma)

/* fp -> fp conversions between f32 and f64: from/to are 32, 64 */
int nat_fpconv(int from, int to, const void *pa, int mode, void *pr) {
  float f;
  double d;
  BEGIN
  if (from == 32) {
    memcpy(&f, pa, 4);
    d = f;
    memcpy(pr, &d, 8);
  } else {
    memcpy(&d, pa, 8);
    f = (float)d;
    memcpy(pr, &f, 4);
  }
  (void)to;
  END
}

/* reference-path helpers (f16 and wide integers) */
/* an f64 op under a mode: 0 add 1 sub 2 mul 3 div 4 fma 5 sqrt 6 fmod 7 floor 8 ceil 9 trunc
 * 10 round 11 rint 12 fmax 13 fmin; flags returned */
int nat_f64_op(int op, double a, double b, double c, int mode, double *r) {
  double x = 0;
  BEGIN
  switch (op) {
  case 0: x = a + b; break;
  case 1: x = a - b; break;
  case 2: x = a * b; break;
  case 3: x = a / b; break;
  case 4: x = fma(a, b, c); break;
  case 5: x = sqrt(a); break;
  case 6: x = fmod(a, b); break;
  case 7: x = floor(a); break;
  case 8: x = ceil(a); break;
  case 9: x = trunc(a); break;
  case 10: x = round(a); break;
  case 11: x = rint(a); break;
  case 12: x = fmax(a, b); break;
  case 13: x = fmin(a, b); break;
  }
  int fl_ = FLAGS;
  fesetround(FE_TONEAREST);
  *r = x;
  return fl_;
}
/* rint of x under mode (exact integer rounding); flags discarded */
double nat_rint_mode(double x, int mode) {
  double r;
  fesetround(mode);
  r = rint(x);
  fesetround(FE_TONEAREST);
  return r;
}
/* quiet and signaling compares of two doubles: res = (lt, eq, gt, un) bits; flags returned */
int nat_cmp2_f64(int signaling, double a, double b, int *res) {
  int mode = FE_TONEAREST, v;
  BEGIN
  if (signaling)
    v = a < b;
  else
    v = a == b;
  (void)v;
  int fl_ = FLAGS;
  *res = (__builtin_isless(a, b) ? 1 : 0) | (a == b ? 2 : 0) | (__builtin_isgreater(a, b) ? 4 : 0) |
         (__builtin_isunordered(a, b) ? 8 : 0);
  fesetround(FE_TONEAREST);
  return fl_;
}
