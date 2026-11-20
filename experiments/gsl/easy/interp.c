/* gsl_interp_eval, linear interpolation over four knots at a point with two quantum bits. The interval is found by a search on the data. */
#include <gsl/gsl_interp.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double xs[] = {0.0, 1.0, 2.0, 4.0}, ys[] = {1.0, 3.0, 2.0, 6.0};
    gsl_interp *in = gsl_interp_alloc(gsl_interp_linear, 4);
    gsl_interp_init(in, xs, ys, 4);
    return cq_measure((int)(4.0 * gsl_interp_eval(in, xs, ys, x * 0.75, 0)));
}
