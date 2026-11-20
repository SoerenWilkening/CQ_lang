/* gsl_complex arithmetic: (x + 2i) * (1 + xi), then its modulus, x with two quantum bits. */
#include <gsl/gsl_complex_math.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    gsl_complex a = gsl_complex_rect(x, 2.0), b = gsl_complex_rect(1.0, x);
    return cq_measure((int)gsl_complex_abs(gsl_complex_mul(a, b)));
}
