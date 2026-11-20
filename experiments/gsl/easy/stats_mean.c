/* gsl_stats_mean of four doubles, one of them with two quantum bits. */
#include <gsl/gsl_statistics_double.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double d[4] = {1.0, 2.0, (double)(q & 3), 5.0};
    return cq_measure((int)(4.0 * gsl_stats_mean(d, 1, 4)));
}
