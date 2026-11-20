/* gsl_stats_median_from_sorted_data and gsl_stats_correlation of two 4-samples, one value with two quantum bits. */
#include <gsl/gsl_statistics_double.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double a[4] = {1.0, 2.0, x, 5.0}, b[4] = {2.0, 1.0, 4.0, 3.0};
    return cq_measure((int)(100.0 * gsl_stats_correlation(a, 1, b, 1, 4)));
}
