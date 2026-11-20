/* gsl_fit_linear: least-squares line through four points, one y with two quantum bits. */
#include <gsl/gsl_fit.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double xs[] = {0.0, 1.0, 2.0, 3.0}, ys[] = {1.0, x, 5.0, 7.0};
    double c0, c1, cov00, cov01, cov11, sumsq;
    gsl_fit_linear(xs, 1, ys, 1, 4, &c0, &c1, &cov00, &cov01, &cov11, &sumsq);
    return cq_measure((int)(8.0 * c1));
}
