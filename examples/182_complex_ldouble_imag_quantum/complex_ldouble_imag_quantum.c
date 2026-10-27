#include <complex.h>
#include <math.h>
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

/* Rule 26: long double _Complex (x87 { x86_fp80, x86_fp80 }, byval) with the IMAGINARY part quantum: add, multiply by a
 * classical complex (__mulxc3 above lifted with mask 0100), conjl, creall/cimagl. __mulxc3 reproduced from LLVM
 * compiler-rt (Apache-2.0 WITH LLVM-exception). */
long double complex_ldouble_imag_quantum(long double re, long double im0, double ti, long double a, long double b) {
    long double im = im0;
    cq_theta(&im, ti);
    long double complex z = re + im * I;
    long double complex w = a + b * I;
    long double complex s = z + w;
    long double complex p = z * w;
    long double complex c = conjl(p);
    return cq_measure(creall(s) + cimagl(s) + creall(c) - cimagl(c));
}
