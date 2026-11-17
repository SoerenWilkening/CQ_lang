#include <complex.h>
/* Rule 18 with the REAL builtin bodies: nothing here defines __muldc3 or __divdc3, so clang's calls reach compiler-rt's
 * pinned 19.1.7 bodies in the injection bundle (inline __compiler_rt_logb / __compiler_rt_scalbn / fmax: ctlz,
 * sadd.with.overflow, maxnum, copysign; no libm call), lifted as clones. 169-174 define their own helpers and witness the
 * lifted-musl shape instead. */
double complex_mul_builtin(double re0, double th, double im, double a, double b) {
    double re = re0;
    cq_theta(&re, th);
    double complex z = re + im * I;
    double complex w = a + b * I;
    double complex p = z * w;
    return cq_measure(creal(p) + cimag(p));
}
double complex_div_builtin(double a, double b, double c0, double tc, double d0, double td) {
    double c = c0, d = d0;
    cq_theta(&c, tc);
    cq_theta(&d, td);
    double complex z = a + b * I;
    double complex w = c + d * I;
    double complex q = z / w;
    return cq_measure(creal(q)) + cq_measure(cimag(q));
}
