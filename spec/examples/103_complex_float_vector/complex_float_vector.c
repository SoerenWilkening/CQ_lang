#include <complex.h>
__attribute__((noinline)) static float _Complex twicef(float _Complex z) { return z + z; }
float complex_float(float a0, double th, float b, float c) {
    float a = a0;
    cq_theta(&a, th);
    float _Complex z = a + b * I;        /* quantum real part, classical imaginary part */
    float _Complex w = z * c + z;        /* real scale: per-lane products, no __mulsc3 */
    float _Complex q = twicef(w);        /* <2 x float> in and out */
    return cq_measure(crealf(q) + cimagf(q));
}
