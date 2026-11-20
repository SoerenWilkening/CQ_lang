/* gsl_pow_int(x, 3): x^3 by repeated squaring, x a double with two quantum bits (0..3). */
#include <gsl/gsl_math.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);
    return cq_measure((int)gsl_pow_int(x, 3));
}
