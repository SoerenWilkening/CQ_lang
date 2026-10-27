#include <math.h>
int fpclass_d(double x0, double th, double c) {
    double x = x0;
    cq_theta(&x, th);
    double y = x * c;
    return cq_measure(__builtin_isnan(y) + 2 * __builtin_isinf(y) + 4 * __builtin_isfinite(y) + 8 * __builtin_isnormal(y));
}
int fpclass_f(float x0, double th) {
    float x = x0;
    cq_theta(&x, th);
    return cq_measure(__builtin_fpclassify(FP_NAN, FP_INFINITE, FP_NORMAL, FP_SUBNORMAL, FP_ZERO, x));
}
