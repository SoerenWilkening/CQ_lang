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

/* Rule 26: complex multiply with BOTH operands fully quantum: the inline products are templates, the two `fcmp uno`
 * branches are quantum control, and __muldc3 is lifted with mask 1111. */
double complex_mul_both_quantum(double a0, double ta, double b0, double tb, double c0, double tc, double d0, double td) {
    double a = a0, b = b0, c = c0, d = d0;
    cq_theta(&a, ta); cq_theta(&b, tb); cq_theta(&c, tc); cq_theta(&d, td);
    double complex z = a + b * I;
    double complex w = c + d * I;
    double complex p = z * w;
    return cq_measure(creal(p)) + cq_measure(cimag(p));
}
