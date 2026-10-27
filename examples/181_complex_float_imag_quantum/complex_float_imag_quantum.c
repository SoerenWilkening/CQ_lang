#include <complex.h>
#include <math.h>
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

/* Rule 26: float _Complex (vector <2 x float> ABI) with the IMAGINARY part quantum: add, multiply by a classical
 * complex (__mulsc3 above lifted with mask 0100), conj, crealf/cimagf. __mulsc3 reproduced from LLVM compiler-rt
 * (Apache-2.0 WITH LLVM-exception). */
float complex_float_imag_quantum(float re, float im0, double ti, float a, float b) {
    float im = im0;
    cq_theta(&im, ti);
    float complex z = re + im * I;
    float complex w = a + b * I;
    float complex s = z + w;
    float complex p = z * w;
    float complex c = conjf(p);
    return cq_measure(crealf(s) + cimagf(s) + crealf(c) - cimagf(c));
}
