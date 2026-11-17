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

/* Rule 26: the IMAGINARY part is the quantum one (every earlier complex example rotates the real part): add, multiply
 * by a classical complex, and conj/creal/cimag. */
double complex_imag_quantum(double re, double im0, double ti, double a, double b) {
    double im = im0;
    cq_theta(&im, ti);
    double complex z = re + im * I;
    double complex w = a + b * I;
    double complex s = z + w;
    double complex p = z * w;
    double complex c = conj(p);
    return cq_measure(creal(s) + cimag(s) + creal(c) - cimag(c));
}
