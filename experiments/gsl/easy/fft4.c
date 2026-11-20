/* gsl_fft_complex_radix2_forward on 4 complex points, one real part with two quantum bits. */
#include <gsl/gsl_fft_complex.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double d[8] = {x, 0.0, 1.0, 0.0, 2.0, 0.0, 3.0, 0.0};
    gsl_fft_complex_radix2_forward(d, 1, 4);
    return cq_measure((int)(d[0] + d[2]));
}
