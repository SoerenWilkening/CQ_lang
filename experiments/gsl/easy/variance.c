/* gsl_stats_variance of four doubles, one with two quantum bits. */
#include <gsl/gsl_statistics_double.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double d[4] = {1.0, 2.0, x, 5.0};
    return cq_measure((int)(4.0 * gsl_stats_variance(d, 1, 4)));
}
