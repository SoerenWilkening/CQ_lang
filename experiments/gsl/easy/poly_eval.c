/* gsl_poly_eval: 1 + 2x + 3x^2 + 4x^3 by Horner's rule, x a double with two quantum bits. */
#include <gsl/gsl_poly.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);
    static const double c[4] = {1.0, 2.0, 3.0, 4.0};
    return cq_measure((int)gsl_poly_eval(c, 4, x));
}
