/* gsl_sort (heapsort) of four doubles, one with two quantum bits. Which elements are swapped depends on the data. */
#include <gsl/gsl_sort.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double d[4] = {2.5, x, 0.5, 1.5};
    gsl_sort(d, 1, 4);
    return cq_measure((int)(2.0 * d[1]));
}
