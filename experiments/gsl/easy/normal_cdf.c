/* gsl_cdf_ugaussian_P: the standard normal distribution function at x - 1.5, x with two quantum bits. */
#include <gsl/gsl_cdf.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    return cq_measure((int)(1000.0 * gsl_cdf_ugaussian_P(x - 1.5)));
}
