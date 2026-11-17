#include <complex.h>
#include <math.h>
/* Rule 26: long double _Complex multiply and divide (x87 { x86_fp80, x86_fp80 }, byval) with a quantum real part.
 * __mulxc3/__divxc3 reproduced from LLVM compiler-rt (Apache-2.0 WITH LLVM-exception). */
long double _Complex __mulxc3(long double __a, long double __b, long double __c, long double __d) {
  long double __ac = __a * __c, __bd = __b * __d, __ad = __a * __d, __bc = __b * __c;
  long double _Complex z;
  __real__ z = __ac - __bd; __imag__ z = __ad + __bc;
  if (isnan(__real__ z) && isnan(__imag__ z)) {
    int __recalc = 0;
    if (isinf(__a) || isinf(__b)) {
      __a = copysignl(isinf(__a) ? 1 : 0, __a); __b = copysignl(isinf(__b) ? 1 : 0, __b);
      if (isnan(__c)) __c = copysignl(0, __c);
      if (isnan(__d)) __d = copysignl(0, __d);
      __recalc = 1; }
    if (isinf(__c) || isinf(__d)) {
      __c = copysignl(isinf(__c) ? 1 : 0, __c); __d = copysignl(isinf(__d) ? 1 : 0, __d);
      if (isnan(__a)) __a = copysignl(0, __a);
      if (isnan(__b)) __b = copysignl(0, __b);
      __recalc = 1; }
    if (!__recalc && (isinf(__ac) || isinf(__bd) || isinf(__ad) || isinf(__bc))) {
      if (isnan(__a)) __a = copysignl(0, __a);
      if (isnan(__b)) __b = copysignl(0, __b);
      if (isnan(__c)) __c = copysignl(0, __c);
      if (isnan(__d)) __d = copysignl(0, __d);
      __recalc = 1; }
    if (__recalc) {
      __real__ z = __builtin_huge_vall() * (__a * __c - __b * __d);
      __imag__ z = __builtin_huge_vall() * (__a * __d + __b * __c); }
  }
  return z;
}
long double _Complex __divxc3(long double __a, long double __b, long double __c, long double __d) {
  int __ilogbw = 0;
  long double __logbw = logbl(fmaxl(fabsl(__c), fabsl(__d)));
  if (isfinite(__logbw)) { __ilogbw = (int)__logbw; __c = scalbnl(__c, -__ilogbw); __d = scalbnl(__d, -__ilogbw); }
  long double __denom = __c * __c + __d * __d;
  long double _Complex z;
  __real__ z = scalbnl((__a * __c + __b * __d) / __denom, -__ilogbw);
  __imag__ z = scalbnl((__b * __c - __a * __d) / __denom, -__ilogbw);
  if (isnan(__real__ z) && isnan(__imag__ z)) {
    if ((__denom == 0) && (!isnan(__a) || !isnan(__b))) {
      __real__ z = copysignl(__builtin_huge_vall(), __c) * __a;
      __imag__ z = copysignl(__builtin_huge_vall(), __c) * __b;
    } else if ((isinf(__a) || isinf(__b)) && isfinite(__c) && isfinite(__d)) {
      __a = copysignl(isinf(__a) ? 1 : 0, __a); __b = copysignl(isinf(__b) ? 1 : 0, __b);
      __real__ z = __builtin_huge_vall() * (__a * __c + __b * __d);
      __imag__ z = __builtin_huge_vall() * (__b * __c - __a * __d);
    } else if (isinf(__logbw) && __logbw > 0 && isfinite(__a) && isfinite(__b)) {
      __c = copysignl(isinf(__c) ? 1 : 0, __c); __d = copysignl(isinf(__d) ? 1 : 0, __d);
      __real__ z = 0 * (__a * __c + __b * __d);
      __imag__ z = 0 * (__b * __c - __a * __d);
    }
  }
  return z;
}
long double complex_ldouble_muldiv(long double re0, double th, long double im, long double a, long double b) {
    long double re = re0;
    cq_theta(&re, th);
    long double complex z = re + im * I;
    long double complex w = a + b * I;
    long double complex p = z * w;
    long double complex q = p / w;
    return cq_measure(creall(q) + cimagl(q));
}
