#include <complex.h>
#include <math.h>
/* Rule 26: float _Complex multiply and divide (vector <2 x float> ABI) with a quantum real part. __mulsc3/__divsc3
 * reproduced from LLVM compiler-rt (Apache-2.0 WITH LLVM-exception), so the -O1 IR holds the bodies. */
float _Complex __mulsc3(float __a, float __b, float __c, float __d) {
  float __ac = __a * __c, __bd = __b * __d, __ad = __a * __d, __bc = __b * __c;
  float _Complex z;
  __real__ z = __ac - __bd; __imag__ z = __ad + __bc;
  if (isnan(__real__ z) && isnan(__imag__ z)) {
    int __recalc = 0;
    if (isinf(__a) || isinf(__b)) {
      __a = copysignf(isinf(__a) ? 1 : 0, __a); __b = copysignf(isinf(__b) ? 1 : 0, __b);
      if (isnan(__c)) __c = copysignf(0, __c);
      if (isnan(__d)) __d = copysignf(0, __d);
      __recalc = 1; }
    if (isinf(__c) || isinf(__d)) {
      __c = copysignf(isinf(__c) ? 1 : 0, __c); __d = copysignf(isinf(__d) ? 1 : 0, __d);
      if (isnan(__a)) __a = copysignf(0, __a);
      if (isnan(__b)) __b = copysignf(0, __b);
      __recalc = 1; }
    if (!__recalc && (isinf(__ac) || isinf(__bd) || isinf(__ad) || isinf(__bc))) {
      if (isnan(__a)) __a = copysignf(0, __a);
      if (isnan(__b)) __b = copysignf(0, __b);
      if (isnan(__c)) __c = copysignf(0, __c);
      if (isnan(__d)) __d = copysignf(0, __d);
      __recalc = 1; }
    if (__recalc) {
      __real__ z = __builtin_huge_valf() * (__a * __c - __b * __d);
      __imag__ z = __builtin_huge_valf() * (__a * __d + __b * __c); }
  }
  return z;
}
float _Complex __divsc3(float __a, float __b, float __c, float __d) {
  int __ilogbw = 0;
  float __logbw = logbf(fmaxf(fabsf(__c), fabsf(__d)));
  if (isfinite(__logbw)) { __ilogbw = (int)__logbw; __c = scalbnf(__c, -__ilogbw); __d = scalbnf(__d, -__ilogbw); }
  float __denom = __c * __c + __d * __d;
  float _Complex z;
  __real__ z = scalbnf((__a * __c + __b * __d) / __denom, -__ilogbw);
  __imag__ z = scalbnf((__b * __c - __a * __d) / __denom, -__ilogbw);
  if (isnan(__real__ z) && isnan(__imag__ z)) {
    if ((__denom == 0) && (!isnan(__a) || !isnan(__b))) {
      __real__ z = copysignf(__builtin_huge_valf(), __c) * __a;
      __imag__ z = copysignf(__builtin_huge_valf(), __c) * __b;
    } else if ((isinf(__a) || isinf(__b)) && isfinite(__c) && isfinite(__d)) {
      __a = copysignf(isinf(__a) ? 1 : 0, __a); __b = copysignf(isinf(__b) ? 1 : 0, __b);
      __real__ z = __builtin_huge_valf() * (__a * __c + __b * __d);
      __imag__ z = __builtin_huge_valf() * (__b * __c - __a * __d);
    } else if (isinf(__logbw) && __logbw > 0 && isfinite(__a) && isfinite(__b)) {
      __c = copysignf(isinf(__c) ? 1 : 0, __c); __d = copysignf(isinf(__d) ? 1 : 0, __d);
      __real__ z = 0 * (__a * __c + __b * __d);
      __imag__ z = 0 * (__b * __c - __a * __d);
    }
  }
  return z;
}
float complex_float_muldiv(float re0, double th, float im, float a, float b) {
    float re = re0;
    cq_theta(&re, th);
    float complex z = re + im * I;
    float complex w = a + b * I;
    float complex p = z * w;
    float complex q = p / w;
    return cq_measure(crealf(q) + cimagf(q));
}
