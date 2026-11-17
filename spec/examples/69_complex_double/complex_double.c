#include <complex.h>
/* __muldc3 reproduced from LLVM compiler-rt, lib/builtins/muldc3.c (Apache-2.0 WITH LLVM-exception): the body clang
 * calls for a full-precision complex multiply when the fast path produced NaNs. Defined here so the -O1 IR holds the body
 * the source bundle would inject. */
double _Complex __muldc3(double __a, double __b, double __c, double __d) {
  double __ac = __a * __c;
  double __bd = __b * __d;
  double __ad = __a * __d;
  double __bc = __b * __c;
  double _Complex z;
  __real__ z = __ac - __bd;
  __imag__ z = __ad + __bc;
  if (__builtin_isnan(__real__ z) && __builtin_isnan(__imag__ z)) {
    int __recalc = 0;
    if (__builtin_isinf(__a) || __builtin_isinf(__b)) {
      __a = __builtin_copysign(__builtin_isinf(__a) ? 1 : 0, __a);
      __b = __builtin_copysign(__builtin_isinf(__b) ? 1 : 0, __b);
      if (__builtin_isnan(__c))
        __c = __builtin_copysign(0, __c);
      if (__builtin_isnan(__d))
        __d = __builtin_copysign(0, __d);
      __recalc = 1;
    }
    if (__builtin_isinf(__c) || __builtin_isinf(__d)) {
      __c = __builtin_copysign(__builtin_isinf(__c) ? 1 : 0, __c);
      __d = __builtin_copysign(__builtin_isinf(__d) ? 1 : 0, __d);
      if (__builtin_isnan(__a))
        __a = __builtin_copysign(0, __a);
      if (__builtin_isnan(__b))
        __b = __builtin_copysign(0, __b);
      __recalc = 1;
    }
    if (!__recalc && (__builtin_isinf(__ac) || __builtin_isinf(__bd) ||
                      __builtin_isinf(__ad) || __builtin_isinf(__bc))) {
      if (__builtin_isnan(__a))
        __a = __builtin_copysign(0, __a);
      if (__builtin_isnan(__b))
        __b = __builtin_copysign(0, __b);
      if (__builtin_isnan(__c))
        __c = __builtin_copysign(0, __c);
      if (__builtin_isnan(__d))
        __d = __builtin_copysign(0, __d);
      __recalc = 1;
    }
    if (__recalc) {
      __real__ z = __builtin_huge_val() * (__a * __c - __b * __d);
      __imag__ z = __builtin_huge_val() * (__a * __d + __b * __c);
    }
  }
  return z;
}
__attribute__((noinline)) static double complex twice(double complex z) { return z + z; }
double complex_double(double re0, double th, double im, double a, double b) {
    double re = re0;
    cq_theta(&re, th);
    double complex z = re + im * I;      /* quantum real part, classical imaginary part */
    double complex w = a + b * I;        /* classical */
    double complex p = z * w;            /* inline products; __muldc3 only when both parts are NaN */
    double complex q = twice(p);         /* aggregate in (two doubles) and out ({ double, double }) */
    return cq_measure(creal(q) + cimag(q));
}
