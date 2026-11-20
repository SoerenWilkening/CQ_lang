/* gsl_poly_solve_quadratic: real roots of x^2 - (3 + q) x + 2, q with two quantum bits. */
#include <gsl/gsl_poly.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double r0 = 0, r1 = 0;
    gsl_poly_solve_quadratic(1.0, -(3.0 + x), 2.0, &r0, &r1);
    return cq_measure((int)(r0 + r1));
}
