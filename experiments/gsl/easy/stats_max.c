/* gsl_stats_max of four doubles, one with two quantum bits. */
#include <gsl/gsl_statistics_double.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double d[4] = {1.0, x, 2.5, 0.5};
    return cq_measure((int)(2.0 * gsl_stats_max(d, 1, 4)));
}
