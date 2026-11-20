/* gsl_hypot(x, 3.0): sqrt(x^2 + 9) without overflow, x a double with two quantum bits. */
#include <gsl/gsl_math.h>
#include <gsl/gsl_sys.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);
    return cq_measure((int)gsl_hypot(x, 3.0));
}
