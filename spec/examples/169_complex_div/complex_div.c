#include <complex.h>
#include <math.h>
/* __divdc3 reproduced from LLVM compiler-rt, lib/builtins/divdc3.c (Apache-2.0 WITH LLVM-exception): the body clang
 * calls for a complex divide. Defined here so the -O1 IR holds the body the source bundle would inject. */
double _Complex __divdc3(double __a, double __b, double __c, double __d) {
  int __ilogbw = 0;
  double __logbw = logb(fmax(fabs(__c), fabs(__d)));
  if (isfinite(__logbw)) {
    __ilogbw = (int)__logbw;
    __c = scalbn(__c, -__ilogbw);
    __d = scalbn(__d, -__ilogbw);
  }
  double __denom = __c * __c + __d * __d;
  double _Complex z;
  __real__ z = scalbn((__a * __c + __b * __d) / __denom, -__ilogbw);
  __imag__ z = scalbn((__b * __c - __a * __d) / __denom, -__ilogbw);
  if (isnan(__real__ z) && isnan(__imag__ z)) {
    if ((__denom == 0.0) && (!isnan(__a) || !isnan(__b))) {
      __real__ z = copysign(__builtin_huge_val(), __c) * __a;
      __imag__ z = copysign(__builtin_huge_val(), __c) * __b;
    } else if ((isinf(__a) || isinf(__b)) && isfinite(__c) && isfinite(__d)) {
      __a = copysign(isinf(__a) ? 1.0 : 0.0, __a);
      __b = copysign(isinf(__b) ? 1.0 : 0.0, __b);
      __real__ z = __builtin_huge_val() * (__a * __c + __b * __d);
      __imag__ z = __builtin_huge_val() * (__b * __c - __a * __d);
    } else if (isinf(__logbw) && __logbw > 0.0 && isfinite(__a) && isfinite(__b)) {
      __c = copysign(isinf(__c) ? 1.0 : 0.0, __c);
      __d = copysign(isinf(__d) ? 1.0 : 0.0, __d);
      __real__ z = 0.0 * (__a * __c + __b * __d);
      __imag__ z = 0.0 * (__b * __c - __a * __d);
    }
  }
  return z;
}

/* Rule 26: complex division with a quantum real part of the dividend (first entry) and a fully quantum divisor
 * (second). clang always calls __divdc3 (no inline fast path); its body above is lifted as a clone; logb/scalbn/fmax/
 * fabs/copysign on quantum operands are templates or injected libm bodies. */
double complex_div_q_c(double re0, double th, double im, double a, double b) {
    double re = re0;
    cq_theta(&re, th);
    double complex z = re + im * I;
    double complex w = a + b * I;
    double complex q = z / w;
    return cq_measure(creal(q) + cimag(q));
}
double complex_div_c_qq(double a, double b, double c0, double tc, double d0, double td) {
    double c = c0, d = d0;
    cq_theta(&c, tc);
    cq_theta(&d, td);
    double complex z = a + b * I;
    double complex w = c + d * I;
    double complex q = z / w;
    return cq_measure(creal(q)) + cq_measure(cimag(q));
}
