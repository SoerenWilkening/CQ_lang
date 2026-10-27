#include <complex.h>
__attribute__((noinline)) static long double complex scale2(long double complex z) { return z + z; }
long double complex_long_double(long double re0, double th, long double im) {
    long double re = re0;
    cq_theta(&re, th);
    long double complex z = re + im * I;   /* quantum real part, classical imaginary part */
    long double complex q = scale2(z);     /* long double complex travels through memory on x86-64 */
    return cq_measure(creall(q) + cimagl(q));
}
