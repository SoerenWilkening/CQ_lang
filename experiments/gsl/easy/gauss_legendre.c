/* gsl_integration_glfixed: 4-point Gauss-Legendre quadrature of f(t) = x t^2 on [0, 1], x with two quantum bits (the integrand is called through a function pointer). */
#include <gsl/gsl_integration.h>
static double f(double t, void *p) { return *(double *)p * t * t; }
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    gsl_integration_glfixed_table *t = gsl_integration_glfixed_table_alloc(4);
    gsl_function F = {f, &x};
    return cq_measure((int)(12.0 * gsl_integration_glfixed(&F, 0.0, 1.0, t)));
}
